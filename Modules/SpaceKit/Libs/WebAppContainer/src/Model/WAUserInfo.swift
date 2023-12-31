//
//  WAUserInfo.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/29.
//

import Foundation


public protocol WAUserInfoProtocol {
    var userId: String { get }
    var tenantId: String { get }
    var avatarUrl: String { get }
    var avatarKey: String { get }
    var gender: String { get }
    
    func toDic() -> [String: Any]
}

public struct WAUserInfo: WAUserInfoProtocol, Codable {
    public var userId: String
    
    public var tenantId: String
    
    public var avatarUrl: String
    
    public var avatarKey: String
    
    public var gender: String
    
    public init(userId: String,
                tenantId: String,
                avatarUrl: String,
                avatarKey: String,
                gender: String) {
        self.userId = userId
        self.tenantId = tenantId
        self.avatarUrl = avatarUrl
        self.avatarKey = avatarKey
        self.gender = gender
    }

    
    public func toDic() -> [String : Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}
