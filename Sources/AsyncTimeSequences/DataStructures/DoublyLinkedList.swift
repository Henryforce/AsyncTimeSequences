//
//  DoublyLinkedList.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import Foundation

final class DoublyLinkedList<T> {
    weak var previous: DoublyLinkedList<T>?
    var next: DoublyLinkedList<T>?
    var currentValue: T!
    
    init(
        value: T? = nil,
        previous: DoublyLinkedList<T>? = nil,
        next: DoublyLinkedList<T>? = nil
    ) {
        self.currentValue = value
        self.previous = previous
        self.next = next
    }
}

// Useful extension for debugging
extension DoublyLinkedList {
    func toArray(until item: DoublyLinkedList<T>?) -> [T] {
        var array = [T]()
        var next: DoublyLinkedList<T>? = self.next
        while(next !== item) {
            guard let value = next?.currentValue else { break }
            array.append(value)
            next = next?.next
        }
        return array
    }
}
