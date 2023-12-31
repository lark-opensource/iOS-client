//
//  String+Ext.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/5/10.
//  


import Foundation

extension String {
    
    func htmlAttributedString(attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        guard let data = self.data(using: .utf8) else {
            return NSAttributedString(string: self, attributes: attributes)
        }
        do {
            let attributedString = try NSMutableAttributedString(
               data: data,
               options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
               documentAttributes: nil)
            attributedString.addAttributes(attributes,
                                           range: NSRange(location: 0, length: attributedString.length))
            return attributedString
        } catch {
            LarkInlineAILogger.error("htmlAttributedString error:\(error)")
            return NSAttributedString(string: self, attributes: attributes)
        }
    }
    
    func subString(with range: NSRange) -> String? {
         let str = self
         guard let strRange = Range(range, in: str) else { return nil }
         return String(str[strRange])
    }
}
