# AsyncTimeSequences

(Work in Progress)

This is a convenient package to add missing time async sequences such as debounce, delay, timeout...

These sequences are recommended to be used with AsyncStreams, but as they conform to AsyncSequence the possibilities are endless.

## How to use

For all examples, please first consider this sample sequence (remember that you can use any Async Sequence):

```
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

### Timeout

```
    asyncSequence.timeout(for: .seconds(2), scheduler: DispatchQueue.main)
```

### Delay

```
    asyncSequence.delay(for: .seconds(3), scheduler: DispatchQueue.main)
```

### Debounce

```
    asyncSequence.debounce(for: .seconds(3), scheduler: DispatchQueue.main)
```

### Throttle

```
    asyncSequence.throttle(for: .seconds(3), scheduler: DispatchQueue.main, latest: true)
```

### MeasureInterval

```
    asyncSequence.measureInterval(using: DispatchQueue.main)
```

## How to test

(Coming soon)

## Installation

### Swift Package Manager
