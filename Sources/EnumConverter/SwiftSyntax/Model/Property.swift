//
//  Property.swift
//  EnumConverter
//
//  Created by Vidu Glöck on 26.06.21.
//

import SwiftSyntax

extension ConvertibleEnum {
    /// Represents properties that switch over Self and return a value of a given Type
    struct Property: Equatable {
        init(name: String, type: String, body: SwitchStmtSyntax) {
            self.name = name
            self.type = type
            self.body = body
        }
        
        let name: String
        let type: String
        let body: SwitchStmtSyntax
        
        func expressionForPropertyName(_ name: String) -> ExprSyntax {
            SF.makeBlankTypeExpr().eraseToExprSyntax()
        }
        
        
        /// Returns variable declaration without accessor / body
        func convert() -> VariableDeclSyntax {
            VariableDeclSyntax {
                $0.useLetOrVarKeyword(SF.makeLetKeyword(trailingTrivia: .spaces(1)))
                $0.addBinding(
                    PatternBindingSyntax {
                        $0.usePattern(SF.makeIdentifierPattern(identifier: SF.makeIdentifier(name)).eraseToPatternSyntax())
                        $0.useTypeAnnotation(SF.makeTypeAnnotation(colon: SF.makeColonToken(trailingTrivia: .spaces(1)),
                                                                   type: SF.makeTypeIdentifier(type, trailingTrivia: .spaces(1))))
                    }
                )
            }
        }
        
        private func expressionForCase(_ caseName: String, associatedTypes: [Case.AssociatedType]) -> ExprSyntax {
            body.descendant(where: { syntax -> ExprSyntax? in
                guard let switchCase = SwitchCaseSyntax(syntax) else { return nil }
                guard let caseItem = switchCase.descendant(where: { CaseItemSyntax($0) }) else { return nil }
                guard let caseLabel = caseItem.descendant(where: { MemberAccessExprSyntax($0) }) else { return nil }
                guard caseLabel.name.text == caseName else { return nil }
                guard let returnStmnt = switchCase.descendant(where: { ReturnStmtSyntax($0) }) else { return nil }
                var expression: ExprSyntax? = returnStmnt.expression?.eraseToExprSyntax()
                if let parameterNamesTupleExpressionList = caseItem.descendant(where: { TupleExprElementListSyntax($0) }) {
                    zip(associatedTypes, parameterNamesTupleExpressionList).enumerated().forEach { index, items in
                        let (a, p) = items
                        guard let identifier = p.descendant(where: { IdentifierPatternSyntax($0) })?.identifier else { return }
                        if a.name != identifier.text {
                            let name = a.name ?? "value\(index)"
                            let rewriter = ExpressionRewriter(toBeReplaced: identifier.text, replacement: name)
                            expression = ExprSyntax(rewriter.visit(expression!.eraseToSyntax()))
                        }
                    }
                }
                return expression
                
            })!
        }
        
        func convertToTupleExpression(caseName: String, associatedTypes: [Case.AssociatedType], useTrailingComma: Bool) -> TupleExprElementSyntax {
            TupleExprElementSyntax {
                $0.useLabel(SF.makeIdentifier(name))
                $0.useColon(SF.makeColonToken(trailingTrivia: .spaces(1)))
                $0.useExpression(expressionForCase(caseName, associatedTypes: associatedTypes))
                if useTrailingComma {
                    $0.useTrailingComma(SF.makeCommaToken(trailingTrivia: .spaces(1)))
                }
            }
        }
    }
}

class ExpressionRewriter: SyntaxRewriter {
    init(toBeReplaced: String, replacement: String) {
        self.toBeReplaced = toBeReplaced
        self.replacement = replacement
    }
    
    let toBeReplaced: String
    let replacement: String
    override func visit(_ node: IdentifierExprSyntax) -> ExprSyntax {
        if node.identifier.text == toBeReplaced {
            return node.withIdentifier(SF.makeIdentifier(replacement)).eraseToExprSyntax()
        }
        return node.eraseToExprSyntax()
    }
}
