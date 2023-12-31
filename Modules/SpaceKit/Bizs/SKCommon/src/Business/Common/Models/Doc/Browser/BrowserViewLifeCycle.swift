//
//  BrowserViewLifeCycle.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/3.
//

import SKFoundation
import Foundation

public struct BrowserKeyboard: SKKeyboardInfoProtocol {

    public let height: CGFloat
    public let isShow: Bool
    public let trigger: String

    public init(height: CGFloat, isShow: Bool, trigger: String) {
        self.height = height
        self.isShow = isShow
        self.trigger = trigger
    }
}

public protocol BrowserViewLifeCycleEvent: AnyObject {
    func browserWillLoad()
    func browserViewControllerDidLoad()
    func browserWillAppear()
    func browserDidAppear()
    func browserDidDisappear()
    func browserDidDismiss()
    func browserWillDismiss() // 对应 willDisappear
    func browserDidLayoutSubviews()
    func browserWillTransition(from: CGSize, to: CGSize)
    func browserDidTransition(from: CGSize, to: CGSize)
    func browserDidSplitModeChange()
    func browserWillClear()
    func browserTerminate()
    func browserDidHideLoading()
    func browserKeyboardDidChange(_ keyboardInfo: BrowserKeyboard)
    func browserDidBeginEdit()
    func browserDidUpdateDocsInfo()
    func browserWillChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation)
    // 此时拿到的 view 宽度是变化前的
    func browserDidChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation)
    func browserWillRerender()
    func addLifeCycleNotification(level: LifeCyclePriority, noti: @escaping LifeCycleStageBlock)
    func browserDidChangeFloatingWindow(isFloating: Bool) //MS浮窗
    func browserLoadStatusChange(_ status: LoadStatus)
    func browserNavReceivedPopGesture()
    func browserTraitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    func browserBeforeCallRender()
    func browserReceiveRenderCallBack(success: Bool, error: Error?)
    func browserStartPreload()
    func browserEndPreload()
}

extension BrowserViewLifeCycleEvent {
    public func browserWillLoad() {}
    public func browserViewControllerDidLoad() {}
    public func browserWillDismiss() {}
    public func browserWillAppear() {}
    public func browserDidAppear() {}
    public func browserDidDisappear() {}
    public func browserDidDismiss() {}
    public func browserDidLayoutSubviews() {}
    public func browserWillClear() {}
    public func browserTerminate() {}
    public func browserDidHideLoading() {}
    public func browserDidBeginEdit() {}
    public func browserDidUpdateDocsInfo() {}
    public func browserKeyboardDidChange(_ keyboardInfo: BrowserKeyboard) {}
    public func browserWillChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation) {}
    public func browserDidChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation) {}
    public func browserWillTransition(from: CGSize, to: CGSize) {}
    public func browserDidTransition(from: CGSize, to: CGSize) {}
    public func browserDidSplitModeChange() {}
    public func browserWillRerender() {}
    public func addLifeCycleNotification(level: LifeCyclePriority, noti: @escaping LifeCycleStageBlock) {}
    public func browserDidChangeFloatingWindow(isFloating: Bool) {}
    public func browserLoadStatusChange(_ status: LoadStatus) {}
    public func browserNavReceivedPopGesture() {}
    public func browserTraitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {}
    public func browserBeforeCallRender() {}
    public func browserReceiveRenderCallBack(success: Bool, error: Error?) {}
    public func browserStartPreload() {}
    public func browserEndPreload() {}
}

public enum LifeCycleStage {
    case browserWillLoad
    case browserViewControllerDidLoad
    case browserWillDismiss
    case browserWillAppear
    case browserDidAppear
    case browserDidDisappear
    case browserDidDismiss
    case browserDidLayoutSubviews
    case browserWillClear
    case browserDidHideLoading
    case browserDidBeginEdit
    case browserDidUpdateDocsInfo
    case browserKeyboardDidChange(keyboardInfo: BrowserKeyboard)
    case browserWillChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation)
    case browserDidChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation)
    case browserWillTransition(from: CGSize, to: CGSize)
    case browserDidTransition(from: CGSize, to: CGSize)
    case browserDidSplitModeChange
    case browserWillRerender
    case browserDidChangeFloatingWindow(isFloating: Bool)
    case browserTerminate
    case browserLoadStatusChange(_ status: LoadStatus)
    case browserNavReceivedPopGesture
    case browserTraitCollectionDidChange(previousTraitCollection: UITraitCollection?)
    case browserBeforeCallRender
    case browserReceiveRenderCallBack(success: Bool, error: Error?)
    case browserStartPreload
    case browserEndPreload
}

public enum LifeCyclePriority: String {
    case `default`
    case middle
    case high
}

public typealias LifeCycleStageBlock = (LifeCycleStage) -> Void

public final class BrowserViewLifeCycle {

    public final class NotificationDispose {
        
        private var disposeBlock: () -> Void
        
        init(block: @escaping () -> Void) {
            self.disposeBlock = block
        }
        
        public func dispose() {
            disposeBlock()
        }
    }
    
    class NotificationObserver {
        
        private var block: LifeCycleStageBlock
        /// 用于标识该observer
        private(set) var id: String
        
        init(_ block: @escaping LifeCycleStageBlock) {
            self.block = block
            self.id = UUID().uuidString
        }
        
        func callAsFunction(_ stage: LifeCycleStage) {
            block(stage)
        }
    }
    
    private(set) var notifications: [LifeCyclePriority: [NotificationObserver]]
    
    let observers: ObserverContainer<BrowserViewLifeCycleEvent>

    public init() {
        self.observers = ObserverContainer<BrowserViewLifeCycleEvent>()
        notifications = [:]
    }

