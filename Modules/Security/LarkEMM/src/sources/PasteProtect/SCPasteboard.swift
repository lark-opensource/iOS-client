//
//  SCPasteboard.swift
//  EnterpriseMobilityManagement
//
//  Created by WangXijing on 2022/7/6.
//

import Foundation
import SwiftUI
import LarkContainer
import UniverseDesignDialog
import EENavigator
import WebKit
import LarkSecurityComplianceInfra
import PDFKit
import ByteDanceKit
import AppContainer
import LarkSensitivityControl

public enum Scene: String {
    case sc
}

public struct PasteboardConfig {
    public var scene: Scene?
    public var pointId: String?
    public var shouldImmunity: Bool?
    public var ignoreAlert: Bool?
    public var token: Token
    public init(token: Token, scene: Scene? = nil, pointId: String? = nil, shouldImmunity: Bool? = nil, ignoreAlert: Bool? = nil) {
        self.scene = scene
        self.pointId = pointId
        self.shouldImmunity = shouldImmunity
        self.ignoreAlert = ignoreAlert
        self.token = token
    }
}

public final class SCPasteboard {

    var pasteboardService: PasteboardService? {
        return try? userResolver?.resolve(assert: PasteboardService.self)
    }
    public var uid: String?
    private var scene: Scene?
    private var pointId: String? // 单一点位保护标识
    private var shouldImmunity: Bool? // 粘贴保护豁免
    private var ignoreAlert: Bool? // 粘贴保护弹窗豁免
    static let general = SCPasteboard()
    var pasteboardList: [String] = []
    var config: PasteboardConfig = SCPasteboard.defaultConfig()
    private var userResolver: UserResolver?
    /// 通用证书，内部逻辑调用UIPasteboard.addItems/UIPasteboard.items时使用
    private let token = Token("LARK-PSDA-pasteboard_scpasteboard")
    
    static var enablePasteProtectOpt: Bool = false
    var lastPointId: String?

    var customPasteboard: UIPasteboard? {
        guard let uid = pasteboardService?.currentEncryptUserId() else {
            return nil
        }

        let pasteboard = UIPasteboard(name: UIPasteboard.Name(uid), create: true)
        if let pasteboard = pasteboard {
            if pasteboardList.contains(uid) {
                pasteboard.scUid = uid
                SCLogger.info("SCPasteboard: customPasteboard create with \(uid)")
                pasteboardList.append(uid)
            }
        }
        return pasteboard
    }

    public var string: String? {
        get {
            if Self.enablePasteProtectOpt {
                return UIPasteboard.general.string
            } else {
                let generalHasNewContent: Bool = SCPasteboard.generalHasNewContent(.string)
                var string: String?
                if generalHasNewContent {
                    SCLogger.info("SCPasteboard: get UIPasteboard.general.string")
                    do {
                        string = try PasteboardEntry.string(ofToken: config.token, pasteboard: UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get UIPasteboard string error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.string, error: error)
                    }
                    return string
                } else if checkPastePermission() {
                    SCLogger.info("SCPasteboard: get SCPasteboard.customPasteboard.string")
                    do {
                        string = try PasteboardEntry.string(ofToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get customPasteboard string error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.string, error: error)
                    }
                    return string
                }
                do {
                    string = try PasteboardEntry.string(ofToken: config.token, pasteboard: UIPasteboard.general)
                } catch {
                    SCLogger.error("SCPasteboard: get string error: \(error.localizedDescription)")
                    monitorPasteProtectGetFail(.string, error: error)
                }

                return string
            }
        }

        set {
            if Self.enablePasteProtectOpt {
                UIPasteboard.general.string = newValue
            } else {
                guard newValue != nil  else { return }

                if checkCopyPermission() {
                    do {
                        try PasteboardEntry.setString(forToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general, string: newValue)
                    } catch {
                        SCLogger.error("SCPasteboard: set customPasteboard string error: \(error.localizedDescription)")
                        monitorPasteProtectSetFail(.string, error: error)
                    }
                    dealAfterCustomSetValue()
                    SCLogger.info("SCPasteboard: set SCPasteboard.customPasteboard.string")
                    return
                }
                do {
                    try PasteboardEntry.setString(forToken: config.token, pasteboard: UIPasteboard.general, string: newValue)
                } catch {
                    SCLogger.error("SCPasteboard: set UIPasteboard string error: \(error.localizedDescription)")
                    monitorPasteProtectSetFail(.string, error: error)
                }
                customPasteboard?.clearPasteboard()
                SCLogger.info("SCPasteboard: set UIPasteboard.general.string")
            }
        }
    }

