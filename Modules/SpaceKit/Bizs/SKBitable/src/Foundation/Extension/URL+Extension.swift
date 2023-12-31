//
//  URL+Extension.swift
//  SKBitable
//
//  Created by X-MAN on 2023/12/20.
//

import Foundation
import SKFoundation

fileprivate let docxTokenKey = "docxToken"

extension BitableWrapper where Base == URL {
    // 如果query包含 docxToken， 需要预加载，并优先展示docx
    func getBitableLinkedDocxToken() -> String? {
        if UserScopeNoChangeFG.XM.docxBaseOptimized {
            return base.queryParameters[docxTokenKey]
        }
        return nil
    }
}

extension URL: BitableCompatible {}

