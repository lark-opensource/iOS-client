//
//  SearchHelper.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/30.
//

import Foundation
import YYText

class SearchHelper {
    // 字符相关
    enum AttributeText {
        static func searchHighlightAttributeText(attributedString: NSAttributedString,
                                                 keywords: [String],
                                                 highlightColor: UIColor,
                                                 attr: (UIFont, UIColor)? = nil) -> NSAttributedString {
            let text = attributedString.string
            let muAttributedString = NSMutableAttributedString(attributedString: attributedString)
            if let font = attr?.0, let color = attr?.1 {
                muAttributedString.addAttributes([.font: font, .foregroundColor: color],
                                                 range: NSRange(location: 0, length: text.count))
            }
            keywords.forEach { (term) in
                var searchRange = NSRange(location: 0, length: text.count)
                let maxSearchTime = 10
                var searchTime = 0
                while searchRange.location < text.count, searchTime < maxSearchTime {
                    searchTime += 1
                    let foundRange = (text as NSString).range(of: term, options: [.caseInsensitive], range: searchRange)
                    if foundRange.location != NSNotFound {
                        muAttributedString.addAttribute(.foregroundColor,
                                                        value: highlightColor,
                                                        range: foundRange)
                        searchRange.location = foundRange.location + foundRange.length
                        searchRange.length = text.count - searchRange.location
                    } else {
                        break
                    }
                }
            }
//            let attString = NSAttributedString(attributedString: muAttributedString)
            return muAttributedString
        }
    }
}
