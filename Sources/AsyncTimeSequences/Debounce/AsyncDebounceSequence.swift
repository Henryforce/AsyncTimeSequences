//
//  AsyncDebounceSequence.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import Foundation
import Combine

public struct AsyncDebounceSequence<Base: AsyncSequence> {
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
    public __consuming func debounce(
        for interval: TimeInterval,
        scheduler: AsyncScheduler
    ) -> AsyncDebounceSequence<Self> {
        return AsyncDebounceSequence(self, interval: interval, scheduler: scheduler)
    }
}

extension AsyncDebounceSequence: AsyncSequence {
    
    public typealias Element = Base.Element
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = AsyncStream<Base.Element>.Iterator

    actor DebounceActor {
        let continuation: AsyncStream<Base.Element>.Continuation
        let interval: TimeInterval
        let scheduler: AsyncScheduler

        var counter: UInt = .zero
        var scheduledCount: UInt = .zero
        var finishedContinuation: CheckedContinuation<Void, Never>?

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
            let localCounter = updateCounter()
            scheduledCount += 1
            await scheduler.schedule(after: interval, handler: { [weak self] in
                await self?.yield(element, savedCounter: localCounter)
            })
        }

        func finish() async {
            if scheduledCount == .zero {
                continuation.finish()
            } else {
                // Keep the owner of the actor waiting for the end to avoid having this actor released from memory
                await withCheckedContinuation({ (continuation: CheckedContinuation<Void, Never>) in
                    finishedContinuation = continuation
                })
            }
        }
        
        private func updateCounter() -> UInt {
            counter += 1
            if counter == .max {
                counter = .zero
            }
            return counter
        }

        private func yield(_ element: Base.Element, savedCounter: UInt) {
            scheduledCount -= 1
            
            guard savedCounter == counter else { return }
            
            continuation.yield(element)
            
            // If finished has been triggered and there are no more items in the queue, finish now
            if let finishedContinuation = finishedContinuation {
                continuation.finish()
                finishedContinuation.resume()
                self.finishedContinuation = nil
            }
        }
    }

    @usableFromInline
    struct Debounce {
        private var baseIterator: Base.AsyncIterator
        private let actor: DebounceActor

        @usableFromInline
        init(
            baseIterator: Base.AsyncIterator,
            continuation: AsyncStream<Base.Element>.Continuation,
            interval: TimeInterval,
            scheduler: AsyncScheduler
        ) {
            self.baseIterator = baseIterator
            self.actor = DebounceActor(
                continuation: continuation,
                interval: interval,
                scheduler: scheduler
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
                var debounce = Debounce(
                    baseIterator: base.makeAsyncIterator(),
                    continuation: continuation,
                    interval: interval,
                    scheduler: scheduler
                )
                await debounce.start()
            }
        }.makeAsyncIterator()
    }
}
