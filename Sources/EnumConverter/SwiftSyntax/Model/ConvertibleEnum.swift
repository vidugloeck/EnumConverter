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