    public var strings: [String]? {
        get {
            if Self.enablePasteProtectOpt {
                return UIPasteboard.general.strings
            } else {
                let generalHasNewContent: Bool = SCPasteboard.generalHasNewContent(.string)
                var strings: [String]?
                if generalHasNewContent {
                    SCLogger.info("SCPasteboard: get UIPasteboard.general.strings")
                    do {
                        strings = try PasteboardEntry.strings(ofToken: config.token, pasteboard: UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get UIPasteboard strings error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.strings, error: error)
                    }
                    return strings
                } else if checkPastePermission() {
                    SCLogger.info("SCPasteboard: get SCPasteboard.customPasteboard.strings")
                    do {
                        strings = try PasteboardEntry.strings(ofToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get customPasteboard strings error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.strings, error: error)
                    }
                    return strings
                }
                do {
                    strings = try PasteboardEntry.strings(ofToken: config.token, pasteboard: UIPasteboard.general)
                } catch {
                    SCLogger.error("SCPasteboard: get strings error: \(error.localizedDescription)")
                    monitorPasteProtectGetFail(.strings, error: error)
                }
                return strings
            }
        }

        set {
            if Self.enablePasteProtectOpt {
                UIPasteboard.general.strings = newValue
            } else {
                guard newValue != nil  else { return }

                if checkCopyPermission() {
                    do {
                        try PasteboardEntry.setStrings(forToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general, strings: newValue)
                    } catch {
                        SCLogger.error("SCPasteboard: set customPasteboard string error: \(error.localizedDescription)")
                        monitorPasteProtectSetFail(.strings, error: error)
                    }
                    dealAfterCustomSetValue()
                    SCLogger.info("SCPasteboard: set SCPasteboard.customPasteboard.strings")
                    return
                }
                do {
                    try PasteboardEntry.setStrings(forToken: config.token, pasteboard: UIPasteboard.general, strings: newValue)
                } catch {
                    SCLogger.error("SCPasteboard: set UIPasteboard string error: \(error.localizedDescription)")
                    monitorPasteProtectSetFail(.strings, error: error)
                }
                customPasteboard?.clearPasteboard()
                SCLogger.info("SCPasteboard: set UIPasteboard.general.strings")
            }
        }
    }

    public var color: UIColor? {
        get {
            if Self.enablePasteProtectOpt {
                return UIPasteboard.general.color
            } else {
                let generalHasNewContent: Bool = SCPasteboard.generalHasNewContent(.color)
                if generalHasNewContent {
                    SCLogger.info("SCPasteboard: get UIPasteboard.general.color")
                    return UIPasteboard.general.color
                } else if checkPastePermission() {
                    SCLogger.info("SCPasteboard: get SCPasteboard.customPasteboard.color")
                    return customPasteboard?.color
                }
                return UIPasteboard.general.color
            }
        }

        set {
            if Self.enablePasteProtectOpt {
                UIPasteboard.general.color = newValue
            } else {
                guard newValue != nil  else { return }

                if checkCopyPermission() {
                    customPasteboard?.color = newValue
                    dealAfterCustomSetValue()
                    SCLogger.info("SCPasteboard: set SCPasteboard.customPasteboard.color")
                    return
                }
                UIPasteboard.general.color = newValue
                customPasteboard?.clearPasteboard()
                SCLogger.info("SCPasteboard: set UIPasteboard.general.color")
            }
        }
    }

    public var colors: [UIColor]? {
        get {
            if Self.enablePasteProtectOpt {
                return UIPasteboard.general.colors
            } else {
                let generalHasNewContent: Bool = SCPasteboard.generalHasNewContent(.color)
                if generalHasNewContent {
                    SCLogger.info("SCPasteboard: get UIPasteboard.general.colors")
                    return UIPasteboard.general.colors
                } else if checkPastePermission() {
                    SCLogger.info("SCPasteboard: get SCPasteboard.customPasteboard.colors")
                    return customPasteboard?.colors
                }
                return UIPasteboard.general.colors
            }
        }

        set {
            if Self.enablePasteProtectOpt {
                UIPasteboard.general.colors = newValue
            } else {
                guard newValue != nil  else { return }

                if checkCopyPermission() {
                    customPasteboard?.colors = newValue
                    dealAfterCustomSetValue()
                    SCLogger.info("SCPasteboard: set SCPasteboard.customPasteboard.colors")
                    return
                }
                UIPasteboard.general.colors = newValue
                customPasteboard?.clearPasteboard()
                SCLogger.info("SCPasteboard: set UIPasteboard.general.colors")
            }
        }
    }

