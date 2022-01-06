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
    public __consuming func throttle(
        for interval: TimeInterval,
        scheduler: AsyncScheduler,
        latest: Bool
    ) -> AsyncThrottleSequence<Self> {
        return AsyncThrottleSequence(self, interval: interval, scheduler: scheduler, latest: latest)
    }
}

public struct AsyncThrottleSequence<Base: AsyncSequence> {
    @usableFromInline
    let base: Base

    @usableFromInline
    let interval: TimeInterval
    
    @usableFromInline
    let scheduler: AsyncScheduler

    @usableFromInline
    let latest: Bool

    @usableFromInline
    init(_ base: Base, interval: TimeInterval, scheduler: AsyncScheduler, latest: Bool) {
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

    actor ThrottleActor {
        let continuation: AsyncStream<Base.Element>.Continuation
        let interval: TimeInterval
        let scheduler: AsyncScheduler
        let latest: Bool
        
        var savedElement: Base.Element?
        var readyToSendFirst = false
        var started = false
        var shouldFinish = false

        init(
            continuation: AsyncStream<Base.Element>.Continuation,
            interval: TimeInterval,
            scheduler: AsyncScheduler,
            latest: Bool
        ) {
            self.continuation = continuation
            self.interval = interval
            self.scheduler = scheduler
            self.latest = latest
        }

        func putNext(_ element: Base.Element) async {
            savedElement = element
            
            if !started {
                await start()
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
        
        func start() async {
            guard !started else { return }
            started = true
            await runTimer()
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
        
        private func runTimer() async {
            guard !shouldFinish else { return }
            readyToSendFirst = true
            await scheduler.schedule(after: interval) { [weak self] in
                await self?.closureFromTimer()
            }
        }
        
        private func closureFromTimer() async {
            if latest {
                yield()
            }
            await runTimer()
        }
    }

    @usableFromInline
    struct Throttle {
        private var baseIterator: Base.AsyncIterator
        private let actor: ThrottleActor

        @usableFromInline
        init(
            baseIterator: Base.AsyncIterator,
            continuation: AsyncStream<Base.Element>.Continuation,
            interval: TimeInterval,
            scheduler: AsyncScheduler,
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
