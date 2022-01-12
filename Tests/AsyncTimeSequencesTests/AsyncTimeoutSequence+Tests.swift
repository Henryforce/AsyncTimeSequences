//
//  AsyncDelaySequence+Tests.swift
//  AsyncTimeSequencesTests
//
//  Created by Henry Javier Serrano Echeverria on 22/11/21.
//

import XCTest
@testable import AsyncTimeSequences
import AsyncTimeSequencesSupport

final class AsyncDelaySequenceTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAsyncTimeoutSequenceThrowsErrorOnTimeout() async {
        // Given
        let scheduler = TestAsyncScheduler()
        let items = [1,5,10,15,20]
        let baseDelay = 5.0
        var expectedItems = [Int]()
        
        // When
        let sequence = ControlledDataSequence(items: items)
        var iterator = sequence
            .timeout(for: baseDelay, scheduler: scheduler)
            .makeAsyncIterator()

        // If we don't wait for jobs to get scheduled, advancing the scheduler does virtually nothing...
        await sequence.iterator.waitForItemsToBeSent(items.count)
        await scheduler.advance(by: baseDelay)
        
        do {
            // It will throw an error as the sequence finished sending items but it will never send a nil. Thus, triggering a timeout
            while let value = try await iterator.next() {
                expectedItems.append(value)
            }
            XCTFail("Expected an Error")
        } catch (let error) {
            guard let timeoutError = error as? AsyncTimeSequenceError,
                case .timeout = timeoutError
            else {
                XCTFail("Expected Timeout Error")
                return
            }
        }
    }
    
    func testAsyncTimeoutSequenceDoesNotThrowErrorIfElementsDontWaitNTime() async {
        // Given
        let scheduler = TestAsyncScheduler()
        let items = [1,5,10,15,20]
        let baseDelay = 5.0
        var expectedItems = [Int]()

        // When
        var iterator = SampleDataSequence(items: items)
            .timeout(for: baseDelay, scheduler: scheduler)
            .makeAsyncIterator()
        
        await scheduler.waitForScheduledJobs(count: 1) // Make sure that the timeout is scheduled

        do {
            while let value = try await iterator.next() {
                expectedItems.append(value)
            }
        } catch {
            XCTFail("An error was not expected")
        }

        // Then
        XCTAssertEqual(expectedItems, [1, 5, 10, 15, 20])
    }
    
}
