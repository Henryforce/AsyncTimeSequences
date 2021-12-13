//
//  SchedulerExtensions+Tests.swift
//  AsyncTimeSequencesTests
//
//  Created by Henry Javier Serrano Echeverria on 13/12/21.
//

import XCTest
@testable import AsyncTimeSequences

final class SchedulerExtensions_Tests: XCTestCase {

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

}
