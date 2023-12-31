//
//  File.swift
//  EcosystemWeb
//
//  Created by ByteDance on 2023/7/19.
//

import Foundation
import WebBrowser
import LarkUIKit

public extension WebBrowser {
    func ecosystem_registerExtensionItemsForBitableHomePage() {
        do {
            try self.register(item: WebMetaLegacyExtensionItem())
            try self.register(item: WebMetaExtensionItem(browser: self))
            try self.register(item: WebMetaSafeAreaExtensionItem(browser: self))
            
            try self.register(item: MonitorExtensionItem())
            try self.register(item: TerminateReloadExtensionItem(browser: self))
            try self.register(item: ErrorPageExtensionItem())
            try self.register(item: UniteRouterExtensionItem())

            try self.register(item: WebAppExtensionItem(browser: self, webAppInfo: nil))
            try self.register(item: EcosystemAPIExtensionItem())
            try self.register(singleItem: EcosystemWebSingleExtensionItem())
            
            if Display.pad {
                try self.register(item: PadExtensionItem(browser: self))
            }
        } catch {
            NormalWebRouterHandler.logger.error("registerEcosystemWebExtensionItems error", error: error)
        }
    }
}