    public var url: URL? {
        get {
            if Self.enablePasteProtectOpt {
                return UIPasteboard.general.url
            } else {
                let generalHasNewContent: Bool = SCPasteboard.generalHasNewContent(.url)
                var url: URL?
                if generalHasNewContent {
                    SCLogger.info("SCPasteboard: get UIPasteboard.general.url")
                    do {
                        url = try PasteboardEntry.url(ofToken: config.token, pasteboard: UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get UIPasteboard url error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.url, error: error)
                    }
                    return url
                } else if self.checkPastePermission() {
                    SCLogger.info("SCPasteboard: get SCPasteboard.customPasteboard.url")
                    do {
                        url = try PasteboardEntry.url(ofToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get customPasteboard url error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.url, error: error)
                    }
                    return url
                }
                do {
                    url = try PasteboardEntry.url(ofToken: config.token, pasteboard: UIPasteboard.general)
                } catch {
                    SCLogger.error("SCPasteboard: get url error: \(error.localizedDescription)")
                    monitorPasteProtectGetFail(.url, error: error)
                }
                return url
            }
        }

        set {
            if Self.enablePasteProtectOpt {
                UIPasteboard.general.url = newValue
            } else {
                guard newValue != nil  else { return }

                if checkCopyPermission() {
                    do {
                        try PasteboardEntry.setUrl(forToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general, url: newValue)
                    } catch {
                        SCLogger.error("SCPasteboard: set customPasteboard url error: \(error.localizedDescription)")
                        monitorPasteProtectSetFail(.url, error: error)
                    }
                    dealAfterCustomSetValue()
                    SCLogger.info("SCPasteboard: set SCPasteboard.customPasteboard.url")
                    return
                }
                do {
                    try PasteboardEntry.setUrl(forToken: config.token, pasteboard: UIPasteboard.general, url: newValue)
                } catch {
                    SCLogger.error("SCPasteboard: set UIPasteboard url error: \(error.localizedDescription)")
                    monitorPasteProtectSetFail(.url, error: error)
                }
                customPasteboard?.clearPasteboard()
                SCLogger.info("SCPasteboard: set UIPasteboard.general.url")
            }
        }
    }

    public var urls: [URL]? {
        get {
            if Self.enablePasteProtectOpt {
                return UIPasteboard.general.urls
            } else {
                let generalHasNewContent: Bool = SCPasteboard.generalHasNewContent(.url)
                var urls: [URL]?
                if generalHasNewContent {
                    SCLogger.info("SCPasteboard: get UIPasteboard.general.urls")
                    do {
                        urls = try PasteboardEntry.urls(ofToken: config.token, pasteboard: UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get UIPasteboard urls error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.urls, error: error)
                    }
                    return urls
                } else if checkPastePermission() {
                    SCLogger.info("SCPasteboard: get SCPasteboard.customPasteboard.urls")
                    do {
                        urls = try PasteboardEntry.urls(ofToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get customPasteboard urls error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.urls, error: error)
                    }
                    return urls
                }
                do {
                    urls = try PasteboardEntry.urls(ofToken: config.token, pasteboard: UIPasteboard.general)
                } catch {
                    SCLogger.error("SCPasteboard: get urls error: \(error.localizedDescription)")
                    monitorPasteProtectGetFail(.urls, error: error)
                }
                return urls
            }
        }

        set {
            if Self.enablePasteProtectOpt {
                UIPasteboard.general.urls = newValue
            } else {
                guard newValue != nil  else { return }

                if checkCopyPermission() {
                    do {
                        try PasteboardEntry.setUrls(forToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general, urls: newValue)
                    } catch {
                        SCLogger.error("SCPasteboard: set customPasteboard urls error: \(error.localizedDescription)")
                        monitorPasteProtectSetFail(.urls, error: error)
                    }
                    dealAfterCustomSetValue()
                    SCLogger.info("SCPasteboard: set SCPasteboard.customPasteboard.urls")
                    return
                }
                do {
                    try PasteboardEntry.setUrls(forToken: config.token, pasteboard: UIPasteboard.general, urls: newValue)
                } catch {
                    SCLogger.error("SCPasteboard: set UIPasteboard urls error: \(error.localizedDescription)")
                    monitorPasteProtectSetFail(.urls, error: error)
                }
                customPasteboard?.clearPasteboard()
                SCLogger.info("SCPasteboard: set UIPasteboard.general.urls")
            }
        }
    }

