//
//  ShareTokenAPI.swift
//  LarkShareToken
//
//  Created by 赵冬 on 2020/4/21.
//

import Foundation
import LarkRustClient
import RustPB
import RxSwift
import LarkModel

public protocol ShareTokenAPI {
    func getShareTokenByTextRequest(text: String) -> Observable<(GetShareTokenByTextResponse)>
    func getShareTokenContentRequest(token: String) -> Observable<(GetShareTokenContentResponse)>
}

public class ShareTokenAPIImp: ShareTokenAPI {
    public let client: RustService

    public init(client: RustService) {
        self.client = client
    }

    public func getShareTokenByTextRequest(text: String) -> Observable<(GetShareTokenByTextResponse)> {
        var request = RustPB.Basic_V1_GetShareTokenByTextRequest()
        request.shareText = text
        return client.sendAsyncRequest(request)
    }

    public func getShareTokenContentRequest(token: String) -> Observable<(GetShareTokenContentResponse)> {
        var request = RustPB.Basic_V1_GetShareTokenContentRequest()
        request.shareToken = token
        return client.sendAsyncRequest(request)
    }
}
