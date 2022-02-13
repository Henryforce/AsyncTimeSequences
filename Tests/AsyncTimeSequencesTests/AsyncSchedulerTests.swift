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
        let scheduler = MainAsyncScheduler.default
        
        // When
        let (expectedResult, result) = await subTest(with: scheduler)
        let isQueueEmpty = await scheduler.queue.isEmpty
        let allItemsCompleted = await scheduler.completedElementIds.isEmpty
        
        // Then
        XCTAssertEqual(expectedResult, result)
        XCTAssertTrue(isQueueEmpty)
        XCTAssertTrue(allItemsCompleted)
    }
    
    // Uncomment to see the flaky behavior of a scheduler without time-based ordering
//    func testFakeAsyncScheduler() async {
//        let scheduler = FlakyAsyncScheduler()
//        let (expectedResult, result) = await subTest(with: scheduler)
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
        let timeInterval: TimeInterval = 0.0001 // 100us
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
