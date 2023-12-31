//
//  LanguageManager.swift
//  LarkLocalizations
//
//  Created by kkk on 2019/1/25.
//

import UIKit
import Foundation
import EEAtomic

// swiftlint:disable missing_docs
public extension Notification.Name {
    /// 当前语言变化时需要发送该通知清理i18n的缓存.
    static let preferLanguageChange: Notification.Name = Notification.Name("preferLanguageChangeNotification")
    /// 当前语言变化时需要发送该通知，在preferLanguageChange清理缓存后，让使用者可以获取新值
    static let preferLanguageDidChange: Notification.Name = Notification.Name("preferLanguageChangeDidNotification")
}

@available(*, deprecated, message: "Please use Lang instead, this class will be remove in future")
public enum Language: String, CaseIterable {
    // swiftlint:disable identifier_name
    case zh_CN
    case en_US
    case ja_JP
    case zh_HK
    case zh_TW

    // swiftlint:enable identifier_name

    public static let `default`: Language = .en_US

    @available(*, deprecated, message: "use Lang.languageIdentifier instead")
    public var tableName: String { return altTableName.replacingOccurrences(of: "_", with: "-") }
    @available(*, deprecated, message: "use Lang.localeIdentifier instead")
    public var altTableName: String { return self.rawValue }
    @available(*, deprecated, message: "use Lang.languageCode instead")
    public var prefix: String { return String(altTableName.split(separator: "_").first ?? "") }

    public var displayName: String {
        switch self {
        case .zh_CN: return "简体中文"
        case .en_US: return "English"
        case .ja_JP: return "日本語"
        #if OVERSEA
        case .zh_HK: return "繁體中文（香港）"
        case .zh_TW: return "繁體中文（台灣）"
        #else
        case .zh_HK: return "繁體中文（中国香港）"
        case .zh_TW: return "繁體中文（中国台灣）"
        #endif
        }
    }

    public init?(string: String) {
        let string = string.replacingOccurrences(of: "-", with: "_")
        if let language = Language.allCases.first(where: { $0.rawValue == string }) {
            self = language
            return
        }
        let locale = Locale(identifier: string)

        var result = [Language]()
        for type in Language.allCases {
            let matchLocale = Locale(identifier: type.rawValue)

            // 语言相同
            if matchLocale.languageCode == locale.languageCode {
                result.append(type) // 暂存

                // 地区相同
                if matchLocale.regionCode == locale.regionCode {
                    // 直接初始化
                    self = type
                    return
                }
            }
        }

        if let first = result.first {
            self = first
        } else {
            return nil
        }
    }
}

/// https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/LanguageandLocaleIDs/LanguageandLocaleIDs.html#//apple_ref/doc/uid/10000171i-CH15
/// Language use - to join part
/// Locale use lang-script_region format.., note the difference
/// canonicalIdentifier will change script _ to -, keep region _, but not convert - to _.
///     and zh_hans_cn will convert to zh_CN, hans will ignore, hant will keep
/// canonicalLanguageIdentifier will change _ to -, but zh_CN will canonical to zh-Hans (region is loss)
/// and Locale(identifier: "zh_CN") != Locale.current (zh_CN current), need to avoid the bug.
/// since Locale contains Language part, and apple provide locale struct. here choose it to store custom locale info.
/// and extension to the Locale can be use by all code.
/// NOTE: though here is alias, should use init?(rawValue:) to create the Lang type,
///     else may not equal to Locale.current
public typealias Lang = Locale

