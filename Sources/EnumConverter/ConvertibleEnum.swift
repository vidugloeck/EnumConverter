import SwiftSyntax

/// Rules:
/// have to use switch / case in enum properties
/// have to use return expression  in enum properties
class ConvertibleEnum {
    init(name: String, cases: [ConvertibleEnum.Case], properties: [Property]) {
        self.name = name
        self.cases = cases
        self.properties = properties
    }
    
    init(name: String) { self.name = name }
    
    var name: String = ""
    var cases: [Case] = []
    
    var properties: [Property] = []
    
    func convert() -> StructDeclSyntax {
        StructDeclSyntax {
            $0.useStructKeyword(SF.makeStructKeyword(trailingTrivia: .spaces(1)))
            $0.useIdentifier(SF.makeIdentifier(name, trailingTrivia: .spaces(1)))
            $0.useMembers(
                MemberDeclBlockSyntax {
                    $0.useLeftBrace(SF.makeLeftBraceToken(trailingTrivia: .newlines(1)))
                    for p in properties {
                        $0.addMember(
                            MemberDeclListItemSyntax {
                                $0.useDecl(p.convert().eraseToDeclSyntax().withTrailingTrivia(.newlines(1)))
                            }
                        )
                    }
                    for c in cases {
                        $0.addMember(
                            MemberDeclListItemSyntax {
                                $0.useDecl(c.convert(enumName: name, enumType: name, enumProperties: properties).eraseToDeclSyntax()
                                            .withLeadingTrivia(.newlines(cases.first! == c ? 1 : 0))
                                            .withTrailingTrivia(.newlines(1)))
                            }
                        )
                    }
                    $0.useRightBrace(SF.makeRightBraceToken(trailingTrivia: .newlines(1)))
                }
            )
        }
    }
}

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
        
        func expressionForCase(_ caseName: String) -> ExprSyntax {
            body.descendant(where: { syntax -> ExprSyntax? in
                guard let switchCase = SwitchCaseSyntax(syntax) else { return nil }
                guard let caseItem = switchCase.descendant(where: { CaseItemSyntax($0) }) else { return nil }
                guard let caseLabel = caseItem.descendant(where: { MemberAccessExprSyntax($0) }) else { return nil }
                guard caseLabel.name.text == caseName else { return nil }
                guard let returnStmnt = switchCase.descendant(where: { ReturnStmtSyntax($0) }) else { return nil }
                
                return returnStmnt.expression?.eraseToExprSyntax()
            })!
        }
        
        func convertToTupleExpression(caseName: String, useTrailingComma: Bool) -> TupleExprElementSyntax {
            TupleExprElementSyntax {
                $0.useLabel(SF.makeIdentifier(name))
                $0.useColon(SF.makeColonToken(trailingTrivia: .spaces(1)))
                $0.useExpression(expressionForCase(caseName))
                if useTrailingComma {
                    $0.useTrailingComma(SF.makeCommaToken(trailingTrivia: .spaces(1)))
                }
            }
        }
    }
}

extension ConvertibleEnum {
    
    struct Case: Equatable {
        
        var name: String
        var parameterClause: ParameterClauseSyntax?
        var associatedTypes: [AssociatedType]
        
        func convert(enumName: String, enumType: String, enumProperties: [Property]) -> DeclSyntax {
            if let parameterClause = parameterClause {
                return FunctionDeclSyntax {
                    $0.addModifier(DeclModifierSyntax { $0.useName(SF.makeStaticKeyword(trailingTrivia: .spaces(1))) } )
                    $0.useFuncKeyword(SF.makeFuncKeyword(trailingTrivia: .spaces(1)))
                    $0.useIdentifier(SF.makeIdentifier(name))
                    $0.useSignature(
                        FunctionSignatureSyntax {
                            $0.useInput(parameterClause.withTrailingTrivia(.spaces(1)))
                            $0.useOutput(
                                ReturnClauseSyntax {
                                    $0.useArrow(SF.makeArrowToken(trailingTrivia: .spaces(1)))
                                    $0.useReturnType(SF.makeTypeIdentifier(enumType, trailingTrivia: .spaces(1)))
                                }
                            )
                        }
                    )
                    $0.useBody(Self.body(caseName: name, enumProperties: enumProperties))
                }.eraseToDeclSyntax()
            }
            return VariableDeclSyntax {
                $0.addModifier(DeclModifierSyntax { $0.useName(SF.makeStaticKeyword(trailingTrivia: .spaces(1))) } )
                $0.useLetOrVarKeyword(SF.makeVarKeyword(trailingTrivia: .spaces(1)))
                $0.addBinding(PatternBindingSyntax {
                    $0.usePattern(SF.makeIdentifierPattern(identifier: SF.makeIdentifier(name)).eraseToPatternSyntax())
                    $0.useTypeAnnotation(SF.makeTypeAnnotation(colon: SF.makeColonToken(trailingTrivia: .spaces(1)),
                                                               type: SF.makeTypeIdentifier(enumName, trailingTrivia: .spaces(1))))
                    $0.useAccessor(
                        Self.body(caseName: name, enumProperties: enumProperties).eraseToSyntax()
                    )
                }
                )
            }.eraseToDeclSyntax()
        }
        
        static func body(caseName: String, enumProperties: [Property]) -> CodeBlockSyntax {
            CodeBlockSyntax {
                $0.useLeftBrace(SF.makeLeftBraceToken(trailingTrivia: .newlines(1)))
                $0.addStatement(
                    ReturnStmtSyntax {
                        $0.useReturnKeyword(SF.makeReturnKeyword(trailingTrivia: .spaces(1)))
                        $0.useExpression(
                            FunctionCallExprSyntax {
                                $0.useCalledExpression(SF.makeMemberAccessExpr(base: nil, dot: SF.makePeriodToken(), name: SF.makeInitKeyword(), declNameArguments: nil).eraseToExprSyntax())
                                $0.useLeftParen(SF.makeLeftParenToken())
                                for p in enumProperties {
                                    $0.addArgument(p.convertToTupleExpression(caseName: caseName, useTrailingComma: enumProperties.last! != p))
                                }
                                $0.useRightParen(SF.makeRightParenToken())
                            }.eraseToExprSyntax()
                        )
                    }.wrapInCodeBlockItem()
                )
                $0.useRightBrace(SF.makeRightBraceToken(leadingTrivia: .newlines(1)))
            }
        }
    }
}

/// functionParameters
//for v in associatedTypes {
//    $0.addArgument(SF.makeTupleExprElement(label: SF.makeIdentifier(v.name),
//                                           colon: SF.makeColonToken(trailingTrivia: .spaces(1)),
//                                           expression: v.expression,
//                                           trailingComma: associatedTypes.last! != v ? SF.makeCommaToken(trailingTrivia: .spaces(1)) : nil))
//}

extension ConvertibleEnum.Case {
    struct AssociatedType: Equatable {
        init(name: String, expression: ExprSyntax) {
            self.name = name
            self.expression = expression
        }
        
        let name: String
        let expression: ExprSyntax
        
        func convert() -> PatternBindingSyntax {
            fatalError()
        }
    }
}
