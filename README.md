# AsyncTimeSequences

![badge-platforms][] [![badge-spm][]][spm]

This is a convenient package to add missing time async sequences such as debounce, throttle, delay, timeout and measure interval.

These sequences work with any AsyncSequence (such as AsyncStream), and as they conform to the AsyncSequence Protocol the possibilities are endless.

This library relies on an AsynScheduler-conforming class that guarantees async execution order. Due to the nature of the Swift Async architecture, the execution of Tasks is not deterministic and to guarantee the order of time operations it becomes necessary to add further handling. This is critical for many time operators such as Debounce and Delay. The AsyncScheduler class provided in this library promises async task execution following FIFO and cancellation.

## Compatibility

This package is supported on Xcode 13.2+ targeting iOS 13+, MacOS 10.15+, WatchOS 6+ and TvOS 13+.

## How to use

For all examples, please first consider this sample sequence (remember that you can use any AsyncSequence):

```swift
let asyncSequence = AsyncStream { (continuation:AsyncStream<Int>.Continuation) in
    Task {
        let items = [1,2,3,4,5,6]
        for item in items {
            continuation.yield(item)
            try? await Task.sleep(nanoseconds: 1000000)
        }
        continuation.finish()
    }
}
```

All the AsyncTimeSequences will need an AsyncScheduler object. For convenience, there is one already bundled with this package. You should be good with the main one provided. But you are free to add your custom one if required (by conforming to the AsyncScheduler protocol).

### Timeout

```swift
asyncSequence.timeout(for: 2, scheduler: MainAsyncScheduler.default)
```

### Delay

```swift
asyncSequence.delay(for: 3, scheduler: MainAsyncScheduler.default)
```

### Debounce

```swift
asyncSequence.debounce(for: 3, scheduler: MainAsyncScheduler.default)
```

### Throttle

```swift
asyncSequence.throttle(for: 3, scheduler: MainAsyncScheduler.default, latest: true)
```

### MeasureInterval

```swift
asyncSequence.measureInterval(using: MainAsyncScheduler.default)
```

## How to test

Properly testing these time sequences requires some setup. Ideally, it is recommended to inject the scheduler, that will execute the time handling of your sequences, into your logic object.

By injecting the scheduler, you can for example inject a test scheduler to manipulate the time operators.

It is recommended to use the TestAsyncScheduler included in the AsyncTimeSequencesSupport sub-package. It has some really convenient functions to manipulate time:

```swift
let scheduler = AsyncTestScheduler()
scheduler.advance(by: 3.0) // Advances the time virtually and executes scheduled jobs immediately without actually waiting the time interval specified
```

An example on how to inject the schduler if you have a view model:

```swift
final class MyViewModel {

    private let scheduler: AsyncScheduler

    init(
        scheduler: AsyncScheduler = MainAsyncScheduler.default // Allow injection while providing a default scheduler
    ) {
        self.scheduler = scheduler
    }
    
    func debounceSequence<T: AsyncSequence>(_ sequence: T) {
        let debounceSequence = sequence.debounce(for: 3.0, scheduler: scheduler)
        
        Task {
            for await value in debounceSequence {
                // do something that produces an output which can be evaluated and asserted during testing...
            }
        }
    }

}
```

```swift
import AsyncTimeSequences
import AsyncTimeSequencesSupport

...

func testAsyncDebounceSequence() async {
    // Given
    let scheduler = TestAsyncScheduler()
    let viewModel = MyViewModel(scheduler: scheduler)
    let items = [1,5,10,15,20]
    let expectedItems = [20]
    let baseDelay = 3.0
    var receivedItems = [Int]()
    
    // When
    let sequence = ControlledDataSequence(items: items)
    viewModel.debounceSequence()

    // If we don't wait for jobs to get scheduled, advancing the scheduler does virtually nothing...
    await sequence.iterator.waitForItemsToBeSent(items.count)
    await scheduler.advance(by: baseDelay)
    
    // your code to process the view model output...
}
```

If you need further code examples, you can take a look at the tests for this package library. They rely heavily on the AsyncTestScheduler and the ControlledDataSequence classes, which are included in the AsyncTimeSequencesSupport sub-package.

## Installation

### Swift Package Manager

In Xcode, select File --> Swift Packages --> Add Package Dependency and then add the following url:

```swift
https://github.com/Henryforce/AsyncTimeSequences
```

There are two package included:

- AsyncTimeSequences - async time sequences extensions
- AsyncTimeSequencesSupport - async-time-sequences support classes for testing. (Recommended to include only in your test targets)

[badge-platforms]: https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg

[badge-spm]: https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg

[spm]: https://github.com/apple/swift-package-manager
