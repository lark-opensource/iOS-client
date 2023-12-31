//
//  UserInfoData.swift
//  SKCommon
//
//  Created by Guoxinyi on 2023/1/15.
//

import Foundation

public struct UserInfoData {
    
    public struct UserData {
        public let userId: String
        public let avatarUrl: String?
        public let userName: String?
        public let subTitle: String?
        public let rightDecs: String?
        
        // display_name 的 json value
        public init(data: [String: Any]) {
            userId = data["id"] as? String ?? ""
            avatarUrl = data["avatarUrl"] as? String
            userName = data["name"] as? String
            subTitle = data["department"] as? String
            rightDecs = nil
        }
    }
    
}
