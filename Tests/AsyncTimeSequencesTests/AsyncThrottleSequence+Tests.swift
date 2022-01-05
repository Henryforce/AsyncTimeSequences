//
//  AsyncThrottleSequence+Tests.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/12/21.
//

import XCTest
import CombineSchedulers
@testable import AsyncTimeSequences

final class AsyncThrottleSequenceTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAsyncThrottleSequenceWithLatest() async {
        // Given
        let scheduler = DispatchQueue.asyncTest
        let items = [1,5,10,15,20]
        let expectedItems = [20]
        let baseDelay = 5
        var receivedItems = [Int]()
        let sequence = ControlledDataSequence(
            items: items
        )
        var iterator = sequence
            .throttle(
                for: .seconds(baseDelay),
                scheduler: scheduler,
                latest: true
            ).makeAsyncIterator()
        
        // When
        await sequence.iterator.waitForItemsToBeSent(5) // Wait for all items to be dispatched
        await scheduler.waitForScheduledJobs(count: 5) // Wait for 5 jobs to be scheduled
        scheduler.advance(by: .seconds(baseDelay)) // Scheduled jobs will now be executed
        
        while receivedItems.count < expectedItems.count, let value = await iterator.next() {
            receivedItems.append(value)
        }
        
        // Then
        XCTAssertEqual(receivedItems, expectedItems)
        scheduler.advance(by: .seconds(baseDelay)) // If any await is pending, clear it
    }
    
    func testAsyncThrottleSequenceWithLatestWithTwoTimeAdvances() async {
        // Given
        let scheduler = DispatchQueue.asyncTest
        let items = [1,5,10,15,20]
        let expectedItems = [10, 20]
        let baseDelay = 5
        var receivedItems = [Int]()
        let sequence = ControlledDataSequence(
            items: items
        )
        var iterator = sequence
            .throttle(
                for: .seconds(baseDelay),
                scheduler: scheduler,
                latest: true
            ).makeAsyncIterator()
        
        // When
        await sequence.iterator.waitForItemsToBeSent(3) // Wait for 3 items to be dispatched
        await scheduler.waitForScheduledJobs(count: 3) // Wait for 3 jobs to be scheduled
        scheduler.advance(by: .seconds(baseDelay)) // Scheduled jobs will now be executed and upon advancing the timer will schedule a new job
        
        await scheduler.waitForScheduledJobs(count: 1) // Wait for the timer to schedule a throttle job
        
        await sequence.iterator.waitForItemsToBeSent(2)
        await scheduler.waitForScheduledJobs(count: 2) // Wait for the next two items to be registered on the scheduler
        scheduler.advance(by: .seconds(baseDelay))
        
        while receivedItems.count < expectedItems.count, let value = await iterator.next() {
            receivedItems.append(value)
        }
        
        // Then
        XCTAssertEqual(receivedItems, expectedItems)
        scheduler.advance(by: .seconds(baseDelay)) // If any await is pending, clear it
    }
    
    func testAsyncThrottleSequenceWithoutLatestWithTwoTimeAdvances() async {
        // Given
        let scheduler = DispatchQueue.asyncTest
        let items = [1,5,10,15,20]
        let expectedItems = [1, 15]
        let baseDelay = 5
        var receivedItems = [Int]()
        let sequence = ControlledDataSequence(
            items: items
        )
        var iterator = sequence
            .throttle(
                for: .seconds(baseDelay),
                scheduler: scheduler,
                latest: false
            ).makeAsyncIterator()
        
        // When
        await sequence.iterator.waitForItemsToBeSent(3)
        await scheduler.waitForScheduledJobs(count: 3)
        scheduler.advance(by: .seconds(baseDelay)) // Upon advancing the timer will schedule a new job
        
        await scheduler.waitForScheduledJobs(count: 1) // Wait for the timer to schedule the job
        
        await sequence.iterator.waitForItemsToBeSent(2)
        await scheduler.waitForScheduledJobs(count: 2) // Wait for the next two items to be registered on the scheduler
        scheduler.advance(by: .seconds(baseDelay))
        
        while receivedItems.count < expectedItems.count, let value = await iterator.next() {
            receivedItems.append(value)
        }
        
        // Then
        XCTAssertEqual(receivedItems, expectedItems)
        scheduler.advance(by: .seconds(baseDelay)) // If any await is pending, clear it
    }
    
}
