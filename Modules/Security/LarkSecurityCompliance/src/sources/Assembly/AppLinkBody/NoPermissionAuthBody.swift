//
//  NoPermissionAuthBody.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/19.
//

import Foundation
import EENavigator

public struct NoPermissionAuthBody: CodablePlainBody {

    public static let pattern: String = "/client/security/bind_device"

    public let webId: String
    public let userId: String
    public let scheme: String

    public init(webId: String, scheme: String, userId: String) {
        self.webId = webId
        self.scheme = scheme
        self.userId = userId
    }
}
