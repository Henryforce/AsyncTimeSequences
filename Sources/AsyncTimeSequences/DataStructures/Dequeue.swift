//
//  Dequeue.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import Foundation

final class Dequeue<T> {
    
    final class DoublyLinkedList<T> {
        var value: T!
        weak var previous: DoublyLinkedList<T>?
        var next: DoublyLinkedList<T>?
    }
    
    var head: DoublyLinkedList<T>?
    var tail: DoublyLinkedList<T>?
    var count = 0
    
    init() {
        head = DoublyLinkedList<T>()
        tail = DoublyLinkedList<T>()
        
        head?.next = tail
        tail?.previous = head
    }
    
    func enqueue(_ value: T) {
        count += 1
        add(value)
    }
    
    @discardableResult
    func dequeue() -> T? {
        guard count > 0, let first = head?.next else { return nil }
        count -= 1
        disconnect(first)
        return first.value
    }
    
    func peek() -> T? {
        guard let first = head?.next else { return nil }
        return first.value
    }
    
    private func add(_ value: T) {
        let list = DoublyLinkedList<T>()
        list.value = value
        
        tail?.previous?.next = list
        list.previous = tail?.previous
        list.next = tail
        tail?.previous = list
    }
    
    private func disconnect(_ list: DoublyLinkedList<T>) {
        list.previous?.next = list.next
        list.next?.previous = list.previous
    }
}

extension Dequeue {
    var isEmpty: Bool { count == .zero }
}
