//
//  AsyncDebounceSequence+Tests.swift
//  AsyncTimeSequencesTests
//
//  Created by Henry Javier Serrano Echeverria on 13/12/21.
//

import Foundation

import XCTest
import CombineSchedulers
@testable import AsyncTimeSequences

final class AsyncDebounceSequence_Tests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAsyncDebounceSequence() async {
        // Given
        let scheduler = TestAsyncScheduler()
        let items = [1,5,10,15,20]
        let expectedItems = [20]
        let baseDelay = 5.0
        var receivedItems = [Int]()
        
        // When
        let sequence = ControlledDataSequence(items: items)
        var iterator = sequence
            .debounce(for: baseDelay, scheduler: scheduler)
            .makeAsyncIterator()

        // If we don't wait for jobs to get scheduled, advancing the scheduler does virtually nothing...
        await sequence.iterator.waitForItemsToBeSent(items.count)
        await scheduler.advance(by: baseDelay)
        
        while receivedItems.count < expectedItems.count, let value = await iterator.next() {
            receivedItems.append(value)
        }
        
        // Then
        XCTAssertEqual(receivedItems, expectedItems)
    }

}
