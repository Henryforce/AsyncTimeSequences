//
//  AsyncDelaySequence+Tests.swift
//  AsyncTimeSequencesTests
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import XCTest
@testable import AsyncTimeSequences
import AsyncTimeSequencesSupport

final class AsyncDelaySequence_Tests: XCTestCase {
    
    func testAsyncDelaySequence() async {
        // Given
        let scheduler = TestAsyncScheduler()
        let items = [1,5,10,15,20]
        let expectedItems = [1, 5, 10, 15, 20]
        let baseDelay = 5.0
        var receivedItems = [Int]()
        
        // When
        let sequence = ControlledDataSequence(items: items)
        var iterator = sequence
            .delay(
                for: baseDelay,
                scheduler: scheduler
            ).makeAsyncIterator()

        // If we don't wait for jobs to get scheduled, advancing the scheduler does virtually nothing...
        await sequence.iterator.waitForItemsToBeSent(items.count)
        await scheduler.advance(by: baseDelay)
        
        while receivedItems.count < expectedItems.count, let value = await iterator.next() {
            receivedItems.append(value)
        }
        
        // Then
        XCTAssertEqual(receivedItems, expectedItems)
    }
    
    func testAsyncDelaySequenceWithPartialTimeAdvances() async {
        // Given
        let scheduler = TestAsyncScheduler()
        let items = [1,5,10,15,20]
        let expectedFirstItems = [1, 5, 10]
        let expectedSecondItems = [15, 20]
        let baseDelay = 5.0
        var receivedFirstItems = [Int]()
        var receivedSecondItems = [Int]()
        
        // When
        let sequence = ControlledDataSequence(items: items)
        var iterator = sequence
            .delay(
                for: baseDelay,
                scheduler: scheduler
            ).makeAsyncIterator()

        // If we don't wait for jobs to get scheduled, advancing the scheduler does virtually nothing...
        await sequence.iterator.waitForItemsToBeSent(expectedFirstItems.count)
        await scheduler.advance(by: baseDelay)
        
        while receivedFirstItems.count < expectedFirstItems.count, let value = await iterator.next() {
            receivedFirstItems.append(value)
        }
        
        await sequence.iterator.waitForItemsToBeSent(expectedSecondItems.count)
        await scheduler.advance(by: baseDelay)
        
        while receivedSecondItems.count < expectedSecondItems.count, let value = await iterator.next() {
            receivedSecondItems.append(value)
        }
        
        // Then
        XCTAssertEqual(receivedFirstItems, expectedFirstItems)
        XCTAssertEqual(receivedSecondItems, expectedSecondItems)
    }

}
