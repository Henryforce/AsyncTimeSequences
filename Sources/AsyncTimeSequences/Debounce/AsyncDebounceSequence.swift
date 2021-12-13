//
//  AsyncDebounceSequence.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import Foundation
import Combine

public struct AsyncDebounceSequence<Base: AsyncSequence, S: Scheduler> {
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
    public __consuming func debounce<S: Scheduler>(
        for interval: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> AsyncDebounceSequence<Self, S> {
        return AsyncDebounceSequence(self, interval: interval, scheduler: scheduler)
    }
}

extension AsyncDebounceSequence: AsyncSequence {
    
    public typealias Element = Base.Element
    /// The type of iterator that produces elements of the sequence.
    public typealias AsyncIterator = AsyncStream<Base.Element>.Iterator

    actor DebounceActor<S: Scheduler> {
        let continuation: AsyncStream<Base.Element>.Continuation
        let interval: S.SchedulerTimeType.Stride
        let scheduler: S

        var task: Task<Void, Never>?
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
            task?.cancel() // Only the last task will yield
            
            task = Task {
                await scheduler.sleep(interval)
                guard !Task.isCancelled else { return }
                yield(element)
            }
        }

        func finish() {
            // If there are still elements waiting to be yielded, flag the finish variable
            shouldFinish = true
    
            // If there are no elements waiting to be yielded, finish now
            if task?.isCancelled ?? true {
                continuation.finish()
            }
        }

        private func yield(_ element: Base.Element) {
            continuation.yield(element)
            
            // The flag to finish was set while waiting, finish now
            if shouldFinish {
                continuation.finish()
            }
        }
    }

    struct Debounce<S: Scheduler> {
//        @usableFromInline
        var baseIterator: Base.AsyncIterator
//        @usableFromInline
        let actor: DebounceActor<S>

        init(
            baseIterator: Base.AsyncIterator,
            continuation: AsyncStream<Base.Element>.Continuation,
            interval: S.SchedulerTimeType.Stride,
            scheduler: S
        ) {
            self.baseIterator = baseIterator
            self.actor = DebounceActor(
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
