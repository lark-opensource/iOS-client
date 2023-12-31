//
//  OPComponentKeyboardHelper.swift
//  TTMicroApp
//
//  Created by zhujingcheng on 6/12/23.
//

import Foundation
import LarkKeyboardKit
import RxSwift
import LarkUIKit
import LKCommonsLogging
import LarkSceneManager

@objc public protocol OPComponentKeyboardDelegate: AnyObject {
    // 当前view光标所在高度的相对UIWindow的frame
    @objc optional func owningViewFrame() -> CGRect
    // 上推容器的frame
    @objc optional func adjustViewFrame() -> CGRect
    // 上推容器所在坐标系
    @objc optional func adjustViewCoordinateSpace() -> UICoordinateSpace?
    
    func isOwningViewFirstResponder() -> Bool
    
    func keyboardWillShow(keyboardInfo: OPComponentKeyboardInfo)
    func keyboardWillHide(keyboardInfo: OPComponentKeyboardInfo)
    @objc optional func keyboardWillChangeFrame(keyboardInfo: OPComponentKeyboardInfo)
    @objc optional func keyboardDidChangeFrame(keyboardInfo: OPComponentKeyboardInfo)
    @objc optional func keyboardHeightDidChange(height: CGFloat)
}

@objc
public final class OPComponentKeyboardInfo: NSObject {
    @objc
    public lazy var animDuration: Double = {
        options?.animationDuration ?? 0.25
    }()
    
    @objc
    public lazy var animOption: UIView.AnimationOptions = {
        options?.animationOptions ?? .curveEaseInOut
    }()
    
    public var displayType: Keyboard.DisplayType {
        keyboard?.displayType ?? .`default`
    }
    
    @objc
    public let adjustFrame: CGRect
    @objc
    public let keyboardFrame: CGRect
    
    private let options: KeyboardOptions?
    public let keyboard: Keyboard?
    
    init(keyboardFrame: CGRect, options: KeyboardOptions?, adjustFrame: CGRect?, keyboard: Keyboard?) {
        self.keyboardFrame = keyboardFrame
        self.options = options
        self.adjustFrame = adjustFrame ?? .zero
        self.keyboard = keyboard
        super.init()
    }
}


@objc
public final class OPComponentKeyboardHelper: NSObject {
    private static let logger = Logger.oplog(OPComponentKeyboardHelper.self)
    
    @objc public weak var delegate: OPComponentKeyboardDelegate?
    @objc public var componentID = ""
    
    private var hadOwningViewBecomeFirstResponder: Bool = false
    
    private var originAdjustViewOriginY: CGFloat = .zero
    private var hasAdjustViewOriginYChanged: Bool = false
    private var originAdjustViewHeight: CGFloat = .zero
    private var hasAdjustViewHeightChanged: Bool = false
    
    private var disposeBag = DisposeBag()
    
    public override init() {
        super.init()
        self.setup()
    }
    
    @objc
    public convenience init(delegate: OPComponentKeyboardDelegate) {
        self.init()
        self.delegate = delegate
    }
    
    @objc
    public func isHardwareKeyboard() -> Bool {
        KeyboardKit.shared.keyboardType == .hardware
    }
    
    @objc
    public func isFloatOrSplitKeyboard() -> Bool {
        guard let displayType = KeyboardKit.shared.current?.displayType else {
            return false
        }
        return displayType == .float || displayType == .splitOrUnlock
    }
    
    @objc
    public func isKeyboardShowing() -> Bool {
        KeyboardKit.shared.current != nil
    }
    
    @objc
    public func getKeyboardHeight() -> CGFloat {
        if isSplitKeyboard() {
            return 0
        }
        if isHardwareKeyboard() || isFloatOrSplitKeyboard() {
            return KeyboardKit.shared.current?.inputAccessoryHeight ?? 0
        }
        return KeyboardKit.shared.currentHeight
    }
    
    @objc
    public func getAdjustFrame() -> CGRect {
        let keyboardFrameToWindow = Self.getKeyboardFrameToWindow()
        return getAdjustFrameForKeyboardShow(keyboardFrame: keyboardFrameToWindow)
    }
    
