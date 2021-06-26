import XCTest
@testable import EnumConverter
import SwiftSyntax
final class EnumConverterTests: XCTestCase {
    func testEnumSourceToConvertibleEnum() {
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
        }
        """#
        
        let sourceFile = try! SyntaxParser.parse(source: source)
        let collector = EnumCollector()
        collector.walk(sourceFile)
        let result = collector.convertible.convert()
        
        let expected = #"""
        struct Test {
        let text: String
        
        static var beginner: Test {
        return .init(text: "a beginner")
        }
        static func normal(text: String, number: Int) -> Test {
        return .init(text: text + String(number))
        }
        static func pro(value0: String, value1: Int) -> Test {
        return .init(text: "\(value0): \(value1)")
        }
        }
        
        """#
        
        assertEqual(expected: expected, actual: result.description)
    }
}
