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

extension ConvertibleEnum {
    
    struct Case: Equatable {
        
        var name: String
        var associatedTypes: [AssociatedType] = []
        
        init(name: String, parameterClause: ParameterClauseSyntax?) {
            self.name = name
            associatedTypes = parameterClause?.parameterList.map(associatedTypeFromParameter) ?? []
        }
        
        private func associatedTypeFromParameter(_ item: FunctionParameterSyntax) -> AssociatedType {
            if let secondName = item.secondName { fatalError("second labels (\(secondName)) are not supported") }
            guard let type = item.type else { fatalError("can't do this without a type") }
            return AssociatedType(name: item.firstName?.text, type: type.description)
        }
        
        func convert(enumName: String, enumType: String, enumProperties: [Property]) -> DeclSyntax {
            if associatedTypes.count > 0 {
                return FunctionDeclSyntax {
                    $0.addModifier(DeclModifierSyntax { $0.useName(SF.makeStaticKeyword(trailingTrivia: .spaces(1))) } )
                    $0.useFuncKeyword(SF.makeFuncKeyword(trailingTrivia: .spaces(1)))
                    $0.useIdentifier(SF.makeIdentifier(name))
                    $0.useSignature(
                        FunctionSignatureSyntax {
                            $0.useInput(ParameterClauseSyntax {
                                $0.useLeftParen(SF.makeLeftParenToken())
                                for (index, item) in associatedTypes.enumerated() {
                                    $0.addParameter(item.convert(index, useTrailingComma: item != associatedTypes.last))
                                }
                                $0.useRightParen(SF.makeRightParenToken(trailingTrivia: .spaces(1)))
                            })
                            $0.useOutput(
                                ReturnClauseSyntax {
                                    $0.useArrow(SF.makeArrowToken(trailingTrivia: .spaces(1)))
                                    $0.useReturnType(SF.makeTypeIdentifier(enumType, trailingTrivia: .spaces(1)))
                                }
                            )
                        }
                    )
                    $0.useBody(Self.body(caseName: name, associatedTypes: associatedTypes, enumProperties: enumProperties))
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
                        Self.body(caseName: name, associatedTypes: [], enumProperties: enumProperties).eraseToSyntax()
                    )
                }
                )
            }.eraseToDeclSyntax()
        }
        
        static func body(caseName: String, associatedTypes: [Case.AssociatedType] , enumProperties: [Property]) -> CodeBlockSyntax {
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
                                    $0.addArgument(p.convertToTupleExpression(caseName: caseName,
                                                                              associatedTypes: associatedTypes,
                                                                              useTrailingComma: enumProperties.last! != p))
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

extension ConvertibleEnum.Case {
    struct AssociatedType: Equatable {
        init(name: String?, type: String) {
            self.name = name == "" ? nil : name
            self.type = type
        }
        
        let name: String?
        let type: String
        
        func convert(_ index: Int, useTrailingComma: Bool) -> FunctionParameterSyntax {
            FunctionParameterSyntax {
                $0.useFirstName(SF.makeIdentifier(name ?? "value\(index)"))
                $0.useColon(SF.makeColonToken(trailingTrivia: .spaces(1)))
                $0.useType(SF.makeTypeIdentifier(type))
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