    @objc
    public func keyboardWillShow() {
        let keyboardFrame = Self.getKeyboardFrameToWindow()
        keyboardWillShow(keyboardFrame: keyboardFrame, keyboard: nil, options: nil)
    }
    
    @objc
    public func keyboardWillHide() {
        let keyboardFrame = Self.getKeyboardFrameToWindow()
        keyboardWillHide(keyboardFrame: keyboardFrame, keyboard: nil, options: nil)
    }
    
    private func setup() {
        KeyboardKit.shared.keyboardEventChange.subscribe(onNext: { [weak self] event in
            guard let self = self else {
                return
            }
            var keyboardFrame = event.options.endFrame
            if let window = Self.currentWindow {
                keyboardFrame = Self.convertFrameToWindow(fromSpace: window.screen.coordinateSpace, frame: event.options.endFrame)
            }
            switch event.type {
            case .willShow:
                self.keyboardWillShow(keyboardFrame: keyboardFrame, keyboard: event.keyboard, options: event.options)
            case .willHide:
                self.keyboardWillHide(keyboardFrame: keyboardFrame, keyboard: event.keyboard, options: event.options)
            case .willChangeFrame:
                let info = OPComponentKeyboardInfo(keyboardFrame: keyboardFrame, options: event.options, adjustFrame: nil, keyboard: event.keyboard)
                self.delegate?.keyboardWillChangeFrame?(keyboardInfo: info)
            case .didChangeFrame:
                let info = OPComponentKeyboardInfo(keyboardFrame: keyboardFrame, options: event.options, adjustFrame: nil, keyboard: event.keyboard)
                self.delegate?.keyboardDidChangeFrame?(keyboardInfo: info)
            default: break
            }
        }).disposed(by: disposeBag)
        
        KeyboardKit.shared.keyboardHeightChange.distinctUntilChanged().drive { [weak self] height in
            guard let self = self, let isFirstResponder = self.delegate?.isOwningViewFirstResponder(), isFirstResponder else {
                return
            }
            self.delegate?.keyboardHeightDidChange?(height: height)
        }.disposed(by: disposeBag)
    }
    
    private func isSplitKeyboard() -> Bool {
        guard let displayType = KeyboardKit.shared.current?.displayType else {
            return false
        }
        return displayType == .splitOrUnlock
    }
    
    private func getAdjustFrameForKeyboardShow(keyboardFrame: CGRect) -> CGRect {
        guard let owningViewFrame = delegate?.owningViewFrame?() else {
            return .zero
        }
        guard let adjustViewFrame = delegate?.adjustViewFrame?() else {
            return .zero
        }
        if isFloatOrSplitKeyboard() || owningViewFrame.maxY.isInfinite || keyboardFrame.height <= 0 {
            Self.logger.info("\(componentID) keyboard show NO frame adjust")
            return adjustViewFrame
        }
        
        var outofWindowHeight = 0.0
        if let window = Self.currentWindow {
            // 去除不在当前window可视范围内的部分
            let offset = owningViewFrame.maxY - window.frame.maxY
            outofWindowHeight = offset > 0 ? offset : 0
        }
        let offsetY = owningViewFrame.maxY - keyboardFrame.minY - outofWindowHeight
        var result = adjustViewFrame
        if !hasAdjustViewOriginYChanged {
            originAdjustViewOriginY = adjustViewFrame.origin.y
            hasAdjustViewOriginYChanged = true
            Self.logger.info("\(componentID) keyboard save originY \(originAdjustViewOriginY) \(hasAdjustViewOriginYChanged)")
        }
        result = adjustViewFrame.offsetBy(dx: 0, dy: -offsetY)
        // 确保页面不会下推
        result.origin.y = min(result.origin.y, originAdjustViewOriginY)
        
        var adjustFrameToWindow = result
        if let fromCoordinateSpace = delegate?.adjustViewCoordinateSpace?() {
            adjustFrameToWindow = Self.convertFrameToWindow(fromSpace: fromCoordinateSpace, frame: result)
        }
        let addHeight = keyboardFrame.minY - adjustFrameToWindow.maxY - outofWindowHeight
        if (addHeight > 0) {
            if !hasAdjustViewHeightChanged {
                originAdjustViewHeight = adjustViewFrame.height
                hasAdjustViewHeightChanged = true
            }
            result.size.height += addHeight
        }
        return result
    }
    
