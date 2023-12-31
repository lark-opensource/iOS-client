//
//  RustDraftAPI.swift
//  Lark-Rust
//
//  Created by lichen on 2017/12/16.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import RxSwift
import LarkSDKInterface
import LKCommonsLogging
import LarkRustClient

final class RustDraftAPI: LarkAPI, DraftAPI {
    static let logger = Logger.log(RustDraftAPI.self, category: "RustSDK.Draft")

    func saveDraft(_ draft: Draft) -> Observable<Draft> {
        var request = RustPB.Im_V1_CreateDraftRequest()
        request.draft = draft
        return client.sendAsyncRequest(request) { (response: CreateDraftResponse) -> Draft in
            return response.draft
        }
    }

    func deleteDraft(key: String) -> Observable<Void> {
        var request = RustPB.Im_V1_DeleteDraftRequest()
        request.draftID = key
        return client.sendAsyncRequest(request)
    }

    func getDraft(keys: [String]) -> Observable<[String: Draft]> {
        var request = RustPB.Im_V1_GetDraftsRequest()
        request.draftIds = keys
        return client.sendAsyncRequest(request) { (response: Im_V1_GetDraftsResponse) -> [String: Draft] in
            return response.entity.drafts
        }
    }

    func fetchDefaultTopicGroupDraft() -> Observable<Draft> {
        var request = RustPB.Im_V1_GetDraftByEditorRequest()
        request.type = .individualTopic
        return client.sendAsyncRequest(request) { (response: Im_V1_GetDraftByEditorResponse) -> Draft in
            return response.draft
        }
    }
}
