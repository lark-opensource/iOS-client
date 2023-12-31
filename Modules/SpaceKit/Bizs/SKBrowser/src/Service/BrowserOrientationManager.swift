//
//  BrowserOrientationManager.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/9/9.
//  

import SKFoundation
import CoreMotion
import SKCommon
import SKUIKit
import LarkSensitivityControl

// EditorManager 会持有一个 BrowserOrientationManager，
// Manager 管理对应的 Director，在 EditorManager 监听到 BrowserVC 生命周期时，修改 Director
// Manager 负责方向全局的监听，将方向和传感器变化告知 Director，再通过它分发给 Browser
class BrowserOrientationManager {
    public static let motionDidChangeOrientationNotification = Notification.Name(rawValue: "\(Notification.Name.Docs.nameSpace).motionDidChangeOrientationNotification")
    /// 设备的实际方向。考虑了关闭自动旋转但设备已经倾斜的情况。
    private(set) var deviceOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
    
    //仅用于docX转屏埋点
    public var docXReportSource: DocXReportSource = .auto

    private let cmManager: CMMotionManager = {
        let cm = CMMotionManager()
        cm.deviceMotionUpdateInterval = 1
        return cm
    }()

    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private var isRunning: Bool {
        return cmManager.isDeviceMotionActive
    }

    private var directors = [BrowserOrientationDirector]()

    func addEditor(_ orientationDelegate: BrowserOrientationDelegate) {
        if directors.contains(where: { $0.browser === orientationDelegate }) {
            //避免重复添加OrientationDirector
            DocsLogger.info("BrowserOrientationDirector(\(ObjectIdentifier(orientationDelegate)) is exist")
            return
        }
        _addObserver()
        let director = BrowserOrientationDirector(orientationDelegate, manager: self)
        orientationDelegate.orientationDirector = director
        directors.append(director)
    }

    func removeEditor(_  orientationDelegate: BrowserOrientationDelegate) {
        directors.removeAll { $0.browser === orientationDelegate || $0.browser == nil }
        if directors.count == 0 {
            operationQueue.addOperation { [weak self] in
                self?._removeObserver()
            }
        }
    }

    func resetLastBrowserNeedSetPortraitWhenDismiss() {
        if directors.count - 2 >= 0 {
            directors[directors.count - 2].needSetPortraitWhenDismiss = true
        }
    }

    // MARK: - Observer
    private func _addObserver() {
        if isRunning {
            return
        }
        _addObserverForNotification()
        _addObserverForMotion()
    }

    private func _addObserverForNotification() {
        // Keyboard
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow(note:)),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidHide(note:)),
                                               name: UIResponder.keyboardDidHideNotification,
                                               object: nil)
        // StatusBar
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationWillChange(_:)),
                                               name: UIApplication.willChangeStatusBarOrientationNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationDidChange(_:)),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }

    private func _addObserverForMotion() {
        // 监听传感器状态
        if let deviceMotion = cmManager.deviceMotion {
            deviceOrientation = _getCurrentOrientation(deviceMotion.gravity)
        }
        operationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            self._internalStartMonitor()
        }
    }
    
    private func _internalStartMonitor() {
        
        do {
            // 敏感api管控 https://bytedance.feishu.cn/wiki/wikcn0fkA8nvpAIjjz4VXE6GC4f
            // BOE和正式环境下该token一致
            let tokenString = "LARK-PSDA-browserView_gravity_monitor"
            let token = Token(tokenString, type: .deviceInfo)
            
            try DeviceInfoEntry.startDeviceMotionUpdates(forToken: token, manager: cmManager, to: operationQueue) { [weak self] (motions, _) in
                guard let motion = motions else {
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    self?.gravityDidChanged(motion.gravity)
                }
            }
        } catch {
            DocsLogger.error("[LarkSensitivityControl] DeviceInfoEntry.startDeviceMotionUpdates rejected. error: \(error.localizedDescription)")
        }
    }
    
    // swiftlint:disable notification_center_detachment
    private func _removeObserver() {
        NotificationCenter.default.removeObserver(self)
        cmManager.stopDeviceMotionUpdates()
    }
    
    @objc
    private func statusBarOrientationWillChange(_ notification: Notification) {
        guard let int = notification.userInfo?[UIApplication.statusBarOrientationUserInfoKey] as? Int,
            let newOrientation = UIInterfaceOrientation(rawValue: int) else {
                return
        }
        notifyDirectorStatusBarOrientationWillChange(from: deviceOrientation, to: newOrientation)
        deviceOrientation = newOrientation
    }

    @objc
    private func statusBarOrientationDidChange(_ notification: Notification) {
        guard let int = notification.userInfo?[UIApplication.statusBarOrientationUserInfoKey] as? Int,
            let oldOrientation = UIInterfaceOrientation(rawValue: int) else {
                return
        }
        notifyDirectorStatusBarOrientationDidChange(from: oldOrientation, to: deviceOrientation)
    }

    // 传感器发生变化时的处理
    private func gravityDidChanged(_ gravity: CMAcceleration) {
        let currentOrientation = _getCurrentOrientation(gravity)
        motionSensorUpdatesOrientation(to: currentOrientation)
        if currentOrientation != deviceOrientation {
            deviceOrientation = currentOrientation
            NotificationCenter.default.post(name: Notification.Name.motionDidChangeOrientationNotification, object: deviceOrientation)
        }
        if currentOrientation.isLandscape == UIApplication.shared.statusBarOrientation.isLandscape {
            browserHideForceOrientationTip()
        } else {
            browserShowForceOrientationTip(currentOrientation)
        }
    }

    private func _getCurrentOrientation(_ gravity: CMAcceleration) -> UIInterfaceOrientation {
        let threshold: Double = 0.6
        let gravityX = gravity.x
        let gravityY = gravity.y
        var currentOrientation = deviceOrientation
        if gravityX <= -threshold && abs(gravityY) < 1 - threshold {
            currentOrientation = .landscapeRight
        }
        if gravityX >= threshold && abs(gravityY) < 1 - threshold {
            currentOrientation = .landscapeLeft
        }
        if gravityY <= -threshold && abs(gravityX) < 1 - threshold {
            currentOrientation = .portrait
        }
        if gravityY >= threshold && abs(gravityX) < 1 - threshold {
            currentOrientation = .portraitUpsideDown
        }
        return currentOrientation
    }
    
    public enum DocXReportSource: String {
        case auto
        case force
    }
}

