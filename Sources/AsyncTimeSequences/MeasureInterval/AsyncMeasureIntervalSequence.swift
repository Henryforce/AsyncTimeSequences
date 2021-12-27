//
//  AsyncMeasureIntervalSequences.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 27/12/21.
//

import Foundation
import Combine

public struct AsyncMeasureIntervalSequence<Base: AsyncSequence, S: Scheduler> {
    @usableFromInline
    let base: Base
    
    @usableFromInline
    let scheduler: S

    @usableFromInline
    init(_ base: Base, using scheduler: S) {
        self.base = base
        self.scheduler = scheduler
    }
}

extension AsyncSequence {
    @inlinable
    public __consuming func measureInterval<S: Scheduler>(
        using scheduler: S
    ) -> AsyncMeasureIntervalSequence<Self, S> {
        return AsyncMeasureIntervalSequence(self, using: scheduler)
    }
}

extension AsyncMeasureIntervalSequence: AsyncSequence {
    
    public typealias Element = S.SchedulerTimeType.Stride
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = AsyncStream<S.SchedulerTimeType.Stride>.Iterator

    actor MeasureIntervalActor<S: Scheduler> {
        let continuation: AsyncStream<S.SchedulerTimeType.Stride>.Continuation
        let scheduler: S

        var lastTime: S.SchedulerTimeType?

        init(
            continuation: AsyncStream<S.SchedulerTimeType.Stride>.Continuation,
            scheduler: S
        ) {
            self.continuation = continuation
            self.scheduler = scheduler
        }

        func putNext() {
            let now = scheduler.now
            
            if let lastTime = lastTime {
                let distance = lastTime.distance(to: now)
                yield(distance)
            }
                
            self.lastTime = now
            
            // Just to inform the scheduler there has been a time event processed..
            scheduler.schedule(interval: 0, closure: { })
        }

        func finish() {
            continuation.finish()
        }

        private func yield(_ element: S.SchedulerTimeType.Stride) {
            continuation.yield(element)
        }
    }

    struct MeasureInterval<S: Scheduler> {
//        @usableFromInline
        var baseIterator: Base.AsyncIterator
//        @usableFromInline
        let actor: MeasureIntervalActor<S>

        init(
            baseIterator: Base.AsyncIterator,
            continuation: AsyncStream<S.SchedulerTimeType.Stride>.Continuation,
            scheduler: S
        ) {
            self.baseIterator = baseIterator
            self.actor = MeasureIntervalActor(
                continuation: continuation,
                scheduler: scheduler
            )
        }

//        @usableFromInline
        mutating func start() async {
            while (try? await baseIterator.next() != nil) ?? false {
                await actor.putNext()
            }
            await actor.finish()
        }
    }

//    @inlinable
    public __consuming func makeAsyncIterator() -> AsyncStream<S.SchedulerTimeType.Stride>.Iterator {
        return AsyncStream { (continuation: AsyncStream<S.SchedulerTimeType.Stride>.Continuation) in
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
