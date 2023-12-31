//
//  AppLanguageServiceImpl.swift
//  LarkMine
//
//  Created by au on 2022/12/6.
//

import UIKit
import Foundation
import EENavigator
import UniverseDesignDialog
import UniverseDesignToast
import LarkMessengerInterface
import LarkLocalizations
import LarkSDKInterface
import LarkUIKit
import LKCommonsLogging
import RxSwift

final class AppLanguageServiceImpl: AppLanguageService {

    private static let logger = Logger.log(AppLanguageServiceImpl.self, category: "LarkMine")
    private let configurationAPI: ConfigurationAPI
    private let userNavigator: Navigatable
    private let disposeBag: DisposeBag = DisposeBag()

    init(userNavigator: Navigatable,
        configurationAPI: ConfigurationAPI) {
        self.userNavigator = userNavigator
        self.configurationAPI = configurationAPI
    }

    func updateAppLanguage(model: LanguageModel, from: UIViewController) {
        let message = BundleI18n.LarkMine.Lark_Legacy_MineLanguageChangeIOSNotice(model.name)
        let alertController = UDDialog()
        alertController.setContent(text: message)
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.LarkMine.Lark_IM_ChangeLanguageAndRestart_RestartButton, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            let language = model.language.localeIdentifier
            var hud: UDToast?
            if let window = from.view.window {
                hud = UDToast.showLoading(on: window, disableUserInteraction: true)
            }
            /// 上传语言 + 触发 sdk 拉取系统消息模板
            self.configurationAPI
                .updateDeviceSetting(language: language)
                .flatMap({ (_) -> Observable<Void> in
                    return self.configurationAPI.getSystemMessageTemplate(language: language)
                }).catchError({ (error) -> Observable<()> in
                    Self.logger.error(
                        "update message error",
                        additionalData: ["language": language],
                        error: error
                    )

                    DispatchQueue.main.async {
                        if let window = from.view.window {
                            hud?.showFailure(with: BundleI18n.LarkMine.Lark_Legacy_MineLanguageUploadError,
                                             on: window,
                                             error: error)
                        }
                    }
                    return Observable.empty()
                }).subscribe(onNext: { (_) in
                    LanguageManager.setCurrent(language: model.language, isSystem: model.isSystem)
                    let (sysLang, curLang, isSelectSystem) = LanguageManager.getLanguageSettings()
                    Self.logger.info("language setting: after switch lan to \(language),"
                                     + "sysLanguage: \(sysLang) currentLanguage: \(curLang) isSelectSystem: \(isSelectSystem)")
                    /// 主线程执行UI操作
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        hud?.remove()
                        var exitSel: Selector { Selector(["terminate", "With", "Success"].joined()) }
                        UIApplication.shared.perform(exitSel, on: Thread.main, with: nil, waitUntilDone: false)
                    }
                }, onError: { (error) in
                    DispatchQueue.main.async {
                        hud?.remove()
                    }
                    Self.logger.error(
                        "get system template failed",
                        additionalData: ["language": language],
                        error: error
                    )
                })
                .disposed(by: self.disposeBag)
        })

        self.userNavigator.present(alertController, from: from)
    }
}