    public var image: UIImage? {
        get {
            if Self.enablePasteProtectOpt {
                return UIPasteboard.general.image
            } else {
                let generalHasNewContent: Bool = SCPasteboard.generalHasNewContent(.image)
                var image: UIImage?
                if generalHasNewContent {
                    SCLogger.info("SCPasteboard: get UIPasteboard.general.image")
                    do {
                        image = try PasteboardEntry.image(ofToken: config.token, pasteboard: UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get UIPasteboard image error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.image, error: error)
                    }
                    return image
                } else if checkPastePermission() {
                    SCLogger.info("SCPasteboard: get SCPasteboard.customPasteboard.image")
                    do {
                        image = try PasteboardEntry.image(ofToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get customPasteboard image error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.image, error: error)
                    }
                    return image
                }
                do {
                    image = try PasteboardEntry.image(ofToken: config.token, pasteboard: UIPasteboard.general)
                } catch {
                    SCLogger.error("SCPasteboard: get image error: \(error.localizedDescription)")
                    monitorPasteProtectGetFail(.image, error: error)
                }
                return image
            }
        }

        set {
            if Self.enablePasteProtectOpt {
                UIPasteboard.general.image = image
            } else {
                guard newValue != nil  else { return }

                if checkCopyPermission() {
                    do {
                        try PasteboardEntry.setImage(forToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general, image: newValue)
                    } catch {
                        SCLogger.error("SCPasteboard: set customPasteboard image error: \(error.localizedDescription)")
                        monitorPasteProtectSetFail(.image, error: error)
                    }
                    dealAfterCustomSetValue()
                    SCLogger.info("SCPasteboard: set SCPasteboard.customPasteboard.image")
                    return
                }
                do {
                    try PasteboardEntry.setImage(forToken: config.token, pasteboard: UIPasteboard.general, image: newValue)
                } catch {
                    SCLogger.error("SCPasteboard: set UIPasteboard image error: \(error.localizedDescription)")
                    monitorPasteProtectSetFail(.image, error: error)
                }
                customPasteboard?.clearPasteboard()
                SCLogger.info("SCPasteboard: set UIPasteboard.general.image")
            }
        }
    }

    public var images: [UIImage]? {
        get {
            if Self.enablePasteProtectOpt {
                return UIPasteboard.general.images
            } else {
                let generalHasNewContent: Bool = SCPasteboard.generalHasNewContent(.image)
                var images: [UIImage]?
                if generalHasNewContent {
                    SCLogger.info("SCPasteboard: get UIPasteboard.general.images")
                    do {
                        images = try PasteboardEntry.images(ofToken: config.token, pasteboard: UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get UIPasteboard images error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.images, error: error)
                    }
                    return images
                } else if checkPastePermission() {
                    SCLogger.info("SCPasteboard: get SCPasteboard.customPasteboard.images")
                    do {
                        images = try PasteboardEntry.images(ofToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get customPasteboard images error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.images, error: error)
                    }
                    return images
                }
                do {
                    images = try PasteboardEntry.images(ofToken: config.token, pasteboard: UIPasteboard.general)
                } catch {
                    SCLogger.error("SCPasteboard: get images error: \(error.localizedDescription)")
                    monitorPasteProtectGetFail(.images, error: error)
                }
                return images
            }
        }

        set {
            if Self.enablePasteProtectOpt {
                UIPasteboard.general.images = newValue
            } else {
                guard newValue != nil  else { return }

                if checkCopyPermission() {
                    do {
                        try PasteboardEntry.setImages(forToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general, images: newValue)
                    } catch {
                        SCLogger.error("SCPasteboard: set customPasteboard images error: \(error.localizedDescription)")
                        monitorPasteProtectSetFail(.images, error: error)
                    }
                    dealAfterCustomSetValue()
                    SCLogger.info("SCPasteboard: set SCPasteboard.customPasteboard.images")
                    return
                }
                do {
                    try PasteboardEntry.setImages(forToken: config.token, pasteboard: UIPasteboard.general, images: newValue)
                } catch {
                    SCLogger.error("SCPasteboard: set UIPasteboard images error: \(error.localizedDescription)")
                    monitorPasteProtectSetFail(.images, error: error)
                }
                customPasteboard?.clearPasteboard()
                SCLogger.info("SCPasteboard: set UIPasteboard.general.images")
            }
        }
    }

    public var items: [[String: Any]]? {
        get {
            if Self.enablePasteProtectOpt {
                return UIPasteboard.general.items
            } else {
                let generalHasNewContent: Bool = SCPasteboard.generalHasNewContent(.all)
                var items: [[String: Any]]?
                if generalHasNewContent {
                    SCLogger.info("SCPasteboard: get UIPasteboard.general.items")
                    do {
                        items = try PasteboardEntry.items(ofToken: config.token, pasteboard: UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get UIPasteboard items error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.items, error: error)
                    }
                    return items
                } else if checkPastePermission() {
                    SCLogger.info("SCPasteboard: get SCPasteboard.customPasteboard.items")
                    do {
                        items = try PasteboardEntry.items(ofToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general)
                    } catch {
                        SCLogger.error("SCPasteboard: get customPasteboard items error: \(error.localizedDescription)")
                        monitorPasteProtectGetFail(.items, error: error)
                    }
                    items = items?.filter({ item in
                        return item.contains { (key, _) in
                            return key == "encryptId"
                        } == false
                    })
                    return items
                }
                do {
                    items = try PasteboardEntry.items(ofToken: config.token, pasteboard: UIPasteboard.general)
                } catch {
                    SCLogger.error("SCPasteboard: get items error: \(error.localizedDescription)")
                    monitorPasteProtectGetFail(.items, error: error)
                }
                return items
            }
        }

        set {
            if Self.enablePasteProtectOpt {
                UIPasteboard.general.items = newValue ?? []
            } else {
                guard let newValue = newValue else { return }

                if self.checkCopyPermission() {
                    do {
                        try PasteboardEntry.setItems(forToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general, newValue)
                    } catch {
                        SCLogger.error("SCPasteboard: set customPasteboard items error: \(error.localizedDescription)")
                        monitorPasteProtectSetFail(.items, error: error)
                    }
                    self.dealAfterCustomSetValue()
                    SCLogger.info("SCPasteboard: set SCPasteboard.customPasteboard.items")
                    return
                }
                do {
                    try PasteboardEntry.setItems(forToken: config.token, pasteboard: UIPasteboard.general, newValue)
                } catch {
                    SCLogger.error("SCPasteboard: set UIPasteboard items error: \(error.localizedDescription)")
                    monitorPasteProtectSetFail(.items, error: error)
                }
                customPasteboard?.clearPasteboard()
                SCLogger.info("SCPasteboard: set UIPasteboard.general.items")
            }
        }
    }