extension Lang: RawRepresentable {
    public var rawValue: String { return identifier }
    /// here is the known language, helper case constant
    // swiftlint:disable identifier_name
    public static let id_ID = Lang(rawValue: "id_ID")  // 印尼文（Bahasa）
    public static let de_DE = Lang(rawValue: "de_DE")  // 德文
    public static let en_US = Lang(rawValue: "en_US")  // 英文
    public static let es_ES = Lang(rawValue: "es_ES")  // 西班牙文
    public static let fr_FR = Lang(rawValue: "fr_FR")  // 法文
    public static let it_IT = Lang(rawValue: "it_IT")  // 意大利文
    public static let pt_BR = Lang(rawValue: "pt_BR")  // 葡萄牙文（巴西）
    public static let vi_VN = Lang(rawValue: "vi_VN")  // 越南文
    public static let ru_RU = Lang(rawValue: "ru_RU")  // 俄文
    public static let hi_IN = Lang(rawValue: "hi_IN")  // 印地文
    public static let th_TH = Lang(rawValue: "th_TH")  // 泰文
    public static let ko_KR = Lang(rawValue: "ko_KR")  // 韩文
    public static let zh_CN = Lang(rawValue: "zh_CN")  // 中文
    public static let zh_TW = Lang(rawValue: "zh_TW")  // 台湾繁体中文
    public static let zh_HK = Lang(rawValue: "zh_HK")  // 香港繁体中文
    public static let ja_JP = Lang(rawValue: "ja_JP")  // 日文
    public static let ms_MY = Lang(rawValue: "ms_MY")  // 马来西亚语
    public static let pseudo = Lang(rawValue: "rw") // pseudo language
    public static var rw: Lang { pseudo }

    public static let rawKey = Lang(rawValue: "st_JO") // key包文案

    // swiftlint:enable identifier_name
    public init(rawValue: String) {
        // ensure region concat with _
        self = Locale(identifier: rawValue.replacingOccurrences(of: "-", with: "_"))
    }
    // language display name
    // https://bytedance.feishu.cn/sheets/shtcnoFfFMWcZvqb6xyTNUvWwFc?sheet=c7e380
    public var displayName: String {
        switch self {
        case .rw: return "Pseudo Language"
        case .id_ID: return "Bahasa Indonesia"
        case .de_DE: return "Deutsch"
        case .en_US: return "English"
        case .es_ES: return "Español"
        case .fr_FR: return "Français"
        case .it_IT: return "Italiano"
        case .pt_BR: return "Português (Brasil)"
        case .vi_VN: return "Tiếng Việt "
        case .ru_RU: return "Русский"
        case .hi_IN: return "हिन्दी"
        case .th_TH: return "ภาษาไทย "
        case .ko_KR: return "한국어"
        case .zh_CN: return "简体中文"
        #if OVERSEA
        case .zh_HK: return "繁體中文 (香港)"
        case .zh_TW: return "繁體中文 (台灣)"
        #else
        case .zh_HK: return "繁體中文 (中国香港)"
        case .zh_TW: return "繁體中文 (中国台灣)"
        #endif

        case .ja_JP: return "日本語"
        case .rawKey: return "Raw Key"
        default:
            // 默认使用语言自身来描述自己的语言
            return localizedString(forLanguageCode: identifier) ?? ""
        }
    }

    /// ensure keep all part, zh_CN should convert to zh-CN, not zh-Hans
    public var languageIdentifier: String {
        /// locale identifier already canonical, so just replace _ to -
        return identifier.replacingOccurrences(of: "_", with: "-")
    }

    /// this is the locale identifier form, which concat region by _, script code still join by -. eg: zh-Hant_TW
    public var localeIdentifier: String {
        return Locale.canonicalIdentifier(from: identifier.replacingOccurrences(of: "-", with: "_"))
    }

    /// ensure the _ join region format
    public var locale: Locale {
        return Locale(identifier: identifier.replacingOccurrences(of: "-", with: "_"))
    }
}

/// Base localizations tool
open class LanguageManager {
    static let shared = LanguageManager()
    /// 全局单例，应该用static的方法进行调用，不用实例化
    private init() {}
    deinit {
        lock.deallocate()
        _bundleDisplayNameLock.deallocate()
    }
    #if DEBUG || ALPHA
    var state = AtomicUInt()
    #endif

