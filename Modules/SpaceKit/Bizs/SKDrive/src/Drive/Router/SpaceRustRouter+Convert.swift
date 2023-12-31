//
//  SpaceRustRouter+Convert.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/5/13.
//

import Foundation
import RxSwift
import RustPB
import LarkRustClient

// MARK: - IM附件转在线文档
public typealias GetConvertTokenRequest = Space_Doc_V1_GetConvertTokenRequest
public typealias GetConvertTokenResponse = Space_Doc_V1_GetConvertTokenResponse
public enum ConvertChatFileError: Error, LocalizedError {
    case rustServiceNotInitailzed
}
extension SpaceRustRouter {
    struct ConvertInfo {
        let token: String
        let chatToken: String
    }
    // params:
    // - msgID: 附件对应的messageID
    // returns:
    // - token: 附件token
    // - chatToken: 获取chat信息的token
    func getConvertToken(msgID: String) -> Observable<ConvertInfo> {
        var req = GetConvertTokenRequest()
        req.messageID = msgID
        guard let service = self.rustService else {
            SpaceRustRouter.logger.warn("Rust service can not be nil")
            return .error(ConvertChatFileError.rustServiceNotInitailzed)
        }

        return service.sendAsyncRequest(req) { (resp: GetConvertTokenResponse) -> ConvertInfo in
            return ConvertInfo(token: resp.token, chatToken: resp.chatToken)
        }
    }
}