    @available(iOS 10.0, *)
    public func setItems(_ items: [[String: Any]], options: [UIPasteboard.OptionsKey: Any] = [:]) {
        if Self.enablePasteProtectOpt {
            UIPasteboard.general.setItems(items, options: options)
        } else {
            if checkCopyPermission() {
                do {
                    try PasteboardEntry.setItems(forToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general, items, options: options)
                } catch {
                    SCLogger.error("SCPasteboard: set customPasteboard items has options error: \(error.localizedDescription)")
                    monitorPasteProtectSetFail(.items, error: error, params: ["options": "\(options)"])
                }
                dealAfterCustomSetValue()
                return
            }
            do {
                try PasteboardEntry.setItems(forToken: config.token, pasteboard: UIPasteboard.general, items, options: options)
            } catch {
                SCLogger.error("SCPasteboard: set UIPasteboard items has options error: \(error.localizedDescription)")
                monitorPasteProtectSetFail(.items, error: error, params: ["options": "\(options)"])
            }
            customPasteboard?.clearPasteboard()
        }
    }

    @available(iOS 11.0, *)
    public var itemProviders: [NSItemProvider]? {
        if Self.enablePasteProtectOpt {
            return UIPasteboard.general.itemProviders
        } else {
            let generalHasNewContent: Bool = SCPasteboard.generalHasNewContent(.all)
            var itemProviders: [NSItemProvider]?
            if generalHasNewContent {
                SCLogger.info("SCPasteboard: get UIPasteboard.general.itemProviders")
                do {
                    itemProviders = try PasteboardEntry.itemProviders(forToken: config.token, pasteboard: UIPasteboard.general)
                } catch {
                    SCLogger.error("SCPasteboard: get UIPasteboard itemProviders error: \(error.localizedDescription)")
                    monitorPasteProtectGetFail(.itemProviders, error: error)
                }
                return itemProviders
            } else if checkPastePermission() {
                SCLogger.info("SCPasteboard: get SCPasteboard.customdPasteboard.itemProviders")
                do {
                    itemProviders = try PasteboardEntry.itemProviders(forToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general)
                } catch {
                    SCLogger.error("SCPasteboard: get customPasteboard itemProviders error: \(error.localizedDescription)")
                    monitorPasteProtectGetFail(.itemProviders, error: error)
                }
                return itemProviders
            }
            do {
                itemProviders = try PasteboardEntry.itemProviders(forToken: config.token, pasteboard: UIPasteboard.general)
            } catch {
                SCLogger.error("SCPasteboard: get itemProviders error: \(error.localizedDescription)")
                monitorPasteProtectGetFail(.itemProviders, error: error)
            }
            return itemProviders
        }
    }

    @available(iOS 11.0, *)
    public func setItemProviders(_ itemProviders: [NSItemProvider], localOnly: Bool, expirationDate: Date?) {
        if Self.enablePasteProtectOpt {
            UIPasteboard.general.setItemProviders(itemProviders, localOnly: localOnly, expirationDate: expirationDate)
        } else {
            if checkCopyPermission() {
                SCLogger.info("SCPasteboard: set SCPasteboard.customPasteboard.setItemProviders")
                do {
                    try PasteboardEntry.setItemProviders(
                        forToken: config.token,
                        pasteboard: customPasteboard ?? UIPasteboard.general,
                        itemProviders,
                        localOnly: localOnly,
                        expirationDate: expirationDate)
                } catch {
                    SCLogger.error("SCPasteboard: set customPasteboard itemProviders error: \(error.localizedDescription)")
                    monitorPasteProtectSetFail(.itemProviders, error: error)
                }
                dealAfterCustomSetValue()
                return
            }
            SCLogger.info("SCPasteboard: set UIPasteboard.general.setItemProviders")
            do {
                try PasteboardEntry.setItemProviders(forToken: config.token, pasteboard: UIPasteboard.general, itemProviders, localOnly: localOnly, expirationDate: expirationDate)
            } catch {
                SCLogger.error("SCPasteboard: set itemProviders error: \(error.localizedDescription)")
                monitorPasteProtectSetFail(.itemProviders, error: error)
            }
        }
    }

