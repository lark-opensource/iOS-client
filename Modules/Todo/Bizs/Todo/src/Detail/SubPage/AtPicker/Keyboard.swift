//
//  Keyboard.swift
//  Todo
//
//  Created by 张威 on 2021/2/8.
//
//  Included OSS: Typist
//  Copyright (c) 2016 Toto Tvalavadze
//  spdx license identifier: MIT

// Ref: SKUIKit - Keyboard

public final class Keyboard {
    public static let needHideKeyBoardNotification = Notification.Name(rawValue: "com.feishu.todo.needHideKeyBoard")

    public struct KeyboardOptions {
        public let event: KeyboardEvent
        public let beginFrame: CGRect
        public let endFrame: CGRect
        public let animationCurve: UIView.AnimationCurve
        public let animationDuration: TimeInterval
        public let isShow: Bool
        public let trigger: String
    }

    public init() {}

    public typealias TypistCallback = (KeyboardOptions) -> Void
    public var trigger: String = "editor"
    public enum KeyboardEvent: String, CaseIterable {
        case willChangeFrame
        case didChangeFrame
        case willShow
        case didShow
        case willHide
        case didHide
    }
    public var options: KeyboardOptions?

    public var isShow: Bool = false
    public var isHiding: Bool = false
    public var shownHeight: CGFloat?

    public var isListening: Bool = false // 正在监听键盘事件

    // 唤起键盘的响应者
    private weak var fireKeyboardObject: AnyObject?
    // 当前关心的响应者
    private let caredResponders: NSHashTable<AnyObject> = NSHashTable(options: .weakMemory)

    private var isRelatedEvent: Bool {
        guard !caredResponders.allObjects.isEmpty, let fireObject = fireKeyboardObject else { return true }
        return caredResponders.contains(fireObject)
    }

    public init(listenTo responders: [UIResponder]? = nil, trigger: String = "editor") {
        if let relatedResponders = responders {
            relatedResponders.forEach { caredResponders.add($0) }
        }
        self.trigger = trigger
    }

    @discardableResult
    public func on(event: KeyboardEvent, do callback: TypistCallback?) -> Self {
        callbacks[event] = callback
        return self
    }

    @discardableResult
    public func on(events: [KeyboardEvent], do callback: TypistCallback?) -> Self {
        events.forEach { (event) in
            callbacks[event] = callback
        }
        return self
    }

    @discardableResult
    public func listenWillEvents(do callback: TypistCallback?) -> Self {
        let events: [KeyboardEvent] = [.willChangeFrame, .willShow, .willHide]
        events.forEach { (event) in
            callbacks[event] = callback
        }
        start()
        return self
    }

    @discardableResult
    public func listenDidEvents(do callback: TypistCallback?) -> Self {
        let events: [KeyboardEvent] = [.didChangeFrame, .didShow, .didHide]
        events.forEach { (event) in
            callbacks[event] = callback
        }
        start()
        return self
    }

    @discardableResult
    public func listenAnyEvent(do callback: TypistCallback?) -> Self {
        let events: [KeyboardEvent] = KeyboardEvent.allCases
        events.forEach { (event) in
            callbacks[event] = callback
        }
        start()
        return self
    }

    public func start() {
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

    public func stop() {
        // swiftlint:disable notification_center_detachment
        NotificationCenter.default.removeObserver(self)
        // swiftlint:enable notification_center_detachment
        isListening = false
    }

    public func clear() {
        callbacks.removeAll()
    }

    public func addReponder(_ responder: UIResponder) {
        caredResponders.add(responder)
    }

    internal var callbacks: [KeyboardEvent: TypistCallback] = [:]
    internal func keyboardOptions(
        fromNotificationDictionary userInfo: [AnyHashable: Any]?,
        event: KeyboardEvent
    ) -> KeyboardOptions {
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

        var animationDuration: TimeInterval = 0.0
        if let value = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue {
            animationDuration = value
        }

        if event == .willShow || event == .didShow {
            self.isShow = true
            shownHeight = endFrame.height
        } else if event == .willHide || event == .didHide {
            self.isShow = false
        } else {
            if endFrame.origin.y < UIScreen.main.bounds.height {
                self.isShow = true
            } else {
                self.isShow = false
            }
        }
        options = KeyboardOptions(
            event: event,
            beginFrame: beginFrame,
            endFrame: endFrame,
            animationCurve: animationCurve,
            animationDuration: animationDuration,
            isShow: self.isShow,
            trigger: self.trigger
        )
        return options!
    }

    @objc
    internal func keyboardWillShow(noti: Notification) {
        catchFireKeyboardObject()
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .willShow, noti: noti)
    }

    func scheduleCallBack(event: KeyboardEvent, noti: Notification) {
        guard let callBack = callbacks[event] else { return }
        let options = keyboardOptions(fromNotificationDictionary: noti.userInfo, event: event)

        callBack(options)
    }

    @objc
    internal func keyboardDidShow(noti: Notification) {
        catchFireKeyboardObject()
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .didShow, noti: noti)
    }

    @objc
    internal func keyboardWillHide(noti: Notification) {
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .willHide, noti: noti)
    }
    @objc
    internal func keyboardDidHide(noti: Notification) {
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .didHide, noti: noti)
    }

    @objc
    internal func keyboardWillChangeFrame(noti: Notification) {
        catchFireKeyboardObject()
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .willChangeFrame, noti: noti)
    }

    @objc
    internal func keyboardDidChangeFrame(noti: Notification) {
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .didChangeFrame, noti: noti)
    }

    func catchFireKeyboardObject() {
        fireKeyboardObject = UIResponder.todoFirstResponder()
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
            return #selector(Keyboard.keyboardWillShow(noti:))
        case .didShow:
            return #selector(Keyboard.keyboardDidShow(noti:))
        case .willHide:
            return #selector(Keyboard.keyboardWillHide(noti:))
        case .didHide:
            return #selector(Keyboard.keyboardDidHide(noti:))
        case .willChangeFrame:
            return #selector(Keyboard.keyboardWillChangeFrame(noti:))
        case .didChangeFrame:
            return #selector(Keyboard.keyboardDidChangeFrame(noti:))
        }
    }
}

private weak var todoFirstResponderObj: AnyObject?

extension UIResponder {

    public static func todoFirstResponder() -> AnyObject? {
        todoFirstResponderObj = nil
        // 通过将target设置为nil，让系统自动遍历响应链
        // 从而响应链当前第一响应者响应我们自定义的方法
        UIApplication.shared.sendAction(#selector(todoFindFirstResponder(_:)), to: nil, from: nil, for: nil)
        return todoFirstResponderObj
    }

    @objc
    func todoFindFirstResponder(_ sender: AnyObject) {
        // 第一响应者会响应这个方法，并且将静态变量currentFirstResponder设置为自己
        todoFirstResponderObj = self
    }
}
