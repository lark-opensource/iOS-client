//
//  ChatExtensionFunctionsViewModel.swift
//  LarkChatSetting
//
//  Created by zc09v on 2020/5/18.
//
import Foundation
import LarkModel
import LarkBadge
import RxSwift
import LarkCore
import LarkContainer
import RxCocoa
import LarkOpenChat
import LKCommonsLogging

final class ChatExtensionFunctionsViewModel {
    static let logger = Logger.log(ChatExtensionFunctionsViewModel.self, category: "ChatExtensionFunctionsViewModel")
    //业务线factory注册
    private let factorysRegister: [ChatExtensionFunctionsFactory.Type] = [MessengerChatExtensionFunctionsFactory.self,
                                                                          TodoChatExtensionFunctionsFactory.self,
                                                                          CalendarChatExtensionFunctionsFactory.self
    ]
    // 开放模块注册的工厂
    private let moduleFatories: [ChatSettingFunctionItemsFactory]
    //共UI使用的刷新信号
    lazy var reload: Driver<Void> = {
        return reloadPublish.asDriver(onErrorJustReturn: ())
    }()
    //共UI使用的数据源
    private(set) var functions: [ChatExtensionFunction] = [] {
        didSet {
            reloadPublish.onNext(())
        }
    }

    private var reloadPublish: PublishSubject<Void> = PublishSubject<Void>()
    private var factorys: [ChatExtensionFunctionsFactory]
    private let disposeBag = DisposeBag()

    init(resolver: UserResolver,
         chatWrapper: ChatPushWrapper,
         pushCenter: PushNotificationCenter,
         moduleFatoryTypes: [ChatSettingFunctionItemsFactory.Type]) {
        self.factorys = self.factorysRegister.map({ (factoryType) -> ChatExtensionFunctionsFactory in
            return factoryType.init(userResolver: resolver)
        })
        self.moduleFatories = moduleFatoryTypes.map({ (factoryType) -> ChatSettingFunctionItemsFactory in
            return factoryType.init()
        })
        let chat = chatWrapper.chat.value
        let rootPath: Path = Path().prefix(Path().chat_id, with: chat.id).chat_more
        var subFunctionsObservables: [Observable<[ChatExtensionFunction]>] = []
        for factory in factorys {
            //收集各业务线子功能（信号）
            subFunctionsObservables.append(factory.createExtensionFuncs(chatWrapper: chatWrapper,
                                                                        pushCenter: pushCenter,
                                                                        rootPath: rootPath))
        }
        for factory in moduleFatories {
            //收集开放模块注册的items信号
            subFunctionsObservables.append(factory.createExtensionFuncs(chat: chatWrapper.chat.value,
                                                                        rootPath: rootPath))
        }
        let layout = LarkOpenChat.settingFuctionLayout
        //监听各业务线子功能变更
        Observable.combineLatest(subFunctionsObservables)
            .map { (subFunctions) -> [ChatExtensionFunction] in
                return subFunctions.flatMap { return $0 }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (functions) in
                let layoutedFunctions = layout.items.compactMap { identify in
                    return functions.first(where: { $0.type.rawValue == identify })
                }
                self?.functions = layoutedFunctions
            }, onError: { (error) in
                ChatExtensionFunctionsViewModel.logger.error("subFunctionsObservables error \(chat.id)", error: error)
            }).disposed(by: self.disposeBag)
    }
}
