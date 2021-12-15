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
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
