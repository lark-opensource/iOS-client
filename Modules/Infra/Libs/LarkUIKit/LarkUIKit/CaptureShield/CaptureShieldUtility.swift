//
//  CaptureShieldUtility.swift
//  SpaceInterface
//
//  Created by ByteDance on 2023/5/16.
//

import Foundation
import UIKit

public protocol CaptureShieldUtilityDelegate: AnyObject {
    func captureAllowStateWillChange(_ utility: CaptureShieldUtility, oldValue: Bool, newValue: Bool)
    func captureAllowStateDidChange(_ utility: CaptureShieldUtility, oldValue: Bool, newValue: Bool)
}

// 防截图工具，支持iOS13+
public class CaptureShieldUtility: NSObject {

    // internalView实际类型: ios15: _UITextLayoutCanvasView; ios13~14: _UITextFieldCanvasView
    // textField: internalView的父视图，用它来控制防截图
    private let preventerViewTuple: (internalView: UIView, textField: UITextField)

    // 默认允许截图
    private static let defaultCanCopy = true

    // 业务方设置的状态, 不随是否外接显示器而变化
    private var _canCopy = CaptureShieldUtility.defaultCanCopy

    public weak var delegate: CaptureShieldUtilityDelegate?

    public override init() {
        preventerViewTuple = Self.createView()
        super.init()
        self.setupNotification()
    }
}

// MARK: - Public
extension CaptureShieldUtility {

    /// 是否允许截图录屏, 默认允许
    public var isCaptureAllowed: Bool {
        !preventerViewTuple.textField.isSecureTextEntry
    }

    /// 设置是否允许截图录屏
    public func setCaptureAllowed(_ allow: Bool) {
        self._canCopy = allow
        reloadProtectState()
    }

    /// 需要防护视图的容器view
    public var contentView: UIView {
        preventerViewTuple.internalView
    }
}

// MARK: - Private
extension CaptureShieldUtility {

    private func setupNotification() {
        let notiCenter = NotificationCenter.default
        let name1 = UIScreen.didConnectNotification
        let name2 = UIScreen.didDisconnectNotification
        let name3 = UIScreen.capturedDidChangeNotification
        notiCenter.addObserver(self, selector: #selector(onConnect), name: name1, object: nil)
        notiCenter.addObserver(self, selector: #selector(onDisconnect), name: name2, object: nil)
        notiCenter.addObserver(self, selector: #selector(onCaptureChange), name: name3, object: nil)
    }

    /// 连接外接显示器
    @objc
    private func onConnect() {
        reloadProtectState()
    }

    /// 断开外接显示器
    @objc
    private func onDisconnect() {
        reloadProtectState()
    }

    /// 录制状态变化
    @objc
    private func onCaptureChange() {
        // 延迟200ms原因: 系统外接显示器时，会先触发capturedDidChangeNotification（此时判断是否外接:不准）
        // ≈100ms+之后再收到didConnectNotification，才能判断出是外接的场景。
        let selector = #selector(reloadProtectState)
        let duration: Double = 0.2
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: selector, object: nil)
        self.perform(selector, with: nil, afterDelay: duration)
    }

    @objc
    @discardableResult
    private func reloadProtectState() -> Bool {
        let newValue = shouldProtect()
        let oldValue = preventerViewTuple.textField.isSecureTextEntry
        if oldValue != newValue {
            delegate?.captureAllowStateWillChange(self, oldValue: oldValue, newValue: newValue)
            preventerViewTuple.textField.isSecureTextEntry = newValue
            delegate?.captureAllowStateDidChange(self, oldValue: oldValue, newValue: newValue)
        }
        return newValue
    }

    /// 是否不允许截取
    private func shouldProtect() -> Bool {
        if _canCopy {
            return false
        }
        let isMirrored = UIScreen.isMainScreenMirrored()
        let isCapturing: Bool // 是否在录屏
        if isMirrored { // 被镜像时, 如果开始录屏会自动触发disconnect, app其实无法得知是否真在录屏
            isCapturing = false
        } else { // 未被镜像时, 取mainScreen状态
            isCapturing = UIScreen.main.isCaptured
        }
        switch (isMirrored, isCapturing) {
        case (true, _):
            return isCapturing
        case (false, _):
            return true
        }
    }

    private static func createView() -> (internalView: UIView, textField: UITextField) {
        let field = UITextField()
        field.isSecureTextEntry = !CaptureShieldUtility.defaultCanCopy
        guard let internalView = field.subviews.first else {
            return (UIView(), UITextField())
        }
        internalView.subviews.forEach { $0.removeFromSuperview() }
        internalView.isUserInteractionEnabled = true
        return (internalView, field)
    }
}

extension UIScreen {
    // 存在非mainScreen的实例,且其mirrored属性为mainScreen,则认为mainScreen正在被镜像. 例如投屏、外接显示器
    fileprivate static func isMainScreenMirrored() -> Bool {
        let mainScreen = UIScreen.main
        for screen in UIScreen.screens where screen !== mainScreen {
            if let mirrored = screen.mirrored, mirrored === mainScreen {
                return true
            }
        }
        return false
    }
}