    public func addObserver(_ o: BrowserViewLifeCycleEvent) {
        observers.add(o)
    }
    
    
    /// 按照优先级派发消息, 通过调用NotificationDispose对象dispose方法移除监听
    public func addLifeCycleNotification(level: LifeCyclePriority, noti: @escaping LifeCycleStageBlock) -> NotificationDispose {
        var array = notifications[level] ?? []
        let oberver = NotificationObserver(noti)
        array.append(oberver)
        if level == .high, array.count > 5 {
            spaceAssertionFailure("high level is limited to 5")
        }
        notifications[level] = array
        let id = oberver.id
        return NotificationDispose { [weak self] in
            self?.dispose(level: level, id: id)
        }
    }
    
    public func removeNotificationObserver() {
        notifications.forEach { element in
            spaceAssert(element.value.isEmpty == true, "you should dispose earlier")
        }
        notifications = [:]
    }
    
    private func dispose(level: LifeCyclePriority, id: String) {
        notifications[level]?.removeAll(where: { $0.id == id })
    }
    
    private func dispatch(stage: LifeCycleStage) {
        notifications[.high]?.forEach({ $0(stage) })
        notifications[.middle]?.forEach({ $0(stage) })
        notifications[.default]?.forEach({ $0(stage) })
    }
}

extension BrowserViewLifeCycle: BrowserViewLifeCycleEvent {
    public func browserStartPreload() {
        dispatch(stage: .browserStartPreload)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserStartPreload()
        }
    }

    public func browserEndPreload() {
        dispatch(stage: .browserEndPreload)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserEndPreload()
        }
    }

    public func browserBeforeCallRender() {
        dispatch(stage: .browserBeforeCallRender)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserBeforeCallRender()
        }
    }

    public func browserReceiveRenderCallBack(success: Bool, error: Error?) {
        dispatch(stage: .browserReceiveRenderCallBack(success: success, error: error))
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserReceiveRenderCallBack(success: success, error: error)
        }
    }

    public func browserDidLayoutSubviews() {
        dispatch(stage: .browserDidLayoutSubviews)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserDidLayoutSubviews()
        }
    }
    
    public func browserWillLoad() {
        dispatch(stage: .browserWillLoad)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserWillLoad()
        }
    }
    
    public func browserViewControllerDidLoad() {
        dispatch(stage: .browserViewControllerDidLoad)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserViewControllerDidLoad()
        }
    }

    public func browserWillAppear() {
        dispatch(stage: .browserWillAppear)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserWillAppear()
        }
    }

    public func browserDidAppear() {
        dispatch(stage: .browserDidAppear)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserDidAppear()
        }
    }

    public func browserDidDisappear() {
        dispatch(stage: .browserDidDisappear)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserDidDisappear()
        }
    }
    
    public func browserWillDismiss() {
        dispatch(stage: .browserWillDismiss)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserWillDismiss()
        }
    }

    public func browserDidDismiss() {
        dispatch(stage: .browserDidDismiss)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserDidDismiss()
        }
    }

    public func browserWillTransition(from: CGSize, to: CGSize) {
        dispatch(stage: .browserWillTransition(from: from, to: to))
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserWillTransition(from: from, to: to)
        }
    }

    public func browserDidTransition(from: CGSize, to: CGSize) {
        dispatch(stage: .browserDidTransition(from: from, to: to))
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserDidTransition(from: from, to: to)
        }
    }
    
    public func browserDidSplitModeChange() {
        dispatch(stage: .browserDidSplitModeChange)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserDidSplitModeChange()
        }
    }

    public func browserWillClear() {
        dispatch(stage: .browserWillClear)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserWillClear()
        }
    }
    
    public func browserTerminate() {
        dispatch(stage: .browserTerminate)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserTerminate()
        }
    }

    public func browserKeyboardDidChange(_ keyboardInfo: BrowserKeyboard) {
        dispatch(stage: .browserKeyboardDidChange(keyboardInfo: keyboardInfo))
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserKeyboardDidChange(keyboardInfo)
        }
    }

    public func browserDidHideLoading() {
        dispatch(stage: .browserDidHideLoading)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserDidHideLoading()
        }
    }

    public func browserDidBeginEdit() {
        dispatch(stage: .browserDidBeginEdit)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserDidBeginEdit()
        }
    }

    public func browserDidUpdateDocsInfo() {
        dispatch(stage: .browserDidUpdateDocsInfo)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserDidUpdateDocsInfo()
        }
    }

    public func browserDidChangeOrientation(from oldOrientation: UIInterfaceOrientation, to newOrientation: UIInterfaceOrientation) {
        dispatch(stage: .browserDidChangeOrientation(from: oldOrientation, to: newOrientation))
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserDidChangeOrientation(from: oldOrientation, to: newOrientation)
        }
    }
    
    public func browserWillRerender() {
        dispatch(stage: .browserWillRerender)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserWillRerender()
        }
    }
    
    
    public func browserDidChangeFloatingWindow(isFloating: Bool) {
        dispatch(stage: .browserDidChangeFloatingWindow(isFloating: isFloating))
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserDidChangeFloatingWindow(isFloating: isFloating)
        }
    }
    
    public func browserLoadStatusChange(_ status: LoadStatus) {
        dispatch(stage: .browserLoadStatusChange(status))
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserLoadStatusChange(status)
        }
    }
    
    public func browserNavReceivedPopGesture() {
        dispatch(stage: .browserNavReceivedPopGesture)
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserNavReceivedPopGesture()
        }
    }
    
    public func browserTraitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        dispatch(stage: .browserTraitCollectionDidChange(previousTraitCollection: previousTraitCollection))
        let allListeners = observers.all
        for listener in allListeners {
            listener.browserTraitCollectionDidChange(previousTraitCollection)
        }
    }
}