    func initialize(supportLanguages: [Lang]?, `default`: Lang? = nil, dependency: LanguageManagerDependency?) {
        #if DEBUG || ALPHA
        if state.or(1) > 0 { assertionFailure("should initialize once and before access currentLanguage") }
        #endif
        if let dependency = dependency { self.dependency = dependency }
        self._defaultLanguage = `default`
        if let supportLanguages = supportLanguages {
            #if DEBUG || ALPHA
            if let def = `default` {
                assert(supportLanguages.contains(def), "supportedLanguage should contains default language")
            }
            #endif
            self.supportLanguages = supportLanguages
        }
    }

    // 读文件，如果user default里的appleLanguages与文件的不一样，则设置给user default
    private static let checkLanguage: Void = {
        // lint:disable lark_storage_check
        guard let filePath = backupFilePath else { return }
        guard let unarchiveData = NSData(contentsOfFile: filePath) else {
            print("language setting: not such file \(filePath)")
            return
        }
        let unarchiver = NSKeyedUnarchiver(forReadingWith: unarchiveData as Data)
        let udCurLang = UserDefaults.standard.object(forKey: LanguageManager.appleLanguages) as? [String] ?? []
        let udIsSystemSelected = UserDefaults.standard.bool(forKey: LanguageManager.systemLanguageIsSelected)

        if let storedIsSelectSystem = unarchiver.decodeObject(forKey: LanguageManager.systemLanguageIsSelected) as? Bool,
            storedIsSelectSystem != udIsSystemSelected {
            print("language setting: set systemLanguageIsSelected")
            UserDefaults.standard.set(storedIsSelectSystem, forKey: LanguageManager.systemLanguageIsSelected)
        }
        if let storedCurLang = unarchiver.decodeObject(forKey: LanguageManager.appleLanguages) as? [String],
            storedCurLang != udCurLang {
            print("language setting: set appleLanguages")
            UserDefaults.standard.set(storedCurLang, forKey: LanguageManager.appleLanguages)
        }
        // lint:enable lark_storage_check
    }()

    public static func getLanguageSettings() -> ([String], [String], Bool) {
        // lint:disable lark_storage_check
        let sysLang = CFPreferencesCopyAppValue(LanguageManager.appleLanguages as CFString,
                                                UserDefaults.globalDomain as CFString) as? [String] ?? []
        let curLang = UserDefaults.standard.object(forKey: LanguageManager.appleLanguages) as? [String] ?? []
        let isSelectSystem = UserDefaults.standard.bool(forKey: LanguageManager.systemLanguageIsSelected)
        // lint:enable lark_storage_check
        return (sysLang, curLang, isSelectSystem)
    }

    static let appleLanguages = "AppleLanguages"
    static let appleLocale = "AppleLocale"
    static let systemLanguageIsSelected = "SystemLanguageIsSelected"

    // MARK: local cached state, language related. should reset when language change
    /// 这个锁应该锁那些不耗时的通用锁。耗时在这之上额外加锁
    private let lock = UnfairLockCell()
    /// use to cache to _currentLanguage, which may query often
    private var _currentLanguage: Lang?
    private var _bundleDisplayName: String?
    private var _bundleDisplayNameLock = UnfairLockCell()
    /// should inject at init and shouldn't changed
    var dependency: LanguageManagerDependency?

    /// Application display name in the current language
    var bundleDisplayName: String {
        _bundleDisplayNameLock.lock(); defer { _bundleDisplayNameLock.unlock() }
        if let name = _bundleDisplayName { return name }
        let name = appDisplayName()
        _bundleDisplayName = name
        return name
    }

    var appleLangugeString: String? {
        _ = Self.checkLanguage // 触发执行
        // lint:disable:next lark_storage_check
        return (UserDefaults.standard.object(forKey: LanguageManager.appleLanguages) as? [String])?.first
    }

