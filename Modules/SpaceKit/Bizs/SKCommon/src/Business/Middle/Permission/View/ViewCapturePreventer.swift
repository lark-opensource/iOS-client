//
//  ViewCapturePreventer.swift
//  SKUIKit
//
//  Created by chensi(陈思) on 2022/3/29.
//  


import UIKit
import SKUIKit
import Foundation
import SKFoundation
import SKResource
import UniverseDesignToast
import SKInfra

public struct ViewCaptureNotifyContainer: OptionSet {
    
    public static let superView = ViewCaptureNotifyContainer(rawValue: 1 << 0)
    public static let window = ViewCaptureNotifyContainer(rawValue: 1 << 1)
    public static let controller = ViewCaptureNotifyContainer(rawValue: 1 << 2)
    public static let thisView = ViewCaptureNotifyContainer(rawValue: 1 << 3)
    
    public static var windowOrVC: ViewCaptureNotifyContainer {
        [.window, .controller]
    }
    
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public protocol ViewCapturePreventable: AnyObject {
    
    /// 是否允许截图和录屏，默认false
    var isCaptureAllowed: Bool { get set }
    
    /// 需要防护的视图的容器view
    var contentView: UIView { get }
    
    /// toast容器
    var notifyContainer: ViewCaptureNotifyContainer { get set }
    
    /// 埋点参数获取
    func setAnalyticsFileInfoGetter(block: @escaping () -> (fileId: String?, fileType: String?))
    
    /// 重置为默认状态（默认不允许截图），且不触发toast
    func reset()
    
    /// 重置为默认状态（默认不允许截图），有toast，目前只在doc-vc viewDidLoad 时触发，用于离线场景无权限回调但需要toast"无法录屏"
    func resetIfNetUnreachableWhenDocsViewDidLoad()
}

/// 视图截图&录屏防护器
public final class ViewCapturePreventer: NSObject {
    
    public var notifyContainer = ViewCaptureNotifyContainer()
    
    // 备注：internalView上面有时候会出现一个_UITextLayoutFragmentView的子视图, frame是{0,1,0,1}，不可见，不确定有什么影响，暂不处理
    
    /// internalView实际类型:
    ///     ios15: _UITextLayoutCanvasView
    ///     ios14, ios13: _UITextFieldCanvasView
    /// associatedTextField: internalView的父视图，用它来控制防截图
    private let preventerViewTuple: (internalView: UIView, associatedTextField: UITextField)?
    private lazy var placeholderView = UIView()
    
    /// 是否允许复制视图内容，原始值，不随是否外接显示器变化
    private var originalCanCopy = true
    
    private let notifier = Notifier()
    
    private var analyticsFileInfoGetter: (() -> (fileId: String?, fileType: String?))? // 埋点
    private let tracker = Tracker()
    
