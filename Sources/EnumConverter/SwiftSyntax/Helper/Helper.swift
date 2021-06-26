import Foundation
import SwiftSyntax

extension StringProtocol {
    
    var trimmed: String {
        let startIndex = firstIndex(where: { !$0.isWhitespace }) ?? self.startIndex
        let endIndex = lastIndex(where: { !$0.isWhitespace }) ?? self.endIndex
        return String(self[startIndex...endIndex])
    }
}

extension String {
    func syntax() -> SourceFileSyntax {
        return try! SyntaxParser.parse(source: self)
    }
    
    /// Trims `#>` and `<#` characters
    func trimToken() -> String {
        var result = self
        if self.starts(with: "<#") {
            result = String(result.dropFirst(2))
        }
        if result.reversed().starts(with: ">#") {
            result = String(result.dropLast(2))
        }
        
        return result
    }
}

func wrapInMemberDeclListItemSyntax(_ item: DeclSyntax) -> MemberDeclListItemSyntax {
    SyntaxFactory.makeMemberDeclListItem(decl: item, semicolon: nil)
}

func wrapInMemberDeclBlock(_ items: [MemberDeclListItemSyntax]) -> MemberDeclBlockSyntax {
    SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken(),
                                      members: SyntaxFactory.makeMemberDeclList(items),
                                      rightBrace: SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1)))
}

func wrapInMemberDeclBlock(_ items: [DeclSyntax]) -> MemberDeclBlockSyntax {
    SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken(),
                                      members: SyntaxFactory.makeMemberDeclList(items.map(wrapInMemberDeclListItemSyntax)),
                                      rightBrace: SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1)))
}

typealias SF = SyntaxFactory

extension SyntaxProtocol {
    /// Queries children and returns first Syntax Node that matches where closure
    func descendant<T>(where transform: (Syntax) -> T?) -> T? {
        for child in children {
            if let result = transform(child) {
                return result
            }
            if let result = child.descendant(where: transform) {
                return result
            }
        }
        return nil
    }
}

extension SyntaxProtocol {
    var context: DeclSyntaxProtocol? {
        for case let node? in sequence(first: parent, next: { $0?.parent }) {
            guard let declaration = node.asProtocol(DeclSyntaxProtocol.self) else { continue }
            return declaration
        }
        
        return nil
    }
}