    func compatibleSupportedLanguage(_ languages: [String]) -> Lang? {
        for languageString in languages {
            let lang = Lang(rawValue: languageString)
            if let validLang = compatibleSupportedLanguage(lang) {
                return validLang
            }
        }
        return nil
    }

    /// return the compatibleSupportedLanguage, if lang in supportedLanguage, return it.
    /// else return the first language have same languageCode
    func compatibleSupportedLanguage(_ language: Lang) -> Lang? {
        let supportLanguages = self.supportLanguages
        if supportLanguages.isEmpty { return language } // no filter when not set supportLanguages
        // 按完全相等，lang + region相等(可能多script之类的修饰)，lang相等的顺序兼容降级
        if supportLanguages.contains(language) && dependency?.compatible(language: language) != false {
            return language
        }
        let compatible: [Lang] = supportLanguages.filter { $0.languageCode == language.languageCode }
        if let v = compatible.first(where: { // languageCode and regionCode equal. ignore script code
            $0.regionCode == language.regionCode && dependency?.compatible(language: $0) != false
        }) { return v }
        return compatible.first {
            dependency?.compatible(language: $0) != false
        }
    }
    /// the _defaultLanguage set by app
    private var _defaultLanguage: Lang?
    var defaultLanguage: Lang { _defaultLanguage ?? supportLanguages.first ?? .en_US }

    /// Langeage for key: "AppleLanguages"
    var appleLanguge: Lang? {
        _ = Self.checkLanguage // 触发执行
        // lint:disable:next lark_storage_check
        let languages = UserDefaults.standard.object(forKey: LanguageManager.appleLanguages) as? [String] ?? []
        return compatibleSupportedLanguage(languages)
    }

    /// Language for key: "AppleLocale"
    /// locale的值可能和AppleLanguages不一致, 比如zh-Hant-HK和zh-Hant_US
    /// 所以统一取系统的AppleLanguages
    var systemLanguage: Lang? {
        let system = CFPreferencesCopyAppValue(LanguageManager.appleLanguages as CFString, UserDefaults.globalDomain as CFString) as? [String] ?? []
        return compatibleSupportedLanguage(system)
    }

    /// Is user selected use system language
    var isSelectSystem: Bool {
        get {
            _ = Self.checkLanguage // 触发执行
            // lint:disable lark_storage_check
            if UserDefaults.standard.object(forKey: LanguageManager.systemLanguageIsSelected) != nil {
                return UserDefaults.standard.bool(forKey: LanguageManager.systemLanguageIsSelected)
            }
            if appleLanguge?.languageIdentifier == systemLanguage?.languageIdentifier {
                UserDefaults.standard.set(true, forKey: LanguageManager.systemLanguageIsSelected)
                return true
            }
            // lint:enable lark_storage_check
            return false
        }
        set {
            setCurrent(language: currentLanguage, isSystem: newValue)
        }
    }

    /// Support language settings, will ensure the return locale will be one of the values.
    /// else return the first supportLocale
    /// empty supportLanguages means no limit.
    /// default to empty, means no limit. app should set supportLanguages. eg:
    /// Bundle.main.localizations.compactMap {
    /// // exclude base.lproj. other format is en, en_US, zh-Hans, not 4 chars
    /// $0.count != 4 ? Lang(rawValue: $0) : nil
    /// }
    @AtomicObject var supportLanguages: [Lang] = [] {
        didSet {
            if !supportLanguages.isEmpty {
                if appleLanguge == nil { // appleLanguge will check supportLanguages
                    setCurrent(language: defaultLanguage, isSystem: false)
                }
            }
        }
    }

    /// The language currently set
    @available(*, deprecated, message: "Please use currentLanguage instead, this function will be remove after migrate")
    public class var current: Language {
        return Language(string: currentLanguage.languageIdentifier) ?? .default
    }