    @available(iOS 10.0, *)
    public var hasStrings: Bool {
        if Self.enablePasteProtectOpt {
            UIPasteboard.general.hasStrings
        } else {
            UIPasteboard.general.hasStrings || customPasteboard?.hasStrings == true
        }
    }

    @available(iOS 10.0, *)
    public var hasURLs: Bool {
        if Self.enablePasteProtectOpt {
            UIPasteboard.general.hasURLs
        } else {
            UIPasteboard.general.hasURLs || customPasteboard?.hasURLs == true
        }
    }

    @available(iOS 10.0, *)
    public var hasImages: Bool {
        if Self.enablePasteProtectOpt {
            UIPasteboard.general.hasImages
        } else {
            UIPasteboard.general.hasImages || customPasteboard?.hasImages == true
        }
    }

    @available(iOS 10.0, *)
    public var hasColors: Bool {
        if Self.enablePasteProtectOpt {
            UIPasteboard.general.hasColors
        } else {
            UIPasteboard.general.hasColors || customPasteboard?.hasColors == true
        }
    }

    private init() {}

    public func addItems(_ items: [[String: Any]]) {
        if Self.enablePasteProtectOpt {
            UIPasteboard.general.addItems(items)
        } else {
            if checkCopyPermission() {
                do {
                    try PasteboardEntry.addItems(forToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general, items)
                } catch {
                    SCLogger.error("SCPasteboard: add customPasteboard items error: \(error.localizedDescription)")
                    monitorPasteProtectSetFail(.addedItems, error: error)
                }
                SCLogger.info("SCPasteboard: add SCPasteboard.customPasteboard.items")
                return
            }
            SCLogger.info("SCPasteboard: add UIPasteboard.general.items")
            do {
                try PasteboardEntry.addItems(forToken: config.token, pasteboard: UIPasteboard.general, items)
            } catch {
                SCLogger.error("SCPasteboard: add UIPasteboard items error: \(error.localizedDescription)")
                monitorPasteProtectSetFail(.addedItems, error: error)
            }
        }
    }

    public func data(forPasteboardType pasteboardType: String) -> Data? {
        if Self.enablePasteProtectOpt {
            return UIPasteboard.general.data(forPasteboardType: pasteboardType)
        } else {
            let generalHasNewContent: Bool = SCPasteboard.generalHasNewContent(.all)
            var data: Data?
            if generalHasNewContent {
                SCLogger.info("SCPasteboard: UIPasteboard.general.data")
                do {
                    data = try PasteboardEntry.data(forToken: config.token, pasteboard: UIPasteboard.general, forPasteboardType: pasteboardType)
                } catch {
                    SCLogger.error("SCPasteboard: get UIPasteboard data error: \(error.localizedDescription)")
                    monitorPasteProtectGetFail(.data, error: error, params: ["pasteboard_type": pasteboardType])
                }
                return data
            } else if checkPastePermission() {
                SCLogger.info("SCPasteboard: SCPasteboard.customPasteboard.data")
                do {
                    data = try PasteboardEntry.data(forToken: config.token, pasteboard: customPasteboard ?? UIPasteboard.general, forPasteboardType: pasteboardType)
                } catch {
                    SCLogger.error("SCPasteboard: get customPasteboard data error: \(error.localizedDescription)")
                    monitorPasteProtectGetFail(.data, error: error, params: ["pasteboard_type": pasteboardType])
                }
                return data
            }
            SCLogger.info("SCPasteboard: UIPasteboard.general.data")
            do {
                data = try PasteboardEntry.data(forToken: config.token, pasteboard: UIPasteboard.general, forPasteboardType: pasteboardType)
            } catch {
                SCLogger.error("SCPasteboard: get data error: \(error.localizedDescription)")
                monitorPasteProtectGetFail(.data, error: error, params: ["pasteboard_type": pasteboardType])
            }
            return data
        }
    }

    @available(*, deprecated, renamed: "general", message: "We will deprecate this method in version 6.2 of lark, please use the general(_ config: PasteboardConfig)")
    public static func generalPasteboard(scene: Scene? = nil, pointId: String? = nil, shouldImmunity: Bool? = false, ignoreAlert: Bool? = false) -> SCPasteboard {
        general.config = Self.defaultConfig()
        general.scene = scene
        general.pointId = pointId
        general.shouldImmunity = shouldImmunity
        general.ignoreAlert = ignoreAlert
        return general
    }