    private func isRedundantNotify() -> Bool {
        guard let adjustViewFrame = delegate?.adjustViewFrame?() else {
            return false
        }
        return hasAdjustViewOriginYChanged && adjustViewFrame.origin.y != originAdjustViewOriginY
    }
    
    private func keyboardWillShow(keyboardFrame: CGRect, keyboard: Keyboard?, options: KeyboardOptions?) {
        guard let isFirstResponder = delegate?.isOwningViewFirstResponder(), isFirstResponder else {
            Self.logger.info("\(componentID) keyboard show not first responder")
            return
        }
        hadOwningViewBecomeFirstResponder = true
        if isRedundantNotify() {
            Self.logger.info("\(componentID) is redundant keyboard show notify")
            return
        }
        let adjustFrame = getAdjustFrameForKeyboardShow(keyboardFrame: keyboardFrame)
        let info = OPComponentKeyboardInfo(keyboardFrame: keyboardFrame, options: options, adjustFrame: adjustFrame, keyboard: keyboard)
        delegate?.keyboardWillShow(keyboardInfo: info)
        Self.logger.info("\(componentID) keyboard show keyboardFrame: \(keyboardFrame), adjustFrame: \(adjustFrame)")
    }
    
    private func keyboardWillHide(keyboardFrame: CGRect, keyboard: Keyboard?, options: KeyboardOptions?) {
        if !hadOwningViewBecomeFirstResponder {
            Self.logger.info("\(componentID) keyboard hide return for not first responder")
            if let keyboard, keyboard.type == .hardware {
                // 物理键盘时，允许多次willHide触发
            } else {
                return
            }
        }
        hadOwningViewBecomeFirstResponder = false
        let adjustFrame = getAdjustFrameForKeyboardHide()
        let info = OPComponentKeyboardInfo(keyboardFrame: keyboardFrame, options: options, adjustFrame: adjustFrame, keyboard: keyboard)
        delegate?.keyboardWillHide(keyboardInfo: info)
        Self.logger.info("\(componentID) keyboard hide adjustFrame: \(adjustFrame)")
    }
    
    private func getAdjustFrameForKeyboardHide() -> CGRect {
        guard let adjustViewFrame = delegate?.adjustViewFrame?() else {
            return .zero
        }
        
        var result = adjustViewFrame
        Self.logger.info("\(componentID) keyboard hide originYChanged \(hasAdjustViewOriginYChanged), originY \(originAdjustViewOriginY)")
        if (hasAdjustViewOriginYChanged) {
            result.origin.y = originAdjustViewOriginY
        }
        if (hasAdjustViewHeightChanged) {
            result.size.height = originAdjustViewHeight
        }
        hasAdjustViewOriginYChanged = false
        originAdjustViewOriginY = 0
        hasAdjustViewHeightChanged = false
        originAdjustViewHeight = 0
        return result
    }
    
    private static func getKeyboardFrameToWindow() -> CGRect {
        guard let keyboard = KeyboardKit.shared.current else {
            return .zero
        }
        var keyboardFrameToWindow = keyboard.frame
        if let window = Self.currentWindow {
            keyboardFrameToWindow = Self.convertFrameToWindow(fromSpace: window.screen.coordinateSpace, frame: keyboard.frame)
        }
        return keyboardFrameToWindow
    }
    
    private static func convertFrameToWindow(fromSpace: UICoordinateSpace, frame: CGRect) -> CGRect {
        var result = frame
        if let window = Self.currentWindow {
            result = fromSpace.convert(frame, to: window)
        }
        return result
    }
    
    public static var currentWindow: UIWindow? {
        if #available(iOS 15.0, *) {
            let scene = SceneManager.shared.windowApplicationScenes.first {
                return $0.activationState == .foregroundActive
            }
            if let windowScene = scene as? UIWindowScene {
                return windowScene.windows.first(where: \.isKeyWindow)
            }
            return nil
        } else if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first(where: { $0.windowScene?.activationState == .foregroundActive })
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        }
    }
    
}
