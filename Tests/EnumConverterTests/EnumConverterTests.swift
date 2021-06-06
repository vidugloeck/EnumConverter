import XCTest
@testable import EnumConverter
import SwiftSyntax
final class EnumConverterTests: XCTestCase {
    func testEnumSourceToConvertibleEnum() {
        let source = """
        enum Test {
        case beginner

        var text: String {
        switch self {
        case .beginner:
        return "a beginner"
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
        var text: String
        
        static var beginner: Test {
        return .init(text: "a beginner")
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
