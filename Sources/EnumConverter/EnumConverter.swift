import SwiftSyntax
import Foundation

public struct EnumConverter {
    public static func convertEnumToStruct(from string: String) throws -> String {
        return convert(try SyntaxParser.parse(source: string))
    }
    
    public static func convertEnumToStruct(from url: URL) throws -> String {
        return convert(try SyntaxParser.parse(url))
    }
    
    
    private static func convert(_ source: SourceFileSyntax) -> String {
        let collector = EnumCollector()
        collector.walk(source)
        return collector.convertible.convert().description
    }
}
