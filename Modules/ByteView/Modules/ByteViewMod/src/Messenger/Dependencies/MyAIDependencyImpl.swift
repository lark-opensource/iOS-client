//
//  MyAIDependencyImpl.swift
//  ByteViewMod
//
//  Created by 陈乐辉 on 2023/8/3.
//

import Foundation
import ByteView
import ByteViewCommon
import LarkAIInfra
import LarkContainer
import LarkMessengerInterface
import RxSwift

final class MyAIDependencyImpl: MyAIDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func openMyAIChat(with config: MyAIChatConfig, from: UIViewController) {
        if let myAIService = try? userResolver.resolve(type: MyAIService.self) {
            myAIService.openMyAIChatMode(config: config.toMyAIChatModeConfig(), from: from, isFullScreenWhenPresent: true)
        }
    }

    func isMyAINeedOnboarding() -> Bool {
        if let myAIService = try? userResolver.resolve(type: MyAIService.self) {
            return myAIService.needOnboarding.value
        }
        return false
    }

    func openMyAIOnboarding(from: UIViewController, completion: @escaping ((Bool) -> Void)) {
        if let myAIService = try? userResolver.resolve(type: MyAIService.self) {
            myAIService.openOnboarding(from: from) { _ in
                Util.runInMainThread {
                    completion(true)
                }
            } onError: { _ in
                Util.runInMainThread {
                    completion(false)
                }
            } onCancel: {
                Util.runInMainThread {
                    completion(false)
                }
            }
        }
    }

    func isMyAIEnabled() -> Bool {
        if let myAIService = try? userResolver.resolve(type: MyAIService.self) {
            return myAIService.enable.value
        }
        return false
    }

    func observeName(with disposeBag: DisposeBag, observer: @escaping ((String) -> Void)) {
        if let myAIService = try? userResolver.resolve(type: MyAIService.self) {
            myAIService.info.subscribe { info in
                observer(info.name)
            }.disposed(by: disposeBag)
        } else {
            observer("")
        }
    }
}

extension MyAIChatConfig {

    func toMyAIChatModeConfig() -> MyAIChatModeConfig {
        let config = MyAIChatModeConfig(chatId: chatId, aiChatModeId: aiChatModeId, objectId: objectId, objectType: .MEETING, appContextDataProvider: {  [weak self] in
            self?.appContextDataProvider?() ?? [:]
        }, quickActionsParamsProvider: { [weak self] _ in
            self?.quickActionsParamsProvider?() ?? [:]
        }, callBack: { [weak self] pageService in
            guard let self = self else { return }
            pageService.isActive.subscribe { isActive in
                self.activeBlock?(isActive)
            }.disposed(by: self.disposeBag)
            self.pageService = pageService
            self.closeBlock = { [weak pageService] in
                pageService?.closeMyAIChatMode()
            }
        }, toolIds: toolIds)
        return config
    }
}
