//
//  AsyncDelaySequence+Tests.swift
//  AsyncTimeSequencesTests
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import XCTest
import CombineSchedulers
@testable import AsyncTimeSequences

final class AsyncDelaySequence_Tests: XCTestCase {

    private var counter = 0
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSchedulerSleep() async {
        // Given
        let scheduler = DispatchQueue.asyncTest
        let seconds = 5
        
        // When
        // The sleep is dependent on the scheduler advancing. Hence, the only way to get past the sleep
        // is to advance the scheduler concurrently. The task group is perfect for such requirement.
        await withTaskGroup(of: Void.self, body: { group in
            // Run tasks concurrently and wait for both to finish
            group.addTask {
                await scheduler.sleep(.seconds(seconds))
            }
            group.addTask {
                // Without awaiting for scheduling jobs, this test is flaky.
                // Async code gives no guarantees on the order of execution for tasks
                await scheduler.waitForScheduledJobs(count: 1)
                scheduler.advance(by: .seconds(seconds))
            }
            for await _ in group { }
        })
        
        // Then
        XCTAssert(true)
    }
    
    func testAsyncDelaySequence() async {
        // Given
        let scheduler = DispatchQueue.asyncTest
        let items = [1,5,10,15,20]
        let baseDelay = 5
        var expectedItems = [Int]()
        
        // When
        var iterator = SampleDataSequence(items: items)
            .delay(
                for: .seconds(baseDelay),
                scheduler: scheduler
            ).makeAsyncIterator()

        // If we don't wait for jobs to get scheduled, advancing the scheduler does virtually nothing...
        await scheduler.waitForScheduledJobs(count: items.count)
        scheduler.advance(by: .seconds(baseDelay * items.count))
        
        while let value = await iterator.next() {
            expectedItems.append(value)
        }
        
        // Then
        XCTAssertEqual(expectedItems, [1, 5, 10, 15, 20])
    }

}
