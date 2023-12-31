//
//  Keyboard.swift
//  Pods
//
//  Created by weidong fu on 3/1/2018.
//
// 改动记录: https://bytedance.feishu.cn/docs/doccnrAX6sa7dyIDTmnmsOcKF2b#
// swiftlint:disable line_length

import UIKit
import SKFoundation
import LarkUIKit
import EENavigator

public final class Keyboard {
    public static let needHideKeyBoardNotification: Notification.Name = Notification.Name(rawValue: "com.feishu.docs.didHideKeyBoard")
    
    public static weak var keyboardWindow: UIWindow? {
        var keyBoardWindowStr = "VUlSZW1vdGVLZXlib2FyZFdpbmRvdw==".fromBase64() ?? "" //UIRemoteKeyboardWindow
        var window = UIApplication.shared.windows.first(where: { String(describing: type(of: $0)).hasPrefix(keyBoardWindowStr) })
        if #available(iOS 16.0, *), window == nil {
            keyBoardWindowStr = "VUlUZXh0RWZmZWN0c1dpbmRvdw==".fromBase64() ?? "" //UITextEffectsWindow
            //magicShare下浮动固定键盘切换时会出现一个多余的keyboardWindow，其windowLevel比真正的window小
            window = UIApplication.shared.windows.last(where: { String(describing: type(of: $0)).hasPrefix(keyBoardWindowStr) })
        }
        //当前键盘window
        return window
     }
     
     public static weak var keyboardHostView: UIView? {
         let keyBoardContainerViewStr = "VUlJbnB1dFNldENvbnRhaW5lclZpZXc=".fromBase64() ?? "" //UIInputSetContainerView
         let keyBoardHostViewStr = "VUlJbnB1dFNldEhvc3RWaWV3".fromBase64() ?? "" //UIInputSetHostView
         let keyBoardContainerView = Self.keyboardWindow?.subviews.first(where: { String(describing: type(of: $0)).hasPrefix(keyBoardContainerViewStr) })
         return keyBoardContainerView?.subviews.first(where: { String(describing: type(of: $0)).hasPrefix(keyBoardHostViewStr) })
     }

    public struct KeyboardOptions: CustomStringConvertible {
        public let event: KeyboardEvent
        public let beginFrame: CGRect
        public let endFrame: CGRect
        public let hostViewFrame: CGRect
        public let animationCurve: UIView.AnimationCurve
        public let animationDuration: Double
        public let isShow: Bool
        public let trigger: String
        public let displayType: DisplayType
        ///iPadOS 16台前调度会返回键盘在app window上的minY值，其他情况下和beginFrame相等
        public let beginFrameInWindow: CGRect
        public let endFrameInWindow: CGRect
        
        public var description: String {
            return "event=\(event),show=\(isShow),begin=\(beginFrame),end=\(endFrame),hostFrame=\(hostViewFrame),endInWin:\(endFrameInWindow) trigger=\(trigger), display=\(displayType)"
        }
    }

    public init() {}

    public typealias TypistCallback = (KeyboardOptions) -> Void
    public var trigger: String = "editor"
    public enum KeyboardEvent: String, CaseIterable {
        case willChangeFrame
        case willShow
        case didChangeFrame
        case didShow
        case willHide
        case didHide
        case didChangeInputMode
    }
    public enum DisplayType {
        case `default`
        case floating //ipad悬浮键盘
    }
    
    public var options: KeyboardOptions?

    public var isShow: Bool = false
    public var isHiding: Bool = false
    public var displayType: DisplayType = .default

    public var isListening: Bool = false // 正在监听键盘事件

    //唤起键盘的响应者
    private weak var fireKeyboardObject: AnyObject?
    //当前关心的响应者
    private let caredResponders: NSHashTable<AnyObject> = NSHashTable(options: .weakMemory)
    
    private let minFloatingKeyboardSize = CGSize(width: 200, height: 200)
    private let maxFloatingKeyboardSize = CGSize(width: 400, height: 400)

    private var isRelatedEvent: Bool {
        guard caredResponders.count > 0, let fireObject = fireKeyboardObject else { return true }
        for item in caredResponders.allObjects {
            if item === fireObject {
                return true
            } else if let itemView = item as? UIView, let fireResponderView = fireObject as? UIView {
                if itemView.docsListenToToSubViewResponder == true, fireResponderView.isDescendant(of: itemView) {
                    return true
                }
                if fireResponderView.docsListenToSuperViewResponder == true, itemView.isDescendant(of: fireResponderView) {
                    return true
                }
            }
        }
        return false
    }

    private var throttle = SKThrottle(interval: 1.0)

