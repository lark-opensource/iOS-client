//
//  SceneSetupTask.swift
//  LarkBaseService
//
//  Created by 李晨 on 2021/2/2.
//

import UIKit
import Foundation
import BootManager
import LarkSceneManager
import LarkFeatureGating
import RxSwift
import LarkSplitViewController
import EENavigator

final class SceneSetupTask: FlowBootTask, Identifiable {
    static var identify = "SceneSetupTask"

    private let disposeBag = DisposeBag()

    override var deamon: Bool { return true }

    override func execute(_ context: BootContext) {
        SceneManager.shared.update(supportsMultipleScenes: true)

        if #available(iOS 13.0, *) {
            NotificationCenter.default.rx.notification(SceneManager.SceneActivedByUser).subscribe(onNext: { [weak self] (noti) in
                guard let self = self else { return }
                if SceneManager.shared.supportsMultipleScenes,
                   let scene = noti.object as? UIWindowScene,
                   let sourceScene = scene.sceneInfo.sourceScene(),
                   let sourceWindow = sourceScene.rootWindow(),
                   let topMostVC = sourceWindow.fromViewController {
                    self.autoQuitTopVC(topMostVC: topMostVC, scenetargetIdentifier: scene.sceneInfo.targetContentIdentifier)
                }
            }).disposed(by: self.disposeBag)
            // 注册关闭辅助窗口快捷键
            SceneManager.shared.registerCloseAuxSceneKeyCommand()
        }
        // Scene Switcher
        if #available(iOS 13.4, *), UIDevice.current.userInterfaceIdiom == .pad {
            SceneSwitcher.shared.isEnabled = true
        }
    }

    // 自动退出 topMostVC
    // 先判断 TopMostVC 的来源，是 push 出来的还是 present 出来的，再判断 scentTargetId 是否一致。都满足后确定当前VC是开启了scene，应该退出当前的VC
    private func autoQuitTopVC(topMostVC: UIViewController, scenetargetIdentifier: String) {
        // topMostVC 在 split 上
        if let splitVC = topMostVC.larkSplitViewController {
            if let topVC = splitVC.topViewController(),
                compareSceneTargetIdentifier(vc: topVC, scenetargetIdentifier: scenetargetIdentifier) {
                // 获取split上的topVC，并pop出去
                if let transitionCoordinator = splitVC.transitionCoordinator {
                    transitionCoordinator.animate(alongsideTransition: nil) { [weak splitVC] (_) in
                        splitVC?.popTopViewController(animated: true)
                    }
                } else {
                    splitVC.popTopViewController(animated: true)
                }
            }
        }
        // 有navigation，并且navigation上的controller不止一个，它也是最后一个，那topMost就是push出来的
        else if let navi = topMostVC.navigationController,
                navi.viewControllers.count > 1,
                navi.topViewController == topMostVC,
                compareSceneTargetIdentifier(vc: topMostVC, scenetargetIdentifier: scenetargetIdentifier) {
            // pop
            navi.popViewController(animated: true)
        }
        // 有presentingVC，没有navigation 或者navigation只有当前的VC，那topMost就是present出来的
        else if topMostVC.presentingViewController != nil,
                (topMostVC.navigationController == nil || topMostVC.navigationController?.viewControllers.count == 1),
                compareSceneTargetIdentifier(vc: topMostVC, scenetargetIdentifier: scenetargetIdentifier) {
            // dimiss
            topMostVC.dismiss(animated: true)
        }
        // 剩下的是 viewcontroller 不是 split 类型的，也不是 present 的，并且没有 navi 或者 navi 只有它自己。因此不做处理
    }

    // vc和vc.children的sceneIde，是否有与targetId一样的
    private func compareSceneTargetIdentifier(vc: UIViewController, scenetargetIdentifier: String) -> Bool {
        if vc.sceneTargetContentIdentifier == scenetargetIdentifier ||
            vc.children.contains(where: { childrenVC -> Bool in
                return childrenVC.sceneTargetContentIdentifier == scenetargetIdentifier
            }) {
            return true
        }
        return false
    }
}
