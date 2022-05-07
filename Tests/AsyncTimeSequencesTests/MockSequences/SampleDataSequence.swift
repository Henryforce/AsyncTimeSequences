//
//  SampleDataSequence.swift
//  AsyncTimeSequencesTests
//
//  Created by Henry Javier Serrano Echeverria on 13/12/21.
//

import Foundation

struct SampleDataSequence<T>: AsyncSequence {
  typealias Element = T

  var items: [T]

  func makeAsyncIterator() -> SampleDataIterator<T> {
    SampleDataIterator(items: items)
  }
}

struct SampleDataIterator<T>: AsyncIteratorProtocol {
  var items: [T]
  fileprivate var index = 0

  mutating func next() async throws -> T? {
    guard index < items.count else {
      return nil
    }

    let item = items[index]
    index += 1

    return item
  }
}
