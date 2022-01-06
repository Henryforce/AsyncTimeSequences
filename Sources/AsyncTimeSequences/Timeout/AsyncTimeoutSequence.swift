//
//  AsyncTimeoutSequence.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 22/11/21.
//

import Foundation
import Combine

public struct AsyncTimeoutSequence<Base: AsyncSequence> {
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
    public __consuming func timeout(
        for interval: TimeInterval,
        scheduler: AsyncScheduler
    ) -> AsyncTimeoutSequence<Self> {
        return AsyncTimeoutSequence(self, interval: interval, scheduler: scheduler)
    }
}

public enum AsyncTimeSequenceError: Error {
    case timeout
}

// TODO: handle continuation.finish being called multiple times
extension AsyncTimeoutSequence: AsyncSequence {
    
    public typealias Element = Base.Element
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = AsyncThrowingStream<Base.Element, Error>.Iterator

    actor TimeoutActor {
        let continuation: AsyncThrowingStream<Base.Element, Error>.Continuation
        let interval: TimeInterval
        let scheduler: AsyncScheduler

        var counter: UInt = .zero

        init(
            continuation: AsyncThrowingStream<Base.Element, Error>.Continuation,
            interval: TimeInterval,
            scheduler: AsyncScheduler
        ) {
            self.continuation = continuation
            self.interval = interval
            self.scheduler = scheduler
        }
        
        func start() async {
            await startTimeout()
        }

        func putNext(_ element: Base.Element) async {
            yield(element)
            await startTimeout()
        }

        func finish() {
            continuation.finish(throwing: nil)
        }

        private func yield(_ element: Base.Element) {
            continuation.yield(element)
        }
        
        private func yield(error: Error, savedCounter: UInt) {
            guard counter == savedCounter else { return }
            continuation.finish(throwing: error)
        }
        
        private func startTimeout() async {
            let localCounter = updateCounter()
            await scheduler.schedule(after: interval, handler: { [weak self] in
                await self?.yield(error: AsyncTimeSequenceError.timeout, savedCounter: localCounter)
            })
        }
        
        private func updateCounter() -> UInt {
            counter += 1
            if counter == .max {
                counter = .zero
            }
            return counter
        }
    }

    @usableFromInline
    struct Timeout{
        private var baseIterator: Base.AsyncIterator
        private let actor: TimeoutActor

        @usableFromInline
        init(
            baseIterator: Base.AsyncIterator,
            continuation: AsyncThrowingStream<Base.Element, Error>.Continuation,
            interval: TimeInterval,
            scheduler: AsyncScheduler
        ) {
            self.baseIterator = baseIterator
            self.actor = TimeoutActor(
                continuation: continuation,
                interval: interval,
                scheduler: scheduler
            )
        }

        @usableFromInline
        mutating func start() async {
            await actor.start()
            while let element = try? await baseIterator.next() {
                await actor.putNext(element)
            }
            await actor.finish()
        }
    }

    @inlinable
    public __consuming func makeAsyncIterator() -> AsyncThrowingStream<Base.Element, Error>.Iterator {
        return AsyncThrowingStream { (continuation: AsyncThrowingStream<Base.Element, Error>.Continuation) in
            Task {
                var timeout = Timeout(
                    baseIterator: base.makeAsyncIterator(),
                    continuation: continuation,
                    interval: interval,
                    scheduler: scheduler
                )
                await timeout.start()
            }
        }.makeAsyncIterator()
    }
}
