//
//  SyntaxProtocol.swift
//  ConformKit
//
//  Created by Vidu Glöck on 24.05.21.
//

import SwiftSyntax


extension SyntaxProtocol {
    func eraseToSyntax() -> Syntax {
        Syntax(self)
    }
    
    func wrapInCodeBlockItem() -> CodeBlockItemSyntax {
        SF.makeCodeBlockItem(item: self.eraseToSyntax(), semicolon: nil, errorTokens: nil)
    }
    
    func wrapInCodeBlock() -> CodeBlockSyntax {
        SF.makeCodeBlock(leftBrace: SF.makeLeftBraceToken(trailingTrivia: .spaces(1)),
                         statements: SF.makeCodeBlockItemList([wrapInCodeBlockItem()]),
                         rightBrace: SF.makeRightBraceToken(leadingTrivia: .spaces(1)))
    }
}

extension DeclSyntaxProtocol {
    func eraseToDeclSyntax() -> DeclSyntax {
        DeclSyntax(self)
    }
    
    func eraseToMemberDeclListItemSyntax() -> MemberDeclListItemSyntax {
        SF.makeMemberDeclListItem(decl: self.eraseToDeclSyntax(), semicolon: nil)
    }
    
    func eraseToMemberDeclListSyntax() -> MemberDeclListSyntax {
        SF.makeMemberDeclList([eraseToMemberDeclListItemSyntax()])
    }
    
    func eraseToMemberDeclBlockSyntax() -> MemberDeclBlockSyntax {
        let list: MemberDeclListSyntax
        if let l = self as? MemberDeclListSyntax { list = l } else { list = eraseToMemberDeclListSyntax() }
        
        return SF.makeMemberDeclBlock(leftBrace: SF.makeLeftBraceToken(trailingTrivia: .spaces(1)),
                                      members: list,
                                      rightBrace: SF.makeRightBraceToken(trailingTrivia: .spaces(1)))
    }
}

extension ExprSyntaxProtocol {
    func eraseToExprSyntax() -> ExprSyntax {
        ExprSyntax(self)
    }
}

extension PatternSyntaxProtocol {
    func eraseToPatternSyntax() -> PatternSyntax {
        PatternSyntax(self)
    }
}
