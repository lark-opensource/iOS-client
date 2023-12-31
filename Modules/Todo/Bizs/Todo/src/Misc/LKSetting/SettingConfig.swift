//
//  SettingConfig.swift
//  Todo
//
//  Created by wangwanxin on 2021/8/18.
//

import LarkSetting
import LarkContainer

final class SettingConfig: UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    var config: TodoConfig? {
        return try? userResolver.settings.setting(with: TodoConfig.self)
    }

}

struct TodoConfig: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "todo_config")

    let assigneeLimit: Int
    let followerLimit: Int
    let summaryLimit: Int
    let notesLimit: Int
    let commentLimit: Int

    enum CodingKeys: String, CodingKey {
        case assigneeLimit = "assignee_limit"
        case followerLimit = "follower_limit"
        case summaryLimit = "title_limit"
        case notesLimit = "description_limit"
        case commentLimit = "comment_limit"
    }
}

// setting 的默认值集中位置，忽略魔法数约束
// nolint: magic number
extension SettingConfig {

    /// 执行者上限
    var getAssingeeLimit: Int {
        return config?.assigneeLimit ?? 500
    }

    /// 关注者上限
    var getFollowerLimit: Int {
        return config?.followerLimit ?? 500
    }

}

extension SettingConfig {

    /// 标题上限
    var summaryLimit: Int {
        return config?.summaryLimit ?? 3_000
    }

    /// 备注上限
    var notesLimit: Int {
        return config?.notesLimit ?? 3_000
    }

    /// 评论上限
    var commentLimit: Int {
        return config?.commentLimit ?? 10_000
    }

}
