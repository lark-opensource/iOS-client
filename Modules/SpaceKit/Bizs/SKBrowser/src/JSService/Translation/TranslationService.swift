//
//  TranslationService.swift
//  SpaceKit
//
//  Created by LiXiaolin on 2019/6/11.
//
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import SpaceInterface
import LarkContainer

class TranslationService: BaseJSService {

    private lazy var translateService: CCMTranslateService? = {
        try? model?.userResolver.resolve(assert: CCMTranslateService.self)
    }()

    private var translationPushSetup = false

    private let disposeBag = DisposeBag()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension TranslationService: BrowserViewLifeCycleEvent {
    func browserWillClear() {
        SpaceTranslationCenter.standard.config = nil
    }
}

extension TranslationService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [
            .setUpTranslation,
            .getTranslationConfig,
            .setTranslationItem
        ]
    }

    func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .setUpTranslation:
            guard let isEnableTranlate = params["enableTranslate"] as? Bool else {
                DocsLogger.info("TranlateService setUpTranslation parames not right", extraInfo: params, error: nil, component: nil)
                return
            }
            hostDocsInfo?.isEnableTranslate = isEnableTranlate
        case .getTranslationConfig:
            guard
                let data = try? JSONSerialization.data(withJSONObject: params, options: []),
                let config = try? JSONDecoder().decode(SpaceTranslationCenter.Config.self, from: data) else {
                    DocsLogger.info("翻译配置解析失败", extraInfo: params)
                    return
            }
            SpaceTranslationCenter.standard.config = config
            DocsLogger.info("translation config", extraInfo: params)
        case .setTranslationItem:
            guard let targetLanguage = params["language"] as? String,
                  let targetLanguageTitle = params["languageText"] as? String else {
                DocsLogger.error("TranslateService setTranslateItem params not right", extraInfo: params)
                return
            }
            var translationContext = DocsInfo.TranslationContext(targetLanguage: targetLanguage,
                                                                 targetLanguageTitle: targetLanguageTitle)
            translationContext.contentSourceLanguage = params["srcLang"] as? String
            translationContext.userMainLanguage = params["userMainLang"] as? String
            translationContext.defaultTargetLanguage = params["userDefaultTargetLang"] as? String
            hostDocsInfo?.translationContext = translationContext
            setupTranslattionPush()
        default:
            DocsLogger.info("TranlateService setUpTranslation enter default", extraInfo: params, error: nil, component: nil)
        }
    }

    private func setupTranslattionPush() {
        if translationPushSetup { return }
        translationPushSetup = true
        guard let service = translateService else {
            DocsLogger.error("CCMTranslateService resolve failed", component: LogComponents.translate)
            spaceAssertionFailure("translateService not found")
            return
        }
        service.configUpdated.drive { [weak self] config in
            guard let self else { return }
            DocsLogger.info("notify translate setting changed",
                            extraInfo: [
                                "targetLanguage": config.targetLanguageKey,
                                "enableAutoTranslate": config.enableAutoTranslate
                            ],
                            component: LogComponents.translate)
            self.model?.jsEngine.callFunction(.translateSettingChange,
                                              params: [
                                                "targetLanguage": config.targetLanguageKey,
                                                "enableAutoTranslate": config.enableAutoTranslate]) { _, error in
                DocsLogger.info("translate config update complete",
                                error: error,
                                component: LogComponents.translate)
            }
        }.disposed(by: disposeBag)
    }
}
