import XCTest
@testable import EnumConverter
import SwiftSyntax
final class EnumConverterTests: XCTestCase {
    func testEnumSourceToConvertibleEnum() {
        let source = """
        enum Test {
        case beginner
        case normal(text: String)
        case pro(String)
        
        var text: String {
        switch self {
        case .beginner:
        return "a beginner"
        case .normal(let text):
        return text
        case .pro(let value):
        return value
        }
        }
        }
        """
        
        let sourceFile = try! SyntaxParser.parse(source: source)
        let collector = EnumCollector()
        collector.walk(sourceFile)
        let result = collector.convertible.convert()
        
        let expected = """
        struct Test {
        let text: String
        
        static var beginner: Test {
        return .init(text: "a beginner")
        }
        static func normal(text: String) -> Test {
        return .init(text: text)
        }
        static func pro(value0: String) -> Test {
        return .init(text: value0)
        }
        }
        
        """
        
        assertEqual(expected: expected, actual: result.description)
    }
}