    /// The language currently set.
    /// 经常访问，需要缓存
    var currentLanguage: Lang { lock.withLocking { currentLanguageInLock } }
    private var currentLanguageInLock: Lang {
        #if DEBUG || ALPHA
        lock.assertOwner()
        _ = state.or(2)
        #endif
        if let lang = _currentLanguage { return lang }
        let lang = (isSelectSystem ? systemLanguage : appleLanguge) ?? defaultLanguage
        _currentLanguage = lang
        dependency?.activateInLock(language: lang)
        return lang
    }

    private static var backupFilePath: String? {
        // lint:disable:next lark_storage_check - 资源文件路径，无需进行统一存储检查
        guard let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return nil }
        let filePath = dirPath + "/languageSetting"
        return filePath
    }

    /// Update language setting
    /// - Parameters:
    ///   - language: New language
    ///   - isSystem: Whether to use system language
    func setCurrent(language: Lang, isSystem: Bool) {
        #if DEBUG || ALPHA
        if !supportLanguages.isEmpty {
            assert(supportLanguages.contains(language), "\(language) not in supportLanguages \(supportLanguages) ")
        }
        #endif

        do {
            lock.lock(); defer { lock.unlock() }
            // lint:disable lark_storage_check
            // 用文件存储方式记下修改结果，防止use default更新不及时
            if let filePath = LanguageManager.backupFilePath {
                let contentData = NSMutableData()
                let archiver = NSKeyedArchiver(forWritingWith: contentData)
                let isSystemOptional: Bool? = isSystem // 如果直接存为bool，解析时不存在会当作false，而不是nil
                archiver.encode(isSystemOptional, forKey: LanguageManager.systemLanguageIsSelected)
                if !isSystem {
                    archiver.encode([language.languageIdentifier], forKey: LanguageManager.appleLanguages)
                }
                archiver.finishEncoding()
                do {
                    try contentData.write(toFile: filePath)
                    print("language setting: write to file success.")
                } catch {
                    print("language setting: write to file error: \(error)")
                }
            }

            UserDefaults.standard.set(isSystem, forKey: LanguageManager.systemLanguageIsSelected)
            defer { UserDefaults.standard.synchronize() }
            if isSystem {
                UserDefaults.standard.removeObject(forKey: LanguageManager.appleLanguages)
                // 语言没变，直接退出
                if _currentLanguage == (systemLanguage ?? defaultLanguage) { return }
            } else {
                UserDefaults.standard.set([language.languageIdentifier], forKey: LanguageManager.appleLanguages)
                // 语言没变，直接退出
                if _currentLanguage == language { return }
            }
            // lint:enable lark_storage_check
            _currentLanguage = nil
        }
        resetLanguage()
    }

    /// 通知清理文案缓存
    func resetLanguage() {
        _bundleDisplayNameLock.withLocking {
            _bundleDisplayName = nil
        }
        // 下载资源包生效的回调，切换和重启时更新生效
        dependency?.languageChange()
        NotificationCenter.default.post(name: .preferLanguageChange, object: nil)
        NotificationCenter.default.post(name: .preferLanguageDidChange, object: nil)
    }

    var tableName: String { currentLanguage.languageIdentifier }

    /// - Parameters:
    ///   - bundle: 内置Bundle.
    ///   - downloadedBundle: 返回语言Table对应的下载bundle。应该包含相同的Table strings
    func localizedString(key: String, originalKey: String? = nil, bundle: Bundle, moduleName: String?, lang: Lang?) -> String? {
        /// 使用自定义TableName是因为：系统始终使用locale来读取，可能和封装的currentLanguage不一致
        /// 查找策略：
        /// 按语言降级顺序, zh-CN -> zh -> default
        /// 每个语言按顺序尝试： 下载bundle，内置Bundle
        let value = "\0"
        let dependency = self.dependency
        let lang = lang ?? currentLanguage
//        #if ALPHA
        // TODO: 传入Lang，不过现在上层用来显示raw key，没用上这个参数
        if let v = dependency?.localizedString(key: key, originalKey: originalKey, bundle: bundle, moduleName: moduleName, lang: lang) {
            return v
        }
//        #endif

        // TODO: 优化不必要的检查。比如没有dependency, 或者没有内置资源
        func localizedString(table: String) -> String? {
            var str: String
            if let down = dependency?.downloadedBundle(tableName: table, moduleName: moduleName) {
                str = NSLocalizedString(key, tableName: table, bundle: down, value: value, comment: "")
                if value != str { return str }
            }
            str = NSLocalizedString(key, tableName: table, bundle: bundle, value: value, comment: "")
            if value != str { return str }
            return nil
        }
        let table = lang.languageIdentifier
        if let v = localizedString(table: table) { return v }

        if table.count > 2 { // 先尝试无后缀兜底
            let shortTable = String(table[..<table.index(table.startIndex, offsetBy: 2)])
            if let v = localizedString(table: shortTable) { return v }
        }

        let defaultTable = defaultLanguage.languageIdentifier
        if table != defaultTable { // 再尝试用默认语言兜底
            if let v = localizedString(table: defaultTable) { return v }
        }
        return nil
    }

    /// get image by suffix languageIdentifier. eg: named_en-US
    /// NOTE: should provide default to ensure work in any language
    func localizedImage(
        named: String,
        in bundle: Bundle? = nil,
        compatibleWith: UITraitCollection? = nil,
        lang: Lang? = nil
    ) -> UIImage? {
        let current = "\(named)_\((lang ?? currentLanguage).languageIdentifier)"
        if let image = UIImage(named: current, in: bundle, compatibleWith: compatibleWith) {
            return image
        }
        // 先尝试用无后缀兜底
        if let image = UIImage(named: named, in: bundle, compatibleWith: compatibleWith) {
            return image
        }
        // last use the supported language as the default. if found it
        let base = "\(named)_\(defaultLanguage.languageIdentifier)"
        if base != current {
            return UIImage(named: base, in: bundle, compatibleWith: compatibleWith)
        }
        return nil
    }

    /// 跟据当前语言查找对应后缀的图片, 没有时返回无后缀的图片做为Default
    @available(*, deprecated, message: "Please use `localizedImage(named:in:compatibleWith:)`. NOTE the suffix changed and should rename resources") // swiftlint:disable:this all
    public static func image(named: String,
                             in bundle: Bundle? = nil,
                             compatibleWith: UITraitCollection? = nil) -> UIImage? {
        if case let lang = current.prefix,
                let image = UIImage(named: "\(named)_\(lang)", in: bundle, compatibleWith: compatibleWith) {
            return image
        }
        return UIImage(named: named, in: bundle, compatibleWith: compatibleWith)
    }

    /// Locale
    var locale: Locale {
        // 没经过lang和compatible的规范化
        if !isSelectSystem, let language = appleLangugeString, !language.isEmpty {
            return Locale(identifier: language)
        } else {
            #if os(Linux)
            return Locale.current
            #else
            return Locale.autoupdatingCurrent
            #endif
        }
    }

    // 本地化AppName
    private func appDisplayName() -> String {
        let lang = currentLanguage
        if let name = self.dependency?.appDisplayName(language: lang) {
            return name
        }
        let key = "CFBundleDisplayName"
        let resourceName: String
        switch lang {
        case .zh_CN: resourceName = "zh-Hans"
        case .zh_HK: resourceName = "zh-HK"
        case .zh_TW: resourceName = "zh-Hant-TW"
        case .rawKey: resourceName = "en"
        default: resourceName = lang.languageCode ?? ""
        }
        // NOTE: system NSLocalizedString with lproj always return same content until restart
        // so for change AppleLanguages valid instantly, need to get string customly.
        // maybe force restart after change language?
        // copy/paste menu and Locale.current also only change when restart...
        // even runtime patch won't work for menu..
        let name = NSLocalizedString(key, tableName: "\(resourceName).lproj/InfoPlist", comment: "")
        if name != key {
            return name
        } else {
            // swiftlint:disable force_cast
            return (Bundle.main.infoDictionary?[key] as? String) ?? ""
            // swiftlint:enable force_cast
        }
    }
}

