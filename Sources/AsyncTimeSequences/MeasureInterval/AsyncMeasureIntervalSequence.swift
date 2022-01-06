//
//  AsyncMeasureIntervalSequences.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 27/12/21.
//

import Foundation
import Combine

public struct AsyncMeasureIntervalSequence<Base: AsyncSequence> {
    @usableFromInline
    let base: Base
    
    @usableFromInline
    let scheduler: AsyncScheduler

    @usableFromInline
    init(_ base: Base, using scheduler: AsyncScheduler) {
        self.base = base
        self.scheduler = scheduler
    }
}

extension AsyncSequence {
    @inlinable
    public __consuming func measureInterval(
        using scheduler: AsyncScheduler
    ) -> AsyncMeasureIntervalSequence<Self> {
        return AsyncMeasureIntervalSequence(self, using: scheduler)
    }
}

extension AsyncMeasureIntervalSequence: AsyncSequence {
    
    public typealias Element = TimeInterval
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = AsyncStream<TimeInterval>.Iterator

    actor MeasureIntervalActor {
        let continuation: AsyncStream<TimeInterval>.Continuation
        let scheduler: AsyncScheduler

        var lastTime: TimeInterval?

        init(
            continuation: AsyncStream<TimeInterval>.Continuation,
            scheduler: AsyncScheduler
        ) {
            self.continuation = continuation
            self.scheduler = scheduler
        }

        func putNext() async {
            let now = await scheduler.now
            
            if let lastTime = lastTime {
                let distance = lastTime.distance(to: now)
                yield(distance)
            }
                
            self.lastTime = now
        }

        func finish() {
            continuation.finish()
        }

        private func yield(_ element: TimeInterval) {
            continuation.yield(element)
        }
    }

    @usableFromInline
    struct MeasureInterval {
        private var baseIterator: Base.AsyncIterator
        private let actor: MeasureIntervalActor

        @usableFromInline
        init(
            baseIterator: Base.AsyncIterator,
            continuation: AsyncStream<TimeInterval>.Continuation,
            scheduler: AsyncScheduler
        ) {
            self.baseIterator = baseIterator
            self.actor = MeasureIntervalActor(
                continuation: continuation,
                scheduler: scheduler
            )
        }

        @usableFromInline
        mutating func start() async {
            while (try? await baseIterator.next() != nil) ?? false {
                await actor.putNext()
            }
            await actor.finish()
        }
    }

    @inlinable
    public __consuming func makeAsyncIterator() -> AsyncStream<TimeInterval>.Iterator {
        return AsyncStream { (continuation: AsyncStream<TimeInterval>.Continuation) in
            Task {
                var measureInterval = MeasureInterval(
                    baseIterator: base.makeAsyncIterator(),
                    continuation: continuation,
                    scheduler: scheduler
                )
                await measureInterval.start()
            }
        }.makeAsyncIterator()
    }
}
