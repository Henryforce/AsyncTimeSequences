//
//  AsyncTimeoutSequence.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 22/11/21.
//

import Foundation
import Combine

public struct AsyncTimeoutSequence<Base: AsyncSequence, S: Scheduler> {
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
    public __consuming func timeout<S: Scheduler>(
        for interval: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> AsyncTimeoutSequence<Self, S> {
        return AsyncTimeoutSequence(self, interval: interval, scheduler: scheduler)
    }
}

public enum AsyncTimeSequenceError: Error {
    case timeout
}

extension AsyncTimeoutSequence: AsyncSequence {
    
    public typealias Element = Base.Element
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = AsyncThrowingStream<Base.Element, Error>.Iterator

    actor TimeoutActor<S: Scheduler> {
        let continuation: AsyncThrowingStream<Base.Element, Error>.Continuation
        let interval: S.SchedulerTimeType.Stride
        let scheduler: S

        var task: Task<Void, Never>?

        init(
            continuation: AsyncThrowingStream<Base.Element, Error>.Continuation,
            interval: S.SchedulerTimeType.Stride,
            scheduler: S
        ) {
            self.continuation = continuation
            self.interval = interval
            self.scheduler = scheduler
        }
        
        func start() {
            startTask()
        }

        func putNext(_ element: Base.Element) {
            task?.cancel()
            yield(element)
            startTask()
        }

        func finish() {
            task?.cancel()
            continuation.finish(throwing: nil)
        }

        private func yield(_ element: Base.Element) {
            continuation.yield(element)
        }
        
        private func yield(error: Error) {
            continuation.finish(throwing: error)
        }
        
        private func startTask() {
            task = Task {
                await scheduler.sleep(interval)
                yield(error: AsyncTimeSequenceError.timeout)
            }
        }
    }

    struct Timeout<S: Scheduler> {
//        @usableFromInline
        var baseIterator: Base.AsyncIterator
//        @usableFromInline
        let actor: TimeoutActor<S>

        init(
            baseIterator: Base.AsyncIterator,
            continuation: AsyncThrowingStream<Base.Element, Error>.Continuation,
            interval: S.SchedulerTimeType.Stride,
            scheduler: S
        ) {
            self.baseIterator = baseIterator
            self.actor = TimeoutActor(
                continuation: continuation,
                interval: interval,
                scheduler: scheduler
            )
        }

//        @usableFromInline
        mutating func start() async {
            await actor.start()
            while let element = try? await baseIterator.next() {
                await actor.putNext(element)
            }
            await actor.finish()
        }
    }

//    @inlinable
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
