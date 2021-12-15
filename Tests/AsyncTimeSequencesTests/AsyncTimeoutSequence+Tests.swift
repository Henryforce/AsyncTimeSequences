//
//  AsyncDelaySequence+Tests.swift
//  AsyncTimeSequencesTests
//
//  Created by Henry Javier Serrano Echeverria on 22/11/21.
//

import XCTest
import CombineSchedulers
@testable import AsyncTimeSequences

final class AsyncDelaySequenceTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAsyncTimeoutSequenceThrowsErrorOnTimeout() async {
        // Given
        let scheduler = DispatchQueue.asyncTest
        let items = [1,5,10,15,20]
        let baseDelay = 5
        var expectedItems = [Int]()
        
        // When
        var sequence = InfiniteDataSequence(items: items, delay: 5)
        var iterator = sequence
            .timeout(for: .seconds(baseDelay), scheduler: scheduler)
            .makeAsyncIterator()

        // If we don't wait for jobs to get scheduled, advancing the scheduler does virtually nothing...
        await scheduler.waitForScheduledJobs(count: 1)
        scheduler.advance(by: .seconds(baseDelay))
        
        do {
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
        
        sequence.stop()
    }
    
    func testAsyncTimeoutSequenceDoesNotThrowErrorIfElementsDontWaitNTime() async {
        // Given
        let scheduler = DispatchQueue.asyncTest
        let items = [1,5,10,15,20]
        let baseDelay = 5
        var expectedItems = [Int]()
        
        // When
        var iterator = SampleDataSequence(items: items)
            .timeout(for: .seconds(baseDelay), scheduler: scheduler)
            .makeAsyncIterator()

        // If we don't wait for jobs to get scheduled, advancing the scheduler does virtually nothing...
        await scheduler.waitForScheduledJobs(count: 1)
        
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
