//
//  AVAudioNotificationHooker.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/7/27.
//

import Foundation

public extension LarkAudioSession {
    /// Use this notification if currentRoute is accessed
    /// - post在callback的queue里（非主线程）
    static let lkRouteChangeNotification = Notification.Name("LarkAudioSession.lkRouteChangeNotification")
}

class AVAudioNotificationHooker: Hooker {

    let getterArray: [(Selector, Selector)] = [
        (#selector(getter: AVAudioSession.currentRoute), #selector(getter: AVAudioSession.lk_currentRoute))
    ]

    func willHook() {
        LarkAudioSession.shared._currentRoute = AVAudioSessionRouteDescription()
    }

    func hook() {
        getterArray.forEach {
            swizzleInstanceMethod(AVAudioSession.self, from: $0.0, to: $0.1)
        }
    }

    func didHook() {
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeRoute(_:)),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: LarkAudioSession.shared.avAudioSession)
        AudioQueue.execute.async("init currentRoute") {
            let session = AVAudioSession.sharedInstance()
            self.updateRoute(session)
        }
        LarkAudioSession.logger.info("AVAudioSession Notification swizzle start")
    }

    private func updateRoute(_ session: AVAudioSession) {
        let route = session.lk_currentRoute
        let address = withExtendedLifetime(route as AnyObject) {
            UInt(bitPattern: Unmanaged.passUnretained($0).toOpaque())
        }
        if address == 0 {
            LarkAudioSession.logger.warn("current route is nil!")
        } else {
            LarkAudioSession.shared._currentRoute = route
        }
    }

    @objc private func didChangeRoute(_ notification: Notification) {
        guard let obj = notification.object as? AVAudioSession else {
            return
        }
        let userInfo = notification.userInfo
        AudioQueue.execute.async("routeChangeNotification") {
            self.updateRoute(obj)
            #if DEBUG || ALPHA
            if notification.routeChangeReason == .categoryChange {
                let session = AVAudioSession.sharedInstance()
                let larkSession = LarkAudioSession.shared
                if session.category != larkSession.category {
                    LarkAudioSession.logger.warn("AVAudioSession config changed by private apis: category, current is \(session.category), last set \(larkSession.category)")
                }
                if session.mode != larkSession.mode {
                    LarkAudioSession.logger.warn("AVAudioSession config changed by private apis: mode, current is \(session.mode), last set \(larkSession.mode)")
                }
                if session.categoryOptions != larkSession.categoryOptions {
                    LarkAudioSession.logger.warn("AVAudioSession config changed by private apis: options, current is \(session.categoryOptions), last set \(larkSession.categoryOptions)")
                }
                if session.routeSharingPolicy != larkSession.routeSharingPolicy {
                    LarkAudioSession.logger.warn("AVAudioSession config changed by private apis: policy, current is \(session.routeSharingPolicy), last set \(larkSession.routeSharingPolicy)")
                }
            }
            #endif
            AudioQueue.callback.async("lkRouteChangeNotification") {
                NotificationCenter.default.post(name: LarkAudioSession.lkRouteChangeNotification, object: self, userInfo: userInfo)
            }
        }
    }
}

fileprivate extension AVAudioSession {
    @objc dynamic var lk_currentRoute: AVAudioSessionRouteDescription {
        LarkAudioSession.shared.currentRoute
    }
}
