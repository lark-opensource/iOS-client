//
//  I18nManager.swift
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
import Homeric
import LKCommonsTracker
import LKCommonsLogging
import RichLabel

#if PROFILE
import os.log

@available(iOS 12.0, *)
let log = OSLog(subsystem: "I18nManager", category: OSLog.Category.pointsOfInterest)
#endif

private let defaultLang = "en-US"
private var supportedLanguages: [Lang] {
    // swiftlint:disable force_cast
    (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }
    // swiftlint:enable force_cast
}

final class I18nManager: LanguageManagerDependency {
    // swiftlint:disable all
    // 语言注入管理单例，用于压缩或者下载注入配置
    static let shared = I18nManager()
    // swiftlint:enable all

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
    var metaInfoURL: URL { root.appendingPathComponent("meta.plist", isDirectory: false) }

    init() {
        var supportLanguages = supportedLanguages
        #if ALPHA
        supportLanguages.append(Lang.rawKey) // Raw Key placeholder code
        #endif
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

    func localizedString(key: String, originalKey: String?, bundle: Bundle, moduleName: String?, lang: Lang) -> String? {
        #if ALPHA
        if Self.enableRawKey {
            if let originalKey { return transform(key: originalKey) }
            if let moduleName = moduleName, case let table = keyToRawDict(in: moduleName), let raw = table[key] {
                return transform(key: raw)
            }
            return transform(key: key)

        }
        #endif
        if let originalString = originalKey {
            var env = Env()
            env.language = lang.identifier
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
        #if ALPHA
        DispatchQueue.main.async {
            RawKeyToastPlugin.View.shared.isAttachingWindow = language == .rawKey
        }
        #endif
    }

    /// DEBUG显示Raw Key相关代码，所以只在ALPHA生效
    #if ALPHA
    // 说明文档：https://bytedance.feishu.cn/wiki/wikcnlufqocRNWoplgdr6emyMrd#fQnE79
    private static var enableRawKey: Bool { LanguageManager.currentLanguage == .rawKey }
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
    private var transformedKeys: [String: String] = [:] // short to origin
    func transform(key: String) -> String {
        /// 使用方可能做修改，这样就还不了原了.., 所以直接展示不做修改
        return tr(key)

        // let parts = key.split(separator: "_", maxSplits: 2)
        // guard parts.count == 3 else { return tr(key) }
        // var short = tr(String(parts[2]))
        // lock.lock(); defer { lock.unlock() }
        // func store(short: String) -> Bool {
        //     guard let exist = transformedKeys[short] else {
        //         transformedKeys[short] = key
        //         return true
        //     }
        //     return exist == key
        // }
        // if store(short: short) { return short }
        // short.append(shortHash(key: key))
        // if store(short: short) { return short }
        // return tr(key) // hash后仍然冲突，不再压缩

        // help func
        func tr(_ key: String) -> String {
            return "ⓘ'\(key)'" // 使用单引号避免dateFormatter转义
        }
        // func shortHash(key: String) -> String {
        //     var str = ""
        //     let hash = key.hash
        //     let lower = hash & 0x3F
        //     let higher = (hash >> 6) & 0x3F
        //     func append(_ value: Int) {
        //         switch value {
        //         case 0...9: str.append(Character(UnicodeScalar(("0" as UnicodeScalar).value + UInt32(lower))!))
        //         case 10..<36: str.append(Character(UnicodeScalar(("A" as UnicodeScalar).value + UInt32(lower) - 10)!))
        //         case 36..<62: str.append(Character(UnicodeScalar(("a" as UnicodeScalar).value + UInt32(lower) - 36)!))
        //         case 62: str.append("=")
        //         default: break
        //         }
        //     }
        //     append(lower)
        //     append(higher)
        //     return str
        // }
    }
    func restore(key: String) -> String {
        guard key.starts(with: "ⓘ") else { return key }
        lock.lock(); defer { lock.unlock() }
        if let value = transformedKeys[key] { return value }
        return key
    }

    /// 长按显示完整的key
    enum RawKeyToastPlugin {
        class View: UIView, UIGestureRecognizerDelegate {
            static let shared = View(frame: .zero)
            let label = UILabel()
            var tap: UITapGestureRecognizer! = nil
            override init(frame: CGRect) {
                super.init(frame: frame)
                tap = UITapGestureRecognizer(target: self, action: #selector(removeFromSuperview))
                tap.numberOfTapsRequired = 1
                tap.numberOfTouchesRequired = 1
                self.addGestureRecognizer(tap)

                label.font = .systemFont(ofSize: 17)
                label.textColor = .white
                /// debug rawKey 不用修改
                // swiftlint:disable ban_linebreak_byChar
                label.lineBreakMode = .byCharWrapping
                // swiftlint:enable ban_linebreak_byChar
                label.numberOfLines = 0
                label.preferredMaxLayoutWidth = 280
                self.addSubview(label)

                self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.backgroundColor = .black.withAlphaComponent(0.6)
            }
            func show(target: UIView, text: String) {
                guard let window = target.window else { return }
                self.frame = window.bounds
                // let targetFrame = target.convert(target.bounds, to: window)
                // let text = I18nManager.shared.restore(key: text)
                label.text = text
                label.frame = self.bounds
                label.sizeToFit() // sizeToFix宽度过少... 不太明白为啥？

                debug("label size if \(label.frame.size)")
                UIPasteboard.general.string = text

                label.center = self.bounds.center
                window.addSubview(self)

                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 0
                animation.duration = 0.25
                self.layer.add(animation, forKey: "opacity")

                // TODO: Animation, UI优化
            }
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            // window attach
            struct WeakRef { weak var window: UIWindow? }
            var windows = [WeakRef]()
            public var isAttachingWindow: Bool = false { // window attach entry
                didSet {
                    if oldValue != isAttachingWindow {
                        assert(Thread.isMainThread, "should occur on main thread!")
                        if isAttachingWindow {
                            attachAllWindows()
                        } else {
                            for i in windows {
                                if let window = i.window { detach(window: window) }
                            }
                            windows = []
                        }
                    }
                }
            }

            private func attachAllWindows() {
                if #available(iOS 13.0, *) {
                    // swiftlint:disable first_connectedScenes
                    for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
                        scene.windows.forEach(self.attach(window:))
                    }
                    // swiftlint:enable first_connectedScenes
                    NotificationCenter.default.addObserver(self, selector: #selector(sceneActivate(notification:)), name: UIScene.didActivateNotification, object: nil)
                } else {
                    if case let window?? = UIApplication.shared.delegate?.window { attach(window: window) }
                }
            }
            @available(iOS 13.0, *)
            @objc
            private func sceneActivate(notification: NSNotification) {
                guard let scene = notification.object as? UIWindowScene else { return }
                scene.windows.forEach(self.attach(window:))
            }

            private func attach(window: UIWindow) {
                let key = UnsafeRawPointer(bitPattern: UInt(bitPattern: ObjectIdentifier(ShowGesture.self)))!
                if objc_getAssociatedObject(window, key) is ShowGesture { return }
                let gesture = ShowGesture(target: self, action: #selector(handle(gesture:)))
                // gesture.action = { self.handle(gesture: $0) }
                gesture.delaysTouchesBegan = true
                gesture.delegate = self
                window.addGestureRecognizer(gesture)
                objc_setAssociatedObject(window, key, gesture, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                windows.append(.init(window: window))
            }
            private func detach(window: UIWindow) {
                let key = UnsafeRawPointer(bitPattern: UInt(bitPattern: ObjectIdentifier(ShowGesture.self)))!
                guard let ges = objc_getAssociatedObject(window, key) else { return }
                if case let ges as UIGestureRecognizer = ges {
                    window.removeGestureRecognizer(ges)
                }
                objc_setAssociatedObject(window, key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                // no remove windows, can only remove all
            }
            @objc
            func handle(gesture: ShowGesture) {
                guard let (label, text) = gesture.recognizedView else { return }
                debug("show \(text) on \(label)")
                show(target: label, text: text)
            }
            func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
                if gestureRecognizer is ShowGesture {
                    return otherGestureRecognizer != self.tap // 长按弹出key的手势高优先级判断
                }
                debug("[WARN]shouldn't enter this line")
                return false
            }
        }
        class ShowGesture: UIGestureRecognizer {
            var recognizedView: (UIView, String)? // the recognizedView for gesture to start
            var startPoint: CGPoint?
            var counter: UInt8 = 0
            // var action: (ShowGesture) -> Void = { _ in }

            func failed(reason: String) {
                debug("force change raw key gesture began to failed by \(reason)")
                self.state = .failed
            }
            override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
                // View.shared.removeFromSuperview() // 有点击事件时移除对应的提示View
                super.touchesBegan(touches, with: event)
                if touches.count > 1 { return failed(reason: "multiple touch") }
                guard let touch = touches.first, let touchView = touch.view else { return failed(reason: "wrong touch") }
                /// - Parameters:
                ///   - view: testView
                ///   - point: hit point in testView
                /// - Returns: labelView with it's text
                func labelHitTest(view: UIView, point: CGPoint) -> (UIView, String)? {
                    guard
                        view.point(inside: point, with: nil),
                        view.isHidden == false || view.alpha > 0.01
                    else { return nil }

                    switch view {
                    case let v as UILabel:
                        return (v, v.text ?? "")
                    case let v as LKLabel:
                        return (v, v.text ?? "")
                    default:
                        for i in view.subviews.reversed() {
                            if let v = labelHitTest(view: i, point: i.convert(point, from: view)) {
                                return v
                            }
                        }
                    }
                    return nil
                }
                if let v = labelHitTest(view: touchView, point: touch.location(in: touchView)) {
                    debug("find recognizedView \(v)")
                    self.recognizedView = v
                    self.startPoint = touch.location(in: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [counter] in
                        guard self.counter == counter && self.state == .possible else { return }
                        self.state = .recognized
                        // self.action(self)
                        // self.state = .failed // do side effect and failed to avoid affect normal touch
                    }
                } else {
                    failed(reason: "not hit")
                }
            }
            override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
                guard let location = touches.first?.location(in: nil), let start = self.startPoint else { return }
                if abs(location.x - start.x) + abs(location.y - start.y) > 10 {
                    failed(reason: "moved")
                    return
                }
            }
            override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
                failed(reason: "ended")
            }
            override var state: UIGestureRecognizer.State {
                get { super.state }
                set {
                    debug("set ShowGesture super state to \(newValue)")
                    super.state = newValue
                }
            }

            override func reset() {
                debug("reset for ShowGesture")
                recognizedView = nil
                startPoint = nil
                counter &+= 1
                super.reset()
            }
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
final class I18nLoadFGTask: FlowBootTask, Identifiable {
    static var identify = "I18nLoadFGTask"

    private static var logger = Logger.log(I18nLoadFGTask.self)

    override func execute(_ context: BootContext) {
        trackerSwitchLang()
    }

    func trackerSwitchLang() {
        let osLanguage: String = LanguageManager.systemLanguage?.localeIdentifier ?? ""
        Tracker.post(TeaEvent(Homeric.SETTING_APP_LANGUAGE_VIEW, params: [
            "os_language": osLanguage,
            "app_language": LanguageManager.currentLanguage.localeIdentifier,
            "is_default": LanguageManager.isSelectSystem,
            "upload_type": "open"
        ]))
        DispatchQueue.global().async {
            let (sysLang, curLang, isSelectSystem) = LanguageManager.getLanguageSettings()
            let info = "language setting: init sysLanguage: \(sysLang) currentLanguage: \(curLang) isSelectSystem: \(isSelectSystem)"
            Self.logger.info(info)
        }
    }
}

final class LanguageManagerInitTask: FlowBootTask, Identifiable {
    static var identify = "LanguageManagerInitTask"
    override func execute(_ context: BootContext) {
    }
}

@objc(I18nManagerPreload)
final class I18nManagerPreload: NSObject {
    @objc
    static func preload() {
        // trigger LanguageManager init and dependency bind
        _ = I18nManager.shared
    }
}

#if ALPHA
func debug(_ msg: String) {
    // print("[I18n]" + msg)
}
#endif
