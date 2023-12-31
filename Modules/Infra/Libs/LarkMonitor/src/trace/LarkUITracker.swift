//
//  LarkUITracker.swift
//  AFgzipRequestSerializer
//
//  Created by 李晨 on 2020/5/24.
//

import UIKit
import Foundation
import LarkKeyboardKit
import RxSwift
import Heimdallr

public final class LarkUITracker: NSObject {

    static let shared: LarkUITracker = LarkUITracker()
    private let disposeBag = DisposeBag()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    public class func startTrackUI() {
        let tracker = LarkUITracker.shared
        tracker.observeMenuViewController()
    }

    // MARK: - UIMenuController
    private func observeMenuViewController() {
        for name in [
            UIMenuController.willShowMenuNotification,
            UIMenuController.didShowMenuNotification,
            UIMenuController.willHideMenuNotification,
            UIMenuController.didHideMenuNotification
        ] {
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleMenuVCEvent(noti:)), name: name, object: nil)
        }
    }

    /// menu VC 是单例，所以应该配对。现在不太清楚什么场景，可能导致只有willAppear, 没有didAppear
    var menuVCState = UIMenuController.didHideMenuNotification {
        didSet {
            if menuVCState == UIMenuController.willHideMenuNotification
            && oldValue != UIMenuController.didShowMenuNotification {
                let currentState = menuVCState.rawValue
                let oldState = oldValue.rawValue
                DispatchQueue.global().async {
                    let eventName = "ios_menu_hidden"
                    let metric: [String: String] = [
                        "current_state": currentState,
                        "old_state": oldState
                    ]
                    LarkMonitor.trackService(eventName, metric: metric, category: nil, extra: nil)
                }
            }
        }
    }
    @objc
    func handleMenuVCEvent(noti: NSNotification) {
        guard let menuView = noti.object as? UIMenuController else { return }
        menuVCState = noti.name
        LarkAllActionLoggerLoad.logNarmalInfo(info:
            "\(noti.name.rawValue) " +
            "custom items \(menuView.menuItems?.count ?? 0) " +
            "frame \(menuView.menuFrame) " +
            "firstResponder \(self.firstResponderDescription())"
        )
    }

    private func firstResponderDescription() -> String {
        guard let firstResponder = KeyboardKit.shared.firstResponder else {
            return "nil"
        }
        return String(describing: NSStringFromClass(type(of: firstResponder)))
    }
}
