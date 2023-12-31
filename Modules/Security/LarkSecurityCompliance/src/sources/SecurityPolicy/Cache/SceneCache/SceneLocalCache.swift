//
//  SceneLocalCache.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/6/20.
//

import Foundation
import LarkPolicyEngine

public struct SceneLocalCache: Codable, Equatable {
    let taskID: String
    let validateResponse: ValidateResponse
    var needDelete: Bool?
    var expirationTime: CFTimeInterval?

    init(taskID: String, validateResponse: ValidateResponse, needDelete: Bool = false, expirationTime: TimeInterval? = nil) {
        self.taskID = taskID
        self.validateResponse = validateResponse
        self.needDelete = needDelete
        self.expirationTime = expirationTime

    }

    mutating func markInvalid() {
        needDelete = true
    }

    public static func == (lhs: SceneLocalCache, rhs: SceneLocalCache) -> Bool {
        lhs.taskID == rhs.taskID
    }
}
