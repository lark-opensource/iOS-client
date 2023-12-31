//
//  MyAIToolsSelectedViewModel.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/5/30.
//

import UIKit
import Foundation
import LarkMessengerInterface
import LarkModel
import LarkContainer
import RxSwift
import RxCocoa

final class MyAIToolsSelectedViewModel {

    private let myAIToolRustService: RustMyAIToolServiceAPI?
    /// tools 回调
    var status = PublishSubject<MyAIToolsSelectedStatus>()

    private(set) var tools: [MyAIToolInfo] = []

    private(set) var toolIds: [String] = []
    private(set) var aiChatModeId: Int64 = 0
    private var myAIPageService: MyAIPageService?

    private let disposeBag = DisposeBag()

    init(toolItems: [MyAIToolInfo],
         aiChatModeId: Int64,
         userResolver: UserResolver,
         myAIPageService: MyAIPageService?) {
        self.tools = toolItems
        self.aiChatModeId = aiChatModeId
        self.myAIPageService = myAIPageService
        self.myAIToolRustService = try? userResolver.resolve(assert: RustMyAIToolServiceAPI.self)
    }

    init(toolIds: [String],
         aiChatModeId: Int64,
         userResolver: UserResolver,
         myAIPageService: MyAIPageService?) {
        self.toolIds = toolIds
        self.aiChatModeId = aiChatModeId
        self.myAIPageService = myAIPageService
        self.myAIToolRustService = try? userResolver.resolve(assert: RustMyAIToolServiceAPI.self)
    }

    func loadToolsInfo() {
        guard !toolIds.isEmpty else {
            self.status.onNext(tools.isEmpty ? .empty : .loadComplete)
            return
        }
        status.onNext(.loading)
        myAIToolRustService?.getMyAIToolsInfo(toolIds: self.toolIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (tools) in
                guard let self = self else { return }
                MyAIToolsSelectedViewController.logger.info("load selectedToolsInfo success")
                self.tools = tools.map { toolItem in
                    var tool = MyAIToolInfo(toolId: "", toolName: "", toolAvatar: "", toolDesc: "")
                    tool.transform(toolInfo: toolItem)
                    tool.isSelected = true
                    tool.enabled = false
                    return tool
                }
                self.status.onNext(tools.isEmpty ? .empty : .loadComplete)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                MyAIToolsSelectedViewController.logger.info("load selectedToolsInfo failure error: \(error)")
                self.status.onNext(.error(error))
            }).disposed(by: self.disposeBag)
    }

    func teaEventParams(extra: [AnyHashable: Any]) -> [AnyHashable: Any] {
        var params: [AnyHashable: Any] = [:]
        params["msg_id"] = extra["messageId"] ?? ""
        params["chat_id"] = extra["chatId"] ?? ""
        params["source"] = extra["source"] ?? ""
        params["type"] = "extensionDetail"
        if self.myAIPageService?.chatMode ?? false {
            params["app_name"] = self.myAIPageService?.chatModeConfig.extra["app_name"] ?? "other"
        } else {
            params["app_name"] = "other"
        }
        return params
    }
}

public enum MyAIToolsSelectedStatus {
    case error(Error)
    case loading
    case loadComplete
    case empty
}
