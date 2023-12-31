//
//  Keyboard.swift
//  Pods
//
//  Created by weidong fu on 3/1/2018.
//
// 改动记录: https://bytedance.feishu.cn/docs/doccnrAX6sa7dyIDTmnmsOcKF2b#

import UIKit
import LarkUIKit

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
    enum KeyboardEvent: String, CaseIterable {
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

    // 唤起键盘的响应者
    private weak var fireKeyboardObject: AnyObject?
    // 当前关心的响应者
    private let caredResponders: NSHashTable<AnyObject> = NSHashTable(options: .weakMemory)

    private var isReleatedEvent: Bool {
        return true
    }
    private var identifier = ""

    init(listenTo responders: [UIResponder]? = nil, identifier: String = "") {
        if let releatedResponders = responders {
            releatedResponders.forEach { caredResponders.add($0) }
        }
        self.identifier = identifier
    }

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
            let center = NotificationCenter.default
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

    var callbacks: [KeyboardEvent: TypistCallback] = [:]
    func keyboardOptions(fromNotificationDictionary userInfo: [AnyHashable: Any]?, event: KeyboardEvent) -> KeyboardOptions {
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
        options = KeyboardOptions(
            event: event,
            beginFrame: beginFrame,
            endFrame: endFrame,
            animationCurve: animationCurve,
            animationDuration: animationDuration,
            isShow: isShow,
            trigger: self.trigger
        )
        return options!
    }

    @objc
    func keyboardWillShow(note: Notification) {
        scheduleCallBack(event: .willShow, note: note)
    }

    func scheduleCallBack(event: KeyboardEvent, note: Notification) {
        guard let callBack = callbacks[event] else { return }
        let options = keyboardOptions(fromNotificationDictionary: note.userInfo, event: event)

        callBack(options)
    }

    @objc
    func keyboardDidShow(note: Notification) {
        scheduleCallBack(event: .didShow, note: note)
    }

    @objc
    func keyboardWillHide(note: Notification) {
        scheduleCallBack(event: .willHide, note: note)
    }
    @objc
    func keyboardDidHide(note: Notification) {
        scheduleCallBack(event: .didHide, note: note)
    }

    @objc
    func keyboardWillChangeFrame(note: Notification) {
        scheduleCallBack(event: .willChangeFrame, note: note)
    }

    @objc
    func keyboardDidChangeFrame(note: Notification) {
        scheduleCallBack(event: .didChangeFrame, note: note)
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
