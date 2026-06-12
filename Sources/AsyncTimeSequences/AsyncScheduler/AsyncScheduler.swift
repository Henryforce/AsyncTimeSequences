//
//  AsyncScheduler.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 5/1/22.
//

import Foundation

public typealias AsyncSchedulerHandler = @Sendable () async -> Void

public protocol AsyncScheduler: Actor {
  var now: TimeInterval { get }

  @discardableResult
  func schedule(after: TimeInterval, handler: @escaping AsyncSchedulerHandler) -> Task<Void, Never>
}

public actor MainAsyncScheduler: AsyncScheduler {
  public static let `default` = MainAsyncScheduler()

  lazy var queue = MinimumPriorityQueue()
  lazy var idCounter: UInt = 0
  lazy var completedElementIds = Set<UInt>()
  lazy var cancelledElementIds = Set<UInt>()
  private var isCompletingElement = false

  public var now: TimeInterval {
    Date().timeIntervalSince1970
  }

  /// Schedule async-closures to be executed in order based on the timeinterval provided.
  ///
  /// - parameter after: TimeInterval to wait until execution
  /// - parameter handler: async closure to be executed when 'after' time elapses
  ///
  /// - Returns: reference to a Task which supports cancellation
  @discardableResult
  public func schedule(
    after: TimeInterval,
    handler: @escaping AsyncSchedulerHandler
  ) -> Task<Void, Never> {
    let currentId = idCounter
    let element = AsyncSchedulerHandlerElement(
      handler: handler,
      id: currentId,
      time: now + after
    )

    queue.enqueue(element)

    increaseCounterId()

    return createScheduledExecutionTask(currentId: currentId, after: after)
  }

  /// Based on the timeIntervalSince1970 from Date, the smallest intervals will need
  /// to complete before other elements' handlers can be executed. Due to the nature
  /// of Tasks, there could be some situations where some tasks scheduled to finish
  /// before others finish first. This could potentially have unwanted behaviors on
  /// objects scheduling events.
  ///
  /// - parameter currentId: integer variable denoting handler/task id
  ///
  /// - Returns: reference to a Task which supports cancellation
  private func createScheduledExecutionTask(
    currentId: UInt,
    after: TimeInterval
  ) -> Task<Void, Never> {
    return Task {
      if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
        try? await Task.sleep(for: .seconds(after))
      } else {
        try? await Task.sleep(nanoseconds: UInt64(after * 1_000_000_000))
      }

      completedElementIds.insert(currentId)
      if Task.isCancelled {
        cancelledElementIds.insert(currentId)
      }

      // Make sure that only one complete method is running at all times.
      // The reason why this is important is because there is an inner await in a while loop which
      // releases the execution of this actor and it cause race conditions if another scheduled
      // task completes within the time this method is executing causing a weird state where two
      // while loops might have erroneous values and destroy the serial execution intended from
      // this method.
      guard !isCompletingElement else { return }

      // Block any other Tasks from calling complete from this point.
      isCompletingElement = true

      await complete(currentId: currentId)

      // Allow any future callers of this method to call complete.
      isCompletingElement = false
    }
  }

  /// This method runs the completion handler for a given scheduled item matching the `currentId`.
  ///
  /// A minimum priority queue is critical to always keep the first element that should be
  /// completed in the top of the queue. Once its task completes, a Set will keep track of all
  /// completed ID tasks that are yet to be executed. If the current top element of
  /// the queue has already completed, its closure will execute. This will repeat
  /// until all completed top elements of the queue are executed.
  /// The obvious drawback of this handling, is that a small delay could be
  /// introduced to some scheduled async-closures. Ideally, this would be in the
  /// order of micro/nanoseconds depending of the system load.
  ///
  /// This method will execute an inner loop resolving all available completed elements.
  ///
  /// Note that his actor switches execution and during this `paused` time another scheduled task
  /// can complete and call `complete`. It is important to have only one `complete` running at
  /// all times (specifically, due the inner while loop).
  ///
  /// This method should only be called from within `createScheduledExecutionTask`.
  ///
  /// - Complexity: O(log n) where n is the number of elements currently scheduled
  private func complete(currentId: UInt) async {
    while let minElement = queue.peek, completedElementIds.contains(minElement.id) {
      queue.removeFirst()
      completedElementIds.remove(minElement.id)
      // If the current minimum element id is not cancelled, proceed to
      // complete its handler. Otherwise, skip and remove it from the set
      guard !cancelledElementIds.contains(minElement.id) else {
        cancelledElementIds.remove(minElement.id)
        continue
      }
      await minElement.handler()
    }
  }

  private func increaseCounterId() {
    if idCounter == UInt.max {
      idCounter = .zero
    } else {
      idCounter += 1
    }
  }
}
