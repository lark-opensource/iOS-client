//
//  CTATool.swift
//  CTADialog
//
//  Created by aslan on 2023/10/17.
//

import Foundation
import UniverseDesignColor

struct CTATool {
    static func replace(original: String,
                        attributes: [NSAttributedString.Key: Any],
                        enableClickProfile: Bool = true,
                        with fields: [CTAField]) -> NSAttributedString {
        let resultAttributedString = NSMutableAttributedString(string: original, attributes: attributes)
        for field in fields {
            if let key = field.key,
               let content = field.content {
                let placeholderString = "{{\(key)}}"
                let range: NSRange
                range = (resultAttributedString.string as NSString).range(of: placeholderString)
                if range.location == NSNotFound {
                    continue
                }
                if field.type == CTADialogDefine.filedType.user {
                    let replaceContent = enableClickProfile ? "@\(content)" : "\(content)"
                    resultAttributedString.replaceCharacters(in: range, with: replaceContent)
                    if enableClickProfile {
                        let attributesRange: NSRange
                        attributesRange = (resultAttributedString.string as NSString).range(of: replaceContent)
                        resultAttributedString.addAttribute(.link, value: "\(CTADialogDefine.Cons.profileScheme)://\(key)", range: attributesRange)
                        resultAttributedString.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal, range: attributesRange)
                    }
                } else if field.type == CTADialogDefine.filedType.plainText {
                    resultAttributedString.replaceCharacters(in: range, with: content)
                }
            }
        }
        return resultAttributedString
    }
}
