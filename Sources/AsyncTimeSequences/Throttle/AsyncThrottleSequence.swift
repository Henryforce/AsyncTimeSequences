//
//  AsyncThrottleSequence.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import Foundation
import Combine

extension AsyncSequence {
    @inlinable
    public __consuming func throttle<S: Scheduler>(
        for interval: S.SchedulerTimeType.Stride,
        scheduler: S,
        latest: Bool
    ) -> AsyncThrottleSequence<Self, S> {
        return AsyncThrottleSequence(self, interval: interval, scheduler: scheduler, latest: latest)
    }
}

public struct AsyncThrottleSequence<Base: AsyncSequence, S: Scheduler> {
    @usableFromInline
    let base: Base

    @usableFromInline
    let interval: S.SchedulerTimeType.Stride
    
    @usableFromInline
    let scheduler: S

    @usableFromInline
    let latest: Bool

    @usableFromInline
    init(_ base: Base, interval: S.SchedulerTimeType.Stride, scheduler: S, latest: Bool) {
        self.base = base
        self.interval = interval
        self.scheduler = scheduler
        self.latest = latest
    }
}

extension AsyncThrottleSequence: AsyncSequence {
    
    public typealias Element = Base.Element
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = AsyncStream<Base.Element>.Iterator

    actor ThrottleActor<S: Scheduler> {
        let continuation: AsyncStream<Base.Element>.Continuation
        let interval: S.SchedulerTimeType.Stride
        let scheduler: S
        let latest: Bool
        
        var savedElement: Base.Element?
        var readyToSendFirst = false
        var started = false
        var shouldFinish = false

        init(
            continuation: AsyncStream<Base.Element>.Continuation,
            interval: S.SchedulerTimeType.Stride,
            scheduler: S,
            latest: Bool
        ) {
            self.continuation = continuation
            self.interval = interval
            self.scheduler = scheduler
            self.latest = latest
        }

        func putNext(_ element: Base.Element) {
            savedElement = element
            
            if !started {
                start()
            } else {
                scheduler.schedule(interval: interval, closure: { })
            }
            
            if !latest, readyToSendFirst {
                readyToSendFirst = false
                yield()
            }
        }

        func finish() {
            shouldFinish = true
            if savedElement == nil, !started {
                continuation.finish()
            }
        }
        
        func start() {
            guard !started else { return }
            started = true
            runTimer()
        }
        
        private func yield() {
            if let element = savedElement {
                continuation.yield(element)
                savedElement = nil
            }
            
            if shouldFinish {
                continuation.finish()
            }
        }
        
        private func runTimer() {
            guard !shouldFinish else { return }
            readyToSendFirst = true
            scheduler.schedule(interval: interval, closure: { [weak self] in
                await self?.closureFromTimer()
            })
        }
        
        private func closureFromTimer() {
            if latest {
                yield()
            }
            runTimer()
        }
    }

    @usableFromInline
    struct Throttle<S: Scheduler> {
        private var baseIterator: Base.AsyncIterator
        private let actor: ThrottleActor<S>

        @usableFromInline
        init(
            baseIterator: Base.AsyncIterator,
            continuation: AsyncStream<Base.Element>.Continuation,
            interval: S.SchedulerTimeType.Stride,
            scheduler: S,
            latest: Bool
        ) {
            self.baseIterator = baseIterator
            self.actor = ThrottleActor(
                continuation: continuation,
                interval: interval,
                scheduler: scheduler,
                latest: latest
            )
        }

        @usableFromInline
        mutating func start() async {
            while let element = try? await baseIterator.next() {
                await actor.putNext(element)
            }
            await actor.finish()
        }
    }

    @inlinable
    public __consuming func makeAsyncIterator() -> AsyncStream<Base.Element>.Iterator {
        return AsyncStream { (continuation: AsyncStream<Base.Element>.Continuation) in
            Task {
                var throttle = Throttle(
                    baseIterator: base.makeAsyncIterator(),
                    continuation: continuation,
                    interval: interval,
                    scheduler: scheduler,
                    latest: latest
                )
                await throttle.start()
            }
        }.makeAsyncIterator()
    }
}
