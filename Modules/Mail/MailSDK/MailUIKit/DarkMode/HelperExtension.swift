//
//  HelperExtension.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/6/7.
//

import Foundation
import YYText

extension YYLabel {
    open var mailText: String? {
        get {
            return self.attributedText?.string
        }
        set {
            if newValue != nil {
                var new = NSAttributedString(
                    string: newValue!,
                    attributes: [
                        .font: self.font.copy(),
                        .foregroundColor: self.textColor.copy()
                    ]
                )
                self.attributedText = new
            } else {
                self.attributedText = nil
            }
        }
    }

//    func updateMailText(textColor: UIColor? = nil, addDraftPrifix: Bool = false, _ newValue: String?) {
//        if newValue != nil {
//            let draftPrefix: String = addDraftPrifix ? "[草稿]" : ""
//            var new = NSMutableAttributedString(
//                string: newValue!,
//                attributes: [
//                    .font: self.font.copy(),
//                    .foregroundColor: textColor?.copy() ?? UIColor.ud.textTitle.copy()
//                ]
//            )
//            if addDraftPrifix {
//                new.insert(
//                    NSMutableAttributedString(string: draftPrefix,
//                                              attributes: [.font: self.font.copy(),
//                                                           .foregroundColor: UIColor.ud.functionDangerContentDefault.copy()]),
//                    at: 0)
//            }
//            self.attributedText = new
//        } else {
//            self.attributedText = nil
//        }
//    }
}

extension UILabel {
    open var mailText: String? {
        get {
            return self.attributedText?.string
        }
        set {
            if newValue != nil {
                var new = NSAttributedString(
                    string: newValue!,
                    attributes: [
                        .font: self.font.copy(),
                        .foregroundColor: self.textColor.copy()
                    ]
                )
                self.attributedText = new
            } else {
                self.attributedText = nil
            }
        }
    }
}
