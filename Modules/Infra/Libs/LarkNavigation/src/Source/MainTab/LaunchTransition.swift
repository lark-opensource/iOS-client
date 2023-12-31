//
//  LaunchTransition.swift
//  LarkApp
//
//  Created by PGB on 2019/10/29.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import LarkUIKit
import AppContainer
import RunloopTools

final class LaunchTransition {
    public static let shared: LaunchTransition = LaunchTransition()
    private var maskView: UIView?
    private var observer: CFRunLoopObserver?
    private var shouldDismiss: Bool = false

    private init() {
        let storyboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
        self.maskView = storyboard.instantiateInitialViewController()?.view ?? UIView()
        let activityToObserve: CFRunLoopActivity = .beforeTimers
        self.observer = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault,        // allocator
            activityToObserve.rawValue, // activities
            true,                       // repeats
            0                     // order after CA transaction commits
        ) { [weak self] ( _, _ ) in
            guard let `self` = self else { return }
            guard self.shouldDismiss else { return }
            if let observer = self.observer {
                CFRunLoopRemoveObserver(RunLoop.main.getCFRunLoop(), observer, CFRunLoopMode.commonModes)
                self.observer = nil
            }
            self.dismissMaskView()
        }
    }

    private var timeloggerID: AnyObject?
    func add(in superView: UIView, userControlledSignal: BehaviorRelay<Bool>? = nil) {
        timeloggerID = TimeLogger.shared.logBegin(eventName: "LaunchTransition")
        guard let maskView = maskView, let observer = observer else { return }
        guard !superView.subviews.contains(maskView) else { return }
        superView.addSubview(maskView)
        maskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        var disposeBag = DisposeBag()

        // tell the runloop observer to dismiss the mask view when
        // the situation where the developer-defined signal sends true or the timeout exceeds occurs
        Driver.merge(
            userControlledSignal?.asDriver() ?? Driver.just(false),
            Driver.just(true).delay(.seconds(3))
        ).drive( onNext: { [weak self] dismiss in
            guard let `self` = self, dismiss else { return }
            disposeBag = DisposeBag()
            self.shouldDismiss = dismiss
        }).disposed(by: disposeBag)

        // if the developer doesn't want to control the time to dismiss the mask view, just dismiss it with the second Runloop
        shouldDismiss = userControlledSignal == nil ? true : shouldDismiss

        CFRunLoopAddObserver(RunLoop.main.getCFRunLoop(), observer, CFRunLoopMode.commonModes)
    }

    func dismissMaskView() {
        if let id = timeloggerID {
            TimeLogger.shared.logEnd(identityObject: id, eventName: "LaunchTransition")
        }
        UIView.animate(withDuration: 0.15, animations: {
            self.maskView?.alpha = 0
        }) { _ in
            self.maskView?.removeFromSuperview()
            self.maskView = nil
            NotificationCenter.default.post(name: .launchTransitionDidDismiss, object: nil, userInfo: ["show": true])
        }
    }
}
