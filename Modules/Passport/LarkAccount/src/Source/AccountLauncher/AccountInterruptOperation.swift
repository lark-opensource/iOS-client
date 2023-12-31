//
//  AccountInterruptOperation.swift
//  LarkAccount
//
//  Created by tangyunfei.tyf on 2021/1/26.
//

import Foundation
import RxSwift
import EENavigator
import LKCommonsLogging
import LarkAlertController
import LarkAccountInterface
import LarkSceneManager
import LarkContainer

class AccountInterruptOperation: InterruptOperation {
    static let logger = Logger.plog(Launcher.self, category: "LarkAccount.AccountInterruptOperation")

    func getInterruptObservable(type: LarkAccountInterface.InterruptOperationType) -> Single<Bool> {
        if #available(iOS 13.0, *) {
            if type == .switchAccount && UIApplication.shared.connectedScenes.count > 1 {
                let cancelAction = {(single: Single<Bool>.SingleObserver) in
                    single(.success(false))
                }
                let commitAction = {[weak self](single: Single<Bool>.SingleObserver) in
                    self?.closeAllAssitantScenes()
                    single(.success(true))
                }

                return Single<Bool>.create(subscribe: {(single) -> Disposable in
                    let mainScene = Scene.mainScene()
                    SceneManager.shared.active(scene: mainScene, from: nil) { (window, error) in
                        if 
                            let vc = PassportNavigator.topMostVC,
                            error == nil {
                            Self.logger.info("succeed to activate main scene in AccountInterruptOperation")
                            let alertController = LarkAlertController()
                            alertController.setTitle(text: BundleI18n.suiteLogin.Lark_Core_SwitchAccountDialog())
                            alertController.addCancelButton(dismissCompletion: {
                                cancelAction(single)
                            })
                            alertController.addPrimaryButton(text: BundleI18n.suiteLogin.Lark_Core_SwitchAccount, dismissCompletion: {
                                commitAction(single)
                            })
                            Navigator.shared.present(alertController, from: vc) // user:checked (navigator)
                        } else {
                            Self.logger.info("failed to activate main scene in AccountInterruptOperation")
                            single(.success(false))
                        }
                    }
                    return Disposables.create()
                })
            }
        }

        return .just(true)
    }

    private func closeAllAssitantScenes() {
        if #available(iOS 13.0, *) {
            for uiScene in UIApplication.shared.connectedScenes {
                let scene = uiScene.sceneInfo
                if !scene.isMainScene() {
                    SceneManager.shared.deactive(scene: scene)
                }
            }
            Self.logger.info("succeed to close all assistant scenes", method: .local)
        }
    }

    var description: String {
        return "AccountInterruptOperation"
    }
}
