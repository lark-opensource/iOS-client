//
//  LarkBadgeApplicationDelegate.swift
//  LarkApp
//
//  Created by mochangxing on 2019/10/14.
//

import Foundation
import AppContainer
import LKCommonsLogging
import LarkContainer
import RxSwift
import RunloopTools
import LarkNotificationServiceExtensionLib
import LarkUIKit

public final class LarkBadgeApplicationDelegate: ApplicationDelegate {
    static public let config = Config(name: "LarkBadge", daemon: true)
    static let logger = Logger.log(LarkBadgeApplicationDelegate.self, category: "LarkBadge.Log")

    let badgeService = ApplicationBadgeNumber.shared

    private var badgeNumberObserver: LarkBadgeNumberObserver?
    private let badgeNumberSubject = PublishSubject<Int>()
    private let disposeBag = DisposeBag()

    required public init(context: AppContext) {
        RunloopDispatcher.shared.addTask(scope: .container) {
            self.badgeNumberObserver = LarkBadgeNumberObserver(
                badgeNumberObservable: self.badgeNumberSubject.asObservable()
            )
            self.badgeNumberObserver?.observeBadgeNumber()

            self.badgeService.badgeNumberObservable.subscribe(self.badgeNumberSubject).disposed(by: self.disposeBag)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, _: DidEnterBackground) in
            self?.didEnterBackground()
        }

        context.dispatcher.add(observer: self) { [weak self] (_, _: WillEnterForeground) in
            self?.willEnterForeground()
        }
    }

    private func didEnterBackground() {
        self.badgeService.getIconBadgeNumber { badgeNumber in
            LarkBadgeApplicationDelegate.logger.info("didEnterBackground, badgeNumber: \(badgeNumber)")
            self.badgeNumberSubject.onNext(badgeNumber)
        }
    }

    private func willEnterForeground() {
        RunloopDispatcher.shared.addTask {
            self.badgeService.getIconBadgeNumber { badgeNumber in
                LarkBadgeApplicationDelegate.logger.info("willEnterForeground, badgeNumber: \(badgeNumber)")
                self.badgeNumberSubject.onNext(badgeNumber)
            }
        }.waitCPUFree()
    }
}

private final class LarkBadgeNumberObserver {

    var isUpdating = false

    var currentBadgeNumber: Int?

    var needUpdateBadge = false

    let badgeNumberObservable: Observable<Int>

    private let disposeBag = DisposeBag()

    init(badgeNumberObservable: Observable<Int>) {
        self.badgeNumberObservable = badgeNumberObservable
    }

    func observeBadgeNumber() {
        badgeNumberObservable.subscribe(onNext: { [weak self] (badge) in
            guard let `self` = self else {
                return
            }
            self.currentBadgeNumber = badge
            self.updateBadgeNumber()
        }).disposed(by: disposeBag)
    }

    func updateBadgeNumber() {
        guard !isUpdating else {
            needUpdateBadge = true
            return
        }
        needUpdateBadge = false
        isUpdating = true
        let task = DispatchWorkItem { [weak self] in
            guard let `self` = self, let currentBadgeNumber = self.currentBadgeNumber  else {
                return
            }
            LarkBadgeNumberUpdater.updateBadgeNumber(currentBadgeNumber, { _ in
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    self.isUpdating = false
                    if self.needUpdateBadge {
                        self.updateBadgeNumber()
                    }
                }
            })
        }
        DispatchQueue.global().async(execute: task)
    }
}