// MARK: - Observer 分发 (Manager -> Director)
extension BrowserOrientationManager {
    func notifyDirectorStatusBarOrientationWillChange(from oldOrientation: UIInterfaceOrientation, to newOrientation: UIInterfaceOrientation) {
        directors.forEach { $0.statusBarOrientationWillChange(from: oldOrientation, to: newOrientation) }
    }
    func notifyDirectorStatusBarOrientationDidChange(from oldOrientation: UIInterfaceOrientation, to newOrientation: UIInterfaceOrientation) {
        directors.forEach { $0.statusBarOrientationDidChange(from: oldOrientation, to: newOrientation) }
    }
    func motionSensorUpdatesOrientation(to orientation: UIInterfaceOrientation) {
        directors.forEach { $0.motionSensorUpdatesOrientation(to: orientation) }
    }
    func browserShowForceOrientationTip(_ orientation: UIInterfaceOrientation) {
        directors.forEach { $0.browserShowForceOrientationTip(orientation) }
    }
    func browserHideForceOrientationTip() {
        directors.forEach { $0.browserHideForceOrientationTip() }
    }
    @objc
    private func keyboardDidShow(note: Notification) {
        directors.forEach { $0.keyboardDidShow(note: note) }
    }
    @objc
    private func keyboardDidHide(note: Notification) {
        directors.forEach { $0.keyboardDidHide(note: note) }
    }
}

// MARK: - 工具方法
//extension BrowserOrientationManager {
//    private func convertOrientation(_ deviceOrientation: UIDeviceOrientation) -> UIInterfaceOrientation {
//        switch deviceOrientation {
//        case .unknown:
//            return .unknown
//        case .portrait:
//            return .portrait
//        case .portraitUpsideDown:
//            return .portraitUpsideDown
//        case .landscapeLeft:
//            return .landscapeLeft
//        case .landscapeRight:
//            return .landscapeRight
//        case .faceUp:
//            return .portrait
//        case .faceDown:
//            return .portraitUpsideDown
//        default:
//            return .unknown
//        }
//    }
//}


//==============================================================================================================//
//                                              我是一条神奇的分割线                                               //
//==============================================================================================================//


protocol BrowserOrientationObserver: AnyObject {
    func statusBarWillChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation)
    func statusBarDidChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation)
    func motionSensorUpdatesOrientation(to: UIInterfaceOrientation)
    func showForceOrientationTip(_: UIInterfaceOrientation) -> Bool
    func hideForceOrientationTip()
}

typealias BrowserOrientationDelegate = BrowserOrientationObserver & BrowserViewController

// 一个 BrowserVC 会有一个 Director，
// 和 BrowserVC 生命周期相同，负责管理其横竖屏切换和跳转时上下文管理
public final class BrowserOrientationDirector {

