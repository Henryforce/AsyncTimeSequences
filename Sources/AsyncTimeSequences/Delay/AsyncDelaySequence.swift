//
//  AsyncDelaySequence.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import Foundation
import Combine
import AsyncTimeSequencesDataStructures

public struct AsyncDelaySequence<Base: AsyncSequence> {
    @usableFromInline
    let base: Base

    @usableFromInline
    let interval: TimeInterval
    
    @usableFromInline
    let scheduler: AsyncScheduler

    @usableFromInline
    init(_ base: Base, interval: TimeInterval, scheduler: AsyncScheduler) {
        self.base = base
        self.interval = interval
        self.scheduler = scheduler
    }
}

extension AsyncSequence {
    @inlinable
    public __consuming func delay(
        for interval: TimeInterval,
        scheduler: AsyncScheduler
    ) -> AsyncDelaySequence<Self> {
        return AsyncDelaySequence(self, interval: interval, scheduler: scheduler)
    }
}

extension AsyncDelaySequence: AsyncSequence {
    
    public typealias Element = Base.Element
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = AsyncStream<Base.Element>.Iterator

    actor DelayActor {
        let continuation: AsyncStream<Base.Element>.Continuation
        let interval: TimeInterval
        let scheduler: AsyncScheduler
        
        var dequeue = Dequeue<UInt>()
        var ids = [UInt: Base.Element]()
        var nextID: UInt = 0
        var shouldFinish = false

        init(
            continuation: AsyncStream<Base.Element>.Continuation,
            interval: TimeInterval,
            scheduler: AsyncScheduler
        ) {
            self.continuation = continuation
            self.interval = interval
            self.scheduler = scheduler
        }

        func putNext(_ element: Base.Element) async {
            let currentID = nextID
            dequeue.enqueue(currentID)
            nextID += 1
            
            await scheduler.schedule(after: interval, handler: { [weak self] in
                await self?.processAfterDelay(element: element, currentID: currentID)
            })
        }

        func finish() {
            // If there are still elements waiting to be yielded, flag the finish variable
            shouldFinish = true
    
            // If there are no elements waiting to be yielded, finish now
            if dequeue.isEmpty {
                continuation.finish()
            }
        }
        
        private func processAfterDelay(element: Base.Element, currentID: UInt) {
            ids[currentID] = element
            while let first = dequeue.peek(), let savedElement = ids[first] {
                dequeue.dequeue()
                ids.removeValue(forKey: first)

                yield(savedElement)
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

    struct Delay {
//        @usableFromInline
        var baseIterator: Base.AsyncIterator
//        @usableFromInline
        let actor: DelayActor

        init(
            baseIterator: Base.AsyncIterator,
            continuation: AsyncStream<Base.Element>.Continuation,
            interval: TimeInterval,
            scheduler: AsyncScheduler
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