// MARK: Public API
// all api is static
extension LanguageManager {
    /// 初始化设置，应该仅调用一次
    public static func initialize(
        supportLanguages: [Lang]?, `default`: Lang? = nil, dependency: LanguageManagerDependency?
    ) {
        shared.initialize(supportLanguages: supportLanguages, default: `default`, dependency: dependency)
    }

    /// Application display name in the current language
    public static var bundleDisplayName: String { shared.bundleDisplayName }

    /// return the compatibleSupportedLanguage, if lang in supportedLanguage, return it.
    /// else return the first language have same languageCode
    public static func compatibleSupportedLanguage(_ language: Lang) -> Lang? {
        shared.compatibleSupportedLanguage(language)
    }
    /// Language for key: "AppleLanguages"
    public static var appleLanguge: Lang? { shared.appleLanguge }
    /// Language for key: "AppleLocale"
    public static var systemLanguage: Lang? { shared.systemLanguage }
    /// Is user selected use system language
    public static var isSelectSystem: Bool {
        get { shared.isSelectSystem }
        set { shared.isSelectSystem = newValue } // 系统语言和当前语言一致时，可能仅切换isSelectSystem
    }

    /// Support language settings, will ensure the return locale will be one of the values.
    /// else return the first supportLocale
    /// empty supportLanguages means no limit.
    /// Support language settings, currentLanguage will be one of the values.
    /// if not contains current, will return the first supportLanguages
    /// empty supportLanguages means no limit.
    ///
    /// default to empty, means no limit. app should set supportLanguages. eg:
    ///   Bundle.main.localizations.compactMap {
    ///   // exclude base.lproj. other format is en, en_US, zh-Hans, not 4 chars
    ///   $0.count != 4 ? Lang(rawValue: $0) : nil
    ///   }
    public static var supportLanguages: [Lang] {
      get { shared.supportLanguages }
      set { shared.supportLanguages = newValue }
    }

