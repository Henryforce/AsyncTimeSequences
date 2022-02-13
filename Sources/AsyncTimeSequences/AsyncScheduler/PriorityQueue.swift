//
//  PriorityQueue.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 12/2/22.
//  Based on RayWenderlich's `Data Structures & Algorithms in Swift` 
//

import Foundation

struct PriorityQueue<Element: Comparable> {
    var heap: Heap<Element>
    
    enum PriorityQueueType {
        case min
        case max
    }
    
    init(
        type: PriorityQueueType,
        elements: [Element] = []
    ) {
        heap = Heap(sort: { lhs, rhs in
            switch type {
            case .min:
                return lhs < rhs
            case .max:
                return lhs > rhs
            }
        }, elements: elements)
    }
  
    var isEmpty: Bool {
        heap.isEmpty
    }
    
    var peek: Element? {
        heap.peek()
    }
    
    @discardableResult
    mutating func enqueue(_ element: Element) -> Bool {
        heap.insert(element)
        return true
    }
    
    mutating func dequeue() -> Element? {
      heap.remove()
    }
    
    mutating func removeFirst() {
        heap.remove()
    }
    
}
