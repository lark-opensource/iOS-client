//
//  AttributedStringUtil.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/8/11.
//

import Foundation

class AttributedStringUtil {
    static public func attributedString(_ subtitle: String, value: String, placeholder: String) -> NSAttributedString {
        let res = subtitle.replacingOccurrences(
            of: placeholder,
            with: value
        )
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
            .foregroundColor: UIColor.ud.textCaption
        ]
        let baseAttributedString = NSAttributedString(string: res, attributes: baseAttributes)
        let resultAttributedString = NSMutableAttributedString(attributedString: baseAttributedString)

        let range = (res as NSString).range(of: value)
        if range.location != NSNotFound {
            let boldAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14.0, weight: .bold),
                .foregroundColor: UIColor.ud.textTitle
            ]
            resultAttributedString.addAttributes(boldAttributes, range: range)
        }
        return resultAttributedString
    }
}