    public static func defaultConfig() -> PasteboardConfig {
        return PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier))
    }

    public static func general(_ config: PasteboardConfig) -> SCPasteboard {
        general.config = config
        general.scene = config.scene
        general.pointId = config.pointId
        general.shouldImmunity = config.shouldImmunity
        general.ignoreAlert = config.ignoreAlert
        return general
    }

    /// 接入时如果有自己处理异常（获取不到剪贴板内容）的诉求，请使用该方法
    public static func generalUnsafe(_ config: PasteboardConfig) throws -> SCPasteboard {
        let context = Context(sdkName: "LarkEMM", methodName: "generalUnsafe")
        try SensitivityManager.shared.checkToken(config.token, type: .pasteboard, context: context)
        return Self.general(config)
    }

    private func dealAfterCustomSetValue() {
        self.addPointIdIfNeeded()
        UIPasteboard.general.clearPasteboard()
        clearOtherCustomPasteboard()
        showDialogIfNeed()
    }
}

extension SCPasteboard {
    static func startSDK(resolver: UserResolver) {
        Self.config(resolver: resolver)
        SCPasteboardMonitor.monitorPasteProtectVersion(enablePasteProtectOpt ? "v2" : "v1")
        if enablePasteProtectOpt {
            Self.scReplaceUIPasteboard()
            general.lastPointId = nil
        } else {
            Self.hookCopyableViewIfNeeded(userResolver: resolver)
        }
        general.userResolver = resolver
     }

    static func hookCopyableViewIfNeeded(userResolver: UserResolver) {
        DispatchQueue.main.once {
            SCLogger.info("SCPasteboard: hookCopyableViewIfNeeded")
            SCMonitor.info(business: .paste_protect, eventName: "hook_views")
            UITextField.hookPasteMethods()
            UITextView.hookPasteMethods()
            WKWebView.hookPasteMethods()
            PDFView.hookPasteMethods()
            if #available(iOS 13, *) {
                UIAction.startReplaceConfigImp()
            }
            if let scSetting = try? userResolver.resolve(assert: SCSettingService.self), scSetting.bool(.canReplacePdfHostViewController) {
                SCLogger.info("SCPasteboard: call UIViewController.replacePasteProtectMethods")
                UIViewController.replacePasteProtectMethods()
            }
        }
    }

    func checkCopyPermission() -> Bool {
        guard pasteboardService?.currentEncryptUserId() != nil else {
            return false
        }

        if shouldImmunity == true {
            // 是否是豁免场景
            return false
        }

        if pointId != nil {
            // 是否是单一点位保护场景
            return true
        }

        return pasteboardService?.checkProtectPermission() == true
    }

    func checkPastePermission() -> Bool {
        guard (pasteboardService?.currentEncryptUserId()) != nil else {
            return false
        }
        
        if let pointId = self.getPointIdFromPasteboard() {
             if pointId != self.pointId {
               return false
             }
            return true
        }
        return pasteboardService?.checkProtectPermission() == true
    }

    static func generalHasNewContent(_ type: PasteType) -> Bool {
        if enablePasteProtectOpt {
            switch type {
            case .string:
                return UIPasteboard.generalHasStrings()
            case .color:
                return UIPasteboard.generalHasColors()
            case .image:
                return UIPasteboard.generalHasImages()
            case .url:
                return UIPasteboard.generalHasUrls()
            case .all:
                let hasContent: Bool = UIPasteboard.generalHasNewValue()
                return hasContent
            }
        } else {
            return UIPasteboard.general.hasNewValue(type)
        }
    }

    func hasValue() -> Bool {
        let generalHasContent: Bool = SCPasteboard.generalHasNewContent(.all)
        if self.checkPastePermission() {
            let customHasContent: Bool = self.customPasteboard?.hasNewValue(.all) == true
            return generalHasContent || customHasContent
        }
        return generalHasContent
    }

    func assignmentFromPasteboard() {
        let generalPastboard = UIPasteboard.general
        if generalPastboard.hasNewValue(.all) {
            if let pointId = pointId {
                do {
                    try PasteboardEntry.addItems(forToken: config.token, pasteboard: generalPastboard, [["encryptId": pointId]])
                } catch {
                    SCLogger.error("SCPasteboard: add UIPasteboard items error: \(error.localizedDescription)")
                }
            }
            do {
                self.items = try PasteboardEntry.items(ofToken: config.token, pasteboard: generalPastboard)
            } catch {
                SCLogger.error("SCPasteboard: get UIPasteboard items error: \(error.localizedDescription)")
            }
        }
    }

    func clearOtherCustomPasteboard() {
        pasteboardList = pasteboardList.filter({ uid in
            if uid != pasteboardService?.currentEncryptUserId() {
                UIPasteboard.remove(withName: UIPasteboard.Name(uid))
                scStore.removeObject(forKey: "PointId_\(uid)")
            }
            return uid == pasteboardService?.currentEncryptUserId()
        })
    }

    func showDialogIfNeed() {
        guard pasteboardService?.currentEncryptUserId() != nil else { return }
        guard !ignoreAlert.isTrue else { return }

        let pointId = self.getPointIdFromPasteboard()
        let block = { [weak self] in
            guard let self = self else { return }
            let service = try? self.userResolver?.resolve(assert: PasteboardService.self)
            service?.showDialog(pointId)
        }

        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }

}