    public init(FGService: (() -> Bool)? = nil, settingService: (() -> Bool)? = nil) {
        
        let FG = Self.defaultFGBlock
        let setting = Self.defaultServiceBlock
        
        preventerViewTuple = Self.createCapturePreventView(FGService: FGService ?? FG,
                                                           settingService: settingService ?? setting)
        super.init()
        
        let notiCenter = NotificationCenter.default
        let name1 = UIScreen.didConnectNotification
        let name2 = UIScreen.didDisconnectNotification
        let name3 = UIScreen.capturedDidChangeNotification
        notiCenter.addObserver(self, selector: #selector(onConnect), name: name1, object: nil)
        notiCenter.addObserver(self, selector: #selector(onDisconnect), name: name2, object: nil)
        notiCenter.addObserver(self, selector: #selector(onCaptureChange), name: name3, object: nil)
        
        notifier.dataSource = self
        notifier.onToastShown = { [weak self] in
            guard let infoGetter = self?.analyticsFileInfoGetter else { return }
            let analyticsInfo = infoGetter()
            let extra = self?.analyticsExtraParam ?? [:]
            guard let fileType = analyticsInfo.fileType, !fileType.isEmpty else {
                DocsLogger.info("capture-prevent toast is shown BUT fileType is null, extra:\(extra)")
                return
            }
            self?.tracker.reportToast(DocsTracker.EventType.toastView,
                                      fileId: analyticsInfo.fileId, fileType: fileType,
                                      extra: extra)
        }
    }
    
    private var analyticsExtraParam: [String: Any] {
        let name: String
        if let vc = preventerViewTuple?.internalView.affiliatedViewController {
            name = "\(type(of: vc))"
        } else {
            name = "unknown"
        }
        return ["sceneName": name]
    }
}

extension ViewCapturePreventer: ViewCapturePreventable {
    
    public var isCaptureAllowed: Bool {
        get {
            if let tuple = preventerViewTuple {
                return tuple.associatedTextField.isSecureTextEntry == false
            }
            return true // 允许截图(无防护)
        }
        set {
            originalCanCopy = newValue // 先保存:原始值
            let oldValue = isCaptureAllowed
            reloadProtectState() // 再设置:逻辑转换后的值
            notifier.handleCaptureAllowedStateChange(oldValue: oldValue, newValue: newValue)
        }
    }
    
    public var contentView: UIView {
        preventerViewTuple?.internalView ?? placeholderView
    }
    
    public func setAnalyticsFileInfoGetter(block: @escaping () -> (fileId: String?, fileType: String?)) {
        analyticsFileInfoGetter = block
    }
    
    public func reset() {
        DocsLogger.info("reset captureAllow => false")
        notifier.removeToastIfExists() // 清理上次的toast(可能存在)
        originalCanCopy = Self.canCopyDefaultValue
        reloadProtectState()
    }
    
    public func resetIfNetUnreachableWhenDocsViewDidLoad() {
        if !(DocsNetStateMonitor.shared.isReachable) {
            self.isCaptureAllowed = false
        }
    }
}

extension ViewCapturePreventer {
    
    /// 功能是否可用
    public static var isFeatureEnable: Bool {
        return defaultFGBlock() && defaultServiceBlock()
    }
    
    private static func defaultFGBlock() -> Bool {
        return LKFeatureGating.screenCapturePreventEnable
    }
    
    private static func defaultServiceBlock() -> Bool {
        var isSupportVersion = false
        if #available(iOS 13, *) { // 已知 >=13 都支持
            isSupportVersion = true
        }
        if let blacklist = SettingConfig.viewCapturePreventingConfig?.ios_version_blacklist {
            let isInBlacklist = blacklist.contains(where: {
                UIDevice.current.systemVersion.hasPrefix($0) && !$0.isEmpty
            })
            if isInBlacklist {
                isSupportVersion = false
            }
        }
        return isSupportVersion
    }
}

private extension ViewCapturePreventer {
    
    static func createCapturePreventView(FGService: () -> Bool, settingService: () -> Bool) -> (UIView, UITextField)? {
        
        let field = UITextField()
        field.isSecureTextEntry = !Self.canCopyDefaultValue
        
        guard FGService() else {
            DocsLogger.error("FG `screenCapturePreventEnable` is FALSE",
                             component: LogComponents.permission)
            return nil
        }
        
        guard settingService() else {
            let version = UIDevice.current.systemVersion
            DocsLogger.error("system not support CapturePrevent, version:\(version)",
                             component: LogComponents.permission)
            return nil
        }
        
        guard let internalView = field.subviews.first else {
            DocsLogger.error("can not get CapturePreventView",
                             component: LogComponents.permission)
            return nil
        }
        
        internalView.subviews.forEach { $0.removeFromSuperview() }
        internalView.isUserInteractionEnabled = true
        return (internalView, field)
    }
    
    /// 连接外接显示器
    @objc
    func onConnect() {
        DocsLogger.info("screen did connect:\(UIScreen.screens)")
        reloadProtectState()
    }
    
    /// 断开外接显示器
    @objc
    func onDisconnect() {
        DocsLogger.info("screen did disconnect:\(UIScreen.screens)")
        reloadProtectState()
    }
    
    /// 录制状态变化
    @objc
    func onCaptureChange() {
        DocsLogger.info("screen trigger capture-state change")
        // 延迟200ms原因: 系统外接显示器时，会先触发capturedDidChangeNotification（此时判断是否外接:不准）
        // ≈100ms之后再收到didConnectNotification，才能判断出是外接的场景。
        // 这么改的副作用是，开始录制产生的“无复制权限,无法录屏”的toast会晚200ms出现，但是体感不明显
        let selector = #selector(_handleCaptureStateChange)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: selector, object: nil)
        self.perform(selector, with: nil, afterDelay: 0.2)
    }
    
    @objc
    func _handleCaptureStateChange() {
        DocsLogger.info("handle capture-state change")
        let isProtected = reloadProtectState()
        let allowRecord = (isProtected == false)
        notifier.handleRecordChange(isStartRecord: UIScreen.main.isCaptured, allowRecord: allowRecord)
    }
    
    @discardableResult
    func reloadProtectState() -> Bool {
        let value = shouldProtect()
        preventerViewTuple?.associatedTextField.isSecureTextEntry = value
        return value
    }
    
    /// 是否要保护内容(不允许截取)
    func shouldProtect() -> Bool {
        let isMirrored = UIScreen.isMainScreenMirrored()
        let isCapturing: Bool
        if isMirrored { // 被镜像时, 如果开始录屏会自动触发disconnect, app其实无法得知是否真在录屏
            isCapturing = false
        } else { // 未被镜像时, 取mainScreen状态
            isCapturing = UIScreen.main.isCaptured
        }
        DocsLogger.info("canCopy:\(originalCanCopy), isMirrored:\(isMirrored), isCapturing:\(isCapturing)")
        switch (originalCanCopy, isMirrored, isCapturing) {
        case (true, _, _):
            return false
        case (false, true, true): // 不可复制 有外接 在录屏
            return true
        case (false, true, false): // 不可复制 有外接 不在录屏
            return false
        case (false, false, _): // 不可复制 无外接
            return true
        }
    }
}

extension UIScreen {
    // 存在非mainScreen的实例,且其mirrored属性为mainScreen,则认为mainScreen正在被镜像. 例如投屏、外接显示器
    class func isMainScreenMirrored() -> Bool {
        let mainScreen = UIScreen.main
        for screen in UIScreen.screens where screen !== mainScreen {
            
            if let mirrored = screen.mirrored, mirrored === mainScreen {
                return true
            }
        }
        return false
    }
}

extension ViewCapturePreventer: BrowserViewLifeCycleEvent {
    
    public func browserWillLoad() {
        notifier.didShowToastDuringSession = false
    }
    
    public func browserDidUpdateDocsInfo() {
        notifier.didShowToastDuringSession = false
    }
}

extension ViewCapturePreventer {
    /// 是否允许截屏录制的全局默认值，默认不允许
    public static var canCopyDefaultValue: Bool { false }
}

extension ViewCapturePreventer {
    
    /// 负责埋点
    private class Tracker {
        
        @discardableResult
        func reportToast(_ event: DocsTracker.EventType?, fileId: String?, fileType: String?, extra: [String: Any] = [:]) -> [String: Any] {
            var params: [String: Any] = [:]
            params["file_id"] = fileId ?? ""
            params["file_type"] = fileType ?? ""
            params["sub_view"] = "docs_forbid_screenshot"
            params["extra"] = "\(extra)" // 如有多个字段，注意排序
            if let event = event {
                DocsTracker.newLog(enumEvent: event, parameters: params)
            }
            return params
        }
    }
}

// MARK: 单元测试

extension ViewCapturePreventer {
    
    func reportToast(fileId: String?, fileType: String?) -> [String: Any] {
        tracker.reportToast(nil, fileId: fileId, fileType: fileType)
    }
    
    func setShowToastCallback(_ callback: @escaping (() -> Void)) {
        notifier.onToastShown = callback
    }
    
    func getAssociatedTextField() -> UITextField? {
        preventerViewTuple?.associatedTextField
    }
    
    func triggerSnapshot() {
        notifier.handleSnapshot()
    }

    // Debug 调试
    // userInfo: ("isAllow": Bool)
    static var debugAllowStateDidChange: NSNotification.Name {
        NSNotification.Name("com.docs.viewcapturepreventer.debugallowstate.didchange")
    }
}
