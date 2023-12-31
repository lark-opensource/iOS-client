//
//  BTUIEventMonitor.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/31.
//  


import SKCommon
import SKFoundation

final class BTUIEventMonitor {
    
    var didReceiveMove: ((_ translation: CGPoint) -> Void)?
    
    weak var ancestorView: UIView? //限制 touch 区域
    weak var beginTouch: UITouch?
    
    var enable: Bool = true
    
    init(ancestorView: UIView) {
        self.ancestorView = ancestorView
        DocsLogger.btInfo("BTUIEventMonitor \(self) init")
        NotificationCenter.default.addObserver(self, selector: #selector(handleEventNotify(_:)),
                                               name: Notification.Name.Docs.appliationSentEvent, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        DocsLogger.btInfo("BTUIEventMonitor \(self) deinit")
    }
    
    @objc
    func handleEventNotify(_ notify: Notification) {
        guard enable, let event = notify.userInfo?["event"] as? UIEvent,
              let ancestorView = self.ancestorView else {
            return
        }
        self.handle(event: event, ancestorView: ancestorView)
    }
    
    func handle(event: UIEvent, ancestorView: UIView) {
        debugPrint("receiveEvent: \(event)")
        // 只支持单指操作。
        guard let touch = event.allTouches?.first else {
            return
        }
        switch touch.phase {
        case .began:
            if beginTouch != touch, touch.view?.isDescendant(of: ancestorView) ?? false {
                beginTouch = touch
            }
        case .moved, .stationary:
            guard touch == beginTouch else {
                return
            }
            let location = touch.location(in: touch.window)
            let prelocation = touch.previousLocation(in: touch.window)
            let translation = CGPoint(x: location.x - prelocation.x, y: location.y - prelocation.y)
            self.didReceiveMove?(translation)
        case .ended, .cancelled:
            beginTouch = nil
        default: break
        }
    }
}
