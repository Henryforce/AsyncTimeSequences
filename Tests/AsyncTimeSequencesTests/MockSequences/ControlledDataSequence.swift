//
//  ControlledDataSequence.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/12/21.
//

import Foundation

struct ControlledDataSequence<T>: AsyncSequence {
    typealias Element = T

    let iterator: ControlledDataIterator<T>
    
    init(items: [T]) {
        self.iterator = ControlledDataIterator(items: items)
    }

    func makeAsyncIterator() -> ControlledDataIterator<T> {
        iterator
    }
}

final class ControlledDataIterator<T>: AsyncIteratorProtocol {
    private let dataActor: ControlledDataActor<T>

    init(items: [T]) {
        self.dataActor = ControlledDataActor(items: items)
    }
    
    func next() async throws -> T? {
        return await dataActor.next()
    }
    
    func waitForItemsToBeSent(_ count: Int) async {
        await dataActor.waitForItemsToBeSent(count)
    }
}

// TODO: analyze if we should return await upon request of next value
actor ControlledDataActor<T> {
    let items: [T]
    var allowedItemsToBeSentCount = Int.zero
    var index = Int.zero
    var savedNextContinuation: CheckedContinuation<T?, Never>?
    var waitContinuation: CheckedContinuation<Void, Never>?
    
    init(
        items: [T]
    ) {
        self.items = items
    }
    
    /// This function returns the next value in the given initializer items
    /// If there are no allowed items to be sent, return a checked continuation that needs to
    /// be resumed by an awaitForItemsToBeSent.
    func next() async -> T? {
        if allowedItemsToBeSentCount > .zero {
            return nextElement()
        } else if let waitContinuation = waitContinuation {
            waitContinuation.resume(returning: ())
            self.waitContinuation = nil
        }
        return await withCheckedContinuation({ (continuation: CheckedContinuation<T?, Never>) in
            savedNextContinuation = continuation
        })
    }
    
    /// Wait for n items to be sent
    /// This function sets up a continuation to be resumed upon the count reaching zero,
    /// meaning that all the requested items have been returned via next().
    /// If a call to next() has already been made at this point, unwrap its continuation
    /// to return the next valid item.
    func waitForItemsToBeSent(_ count: Int) async {
        await withCheckedContinuation({ (continuation: CheckedContinuation<Void, Never>) in
            allowedItemsToBeSentCount = count
            waitContinuation = continuation
            
            if let savedNextContinuation = savedNextContinuation {
                savedNextContinuation.resume(returning: nextElement())
                self.savedNextContinuation = nil
            }
        })
    }
    
    /// Return next element if any
    /// This function should only be called if the allowedItemsToBeSentCount value is
    /// greater than zero.
    private func nextElement() -> T? {
        defer {
            index += 1
            allowedItemsToBeSentCount -= 1
        }
        let element = items.element(at: index)
        return element
    }
    
}
