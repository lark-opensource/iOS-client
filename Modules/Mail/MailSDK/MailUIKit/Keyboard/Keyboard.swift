//
//  Keyboard.swift
//  MailSDK
//
//  Created by majx on 2019/6/18.
//

import Foundation
import UIKit

final class Keyboard {
    struct KeyboardOptions {
        let event: KeyboardEvent
        let beginFrame: CGRect
        let endFrame: CGRect
        let animationCurve: UIView.AnimationCurve
        let animationDuration: Double
        let isShow: Bool
        let trigger: String
    }

    init() {}

    typealias TypistCallback = (KeyboardOptions) -> Void
    var trigger: String = "editor"
    enum KeyboardEvent: CaseIterable {
        case willShow
        case didShow
        case willHide
        case didHide
        case willChangeFrame
        case didChangeFrame
    }
    var options: KeyboardOptions?

    var isShow: Bool = false
    var isHiding: Bool = false

    var isListening: Bool = false // 正在监听键盘事件

    @discardableResult
    func on(event: KeyboardEvent, do callback: TypistCallback?) -> Self {
        callbacks[event] = callback
        return self
    }

    @discardableResult
    func on(events: [KeyboardEvent], do callback: TypistCallback?) -> Self {
        events.forEach { (event) in
            callbacks[event] = callback
        }
        return self
    }

    func start() {
        // 非监听情况才去监听
        // 防止多次重复监听键盘事件
        if !isListening {
            let center = NotificationCenter.`default`
            for event in callbacks.keys {
                center.addObserver(self, selector: event.selector, name: event.notification, object: nil)
            }
        }
        isListening = true
    }

    func stop() {
        let center = NotificationCenter.default
        center.removeObserver(self)
        isListening = false
    }

    func clear() {
        callbacks.removeAll()
    }

    internal var callbacks: [KeyboardEvent: TypistCallback] = [:]
    internal func keyboardOptions(fromNotificationDictionary userInfo: [AnyHashable: Any]?, event: KeyboardEvent) -> KeyboardOptions {
        var endFrame = CGRect()
        if let value = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            endFrame = value
        }

        var beginFrame = CGRect()
        if let value = (userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            beginFrame = value
        }

        var animationCurve = UIView.AnimationCurve.linear
        if let index = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue,
            let value = UIView.AnimationCurve(rawValue: index) {
            animationCurve = value
        }

        var animationDuration: Double = 0.0
        if let value = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue {
            animationDuration = value
        }

        // 这里有坑
        // iPhone XS Max 上位移动画比屏幕要小 0.0000...1
        // 所以判断不准，用向上取整来解决
        let isShow = ceil(endFrame.origin.y) < ceil(UIScreen.main.bounds.size.height)
        options = KeyboardOptions(event: event,
                                  beginFrame: beginFrame,
                                  endFrame: endFrame,
                                  animationCurve: animationCurve,
                                  animationDuration: animationDuration,
                                  isShow: isShow,
                                  trigger: self.trigger)
        return options!
    }

    @objc
    internal func keyboardWillShow(note: Notification) {
        if let callback = callbacks[.willShow] {
            callback(keyboardOptions(fromNotificationDictionary: note.userInfo, event: .willShow))
        }
    }
    @objc
    internal func keyboardDidShow(note: Notification) {
        if let callback = callbacks[.didShow] {
            callback(keyboardOptions(fromNotificationDictionary: note.userInfo, event: .didShow))
        }
    }

    @objc
    internal func keyboardWillHide(note: Notification) {
        if let callback = callbacks[.willHide] {
            callback(keyboardOptions(fromNotificationDictionary: note.userInfo, event: .willHide))
        }
    }
    @objc
    internal func keyboardDidHide(note: Notification) {
        if let callback = callbacks[.didHide] {
            callback(keyboardOptions(fromNotificationDictionary: note.userInfo, event: .didHide))
        }
    }

    @objc
    internal func keyboardWillChangeFrame(note: Notification) {
        if let callback = callbacks[.willChangeFrame] {
            callback(keyboardOptions(fromNotificationDictionary: note.userInfo, event: .willChangeFrame))
        }
    }
    @objc
    internal func keyboardDidChangeFrame(note: Notification) {
        if let callback = callbacks[.didChangeFrame] {
            callback(keyboardOptions(fromNotificationDictionary: note.userInfo, event: .didChangeFrame))
        }
    }
}

fileprivate extension Keyboard.KeyboardEvent {
    var notification: NSNotification.Name {
        switch self {
        case .willShow:
            return UIResponder.keyboardWillShowNotification
        case .didShow:
            return UIResponder.keyboardDidShowNotification
        case .willHide:
            return UIResponder.keyboardWillHideNotification
        case .didHide:
            return UIResponder.keyboardDidHideNotification
        case .willChangeFrame:
            return UIResponder.keyboardWillChangeFrameNotification
        case .didChangeFrame:
            return UIResponder.keyboardDidChangeFrameNotification
        }
    }

    var selector: Selector {
        switch self {
        case .willShow:
            return #selector(Keyboard.keyboardWillShow(note:))
        case .didShow:
            return #selector(Keyboard.keyboardDidShow(note:))
        case .willHide:
            return #selector(Keyboard.keyboardWillHide(note:))
        case .didHide:
            return #selector(Keyboard.keyboardDidHide(note:))
        case .willChangeFrame:
            return #selector(Keyboard.keyboardWillChangeFrame(note:))
        case .didChangeFrame:
            return #selector(Keyboard.keyboardDidChangeFrame(note:))
        }
    }
}

// MARK: - KeyboardObservingView
protocol KeyboardObservingViewDelegate: AnyObject {
    func keyboardFrameChanged(frame: CGRect)
}

class KeyboardObservingView: UIView {
    weak var delegate: KeyboardObservingViewDelegate?
    private var observation: NSKeyValueObservation?

    private var kvoContext: UInt8 = 1

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startObserving() {
        observation = self.superview?.observe(\.center, options: [.new, .initial]) { [weak self] (_, change) in
            if let newFrame = self?.superview?.frame {
                self?.delegate?.keyboardFrameChanged(frame: newFrame)
            }
        }
    }

    private func stopObserving() {
        observation?.invalidate()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            stopObserving()
        } else {
            startObserving()
        }
    }
}
