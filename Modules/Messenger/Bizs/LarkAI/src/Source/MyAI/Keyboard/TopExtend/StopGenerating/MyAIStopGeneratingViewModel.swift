//
//  MyAIStopGeneratingViewModel.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/23.
//

import Foundation
import RxSwift
import RxCocoa
import LarkCore
import ServerPB
import LarkModel
import LarkContainer
import LarkRustClient
import AsyncComponent
import LarkSDKInterface
import LarkMessengerInterface

final class MyAIStopGeneratingViewModel {
    private let rustClient: RustService?
    private let userResolver: UserResolver
    private let myAIPageService: MyAIPageService?
    private let disposeBag = DisposeBag()
    private let chat: Chat

    /// 显隐信号
    public private(set) var currIsShow: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    init(userResolver: UserResolver, chat: Chat) {
        self.userResolver = userResolver
        self.rustClient = try? userResolver.resolve(type: RustService.self)
        self.myAIPageService = try? userResolver.resolve(type: MyAIPageService.self)
        self.chat = chat
        // 监听AIRoundInfo
        guard let myAIPageService = self.myAIPageService else { return }
        myAIPageService.aiRoundInfo.filter({ $0.chatId != AIRoundInfo.default.chatId }).subscribe(onNext: { [weak self] (info) in
            guard let `self` = self else { return }
            MyAITopExtendSubModule.logger.info("my ai StopGenerating currIsShow: \(info.status == .responding)")
            let isShow = info.status == .responding
            self.currIsShow.accept(isShow)
        }).disposed(by: self.disposeBag)
    }

    func clickStopGenerating(onSuccess: (() -> Void)?, onError: ((Error) -> Void)?) {
        MyAITopExtendSubModule.logger.info("my ai click stop")
        guard let myAIPageService = self.myAIPageService else {
            MyAITopExtendSubModule.logger.info("my ai click stop error, service is none")
            return
        }

        IMTracker.Chat.Main.Click.stopResponding(
            self.chat,
            params: myAIPageService.chatMode ? ["app_name": myAIPageService.chatModeConfig.extra["app_name"] ?? "other"] : [:],
            myAIPageService.chatFromWhere
        )

        let aiRoundInfo = myAIPageService.aiRoundInfo.value
        var request = ServerPB_Office_ai_AIChatStopGenerateRequest()
        request.chatID = Int64(self.chat.id) ?? 0
        request.roundID = aiRoundInfo.roundId
        if self.myAIPageService?.chatMode ?? false { request.aiChatModeID = myAIPageService.chatModeConfig.aiChatModeId }
        self.rustClient?.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiImStopGenerate).observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            MyAITopExtendSubModule.logger.info("my ai stop success")
            onSuccess?()
        }, onError: { error in
            MyAITopExtendSubModule.logger.info("my ai stop error: \(error)")
            onError?(error)
        }).disposed(by: self.disposeBag)
    }
}