    /// The language currently set
    public static var currentLanguage: Lang { shared.currentLanguage }

    /// Update language setting
    /// - Parameters:
    ///   - language: New language
    ///   - isSystem: Whether to use system language
    public static func setCurrent(language: Lang, isSystem: Bool) {
        shared.setCurrent(language: language, isSystem: isSystem)
    }

    /// reset dynamic language resouce cache
    public static func resetLanguage() {
        shared.resetLanguage()
    }

    /// current tableName
    public static var tableName: String { shared.tableName }
    ///
    /// - Parameters:
    ///   - key: the localized key
    ///   - bundle: the bundle need to search
    ///   - moduleName: the moduleName for this bundle. used for get from remote download package
    /// - Returns: current language string for key. with fallback strategy
    ///     return nil if not found even after fallback
    public static func localizedString(key: String, bundle: Bundle, moduleName: String? = nil) -> String? {
        shared.localizedString(key: key, originalKey: nil, bundle: bundle, moduleName: moduleName, lang: nil)
    }
    public static func localizedString(key: String, bundle: Bundle, moduleName: String? = nil, lang: Lang?) -> String? {
        shared.localizedString(key: key, originalKey: nil, bundle: bundle, moduleName: moduleName, lang: lang)
    }
    public static func localizedString(key: String, originalKey: String?, bundle: Bundle, moduleName: String? = nil, lang: Lang?) -> String? {
        shared.localizedString(key: key, originalKey: originalKey, bundle: bundle, moduleName: moduleName, lang: lang)
    }
    /// get image by suffix languageIdentifier. eg: named_en-US
    /// NOTE: should provide default to ensure work in any language
    public static func localizedImage(named: String,
                                      in bundle: Bundle? = nil,
                                      compatibleWith: UITraitCollection? = nil) -> UIImage? {
        shared.localizedImage(named: named, in: bundle, compatibleWith: compatibleWith, lang: nil)
    }
    public static func localizedImage(named: String,
                                      in bundle: Bundle? = nil,
                                      compatibleWith: UITraitCollection? = nil,
                                      lang: Lang?) -> UIImage? {
        shared.localizedImage(named: named, in: bundle, compatibleWith: compatibleWith, lang: lang)
    }
    /// locale, without compatibleSupportedLanguage normalized.
    /// most cases, you shoud use currentLanguage
    public static var locale: Locale { shared.locale }

