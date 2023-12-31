//
//  WebBrowser+KeyBind.swift
//  WebBrowser
//
//  Created by baojianjun on 2023/10/23.
//

import Foundation
import WebKit
import LarkWebViewContainer
import LarkKeyCommandKit

extension WebBrowser {
    func externalKeyCommand() -> [KeyBindingWraper] {
        resolve(WebSearchExtensionItem.self)?.externalKeyCommand() ?? []
    }
}
