//
//  File.swift
//  DocsSDK
//
//  Created by huahuahu on 2018/12/3.
//

import Foundation

extension NSAttributedString: MailExtensionCompatible {}

extension MailExtension where BaseType == NSAttributedString {
    var urlAttributed: NSAttributedString {
        guard let attrText = self.base.mutableCopy() as? NSMutableAttributedString else {
            return NSAttributedString()
        }
        return attrText
    }
}