//    private var identifier = ""

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

//    @discardableResult
//    public func listenDidEvents(do callback: TypistCallback?) -> Self {
//        let events: [KeyboardEvent] = [.didChangeFrame, .didShow, .didHide]
//        events.forEach { (event) in
//            callbacks[event] = callback
//        }
//        start()
//        return self
//    }

//    @discardableResult
//    public func listenAnyEvent(do callback: TypistCallback?) -> Self {
//        let events: [KeyboardEvent] = KeyboardEvent.allCases
//        events.forEach { (event) in
//            callbacks[event] = callback
//        }
//        start()
//        return self
//    }

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
        let center = NotificationCenter.default
        center.removeObserver(self)
        isListening = false
    }

    public func clear() {
        callbacks.removeAll()
    }

    public func addReponder(_ responder: UIResponder) {
        caredResponders.add(responder)
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
        
        self.displayType = calculateDisplayType(beginFrame, endFrame)

        self.isShow = calculateShowState(event, beginFrame, endFrame)
        let hostViewFrame = Keyboard.keyboardHostView?.frame ?? endFrame
        
        let beginFrameInWindow = keyboardFrameInWindow(from: beginFrame)
        let endFrameInWindow = keyboardFrameInWindow(from: endFrame)
        options = KeyboardOptions(event: event,
                                  beginFrame: beginFrame,
                                  endFrame: endFrame,
                                  hostViewFrame: hostViewFrame,
                                  animationCurve: animationCurve,
                                  animationDuration: animationDuration,
                                  isShow: self.isShow,
                                  trigger: self.trigger,
                                  displayType: self.displayType,
                                  beginFrameInWindow: beginFrameInWindow,
                                  endFrameInWindow: endFrameInWindow)
        return options!
    }
    
    private func keyboardFrameInWindow(from frame: CGRect) -> CGRect {
        guard let window = SKDisplay.activeWindow else { return frame }
        // iOS16上window高度小于屏幕高度，认为处于台前调度或浮窗状态
        // 这个时候系统通知keyboardFrame的y值有问题，需要调整
        // 补充的高度 = app window相对整个屏幕的高度偏移
        if SKDisplay.pad,
           #available(iOS 16.0, *),
           SKDisplay.activeWindowBounds.height < SKDisplay.mainScreenBounds.height {
            var fixedFrame = frame
            let zeroPointInScreen = window.convert(CGPoint.zero, to: UIScreen.main.coordinateSpace)
            fixedFrame.origin.y -= zeroPointInScreen.y
            return fixedFrame
        }
        return frame
    }
    
    private func calculateDisplayType(_ beginFrame: CGRect, _ endFrame: CGRect) -> DisplayType {
        
        let keyboardFrame = endFrame != .zero ? endFrame : beginFrame
        let activeWindowSize = SKDisplay.activeWindowBounds.size
        
        if keyboardFrame.size == .zero { return self.displayType }
        
        var keyboardDisplayType: DisplayType = self.displayType
        
        if SKDisplay.pad {
            // >100屏蔽键盘状态为妙控键盘的最小化的情况
            // max是用来适配偶现系统发送的键盘事件frame里height和widht颠倒，width里传过来的反而是height值
            // https://bytedance.feishu.cn/wiki/ViT1wtOIwir8CCkUg1McwYY7nCc
            if keyboardFrame.width > 100, max(keyboardFrame.width, keyboardFrame.height) < activeWindowSize.width {
                keyboardDisplayType = .floating
            } else if SKDisplay.activeWindowBounds.size.width < UIScreen.main.bounds.size.width,
                      keyboardFrame.size > minFloatingKeyboardSize,
                      maxFloatingKeyboardSize > keyboardFrame.size,
                      keyboardFrame.width > activeWindowSize.width {
                //iPad分屏下activeWindow宽度可能小于浮动键盘的宽度
                //https://meego.feishu.cn/larksuite/issue/detail/7471366
                keyboardDisplayType = .floating
            } else {
                keyboardDisplayType = .default
            }
        } else {
            keyboardDisplayType = .default
        }
        
        return keyboardDisplayType
    }
    
    private func calculateShowState(_ event: KeyboardEvent, _ beginFrame: CGRect, _ endFrame: CGRect) -> Bool {
        let keyboardFrame = endFrame != .zero ? endFrame : beginFrame
        var showState: Bool = self.isShow
        if displayType == .floating {
            if event == .willChangeFrame || event == .didChangeFrame {
                if endFrame != .zero {
                    showState = true
                } else {
                    showState = false
                }
            } else if event == .willShow || event == .didShow {
                DocsLogger.info("unexpected float keyboard event: show, frame: \(keyboardFrame)")
            } else {
                if beginFrame != .zero {
                    DocsLogger.info("unexpected float keyboard event: hide, frame: \(keyboardFrame)")
                }
            }
        } else {
            if event == .willShow || event == .didShow {
                 showState = true
            } else if event == .willHide || event == .didHide {
                showState = false
            } else {
                if endFrame.origin.y < UIScreen.main.bounds.height {
                    showState = true
                } else {
                    showState = false
                }
            }
        }
        return showState
    }

    @objc
    internal func keyboardWillShow(note: Notification) {
        catchFireKeyboardObject()
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .willShow, note: note)
    }

    func scheduleCallBack(event: KeyboardEvent, note: Notification) {
        guard let callBack = callbacks[event] else { return }
        let options = keyboardOptions(fromNotificationDictionary: note.userInfo, event: event)
        /*
        let jobId = "\(event.rawValue)_\(options.endFrame.y)_\(options.endFrame.height))"
        throttle.schedule({
            callBack(options)
        }, jobId: jobId)
        */
        callBack(options)
    }

    @objc
    internal func keyboardDidShow(note: Notification) {
        catchFireKeyboardObject()
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .didShow, note: note)
    }

    @objc
    internal func keyboardWillHide(note: Notification) {
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .willHide, note: note)
    }
    @objc
    internal func keyboardDidHide(note: Notification) {
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .didHide, note: note)
    }

    @objc
    internal func keyboardWillChangeFrame(note: Notification) {
        catchFireKeyboardObject()
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .willChangeFrame, note: note)
    }

    @objc
    internal func keyboardDidChangeFrame(note: Notification) {
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .didChangeFrame, note: note)
    }
    
    @objc
    internal func keyboardDidChangeInputMode(note: Notification) {
        guard isRelatedEvent else { return }
        scheduleCallBack(event: .didChangeInputMode, note: note)
    }

    func catchFireKeyboardObject() {
        fireKeyboardObject = UIResponder.docsFirstResponder()
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
        case .didChangeInputMode:
            return UITextInputMode.currentInputModeDidChangeNotification
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
        case .didChangeInputMode:
            return #selector(Keyboard.keyboardDidChangeInputMode(note:))
        }
    }
}

public extension UIResponder {
    private static var docsListenToToSubViewResponderKey: UInt8 = 0
    // 某个subview是FirstResponder, 自己添加的键盘监听能响应。
    var docsListenToToSubViewResponder: Bool? {
        get {
            let value = objc_getAssociatedObject(self, &Self.docsListenToToSubViewResponderKey) as? Bool
            return value
        }
        set {
            objc_setAssociatedObject(self, &Self.docsListenToToSubViewResponderKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    private static var docsListenToSuperViewResponderKey: UInt8 = 0
    // 自己是FirstResponder, subview添加的键盘监听能响应。
    var docsListenToSuperViewResponder: Bool? {
        get {
            let value = objc_getAssociatedObject(self, &Self.docsListenToSuperViewResponderKey) as? Bool
            return value
        }
        set {
            objc_setAssociatedObject(self, &Self.docsListenToSuperViewResponderKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