// SCPasteboard pointId information
extension SCPasteboard {
    func addPointIdIfNeeded() {
        guard let pointId = self.pointId else {
            return
        }
        guard self.getPointIdFromPasteboard() == nil else {
            SCLogger.info("SCPasteboard: has pointId:\(pointId)")
            return
        }
        if Self.enablePasteProtectOpt {
            pasteProtectLogger.info("SCPasteboard: set pointid:\(pointId)")
            scStore.set(pointId, forKey: pointIdKey)
            lastPointId = pointId
        } else {
            if let customPasteboard = customPasteboard {
                do {
                    try PasteboardEntry.addItems(forToken: token, pasteboard: customPasteboard, [["encryptId": pointId]])
                } catch {
                    SCLogger.error("SCPasteboard: add customPasteboard items error: \(error.localizedDescription)")
                }
            }
            SCLogger.info("SCPasteboard: addPointIdIfNeeded pointId:\(pointId)")
        }
    }

    func getPointIdFromPasteboard() -> String? {
        if Self.enablePasteProtectOpt {
            if self.lastPointId.isNil {
                lastPointId = scStore.string(forKey: pointIdKey)
            }
            return lastPointId
        } else {
            var pointId: String?
            var items: [[String: Any]]?
            if let customPasteboard = customPasteboard {
                do {
                    items = try PasteboardEntry.items(ofToken: token, pasteboard: customPasteboard)
                } catch {
                    SCLogger.error("SCPasteboard: get customPasteboard items error: \(error.localizedDescription)")
                }
            }
            _ = items?.contains(where: { items in
                return items.contains { (key, value) in
                    guard key == "encryptId" else {
                        return false
                    }
                    if value is __DispatchData {
                        guard let value = value as? Data else {
                            return false
                        }
                        let string = String(data: value, encoding: String.Encoding.utf8)
                        pointId = string
                        return true
                    }
                    return false
                }
            })
            return pointId
        }
    }
}

extension SCPasteboard {
    public func canRemainActionsDescrption(ignorePreCheck: Bool = false) -> [String]? {
        guard canHideMenuActions() || ignorePreCheck else {
            return nil
        }

        if let remainItems = pasteboardService?.remainItems() {
            return remainItems + defaultCanRemainItems
        }
        return defaultCanRemainItems
    }
    
    @available(iOS 13.0, *)
    public func hiddenItemsDescrption(ignorePreCheck: Bool = false) -> [UIMenu.Identifier]? {
        guard canHideMenuActions() || ignorePreCheck else {
            return nil
        }
        
        let hiddenItems = pasteboardService?.hiddenItems() ?? []
        let hiddenItemsIdentifier = hiddenItems.compactMap { item in
            return UIMenu.Identifier(item)
        }
        return hiddenItemsIdentifier + defaultHiddenItems
    }

    func canHideMenuActions() -> Bool {
        pasteboardService?.canHideMenuActions() ?? false
    }

    @available(iOS 13.0, *)
    private var defaultHiddenItems: [UIMenu.Identifier] {
        [
            .share,
            .learn,
            .lookup,
            .speech
        ]
    }
    
    private var defaultCanRemainItems: [String] {
        [
            "cut:",
            "select:",
            "copy:",
            "selectAll:",
            "paste:",
            "delete:",
            "TRANSLATE",
            "COMMENT",
            "SEND_TO_CHAT",
            "COPY_MULTI_BLOCK_ANCHOR",
            "ADD_LINK",
            "replace:",
            "Export",
            "FREEZE_TO_CUR_CELL",
            "CLEAR",
            "CELL_FAB",
            "ROW_FAB",
            "COL_FAB",
            "EDIT",
            "drillDown",
            "OPEN_LINK",
            "EDIT_LINK",
            "COPY_LINK",
            "CUT_LINK",
            "COMMENT_LINK",
            "DELETE_LINK",
            "INSERT_COL",
            "DELETE_COL",
            "INSERT_ROW",
            "DELETE_ROW",
            "addRecord",
            "comment",
            "PASTE_ON_LINK",
            "COPY_LINK",
            "CUT_LINK",
            "SELECT",
            "SELECT_ALL",
            "CUT",
            "COPY",
            "PASTE"
       ]
    }
}

extension DispatchQueue {
    private static var _onceTracker = [String]()

    func once(file: String = #fileID, function: String = #function, line: Int = #line, block: () -> Void) {
        let token = file + ":" + function + ":" + String(line)
        self.once(token: token, block: block)
    }

    func once(token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if DispatchQueue._onceTracker.contains(token) {
            return
        }
        DispatchQueue._onceTracker.append(token)
        block()
    }
}
