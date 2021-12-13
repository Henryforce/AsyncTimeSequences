//
//  AsyncDelaySequence.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import Foundation
import Combine

public struct AsyncDelaySequence<Base: AsyncSequence, S: Scheduler> {
    @usableFromInline
    let base: Base

    @usableFromInline
    let interval: S.SchedulerTimeType.Stride
    
    @usableFromInline
    let scheduler: S

    @usableFromInline
    init(_ base: Base, interval: S.SchedulerTimeType.Stride, scheduler: S) {
        self.base = base
        self.interval = interval
        self.scheduler = scheduler
    }
}

extension AsyncSequence {
    @inlinable
    public __consuming func delay<S: Scheduler>(
        for interval: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> AsyncDelaySequence<Self, S> {
        return AsyncDelaySequence(self, interval: interval, scheduler: scheduler)
    }
}

extension AsyncDelaySequence: AsyncSequence {
    
    public typealias Element = Base.Element
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = AsyncStream<Base.Element>.Iterator

    actor DelayActor<S: Scheduler> {
        let continuation: AsyncStream<Base.Element>.Continuation
        let interval: S.SchedulerTimeType.Stride
        let scheduler: S
        
        var dequeue = Dequeue<UInt64>()
        var ids = [UInt64: Base.Element]()
        var nextID: UInt64 = 0
        var shouldFinish = false

        init(
            continuation: AsyncStream<Base.Element>.Continuation,
            interval: S.SchedulerTimeType.Stride,
            scheduler: S
        ) {
            self.continuation = continuation
            self.interval = interval
            self.scheduler = scheduler
        }

        func putNext(_ element: Base.Element) {
            let currentID = nextID
            dequeue.enqueue(currentID)
            nextID += 1
            
            Task {
                await scheduler.sleep(interval)
                
                ids[currentID] = element
                while let first = dequeue.peek(), let savedElement = ids[first] {
                    dequeue.dequeue()
                    ids.removeValue(forKey: first)
                    
                    yield(savedElement)
                }
            }
        }

        func finish() {
            // If there are still elements waiting to be yielded, flag the finish variable
            shouldFinish = true
    
            // If there are no elements waiting to be yielded, finish now
            if dequeue.isEmpty {
                continuation.finish()
            }
        }

        private func yield(_ element: Base.Element) {
            continuation.yield(element)
            
            // The flag to finish was set while waiting, finish now
            if shouldFinish, dequeue.isEmpty {
                continuation.finish()
            }
        }
    }

    struct Delay<S: Scheduler> {
//        @usableFromInline
        var baseIterator: Base.AsyncIterator
//        @usableFromInline
        let actor: DelayActor<S>

        init(
            baseIterator: Base.AsyncIterator,
            continuation: AsyncStream<Base.Element>.Continuation,
            interval: S.SchedulerTimeType.Stride,
            scheduler: S
        ) {
            self.baseIterator = baseIterator
            self.actor = DelayActor(
                continuation: continuation,
                interval: interval,
                scheduler: scheduler
            )
        }

//        @usableFromInline
        mutating func start() async {
            while let element = try? await baseIterator.next() {
                await actor.putNext(element)
            }
            await actor.finish()
        }
    }

//    @inlinable
    public __consuming func makeAsyncIterator() -> AsyncStream<Base.Element>.Iterator {
        return AsyncStream { (continuation: AsyncStream<Base.Element>.Continuation) in
            Task {
                var delay = Delay(
                    baseIterator: base.makeAsyncIterator(),
                    continuation: continuation,
                    interval: interval,
                    scheduler: scheduler
                )
                await delay.start()
            }
        }.makeAsyncIterator()
    }
}
