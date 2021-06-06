import Foundation
import SwiftSyntax

class EnumCollector: SyntaxVisitor {
    var convertible = ConvertibleEnum(name: "")
    
    
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        convertible.name = node.identifier.text
        return .visitChildren
    }
    
    override func visit(_ node: CaseItemSyntax) -> SyntaxVisitorContinueKind {
        guard let caseExpression = node.descendant(where: { MemberAccessExprSyntax($0) }) else {
            fatalError("Expected MemberAccessExpression here :-/")
        }
        convertible.cases.append(.init(name: caseExpression.name.text))
        
        return .visitChildren
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let patternBinding = node.descendant(where: { PatternBindingSyntax($0) }) else { return .skipChildren }
        guard let switchStmt = node.descendant(where: { SwitchStmtSyntax($0) }) else { return .skipChildren }
        let property = ConvertibleEnum.Property(name: patternBinding.pattern.description.trimmed,
                                                type: patternBinding.typeAnnotation!.type.description.trimmed,
                                                body: switchStmt)
        convertible.properties.append(property)
        return .visitChildren
    }
}
