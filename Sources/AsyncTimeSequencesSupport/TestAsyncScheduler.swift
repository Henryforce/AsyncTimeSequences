//
//  TestAsyncScheduler.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 5/1/22.
//

import AsyncTimeSequences
import Foundation

/// This class conforms to AsyncScheduler and provides convenient functions to easily test async time sequences.
public actor TestAsyncScheduler: AsyncScheduler {

  struct QueueItem {
    let interval: TimeInterval
    let handler: AsyncSchedulerHandler
  }

  private let queue = Dequeue<QueueItem>()
  private var savedContinuation: CheckedContinuation<Void, Never>?
  private var savedContinuationCount: Int = .zero

  public var now: TimeInterval = Date().timeIntervalSince1970

  public init() {}

  /// Schedule an async handler to be executed after a specific interval.
  /// All the async handler will be enqueued until advance() is called for processing.
  /// This function will also check if n jobs have been scheduled and try to resume a
  /// saved continuation set during waitForScheduledJobs().
  public func schedule(
    after interval: TimeInterval,
    handler: @escaping AsyncSchedulerHandler
  ) -> Task<Void, Never> {
    let item = QueueItem(interval: interval + now, handler: handler)
    queue.enqueue(item)

    checkForSavedContinuation()

    // TODO: decide whether or not to support cancellation with this Task
    return Task {}
  }

  /// Advances local time interval and executes all enqueued async handlers that are
  /// contained within the advanced interval.
  public func advance(by interval: TimeInterval) async {
    let threshold = now + interval
    now = threshold

    while let peekedItem = queue.peek(), peekedItem.interval <= now,
      let item = queue.dequeue()
    {
      await item.handler()
    }
  }

  /// This function waits until n jobs are scheduled via the schedule() function.
  /// If there are already n jobs scheduled, this function will return immediately.
  public func waitForScheduledJobs(count: Int) async {
    await withCheckedContinuation({ (continuation: CheckedContinuation<Void, Never>) in
      if queue.count >= count {
        continuation.resume()
        return
      }
      savedContinuation = continuation
    })
  }

  private func checkForSavedContinuation() {
    guard let savedContinuation = savedContinuation,
      queue.count >= savedContinuationCount
    else { return }
    savedContinuationCount = .zero
    savedContinuation.resume()
    self.savedContinuation = nil
  }
}
