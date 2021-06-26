
# EnumConverter

A tiny tool that uses [SwiftSyntax](https://github.com/apple/swift-syntax) to convert Swift Enums to Structs with static functions.


## Features

- Supports enum properties
- Supports enum cases with associated types
- Supports enum extensions (within same file)

  
## Usage

```swift
let result = try EnumConverter.convertEnumToStruct(from: source)
```

Before:
```swift
enum Test {
    case beginner
    case normal(text: String, number: Int)
    case pro(String, Int)
}

extension Test {
    var text: String {
        switch self {
        case .beginner:
            return "a beginner"
        case .normal(let text, let number):
            return text + String(number)
        case .pro(let string, let number):
            return "\(string): \(number)"
        }
    }
    
    var number: Int  {
        switch self {
        case .beginner:
            return 1
        case .normal(text: _, number: let number):
            return number
        case .pro(_, let value):
            return value
        }
    }
}
```
After:
```swift
struct Test {
    let text: String
    let number: Int
    
    static var beginner: Test {
        return .init(text: "a beginner", number: 1)
    }
    static func normal(text: String, number: Int) -> Test {
        return .init(text: text + String(number), number: number)
    }
    static func pro(value0: String, value1: Int) -> Test {
        return .init(text: "\(value0): \(value1)", number: value1)
    }
}
```
  