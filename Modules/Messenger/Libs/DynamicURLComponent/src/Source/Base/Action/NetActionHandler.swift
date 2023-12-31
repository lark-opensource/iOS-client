//
//  NetActionHandler.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/11/30.
//

import Foundation
import RustPB
import LarkModel
import RxSwift
import LarkRustClient

/// get & post & larkCommand
public struct NetActionHandler: ActionBaseHandler {
    public static func handleAction(entity: URLPreviewEntity?,
                                    action: Basic_V1_UrlPreviewAction,
                                    actionID: String,
                                    dependency: URLCardDependency,
                                    completion: ActionCompletionHandler?,
                                    actionDepth: Int) {
        assert((action.method == .get || action.method == .post || action.method == .larkCommand), "invalidate method")
        var parameters: Basic_V1_UrlPreviewAction.Parameters
        if action.method == .get {
            parameters = action.get.parameters
        } else if action.method == .post {
            parameters = action.post.parameters
        } else if action.method == .larkCommand {
            parameters = action.command.parameters
        } else {
            parameters = Basic_V1_UrlPreviewAction.Parameters()
        }
        var request = Im_V1_PutUrlPreviewActionRequest()
        request.sourceID = parameters.sourceID
        request.previewID = parameters.previewID
        request.actionID = actionID
        let rustService = try? dependency.userResolver.resolve(assert: RustService.self)
        _ = rustService?.sendAsyncRequest(request)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak dependency] (response: Im_V1_PutUrlPreviewActionResponse) in
                guard let dependency = dependency else { return }
                let depth = actionDepth + 1
                response.actions.forEach { resActionID, resAction in
                    ComponentActionRegistry.handleAction(entity: entity, action: resAction, actionID: resActionID, dependency: dependency, actionDepth: depth)
                }
                completion?(nil)
            }, onError: { error in
                ComponentActionRegistry.logger.error(
                    "handle get or post action error",
                    additionalData: ["actionID": actionID,
                                     "sourceID": parameters.sourceID,
                                     "previewID": parameters.previewID],
                    error: error
                )
                completion?(error)
            })
    }
}
