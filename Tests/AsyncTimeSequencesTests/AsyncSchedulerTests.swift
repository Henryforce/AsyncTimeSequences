//
//  AsyncSchedulerTests.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 12/2/22.
//

import XCTest

@testable import AsyncTimeSequences

final class AsyncSchedulerTests: XCTestCase {

  func testMainAsyncSchedulerSortsScheduledClosures() async {
    // Given
    let scheduler = MainAsyncScheduler()

    // When
    let (expectedResult, result) = await subTest(with: scheduler)
    let isQueueEmpty = await scheduler.isQueueEmpty()
    let allItemsCompleted = await scheduler.areAllScheduledItemsCompleted()

    // Then
    XCTAssertEqual(expectedResult, result)
    XCTAssertTrue(isQueueEmpty)
    XCTAssertTrue(allItemsCompleted)
  }

  /// NOTE: This is a slow test, which depends on time waiting in the order of milliseconds
  func testMainAsyncSchedulerReturnsACancellableTask() async {
    // Given
    let scheduler = MainAsyncScheduler()
    let firstExpectation = XCTestExpectation(description: "First Expectation")
    let secondExpectation = XCTestExpectation(description: "Second Expectation")
    var setCounter = Set<Int>()

    // When
    // schedule after 100us
    await scheduler.schedule(after: 0.0001) {
      setCounter.insert(1)
      firstExpectation.fulfill()
    }
    // schedule after 15 ms
    let cancellableTask = await scheduler.schedule(after: 0.030) {
      setCounter.insert(2)
      XCTFail("This should be triggered once cancelled")
    }
    // Without cancelling the task, it would execute and fail
    cancellableTask.cancel()
    // schedule after 100us
    await scheduler.schedule(after: 0.0001) {
      setCounter.insert(3)
      secondExpectation.fulfill()
    }

    wait(for: [firstExpectation, secondExpectation], timeout: 1.0)

    // The cancelled task is scheduled after 30 ms, hence waiting for 50ms
    try? await Task.sleep(milliseconds: 50)

    let isQueueEmpty = await scheduler.isQueueEmpty()
    let allItemsCompleted = await scheduler.areAllScheduledItemsCompleted()

    // Then
    XCTAssertFalse(setCounter.contains(2))
    XCTAssertEqual(setCounter, Set([1, 3]))
    XCTAssertTrue(isQueueEmpty)
    XCTAssertTrue(allItemsCompleted)
  }

  // Uncomment to see the flaky behavior of a scheduler without time-based ordering
  //    func testFakeAsyncScheduler() async {
  //        // Given
  //        let scheduler = FlakyAsyncScheduler()
  //
  //        // When
  //        let (expectedResult, result) = await subTest(with: scheduler)
  //
  //        // Then
  //        XCTAssertEqual(expectedResult, result)
  //    }
  //
  //    actor FlakyAsyncScheduler: AsyncScheduler {
  //        var now: TimeInterval {
  //            Date().timeIntervalSince1970
  //        }
  //        func schedule(after: TimeInterval, handler: @escaping AsyncSchedulerHandler) {
  //            Task {
  //                try? await Task.sleep(nanoseconds: UInt64(after * 1000000000))
  //                await handler()
  //            }
  //        }
  //    }

  /// This test aims to identify the case when many elements are scheduled almost immediately
  /// and the time interval is in the ordered of microseconds. Given the Task behavior plus
  /// the use of Task.sleep() will result in a random execution order of scheduled closures
  /// if not properly handled.
  private func subTest(with scheduler: AsyncScheduler) async -> ([Int], [Int]) {
    // Given
    let timeInterval: TimeInterval = 0.0001  // 100us
    let safeActorArray = SafeActorArrayWrapper<Int>()
    var expectedResult = [Int]()
    let maxElements = 100

    // When
    for index in 0..<maxElements {
      expectedResult.append(index)
      await scheduler.schedule(after: timeInterval) {
        await safeActorArray.append(index)
      }
    }

    // Then
    await safeActorArray.waitForElements(maxElements)
    let result = await safeActorArray.elements
    return (expectedResult, result)
  }

}

/// This extension was defined to bypass a possible bug on actors on the current build version.
/// By some reason, accessing actor properties directly can sometimes result in a crash even
/// if accessing them via await. A workaround was found: accessing the properties via an async
/// function. This workaround is aimed to be temporal and further investigation is required.
extension MainAsyncScheduler {
  func isQueueEmpty() async -> Bool { queue.isEmpty }
  func areAllScheduledItemsCompleted() async -> Bool { completedElementIds.isEmpty }
}
