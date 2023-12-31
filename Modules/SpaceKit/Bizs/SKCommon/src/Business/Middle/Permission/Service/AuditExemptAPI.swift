//
//  AuditExemptAPI.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/11/23.
//

import Foundation
import SKFoundation
import RxSwift
import SpaceInterface
import SKInfra
import SwiftyJSON

public enum AuditExemptAPI {

    public enum ExemptType: String {
        case view
        case edit
    }

    public static func requestExempt(objToken: String, objType: DocsType, exemptType: ExemptType, reason: String?) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.applyExemptAuditControl,
                                        params: [
                                            "token": objToken,
                                            "obj_type": objType.rawValue,
                                            "action": exemptType.rawValue,
                                            "remark": reason ?? "",
                                            "approval_type": 1
                                        ])
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart().asCompletable()
    }

    public enum ExemptError: Error {
        case tooFrequent
        case other(error: Error)
    }

    public static func parse(error: Error) -> ExemptError {
        if let docsError = error as? DocsNetworkError,
           docsError.code == .tooFrequent {
            return .tooFrequent
        }
        return .other(error: error)
    }
}
