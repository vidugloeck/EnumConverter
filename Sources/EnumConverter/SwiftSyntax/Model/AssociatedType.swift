//
//  AssociatedType.swift
//  EnumConverter
//
//  Created by Vidu Glöck on 26.06.21.
//

import SwiftSyntax

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
