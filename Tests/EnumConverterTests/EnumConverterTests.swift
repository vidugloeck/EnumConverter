import XCTest
@testable import EnumConverter
import SwiftSyntax
final class EnumConverterTests: XCTestCase {
    func testEnumSourceToConvertibleEnum() {
        let source = """
        enum Test {
        case beginner
        case normal(text: String)
        
        var text: String {
        switch self {
        case .beginner:
        return "a beginner"
        case .normal(let text):
        return text
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
        }
        
        """
        
        assertEqual(expected: expected, actual: result.description)
    }
}

var maxExpected: String {
    """
        struct Test {
        var text: String
        }
        
        extension Test {
        static var beginner: Test {
        .init(text: "beginner")
        }
        static func normal(text: String) -> Test {
        .init(text: text)
        }
        static func advanced(custom: String) -> Test {
        .init(text: custom)
        }
        }
        """
}
