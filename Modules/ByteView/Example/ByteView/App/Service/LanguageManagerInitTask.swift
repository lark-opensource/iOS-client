//
//  LanguageManagerInitTask.swift
//  Lark
//
//  Created by SolaWing on 2020/7/12.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import EEAtomic
import SSZipArchive
import LarkLocalizations
import LarkSetting
import RxSwift
import BootManager
import LarkDebugExtensionPoint
import LarkResource

#if PROFILE
import os.log

@available(iOS 12.0, *)
let log = OSLog(subsystem: "I18nManager", category: OSLog.Category.pointsOfInterest)
#endif

private let defaultLang = "en-US"
private let traditionalChineseEnableKey = "lark.i18n.traditional.chinese"
private var supportedLanguages: [Lang] {
    // swiftlint:disable force_cast
    (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }
    // swiftlint:enable force_cast
}

class I18nManager: LanguageManagerDependency {

    // 语言注入管理单例，用于压缩或者下载注入配置
    static let shared = I18nManager()

    static let root: URL = {
        var dir: URL
        if let root = try? FileManager.default
            .url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            dir = root
        } else {
            assertionFailure("should get the library directory!")
            dir = FileManager.default.temporaryDirectory
        }
        return dir.appendingPathComponent("unzip_i18n", isDirectory: true)
    }()
    var root: URL { Self.root }
    var metaInfoURL: URL { root.appendingPathComponent("meta.plist") }

    init() {
        var supportLanguages = supportedLanguages
        if !enableTraditionalChinese {
            supportLanguages.removeAll(where: { $0 == .zh_TW || $0 == .zh_HK })
        }
        LanguageManager.initialize(supportLanguages: supportLanguages,
                                   default: .en_US,
                                   dependency: self)
        NewBootManager.register(I18nLoadFGTask.self)
    }
    deinit {
        lock.deallocate()
    }

    /// when lazy unzip, may change state in multiple thread. need to protect and ensure atomic
    let lock = UnfairLockCell()
    /// this use to lock for unzip. this avoid state check be blocked
    let unzipLock = UnfairLockCell()
    var bag = DisposeBag()

    var enableTraditionalChinese = DemoCache.shared.bool(forKey: traditionalChineseEnableKey) {
        didSet {
            if oldValue != enableTraditionalChinese {
                if enableTraditionalChinese {
                    DemoCache.shared.set(true, forKey: traditionalChineseEnableKey)
                    LanguageManager.supportLanguages = supportedLanguages
                } else {
                    DemoCache.shared.removeValue(forKey: traditionalChineseEnableKey)
                    var supportLanguages = supportedLanguages
                    supportLanguages.removeAll(where: { $0 == .zh_TW || $0 == .zh_HK })
                    let current = LanguageManager.currentLanguage
                    if !supportLanguages.contains(current) {
                        supportLanguages.append(current) // 保证当前语言不会被动态改变
                    }
                    LanguageManager.supportLanguages = supportLanguages
                }
            }
        }
    }

    func checkMultipleLanguageFG() {
        enableTraditionalChinese = FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: traditionalChineseEnableKey))
    }

    /// keys in metaInfo:
    /// CFBundleShortVersionString: appVersion, use to check sandbox valid
    /// CFBundleVersion: build version. use to check sandbox valid
    /// languageIdentifier:
    ///     true: valid language
    ///     false: not support language
    ///     nil: unchecked, unknown condition
    #if DEBUG
    private var metaInfo: [String: Any] {
        get {
            lock.assertOwner()
            return _metaInfo
        }
        set {
            lock.assertOwner()
            _metaInfo = newValue
        }
    }
    private lazy var _metaInfo: [String: Any] = lazyInitMetaInfo()
    #else
    private lazy var metaInfo: [String: Any] = lazyInitMetaInfo()
    #endif

    func lazyInitMetaInfo() -> [String: Any] {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        if let data = try? Data(contentsOf: metaInfoURL),
           let info = try? PropertyListSerialization.propertyList(
            from: data, options: .mutableContainers, format: nil) as? [String: Any] {
            if appVersion == info["CFBundleShortVersionString"] as? String, buildVersion == info["CFBundleVersion"] as? String {
                return info
            } else {
                // 升级清理旧资源
                try? FileManager.default.removeItem(at: root)
                return ["CFBundleShortVersionString": appVersion, "CFBundleVersion": buildVersion]
            }
        } else {
            return ["CFBundleShortVersionString": appVersion, "CFBundleVersion": buildVersion]
        }
    }

    // MARK: LanguageManagerDependency API
    func downloadedBundle(tableName: String, moduleName: String?) -> Bundle? {
        if
            let root = downloadedRoot(tableName: tableName),
            let moduleName = moduleName,
            case let url = root.appendingPathComponent("\(moduleName).bundle", isDirectory: true),
            FileManager.default.fileExists(atPath: url.path),
            let bundle = Bundle(url: url)
        {
            return bundle
        }
        return nil
    }

    func downloadedRoot(tableName: String) -> URL? {
        // this method can call from multiple thread, need to protect state
        if lazyActivate(identifier: tableName) {
            return root.appendingPathComponent(tableName, isDirectory: true)
        }
        // 不支持的语言
        return nil
    }

    func localizedString(key: String, originalKey: String?, bundle: Bundle, moduleName: String?) -> String? {
        #if ALPHA
        if Self.enableRawKey {
            if let moduleName = moduleName, case let table = keyToRawDict(in: moduleName), let raw = table[key] {
                return raw
            }
            return key
        }
        #endif
        if let originalString = originalKey {
            var env = Env()
            env.language = LanguageManager.currentLanguage.identifier
            return ResourceManager.get(key: originalString, type: "text", env: env)
        }
        return nil
    }

    func appDisplayName(language: Lang) -> String? {
        var env = Env()
        env.language = language.identifier
        return ResourceManager.get(key: "Lark_App_Name", type: "text", env: env)
    }

    /// block in lazy load and unzip languages resources
    func activateInLock(language: Lang) {
        let identifier = language.languageIdentifier
        // 当前语言lazy获取时解压对应的资源包，并使其生效
        // 支持部分内置部分压缩，所以state可能返回false
        if languageState(identifier) != nil { return }
        _ = activate(identifier: identifier)

        if identifier.count > 2, case let backup = String(identifier.prefix(2)), languageState(backup) == nil {
            // try unzip degrade short lang for full language
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 3) {
                self.lazyActivate(identifier: backup)
            }
        }
        if identifier != defaultLang && languageState(defaultLang) == nil {
            // 英文兜底语言始终解压
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 6) {
                self.lazyActivate(identifier: defaultLang)
            }
        }
    }

    /// DEBUG显示Raw Key相关代码，所以只在ALPHA生效
    #if ALPHA
    // 这个变量的修改需要重启生效，所以是只读的。
    private static let enableRawKey = DemoCache.shared.bool(forKey: "i18n_raw_key")
    private var keyHashDict: [String: [String: String]] = [:]
    func keyToRawDict(in moduleName: String) -> [String: String] {
        return lock.withLocking {
            if let v = keyHashDict[moduleName] { return v }
            var moduleKeyInfo: [String: String] = [:]
            if
                let url = Bundle.main.url(forResource: "i18n/meta/" + moduleName, withExtension: "json"),
                let data = try? Data(contentsOf: url),
                let moduleMeta = try? JSONSerialization.jsonObject(with: data) as? NSDictionary,
                (moduleMeta["short_key"] as? Bool) == true,
                let keys = moduleMeta["keys"] as? NSDictionary
            {
                for case let (key as String, value as NSDictionary) in keys {
                    if let hash = value["hash"] as? String {
                        moduleKeyInfo[hash] = key
                    }
                }
            }

            keyHashDict[moduleName] = moduleKeyInfo
            return moduleKeyInfo
        }
    }
    #endif

    @discardableResult
    func lazyActivate(identifier: String) -> Bool {
        if let state = languageState(identifier) { return state }
        // no identifier, need to activate it
        return activate(identifier: identifier) == true
    }

    func languageState(_ identifier: String) -> Bool? {
        lock.withLocking { metaInfo[identifier] as? Bool }
    }

    /// identifier: Lang Identifier, should like en-US
    func activate(identifier: String) -> Bool? {
        // unzip cause a lot of time, should avoid lock to block ui
        // lock.assertOwner() == false
        unzipLock.lock(); defer { unzipLock.unlock() }
        // recheck after enter locking. may alread activate
        if let state = languageState(identifier) { return state }

        #if PROFILE
        if #available(iOS 12.0, *) {
            os_signpost(.begin, log: log, name: "activate", "language: %@", identifier)
        }
        defer {
            if #available(iOS 12.0, *) {
                os_signpost(.end, log: log, name: "activate")
            }
        }
        #endif

        #if DEBUG
        let beginTime = CACurrentMediaTime()
        defer {
            NSLog("[I18nManager]activateInLock consume \(CACurrentMediaTime() - beginTime)")
        }
        #endif

        if let ok = unzip(identifier: identifier) {
            lock.withLocking {
                metaInfo[identifier] = ok
                if ok { try? saveMetaInfo() }
            }
            return ok
        }
        return nil
    }

    func unzip(identifier: String) -> Bool? {
        guard let zipURL = Bundle.main.url(forResource: "i18n/" + identifier, withExtension: "zip")
        else {
            // bundle url(forResource) will check exist
            return false
        }
        // bundle是不可变的，所以解压后的资源包不应该再变动
        // 但如果以后做动态下载时，是需要更新的，需要注意bundle的全局缓存...
        let dstURL = root.appendingPathComponent(identifier, isDirectory: true)

        NSLog("[I18nManager]unzip \(identifier) to \(dstURL)")
        if SSZipArchive.unzipFile(atPath: zipURL.path, toDestination: dstURL.path) != true { return nil }
        return true
    }
    func saveMetaInfo() throws {
        NSLog("[I18nManager]save meta info to \(metaInfoURL)")
        try PropertyListSerialization.data(fromPropertyList: metaInfo, format: .binary, options: 0)
            .write(to: metaInfoURL, options: .atomic)
    }
}

