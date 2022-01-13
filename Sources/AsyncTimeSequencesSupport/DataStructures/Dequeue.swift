//
//  Dequeue.swift
//  AsyncTimeSequencesSupport
//
//  Created by Henry Javier Serrano Echeverria on 13/1/22.
//

import Foundation

final class Dequeue<T> {
    
    var head: DoublyLinkedList<T>?
    var tail: DoublyLinkedList<T>?
    var _count = 0
    
    public init() {
        head = DoublyLinkedList<T>()
        tail = DoublyLinkedList<T>()
        
        head?.next = tail
        tail?.previous = head
    }
    
    public func enqueue(_ value: T) {
        _count += 1
        add(value)
    }
    
    @discardableResult
    public func dequeue() -> T? {
        guard count > 0, let first = head?.next else { return nil }
        _count -= 1
        disconnect(first)
        return first.value
    }
    
    public func peek() -> T? {
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
    public var count: Int { _count }
    public var isEmpty: Bool { _count == .zero }
}
