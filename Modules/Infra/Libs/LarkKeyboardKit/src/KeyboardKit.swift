//
//  KeyboardKit.swift
//  KeyboardKit
//
//  Created by 李晨 on 2019/10/17.
//

import UIKit
import Foundation
import LKCommonsLogging
import RxSwift
import RxCocoa
import RxRelay

/// KeyboardKit Core
public final class KeyboardKit {

    /// KeyboardKit instance
    public static let shared: KeyboardKit = KeyboardKit()

    private(set) var observing: Bool = false

    /// current firstResponder
    public var firstResponder: UIResponder? {
        return firstResponderRelay.value.firstResponder
    }

    /// firstResponder change signal
    public var firstResponderChange: Driver<UIResponder?> {
        return firstResponderRelay.asDriver().map({ (proxy) -> UIResponder? in
            return proxy.firstResponder
        })
    }

    /// firstResponder behavior reply
    private let firstResponderRelay = BehaviorRelay<FirstResponderProxy>(value: FirstResponderProxy())

    func update(firstResponder: UIResponder?) {
        if observing {
            self.firstResponderRelay.accept(FirstResponderProxy(firstResponder: firstResponder))
        }
    }
    /// key notification before than func `becomeFirstResponder` return
    /// use tempFirstRespnder to record temp first responder
    var tempFirstRespnder: UIResponder?

    /// keyboard type
    public var keyboardType: Keyboard.TypeEnum = .system

    /// current Keyboard info
    public var current: Keyboard? {
        return keyboardRelay.value
    }

    /// current Keyboard info
    public var currentHeight: CGFloat {
        return KeyboardKit.keyboardHeight(keyboard: self.current)
    }

    /// keyboard change signal
    public var keyboardChange: Driver<Keyboard?> {
       return keyboardRelay.asDriver()
    }

    /// keyboard height signal
    /// return real height when keyboard display type is default, other return 0
    public var keyboardHeightChange: Driver<CGFloat> {
        return keyboardRelay.asDriver().map { (keyboard) -> CGFloat in
            return KeyboardKit.keyboardHeight(keyboard: keyboard)
        }
    }

    init() {
        self.start()
    }

    /// keyboard height for view
    /// - Parameter view: UIView,  get height for this view
    public func keyboardHeightChange(for view: UIView) -> Driver<CGFloat> {
        return self.keyboardHeightChange.map { [weak view] (keyboardHeight) -> CGFloat in
            guard let view = view,
                let window = view.window else { return 0 }
            /// not support UIWindowScene
            let frame = view.convert(view.bounds, to: window)
            return max(0, frame.maxY - (KeyboardKit.appWindowHeight - keyboardHeight))
        }
    }

    /// keyboard relay
    private let keyboardRelay = BehaviorRelay<Keyboard?>(value: nil)

    /// keyboard event change signal
    public var keyboardEventChange: Observable<KeyboardEvent> {
       return keyboardEventSubject.asObservable()
    }

    /// keyboard event relay
    private let keyboardEventSubject = PublishSubject<KeyboardEvent>()

    /// dispose bag
    private var notiDisposeBag: DisposeBag = DisposeBag()

    fileprivate static let logger = Logger.log(KeyboardKit.Type.self, category: "LarkKeyboardKit.KeyboardKit")

    static var hadSwizzledResponderMethod: Bool = false

    /// start observe
    public func start() {
        if self.observing {
            return
        }
        self.observing = true
        self.notiDisposeBag = DisposeBag()
        self.addKeyboardObserver()
        self.addFirstResponderObserver()
    }

    /// stop observe
    public func stop() {
        self.observing = false
        self.notiDisposeBag = DisposeBag()
    }
}

/// private method
extension KeyboardKit {

    fileprivate func postKeyboard(event: KeyboardEvent) {
        self.keyboardType = event.keyboard.type
        self.keyboardEventSubject.onNext(event)
        self.keyboardRelay.accept(KeyboardKit.isVisible(keyboard: event.keyboard) ? event.keyboard : nil)
    }

