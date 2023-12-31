//
//  GuideServiceProvider.swift
//  LarkMail
//
//  Created by 龙伟伟 on 2020/8/27.
//

import Foundation
import RxSwift
import RxCocoa
import LarkGuide
import Swinject
import MailSDK
import LarkContainer
import LarkAIInfra
#if MessengerMod
import LarkMessengerInterface
#endif

class GuideServiceProvider: GuideServiceProxy {
    var guideService: NewGuideService? {
        return try? resolver.resolve(assert: NewGuideService.self)
    }
    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }
}

class MyAIServiceProvider: MyAIServiceProxy {
    
    var isAIEnable: Bool {
#if MessengerMod
        if let aiService = try? resolver.resolve(assert: MyAIService.self) {
            return aiService.enable.value
        }
#endif
        return false
    }
    
    var needOnboarding: Bool {
#if MessengerMod
        if let aiService = try? resolver.resolve(assert: MyAIService.self) {
            return aiService.needOnboarding.value
        }
#endif
        return false
    }
    var aiNickName: String {
#if MessengerMod
        if let aiService = try? resolver.resolve(assert: MyAIService.self) {
            var name = aiService.info.value.name
            if !name.isEmpty {
                return name
            }
        }
#endif
        return ""
    }
    var aiDefaultName: String {
#if MessengerMod
        let myAIInfoService = try? resolver.resolve(assert: MyAIInfoService.self)
        return myAIInfoService?.defaultResource.name ?? ""
#endif
        return ""
    }
    var aiNickNameRelay: BehaviorRelay<String> {
        return nickRelay
    }
    var chatModeAIImage: UIImage? {
#if MessengerMod
        if let service = try? resolver.resolve(assert: MyAIQuickLaunchBarService.self) {
            let info = service.getQuickLaunchBarItemInfo(type: .ai(nil))
            return info.value.image
        }
#endif
        return nil
    }
    
    func launchChatMode(chatID: Int64,
                        chatModeID: Int64,
                        mailContent: String?,
                        isTrim: Bool?,
                        accountId: String,
                        bizIds: String,
                        labelId: String,
                        openRag: Bool,
                        callback: ((MyAIChatModeConfig.PageService) -> Void)?) {
#if MessengerMod
        if let service = try? resolver.resolve(assert: MyAIQuickLaunchBarService.self) {
            let provider: MyAIChatModeConfigProvider = {  () -> Observable<MyAIChatModeConfig?> in
                //let publishSubject = PublishSubject<MyAIChatModeConfig?>()
                let config = MyAIChatModeConfig(chatId: chatID,
                                                aiChatModeId: chatModeID,
                                   objectId: "",
                                   objectType: .EMAIL)
                
                var contextDic:[String: String] = [:]
                if let content = mailContent {
                    contextDic["selected_mail_content"] = content
                }
                if let trim = isTrim {
                    contextDic["is_trimmed"] = trim ? "true" : "false"
                }
                contextDic["account_id"] = accountId
                contextDic["biz_ids"] = bizIds
                contextDic["label_id"] = labelId
                contextDic["mail_page_status"] = "reading"
                var triggerDic = ["mail_page_status":"reading"]
                if openRag {
                    contextDic["mail_rag_search"] = "enable"
                    triggerDic["mail_rag_search"] = "enable"
                }
                config.appContextDataProvider = {
                    return contextDic
                }
                config.triggerParamsProvider = {
                    return triggerDic
                }
                config.quickActionsParamsProvider = { (action) in
                    return contextDic
                }
                config.callBack = callback
                return Observable.just(config)
            }
            service.launchByType(.ai(provider))
        }
#endif
    }
    func openAIOnboarding(vc: UIViewController,
                          onSuccess: ((_ chatId: Int64) -> Void)?,
                          onError: ((_ error: Error?) -> Void)?,
                          onCancel: (() -> Void)?) {
#if MessengerMod
        if let service = try? resolver.resolve(assert: MyAIService.self) {
            service.openOnboarding(from: vc,
                                   onSuccess: onSuccess,
                                     onError: onError,
                                     onCancel: onCancel)
        }
#endif
    }
    private let resolver: UserResolver
    private let nickRelay: BehaviorRelay<String>
    private let disposeBag = DisposeBag()
    
    init(resolver: UserResolver) {
        self.resolver = resolver
        self.nickRelay = BehaviorRelay<String>(value: "")
#if MessengerMod
        if let aiService = try? resolver.resolve(assert: MyAIService.self) {
            aiService.info
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] info in
                self?.nickRelay.accept(info.name)
            }).disposed(by: disposeBag)
        }
#endif
    }
}