    // 用来读取 BrowserView 的一些信息。
    weak var browser: BrowserOrientationDelegate?
    weak var editor: BrowserView?
    weak var topContainer: BrowserTopContainer?
    weak var manager: BrowserOrientationManager?
    /// 运行时动态决定是否需要支持横竖屏，优先级 P1
    public var dynamicOrientationMask: UIInterfaceOrientationMask?
    /// 在编辑时决定转屏按钮是否显示
    public var needShowTipWhenEditing: Bool = false
    public var needSetPortraitWhenDismiss = true
    
    var needSetLandscapeWhenAppear = false
    var isKeyboardShow: Bool = false
    private var innerManager: BrowserOrientationManager {
        return manager ?? BrowserOrientationManager()
    }
    var deviceOrientation: UIInterfaceOrientation {
        return innerManager.deviceOrientation
    }

    init(_ browser: BrowserOrientationDelegate, manager: BrowserOrientationManager) {
        self.browser = browser
        self.editor = browser.browerEditor
        self.topContainer = browser.topContainer
        self.manager = manager
        noticeWhenInit()
    }

    private func noticeWhenInit() {
        let isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        let isPhone = SKDisplay.phone
        let isTypeCanChangeOrientation = editor?.docsInfo?.type.changeOrientationsEnable ?? false
        noticeJS(didChangeTo: UIApplication.shared.statusBarOrientation)
        if isLandscape, isPhone, isTypeCanChangeOrientation {
            browser?.updatePhoneUI(for: deviceOrientation)
        }
    }

    // MARK: - Public functions
    var supportedInterfaceOrientations: UIInterfaceOrientationMask? {
        if let dynamicMask = dynamicOrientationMask {
            return dynamicMask
        }
        if SKDisplay.pad {
            return nil
        }
        if editor?.docsInfo?.inherentType.alwaysOrientationsEnable ?? true {
            return [.portrait, .landscape]
        }
        // VC 接受 nil 后应该调用 super 的 supportedInterfaceOrientations. 取决于父 VC 的决策
        return nil
    }

    /// 强制横竖屏
    public func forceSetOrientation(_ orientation: UIInterfaceOrientation, action: SheetReportAction? = nil, source: SheetReportSource? = nil) {
        if SKDisplay.pad {
            return
        }
        manager?.docXReportSource = .force
        LKDeviceOrientation.setOritation(LKDeviceOrientation.convertMaskOrientationToDevice(orientation))
        // 通知前端
        noticeJS(didChangeTo: orientation)
        if let action = action, let source = source {
            reportSheetData(with: orientation, action: action, source: source)
        }
    }

    public func setLandscapeIfNeed() {
        if deviceOrientation.isLandscape {
            forceSetOrientation(deviceOrientation)
        }
    }

    private func noticeJS(didChangeTo orientation: UIInterfaceOrientation) {
        let oriStr = orientation.isLandscape ? "landscape" : "portrait"
        editor?.jsEngine.callFunction(DocsJSCallBack(rawValue: "window.lark.biz.orientation.onSwitch"), params: ["type": oriStr], completion: nil)
    }

    private func getSheetViewType(resultHandler: @escaping (String?) -> Void) {
        editor?.jsEngine.callFunction(DocsJSCallBack.getViewType, params: [:], completion: { type, error in
            guard error == nil else {
                DocsLogger.info("getViewType 失败，js 报错 \(String(describing: error))")
                resultHandler(nil)
                return
            }
            guard let viewType = type as? String else {
                DocsLogger.info("getViewType 返回的类型是 \(String(describing: type))")
                resultHandler(nil)
                return
            }
            resultHandler(viewType)
        })
    }

    // MARK: - 埋点
    /// 埋点用的 Source
    public enum SheetReportSource: String {
        case mobileRotation = "mobile_rotation"
        case sheetTabExitLandscapeButton = "exit_landscape_btn"
        case forceLandscapeTip = "sheet_m_landscape_button"
        case forcePortraitTip = "sheet_m_portrait_button"
        case showLandscapeButton = "show_landscape_button"
        case showPortraitButton = "show_portrait_button"
        case body = "body"
    }
    public enum SheetReportAction: String {
        case enterLandscape = "enter_landscape"
        case exitLandscape = "exit_landscape"
        case showPortraitTip = "show_portrait_btn"
        case showLandscapeTip = "show_landscape_btn"
        case landscapeNoEdit = "landscape_no_edit"
    }
    