    /// add keyboard observer
    private func addKeyboardObserver() {
        let allObserve = KeyboardEvent.TypeEnum.allCases.map(keyboardObserve)
        Observable.merge(allObserve).subscribe(onNext: { [weak self] (event) in
            guard let self = self else { return }
            self.postKeyboard(event: event)
            Self.logger.info("notification type: \(event.type) posted")
        }).disposed(by: self.notiDisposeBag)

        // iPad 退出后台截屏时可能会导致 textview resign firstResponder，此时没有 willHide didHide 通知
        // 进入前台时手动检查键盘信息是否准确
        // 当没有 firstResponder && current 有键盘 && belongsToCurrentApp 时不合理，应该手动刷新键盘信息并补充通知
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self, self.firstResponder == nil, var keyboard = self.current,
                      keyboard.belongsToCurrentApp else { return }
                keyboard.frame = .zero
                func makeEmptyEvent(_ type: KeyboardEvent.TypeEnum, keyboard: Keyboard) -> KeyboardEvent {
                    let hideFrame = keyboard.displayType == .float ? .zero :
                        CGRect(x: 0, y: UIScreen.main.bounds.height,
                               width: UIScreen.main.bounds.width, height: 0)
                    return KeyboardEvent(type: type, keyboard: keyboard,
                                  options: KeyboardOptions(
                                    belongsToCurrentApp: false,
                                    startFrame: hideFrame, endFrame: hideFrame,
                                    animationCurve: .easeInOut, animationDuration: 0
                                  ))
                }
                KeyboardKit.shared.postKeyboard(event: makeEmptyEvent(.willHide, keyboard: keyboard))
                KeyboardKit.shared.postKeyboard(event: makeEmptyEvent(.didHide, keyboard: keyboard))
                KeyboardKit.logger.info("manully add willHide & didHide notification when enter foreground")
            }).disposed(by: self.notiDisposeBag)
    }

    /// add firstResponder observer
    private func addFirstResponderObserver() {
        if !KeyboardKit.hadSwizzledResponderMethod {
            KeyboardKit.hadSwizzledResponderMethod = true
            UIResponder.kk_swizzleMethod()
        }
    }

    /// create keyboard noti observe by keyboard event type
    /// - Parameter eventType: keyboard event type
    private func keyboardObserve(eventType: KeyboardEvent.TypeEnum) -> Observable<KeyboardEvent> {
        return NotificationCenter
            .default
            .rx
            .notification(eventType.notification)
            .observeOn(MainScheduler.instance)
            .compactMap { notification -> KeyboardEvent? in
                let options = self.keyboardOptions(fromNotificationDictionary: notification.userInfo)
                if options.endFrame == .zero && options.startFrame == .zero {
                    // iPadOS 15 上，有外接键盘时拖动一下候选词条，会出现多余的 willShow 和 willChange
                    // 特征是 startFrame 和 endFrame 都为 .zero，暂时过滤掉
                    return nil
                }
                let keyboard = self.keyboard(by: options)
                return KeyboardEvent(type: eventType, keyboard: keyboard, options: options)
            }
    }

    /// keyboard options transform method
    /// - Parameter userInfo: notification userInfo
    private func keyboardOptions(fromNotificationDictionary userInfo: [AnyHashable: Any]?) -> KeyboardOptions {
        var currentApp = true
        if let value = (userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? NSNumber)?.boolValue {
            currentApp = value
        }

        var endFrame = CGRect()
        if let value = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            endFrame = value
        }

        var startFrame = CGRect()
        if let value = (userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            startFrame = value
        }

        var animationCurve = UIView.AnimationCurve.linear
        if let intValue = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue,
            let value = UIView.AnimationCurve(rawValue: intValue) {
            animationCurve = value
        }

        var animationDuration: Double = 0.0
        if let value = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue {
            animationDuration = value
        }

        return KeyboardOptions(
            belongsToCurrentApp: currentApp,
            startFrame: startFrame,
            endFrame: endFrame,
            animationCurve: animationCurve,
            animationDuration: animationDuration
        )
    }

    /// check keyboard is visible
    /// - Parameter keyboard: keyboard model
    private static func isVisible(keyboard: Keyboard) -> Bool {
        return visibleHeight(keyboard: keyboard) > 0
    }

    /// get keyboard visible height
    /// - Parameter keyboard: keyboard model
    private static func visibleHeight(keyboard: Keyboard) -> CGFloat {
        /// if keyboard is float type, when keyboard height < 100, keyboard is dismiss
        if keyboard.displayType == .float &&
            keyboard.frame.height < 100 {
            return 0
        }
        return max(self.screenTopToAppBottom - keyboard.frame.origin.y, 0)
    }

    /// get keyboard real height
    /// return real height when keyboard display type is default, other return 0
    /// - Parameter keyboard: keyboard model
    private static func keyboardHeight(keyboard: Keyboard?) -> CGFloat {
        guard let keyboard = keyboard else { return 0 }
        switch keyboard.displayType {
        case .default:
            return KeyboardKit.visibleHeight(keyboard: keyboard)
        default:
            return 0
        }
    }

    /// create keyboard model
    /// - Parameter keyboardOptions: keyboard options in noti userinfo
    private func keyboard(by keyboardOptions: KeyboardOptions) -> Keyboard {
        return Keyboard(
            type: self.keyboardType(by: keyboardOptions),
            displayType: self.keyboardDisplayType(by: keyboardOptions),
            belongsToCurrentApp: self.keyboardBelongsToCurrentApp(by: keyboardOptions),
            frame: self.keyboardFrame(by: keyboardOptions),
            inputAccessoryHeight: self.keyboardInputAccessoryHeight()
        )
    }

    /// get keyboard  type
    /// - Parameter keyboardOptions: keyboard options
    private func keyboardType(by keyboardOptions: KeyboardOptions) -> Keyboard.TypeEnum {
        let hardwareKeyboardHeight: CGFloat = 100
        let keyboardFrame = self.keyboardFrame(by: keyboardOptions)
        var keyboardHeight = keyboardFrame.height

        /// check custom keyboard type
        if let firstResponder = self.firstResponder ?? self.tempFirstRespnder,
            firstResponder.inputView != nil {
            return .customInputView
        }

        /// check first responder inputAccessoryView
        if let firstResponder = self.firstResponder ?? self.tempFirstRespnder,
            let inputAccessoryView = firstResponder.inputAccessoryView {
            keyboardHeight -= inputAccessoryView.bounds.height
        }

        if keyboardHeight <= hardwareKeyboardHeight &&
            keyboardFrame.width == UIScreen.main.bounds.width {
            return .hardware
        }
        return .system
    }

    /// get keyboard display type
    /// - Parameter keyboardOptions: keyboard options
    private func keyboardDisplayType(by keyboardOptions: KeyboardOptions) -> Keyboard.DisplayType {
        let keyboardFrame = self.keyboardFrame(by: keyboardOptions)
        if keyboardFrame == .zero { return .default }
        if keyboardFrame.width < UIScreen.main.bounds.width { return .float }
        if keyboardFrame.maxY < KeyboardKit.screenTopToAppBottom { return .splitOrUnlock }
        return .default
    }

    /// get keyboard belongsToCurrentApp
    /// - Parameter keyboardOptions: keyboard options
    private func keyboardBelongsToCurrentApp(by keyboardOptions: KeyboardOptions) -> Bool {
        keyboardOptions.belongsToCurrentApp
    }

    /// get keyboard frame
    /// - Parameter keyboardOptions: keyboard options
    private func keyboardFrame(by keyboardOptions: KeyboardOptions) -> CGRect {
        if keyboardOptions.endFrame != .zero {
            return keyboardOptions.endFrame
        }
        return keyboardOptions.startFrame
    }

    /// get keyboard input accessory view height
    private func keyboardInputAccessoryHeight() -> CGFloat {
        if let firstResponder = self.firstResponder ?? self.tempFirstRespnder,
            let inputAccessoryView = firstResponder.inputAccessoryView {
            return inputAccessoryView.bounds.height
        }
        return 0
    }

    // swiftlint:disable identifier_name
    private static var appWindowHeight: CGFloat {
        guard let _window = UIApplication.shared.delegate?.window,
            let window = _window else {
            return UIScreen.main.bounds.height
        }
        return window.bounds.height
    }

    private static var screenTopToAppBottom: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let appWindowHeight = self.appWindowHeight
        if screenHeight == appWindowHeight { return screenHeight }
        return screenHeight - 20
    }
}