// 登录空闲时再检查一下FG，防止切用户或者升级FG无变化无初始通知的情况。
class I18nLoadFGTask: FlowBootTask, Identifiable {
    static var identify = "I18nLoadFGTask"
    override func execute(_ context: BootContext) {
        I18nManager.shared.checkMultipleLanguageFG()
        #if ALPHA
        DebugRegistry.registerDebugItem(I18nRawKey(), to: .debugTool)
        #endif
    }

    #if ALPHA
    struct I18nRawKey: DebugCellItem {
        let title = "显示原始的i18nKey, 需要重启生效"
        let type: DebugCellType = .switchButton

        var isSwitchButtonOn: Bool { return DemoCache.shared.bool(forKey: "i18n_raw_key") }

        var switchValueDidChange: ((Bool) -> Void)?

        init() {
            self.switchValueDidChange = { (isOn: Bool) in
                DemoCache.shared.set(isOn, forKey: "i18n_raw_key")
            }
        }
    }
    #endif
}

class LanguageManagerInitTask: FlowBootTask, Identifiable {
    static var identify = "LanguageManagerInitTask"
    override func execute(_ context: BootContext) {
    }
}

@objc(I18nManagerPreload)
class I18nManagerPreload: NSObject {
    @objc
    static func preload() {
        // trigger LanguageManager init and dependency bind
        _ = I18nManager.shared
    }
}
