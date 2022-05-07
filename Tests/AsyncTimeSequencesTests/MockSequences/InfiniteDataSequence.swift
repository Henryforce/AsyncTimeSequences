//
//  InfiniteDataSequence.swift
//  AsyncTimeSequencesTests
//
//  Created by Henry Javier Serrano Echeverria on 13/12/21.
//

import Foundation

struct InfiniteDataSequence<T>: AsyncSequence {
  typealias Element = T

  var items: [T]
  var delay: UInt64
  var iterator: InfiniteDataIterator<T>

  init(
    items: [T],
    delay: UInt64
  ) {
    self.items = items
    self.delay = delay
    self.iterator = InfiniteDataIterator(items: items, delay: delay)
  }

  mutating func stop() {
    iterator.stop()
  }

  func makeAsyncIterator() -> InfiniteDataIterator<T> {
    return iterator
  }
}

struct InfiniteDataIterator<T>: AsyncIteratorProtocol {
  var items: [T]
  var delay: UInt64
  var index = 0
  var shouldStop = false

  mutating func stop() {
    shouldStop = true
  }

  mutating func next() async throws -> T? {
    if shouldStop {
      return nil
    }
    try? await Task.sleep(seconds: 5)

    if index >= items.count {
      index = 0
    }

    let item = items[index]

    index += 1

    return item
  }
}
