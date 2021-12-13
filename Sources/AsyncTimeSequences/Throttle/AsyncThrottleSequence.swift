//
//  AsyncThrottleSequence.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import Foundation
import Combine

// TODO: work in progress

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

        var latestElement: Base.Element?
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
            latestElement = element
//            print("\tSaved as latest: \(element)")

            guard !started else { return }
            started = true
//            print("\t\tStarted: \(started)")
            Task {
                await scheduler.sleep(interval)
//                print("\tFinished waiting for \(element)")
                readyToThrottle(with: element)
            }
        }

        func finish() {
            shouldFinish = true
            if !started {
                continuation.finish()
            }
        }

        private func readyToThrottle(with initialElement: Base.Element) {
            if let elementToYield = latest ? latestElement : initialElement {
//                print("\tAbout to yield inside \(elementToYield)")
                continuation.yield(elementToYield)
            }
            started = false
            if shouldFinish {
                continuation.finish()
            }
        }
    }

    struct Throttle<S: Scheduler> {
//        @usableFromInline
        var baseIterator: Base.AsyncIterator
//        @usableFromInline
        let actor: ThrottleActor<S>

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

//public struct AsyncThrottleSequence<Base: AsyncSequence> {
//    @usableFromInline
//    let base: Base
//
//    @usableFromInline
//    let nanoseconds: UInt64
//
//    @usableFromInline
//    let latest: Bool
//
//    @usableFromInline
//    init(_ base: Base, nanoseconds: UInt64, latest: Bool) {
//        self.base = base
//        self.nanoseconds = nanoseconds
//        self.latest = latest
//    }
//}
//
//extension AsyncThrottleSequence: AsyncSequence {
//    /// The type of element produced by this asynchronous sequence.
//    ///
//    /// The map sequence produces whatever type of element its transforming
//    /// closure produces.
//    public typealias Element = Base.Element
//    /// The type of iterator that produces elements of the sequence.
//    public typealias AsyncIterator = AsyncStream<Base.Element>.Iterator
//
//    actor ThrottleActor {
//        let continuation: AsyncStream<Base.Element>.Continuation
//        let nanoseconds: UInt64
//        let latest: Bool
//
//        var latestElement: Base.Element?
//        var started = false
//        var shouldFinish = false
//
//        init(continuation: AsyncStream<Base.Element>.Continuation, nanoseconds: UInt64, latest: Bool) {
//            self.continuation = continuation
//            self.nanoseconds = nanoseconds
//            self.latest = latest
//        }
//
//        func putNext(_ element: Base.Element) {
//            latestElement = element
//            print("\tSaved as latest: \(element)")
//
//            guard !started else { return }
//            started = true
//            print("\t\tStarted: \(started)")
//            Task {
//                await Task.sleep(nanoseconds)
//                print("\tFinished waiting for \(element)")
//                readyToThrottle(with: element)
//            }
//        }
//
//        func finish() {
//            shouldFinish = true
//            if !started {
//                continuation.finish()
//            }
//        }
//
//        private func readyToThrottle(with initialElement: Base.Element) {
//            print("\tAbout to yield inside \(latestElement ?? initialElement)")
//            continuation.yield(latestElement ?? initialElement)
//            started = false
//            if shouldFinish {
//                continuation.finish()
//            }
//        }
//    }
//
//    struct Throttle {
////        @usableFromInline
//        var baseIterator: Base.AsyncIterator
//        let actor: ThrottleActor
//
//        init(
//            baseIterator: Base.AsyncIterator,
//            continuation: AsyncStream<Base.Element>.Continuation,
//            nanoseconds: UInt64,
//            latest: Bool
//        ) {
//            self.baseIterator = baseIterator
//            self.actor = ThrottleActor(
//                continuation: continuation,
//                nanoseconds: nanoseconds,
//                latest: latest
//            )
//        }
//
//        mutating func start() async {
//            while let element = try? await baseIterator.next() {
//                await actor.putNext(element)
//            }
//            await actor.finish()
//        }
//    }
//
////    @inlinable
//    public __consuming func makeAsyncIterator() -> AsyncStream<Base.Element>.Iterator {
//        return AsyncStream { (continuation: AsyncStream<Base.Element>.Continuation) in
//            Task {
//                var throttle = Throttle(
//                    baseIterator: base.makeAsyncIterator(),
//                    continuation: continuation,
//                    nanoseconds: nanoseconds,
//                    latest: latest
//                )
//                await throttle.start()
//            }
//        }.makeAsyncIterator()
//    }
//}
