//
//  BrowserViewController+Clipboard.swift
//  SKBrowser
//
//  Created by ByteDance on 2022/9/13.
//

import Foundation
import SKUIKit

extension BrowserViewController: ClipboardProtectProtocol {
    public func getDocumentToken() -> String? {
        return self.editor.docsInfo?.token
    }
}