    // MARK: 下载资源包相关方法
    public static var dependency: LanguageManagerDependency? { shared.dependency }

    /// should call this method to check package valid when downloaded and app upgrade
    public static func isDownloadedPackageCompatible(root: URL) -> Bool {
        // TODO: 检测版本兼容性
        return true
    }
    /// return the bundle for module in a downloaded package.
    /// may need to cache it for performance optimize
    public static func downloadedBundle(root: URL, moduleName: String?) -> Bundle? {
        // TODO: 这一块首次调用频繁，虽然eesc有String的缓存，但还是经常进来...
        if let moduleName = moduleName,
        case let url = root.appendingPathComponent("\(moduleName).bundle", isDirectory: true),
            FileManager.default.fileExists(atPath: url.path),
            let bundle = Bundle(url: url) {
            return bundle
        }
        return nil
    }
}

/// 需要外部注入的一些方法
public protocol LanguageManagerDependency: AnyObject {
    /// - Parameters:
    ///   - tableName: the tableName to search downloadedBundle
    ///   - moduleName: the moduleName to search downloadedBundle. nil represent global
    /// - Returns: the found bundle. or nil when not exist or compatible
    /// - See Also: LanguageManager.downloadedBundle(root:moduleName:)
    func downloadedBundle(tableName: String, moduleName: String?) -> Bundle?
    /// return the root url for the language package. if implment downloadedBundle, this imp can be ignored
    func downloadedRoot(tableName: String) -> URL?
    /// return true if the language can be used. eg: already downloaded
    func compatible(language: Lang) -> Bool
    /// notify when language changes
    func languageChange()
    /// 当前语言激活的回调。首次启动后和切换语言获取，都会调用这个方法
    /// NOTE: 注意回调在Lock中，再次调用到依赖CurrentLanguage的代码可能造成死锁
    func activateInLock(language: Lang)

    func appDisplayName(language: Lang) -> String?

    /// #if ALPHA
    /// dependency 可以拦截做特化不同的实现，例如：KA定制文案通过该拦截实现
    func localizedString(key: String, originalKey: String?, bundle: Bundle, moduleName: String?, lang: Lang) -> String?
    /// #endif
}

public extension LanguageManagerDependency {
    func downloadedBundle(tableName: String, moduleName: String?) -> Bundle? {
        if let root = downloadedRoot(tableName: tableName) {
            // 兼容性在currentLanguage就判断了。
            return LanguageManager.downloadedBundle(root: root, moduleName: moduleName)
        }
        return nil
    }
    func downloadedRoot(tableName: String) -> URL? { nil }
    func compatible(language: Lang) -> Bool { true }
    func languageChange() {}
    func activateInLock(language: Lang) {}

    func appDisplayName(language: Lang) -> String? { nil }

//    #if ALPHA
    func localizedString(key: String, originalKey: String?, bundle: Bundle, moduleName: String?, lang: Lang) -> String? {
        return nil
    }
//    #endif
}
// swiftlint:enable missing_docs
