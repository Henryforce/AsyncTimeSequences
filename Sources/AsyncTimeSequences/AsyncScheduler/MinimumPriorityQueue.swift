//
//  MinimumPriorityQueue.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 12/2/22.
//

import Foundation

final class MinimumPriorityQueue {

  lazy var heap: CFBinaryHeap = {
    var callbacks = CFBinaryHeapCallBacks()
    callbacks.compare = { lPtr, rPtr, _ -> CFComparisonResult in
      guard let lhs = lPtr?.load(as: AsyncSchedulerHandlerElement.self),
        let rhs = rPtr?.load(as: AsyncSchedulerHandlerElement.self)
      else { return CFComparisonResult.compareEqualTo }

      if lhs == rhs {
        return CFComparisonResult.compareEqualTo
      }
      return lhs < rhs ? CFComparisonResult.compareLessThan : CFComparisonResult.compareGreaterThan
    }
    return CFBinaryHeapCreate(nil, 0, &callbacks, nil)
  }()

  var isEmpty: Bool {
    CFBinaryHeapGetCount(heap) <= 0
  }

  var peek: AsyncSchedulerHandlerElement? {
    guard !isEmpty else { return nil }
    return CFBinaryHeapGetMinimum(heap).load(as: AsyncSchedulerHandlerElement.self)
  }

  @discardableResult
  func enqueue(_ element: AsyncSchedulerHandlerElement) -> Bool {
    CFBinaryHeapAddValue(heap, element.unsafeMutablePointer)
    return true
  }

  func dequeue() -> AsyncSchedulerHandlerElement? {
    guard let firstElement = peek else { return nil }
    removeFirst()
    return firstElement
  }

  func removeFirst() {
    CFBinaryHeapRemoveMinimumValue(heap)
  }

}
