//
//  RustMyAIToolServiceImpl.swift
//  LarkAI
//
//  Created by ByteDance on 2023/6/7.
//

import Foundation
import RxSwift
import LarkSDKInterface
import RustPB
import LKCommonsLogging
import LarkModel
import LarkRustClient
import LarkContainer
import LarkLocalizations
import ServerPB
import LarkUIKit
import LarkMessengerInterface

final class RustMyAIToolServiceImpl: RustMyAIToolServiceAPI {
    private let rustService: RustService?

    static let logger = Logger.log(RustMyAIToolServiceImpl.self, category: "Module.LarkAI.MyAITool")

    init(userResolver: UserResolver) {
        self.rustService = try? userResolver.resolve(assert: RustService.self)
    }

    public func getMyAIToolList(_ keyWord: String, pageNum: Int, pageSize: Int, _ scenario: String) -> Observable<([MyAIToolInfo], Bool)> {
        guard let rustService = self.rustService else { return .just(([], false)) }
        var request = RustPB.Im_V1_GetMyAIExtensionBasicInfoListRequest()
        request.pageNum = Int64(pageNum)
        request.pageSize = Int64(pageSize)
        request.scenario = scenario
        request.query = keyWord
        let response: Observable<RustPB.Im_V1_GetMyAIExtensionBasicInfoListResponse> = rustService.sendAsyncRequest(request)
        return response.flatMap { (res) -> Observable<([MyAIToolInfo], Bool)> in
            Observable.create { (observer) -> Disposable in
                let hasMore = res.hasMore_p
                let toolList = res.extensionList.map { MyAIToolInfo.transform(pb: $0) }
                observer.onNext((toolList, hasMore))
                observer.onCompleted()
                return Disposables.create()
            }
        }
        .do(onNext: { (_) in
            Self.logger.info("Get myAIToolList success")
        }, onError: { (error) in
            Self.logger.error("Get myAIToolList error", error: error)
        })
    }

    func getMyAIToolsInfo(toolIds: [String]) -> Observable<[MyAIToolInfo]> {
        guard let rustService = self.rustService else { return .just([]) }

        var request = RustPB.Im_V1_MGetMyAIExtensionBasicInfoRequest()
        request.extensionIds = toolIds
        let response: Observable<RustPB.Im_V1_MGetMyAIExtensionBasicInfoResponse> = rustService.sendAsyncRequest(request)
        return response.flatMap { (res) -> Observable<[MyAIToolInfo]> in
            Observable.create { (observer) -> Disposable in
                let toolList = res.extensionList.map { MyAIToolInfo.transform(pb: $0) }
                observer.onNext(toolList)
                observer.onCompleted()
                return Disposables.create()
            }
        }
        .do(onNext: { (_) in
            Self.logger.info("Get myAIToolList success")
        }, onError: { (error) in
            Self.logger.error("Get myAIToolList error", error: error)
        })
    }

    func sendMyAITools(toolIds: [String],
                       messageId: String,
                       aiChatModeID: Int64,
                       toolInfoList: [MyAIToolInfo]) -> Observable<Void> {
        guard let rustService = self.rustService else { return .just(()) }

        var request = ServerPB.ServerPB_Office_ai_PutToolsRequest()
        request.toolIds = toolIds
        request.messageID = Int64(messageId) ?? 0
        if !toolInfoList.isEmpty {
            var toolInfoMap: [String: ServerPB_Office_ai_ToolInfo] = [:]
            for info in toolInfoList {
                var tempInfo = info
                toolInfoMap[info.toolId] = tempInfo.transformServerToolInfo()
            }
            request.id2Tool = toolInfoMap
        }
        if aiChatModeID != 0 {
            request.aiChatModeID = aiChatModeID
        }
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiPutTools)
    }

    func getMyAIToolConfig() -> Observable<MyAIToolConfig> {
        guard let rustService = self.rustService else { return .just(MyAIToolConfig(maxSelectNum: 0, isFirstUseTool: false)) }
        let request = ServerPB.ServerPB_Office_ai_PullExtensionSettingsRequest()
        let response: Observable<ServerPB.ServerPB_Office_ai_PullExtensionSettingsResponse> = rustService.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiPullExtensionSettings)
        return response.flatMap { (res) -> Observable<MyAIToolConfig> in
            Observable.create { (observer) -> Disposable in
//                res.mode == ServerPB_Entities_ExtensionMode.single
                observer.onNext(MyAIToolConfig(maxSelectNum: Int(res.maxNum), isFirstUseTool: res.showNotice))
                observer.onCompleted()
                return Disposables.create()
            }
        }
        .do(onNext: { (_) in
            Self.logger.info("get myAIToolConfig success")
        }, onError: { (error) in
            Self.logger.error("get myAIToolConfig error", error: error)
        })
    }
}
