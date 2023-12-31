//
//  InlineAIMentionModel.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/10/27.
//

import Foundation
import LarkModel

struct InlineAIMentionModel {
    /// 用户id
    var id: String
    /// 用户姓名
    var name: String?
    /// 头像URL
    var avatarURL: String?
    /// 部门
    var department: String?
}

extension InlineAIMentionModel {
    
    static func parseUsersFrom(rawString: String) -> [InlineAIMentionModel] {
        let rawData = rawString.data(using: .utf8) ?? Data()
        let json = try? JSONSerialization.jsonObject(with: rawData, options: .fragmentsAllowed)
        let dict = json as? [String: Any] ?? [:]
        
        guard let entities = dict["entities"] as? [String: Any] else { return [] }
        guard let users = entities["users"] as? [String: [String: Any]] else { return [] }
        var models = [InlineAIMentionModel]()
        for user in users.values {
            let userID = user["id"] as? String ?? ""
            var model = InlineAIMentionModel(id: userID)
            model.name = user["name"] as? String
            model.avatarURL = user["avatar_url"] as? String
            model.department = user["department"] as? String
            models.append(model)
        }
        return models
    }
    
    func asPickerChatter() -> PickerChatterMeta {
        var chatterMeta = PickerChatterMeta(id: self.id)
        chatterMeta.name = self.name
        chatterMeta.avatarUrl = self.avatarURL
        return chatterMeta
    }
}
