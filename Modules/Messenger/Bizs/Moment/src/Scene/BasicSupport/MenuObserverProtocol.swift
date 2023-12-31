//
//  MenuObserverProtocol.swift
//  Moment
//
//  Created by liluobin on 2021/3/15.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkMenuController
import LarkUIKit

protocol MenuObserverProtocol: UIViewController {
    var disposeBag: DisposeBag { get }
    func addMenuObserver()
    func pauseQueue()
    func resumeQueue()
    func canHanderWithUserInfo(_ info: [AnyHashable: Any]?) -> Bool
}
extension MenuObserverProtocol {
    func addMenuObserver() {
        NotificationCenter
            .default
            .rx
            .notification(MenuViewController.Notification.MenuControllerWillShowMenu)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (not) in
                // 判断notification是否指定了在哪些Scene生效
                if let validSceneID = not.userInfo?[MenuViewController.ValidSceneID] as? [String] {
                    if !validSceneID.contains(self?.currentSceneID() ?? "") {
                        return
                    }
                }
                if self?.canHanderWithUserInfo(not.userInfo) ?? false {
                    self?.pauseQueue()
                }
            })
            .disposed(by: disposeBag)

        NotificationCenter
            .default
            .rx
            .notification(MenuViewController.Notification.MenuControllerDidHideMenu)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (not) in
                // 判断notification是否指定了在哪些Scene生效
                if let validSceneID = not.userInfo?[MenuViewController.ValidSceneID] as? [String] {
                    if !validSceneID.contains(self?.currentSceneID() ?? "") {
                        return
                    }
                }
                if self?.canHanderWithUserInfo(not.userInfo) ?? false {
                    self?.resumeQueue()
                }
            })
            .disposed(by: disposeBag)
        NotificationCenter
            .default
            .rx
            .notification(FloatMenuOperationController.Notification.PopOverMenuWillShow)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.pauseQueue()
            })
            .disposed(by: disposeBag)

        NotificationCenter
            .default
            .rx
            .notification(FloatMenuOperationController.Notification.PopOverMenuDidHide)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.resumeQueue()
            })
            .disposed(by: disposeBag)
    }

    func canHanderWithUserInfo(_ info: [AnyHashable: Any]?) -> Bool {
        if let info = info,
           let vc = info[MenuViewController.ParentVCKey] as? UIViewController,
           vc === self {
            return true
        }
        return false
    }
}
