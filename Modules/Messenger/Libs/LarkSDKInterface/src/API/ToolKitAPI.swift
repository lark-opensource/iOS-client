//
//  ToolKitAPI.swift
//  LarkSDKInterface
//
//  Created by JackZhao on 2022/6/21.
//

import Foundation
import RustPB
import RxSwift
import ServerPB
import LarkModel

public typealias PullChatToolKitsResponce = RustPB.Im_V1_GetChatToolkitsResponse
public typealias ToolKitActionResponce = ServerPB.ServerPB_Im_oapi_ToolKitActionResponse

public enum ToolKitActionType: Equatable {
    case unknown
    case redirectUrl(_ iosUrl: String, _ commonUrl: String)
    case callback

    public static func == (lhs: ToolKitActionType, rhs: ToolKitActionType) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown), (.callback, .callback):
            return true
        case (.redirectUrl(let lhsIosUrl, let lhsCommonUrl), .redirectUrl(let rhsIosUrl, let rhsCommonUrl)):
            return (lhsIosUrl == rhsIosUrl) && (lhsCommonUrl == rhsCommonUrl)
        default:
            return false
        }
    }
}

public protocol ToolKit {
    var appTenantID: Int64 { get }
    var id: Int64 { get }
    var name: String { get }
    var hasImageKey: Bool { get }
    var imageKey: String { get }
    var type: ToolKitActionType? { get }
    var extra: [String: String] { get }
}

extension RustPB.Basic_V1_Toolkit: ToolKit {
    public var hasImageKey: Bool {
        !self.imageKey.isEmpty
    }

    public var type: ToolKitActionType? {
        switch self.actionType {
        case .appLink:
            return .redirectUrl(self.appLink.iosURL, self.appLink.commonURL)
        case .callback:
            return .callback
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}

public protocol ToolKitAPI {
    func pullChatToolKitsRequest(chatId: String) -> Observable<PullChatToolKitsResponce>
    func toolKitActionRequest(cid: String,
                              userId: Int64,
                              appTenantID: Int64,
                              chatId: Int64,
                              toolKitId: Int64,
                              extra: [String: String]) -> Observable<ToolKitActionResponce>
}
