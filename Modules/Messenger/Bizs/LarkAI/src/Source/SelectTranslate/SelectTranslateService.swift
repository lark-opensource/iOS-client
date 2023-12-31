//
//  SelectTranslateService.swift
//  LarkAI
//
//  Created by ByteDance on 2022/8/17.
//
import UIKit
import Foundation
import LarkUIKit
import LarkMessageBase
import LarkModel
import EENavigator
import LarkCore
import LKCommonsLogging
import LarkMessengerInterface
import LarkContainer
import UniverseDesignToast
import RustPB
import RxSwift
import LarkSDKInterface
import LarkStorage
import LarkSearchCore

final class SelectTranslateServiceImp: SelectTranslateService, UserResolverWrapper {
    private static let logger = Logger.log(SelectTranslateServiceImp.self, category: "LarkAI.SelectTranslate.")
    private static let englishLanguageKey = "en"
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    private var selectTranslateAPI: SelectTranslateAPI
    private let disposeBag = DisposeBag()
    private var startTranslateTime: TimeInterval?

    let userResolver: UserResolver
    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.selectTranslateAPI = RustSelectTranslateAPI(resolver: resolver)
    }

    func showSelectTranslateView(selectString: String,
                                 fromVC: UIViewController,
                                 copyConfig: TranslateCopyConfig?,
                                 trackParam: [String: Any]) {
        // 先检测选择文本的源语言
        let settingTgtLanguage = userGeneralSettings?.translateLanguageSetting.targetLanguage ?? ""
        if LarkAITracker.enablePostTrack() {
            self.startTranslateTime = Date().timeIntervalSince1970
            LarkAITracker.trackForStableWatcher(domain: "asl_translate",
                                                message: "asl_translate_click",
                                                metricParams: [:],
                                                categoryParams: [
                                                    "source": "message_select",
                                                    "type": -1
                                                ])
        }
        guard AIFeatureGating.optimizeTargetLanuage.isUserEnabled(userResolver: userResolver) else {
            getSelectTranslateCard(selectString: selectString,
                                   tgtLanguage: settingTgtLanguage,
                                   fromVC: fromVC,
                                   copyConfig: copyConfig,
                                   trackParam: trackParam)
            return
        }

        let textList = [selectString]
        guard !textList.isEmpty else { return }
        selectTranslateAPI.detectTextsLanguageRequest(textList: textList)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                var tgtLanguage = settingTgtLanguage
                let detectLanguage = result.language
                let mainLanguage = KVPublic.AI.mainLanguage.value(forUser: self.userResolver.userID)
                let lastSelectLanguage = KVPublic.AI.lastSelectedTargetLanguage.value(forUser: self.userResolver.userID)
                // 源语言和目标语言相同
                if detectLanguage.count == 1,
                   detectLanguage.first == settingTgtLanguage {
                    // 源语言和目标语言都是英语
                    if detectLanguage.contains(Self.englishLanguageKey) {
                        // 主语言不是英语，翻译为主语言
                        if mainLanguage != Self.englishLanguageKey {
                            tgtLanguage = mainLanguage
                            Self.logger.info("[optimizeTargetLanguage]: use mainLanguage-\(tgtLanguage)")
                        } else if !lastSelectLanguage.isEmpty {
                            // 主语言也是英语，翻译为上次选择的语言
                            tgtLanguage = lastSelectLanguage
                            Self.logger.info("[optimizeTargetLanguage]: use lastSelectLanguage-\(tgtLanguage)")
                        }
                    } else {
                    // 源语言和目标语言都不是英语，翻译为英语
                        tgtLanguage = Self.englishLanguageKey
                        Self.logger.info("[optimizeTargetLanguage]: use english-\(tgtLanguage)")
                    }
                }
                Self.logger.info("[optimizeTargetLanguage]: use targetLanguage-\(tgtLanguage)")
                self.getSelectTranslateCard(selectString: selectString,
                                            tgtLanguage: tgtLanguage,
                                            fromVC: fromVC,
                                            copyConfig: copyConfig,
                                            trackParam: trackParam)
            }, onError: { (error) in
                Self.logger.error("query text language error ==== \(error)")
                Self.logger.info("[detectTextsLanguageRequest]request count: \(textList.count)")
                if LarkAITracker.enablePostTrack() {
                    LarkAITracker.trackForStableWatcher(domain: "asl_translate",
                                                        message: "asl_translate_fail",
                                                        metricParams: [:],
                                                        categoryParams: [
                                                            "fail_reason": error.localizedDescription,
                                                            "source": "message_select",
                                                            "type": -1
                                                        ])
                }
                guard let window = fromVC.view.window else { return }
                UDToast.showTips(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: window)
            }).disposed(by: disposeBag)

    }
    func getSelectTranslateCard(selectString: String, tgtLanguage: String, fromVC: UIViewController, copyConfig: TranslateCopyConfig?, trackParam: [String: Any]) {
        var params = trackParam.merging(["tgtLanguage": tgtLanguage, "srcLanguage": "auto"]) { (_, second) -> Any in return second }
        selectTranslateAPI.selectTextTranslateInformation(selectText: selectString, trgLanguage: tgtLanguage)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else { return }
                if let wordID = response.translateDictCardMap[selectString]?.id {
                    params["wordID"] = wordID
                }
                if let translateType = response.trackInfos.first?.chosenContentType {
                    params["translateType"] = translateType
                }
                let controller = SelectTranslateContainerViewController(resolver: self.userResolver,
                                                                        selectTranslateData: response,
                                                                        selectText: selectString,
                                                                        copyConfig: copyConfig,
                                                                        trackParam: params)
                if Display.pad {
                    self.userResolver.navigator.present(
                        controller,
                        wrap: LkNavigationController.self, from: fromVC,
                        prepare: {
                            $0.modalPresentationStyle = .formSheet
                        },
                        animated: true
                    )
                } else {
                    self.userResolver.navigator.present(
                        controller,
                        wrap: LkNavigationController.self, from: fromVC,
                        prepare: {
                            if #available(iOS 15.0, *) {
                                $0.sheetPresentationController?.detents = [.medium(), .large()]
                                $0.sheetPresentationController?.prefersGrabberVisible = true
                                $0.sheetPresentationController?.delegate = controller
                            }
                        },
                        animated: true
                    )
                }

                SelectTranslateTracker.selectTranslateCardView(resultType: "success",
                                                               wordID: params["wordID"],
                                                               messageID: params["messageID"],
                                                               chatID: params["chatID"],
                                                               fileID: params["fileID"],
                                                               fileType: params["fileType"],
                                                               srcLanguage: params["srcLanguage"],
                                                               tgtLanguage: params["tgtLanguage"],
                                                               translateType: params["translateType"],
                                                               cardSouce: params["cardSource"])
                if LarkAITracker.enablePostTrack() {
                    let nowTime = Date().timeIntervalSince1970
                    LarkAITracker.trackForStableWatcher(domain: "asl_translate",
                                                        message: "asl_translate_response_show",
                                                        metricParams: ["duration": ceil((nowTime - (self.startTranslateTime ?? 0)) * 1000)],
                                                        categoryParams: [
                                                            "source": "message_select",
                                                            "type": -1
                                                        ])
                }
            }, onError: { (error) in
                Self.logger.error("query selectTranslate data error ==== \(error)")
                if LarkAITracker.enablePostTrack() {
                    LarkAITracker.trackForStableWatcher(domain: "asl_translate",
                                                        message: "asl_translate_fail",
                                                        metricParams: [:],
                                                        categoryParams: [
                                                            "fail_reason": error.localizedDescription,
                                                            "source": "message_select",
                                                            "type": -1
                                                        ])
                }
                SelectTranslateTracker.selectTranslateCardView(resultType: "error",
                                                               wordID: params["wordID"],
                                                               messageID: params["messageID"],
                                                               chatID: params["chatID"],
                                                               fileID: params["fileID"],
                                                               fileType: params["fileType"],
                                                               srcLanguage: params["srcLanguage"],
                                                               tgtLanguage: params["tgtLanguage"],
                                                               translateType: params["translateType"],
                                                               cardSouce: params["cardSource"])
                guard let window = fromVC.view.window else { return }
                UDToast.showTips(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: window)
            }).disposed(by: disposeBag)
    }

}
