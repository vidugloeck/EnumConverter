//
//  Case.swift
//  EnumConverter
//
//  Created by Vidu Glöck on 26.06.21.
//

import SwiftSyntax

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

