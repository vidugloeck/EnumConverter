import XCTest
import EnumConverter
import SwiftSyntax
final class EnumConverterTests: XCTestCase {
    func testEnumConversionFromString() throws {
        let source = #"""
            enum Test {
            case beginner
            case normal(text: String, number: Int)
            case pro(String, Int)
            
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
        """#
        
        let result = try EnumConverter.convertEnumToStruct(from: source)
        
        let expected = #"""
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
        
        """#
        
        assertEqual(expected: expected, actual: result.description)
    }
    
    func testEnumConversionFromURL() throws  {
        let sourceURL = """
        enum Test {
        case a
        case b
        }
        """.writeToTempURL()
        let result = try EnumConverter.convertEnumToStruct(from: sourceURL)
        
        let expected = """
        struct Test {
        
        static var a: Test {
        return .init()
        }
        static var b: Test {
        return .init()
        }
        }
        
        """
        
        assertEqual(expected: expected, actual: result)
    }
}