    private func reportDocxData(with orientation: UIInterfaceOrientation) {
        guard SKDisplay.phone,
              let docsInfo = editor?.docsInfo,
              docsInfo.inherentType.supportLandscapeShow,
              let commonParam = browser?.commonTrackParams else {
            return
        }
        if manager?.docXReportSource == .auto {
            let isVerion: String = editor?.docsInfo?.isVersion ?? false ? "true" : "false"
            var param: [String: Any] = ["click": "system_automatic", "target": "none", "is_version": isVerion]
            param.merge(other: commonParam)
            if orientation.isLandscape {
                DocsTracker.newLog(enumEvent: .docXSwitchHorizontalClick, parameters: param)
            } else {
                DocsTracker.newLog(enumEvent: .docXSwitchVerticalClick, parameters: param)
            }
        } else {
            manager?.docXReportSource = .auto
        }
    }

    private func reportSheetData(with orientation: UIInterfaceOrientation, action: SheetReportAction, source: SheetReportSource) {
        guard let type = editor?.docsInfo?.inherentType, type == .sheet || type == .bitable else {
            return
        }
        // 事情埋点
        var params: [String: String] = [:]
        params["file_id"] = editor?.docsInfo?.encryptedObjToken ?? ""
        params["file_type"] = editor?.docsInfo?.type.name ?? "sheet"
        params["mode"] = "default"
        params["module"] = editor?.docsInfo?.type.name ?? "sheet"
        params["attr_op_status"] = "effective"
        params["orientation"] = orientation.isLandscape ? "landscape" : "portrait"
        params["action"] = action.rawValue
        params["source"] = source.rawValue
        getSheetViewType { (viewType) -> Void in
            if let viewType = viewType {
                params["is_record_card_open"] = "0"
                params["bitable_view_type"] = viewType
                params["file_type"] = "bitable"
            }
            DocsTracker.log(enumEvent: .sheetOperation, parameters: params)
        }
    }

    func statusBarOrientationWillChange(from oldOrientation: UIInterfaceOrientation, to newOrientation: UIInterfaceOrientation) {
        if #available(iOS 13, *) {
            UIMenuController.shared.hideMenu()
        } else {
            UIMenuController.shared.setMenuVisible(false, animated: false)
        }
        reportDocxData(with: newOrientation)
        browser?.updatePhoneUI(for: newOrientation)
        browser?.statusBarWillChangeOrientation(from: oldOrientation, to: newOrientation)
    }

    func statusBarOrientationDidChange(from oldOrientation: UIInterfaceOrientation, to newOrientation: UIInterfaceOrientation) {
        browser?.statusBarDidChangeOrientation(from: oldOrientation, to: newOrientation)
        noticeJS(didChangeTo: newOrientation)
    }

    func motionSensorUpdatesOrientation(to orientation: UIInterfaceOrientation) {
        browser?.motionSensorUpdatesOrientation(to: orientation)
    }

    func browserShowForceOrientationTip(_ orientation: UIInterfaceOrientation) {
        // 用 UIInterfaceOrientation 创建 UIInterfaceOrientationMask 很麻烦，用字面量最准确直观
        var orientationMask = UIInterfaceOrientationMask()
        switch orientation {
        case .portrait: orientationMask = [.portrait]
        case .landscapeLeft: orientationMask = [.landscapeLeft]
        case .landscapeRight: orientationMask = [.landscapeRight]
        default: orientationMask = [.portraitUpsideDown]
        }
        if SKDisplay.phone,
           !(browser?.isFromTemplatePreview ?? false),
            let webLoader = editor?.docsLoader as? WebLoader, webLoader.loadStatus.isSuccess == true,
           (supportedInterfaceOrientations?.contains(orientationMask) == true || needShowTipWhenEditing) {
            if browser?.showForceOrientationTip(orientation) == true {
                let action = orientation.isLandscape ? SheetReportAction.showLandscapeTip : SheetReportAction.showPortraitTip
                let source = orientation.isLandscape ? SheetReportSource.showLandscapeButton : SheetReportSource.showPortraitButton
                reportSheetData(with: orientation, action: action, source: source)
            }
        }
    }

    func browserHideForceOrientationTip() {
        browser?.hideForceOrientationTip()
    }

    func keyboardDidShow(note: Notification) {
        if let inputAccessoryViewHeight = editor?.editorView.skEditorViewInputAccessory.realInputAccessoryView?.frame.height,
            let rect = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            if inputAccessoryViewHeight == rect.height {
                return
            }
        }
        isKeyboardShow = true
    }

    func keyboardDidHide(note: Notification) {
        isKeyboardShow = false
    }
}
