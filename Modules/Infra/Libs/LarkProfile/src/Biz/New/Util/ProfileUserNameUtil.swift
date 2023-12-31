//
//  ProfileUserNameUtil.swift
//  LarkProfile
//
//  Created by ByteDance on 2023/3/14.
//

import RustPB
import LKCommonsLogging
import LarkSetting
import LarkSDKInterface

final class ProfileUserNameUtil {
    static let logger = Logger.log(ProfileUserNameUtil.self, category: "ProfileUserNameUtil")    
}

extension UserInfoProtocol {
    func displayName(with service: UserUniversalSettingService?) -> String {
        let isShowBilingualName = (service?.getIntUniversalUserSetting(key: "PROFILE_NAME_DISPLAY_TYPE") ?? 0) == 1
        ProfileUserNameUtil.logger.info("get bilingualName FG: \(isShowBilingualName)")
        if isShowBilingualName {
            //最新逻辑-显示多语言名称
            /**
             展示规则：
             1. 英文环境：i18n_name + (默认名)，非英文环境：i18n_name + (英文名)
             2. 没有配置多语言，直接展示默认名
             3. 如果两个名称相同，去重只展示一个
             */
            ProfileUserNameUtil.logger.info("profileUserName isEmpty: \(profileUserName.isEmpty) userName isEmpty: \(userName.isEmpty)")
            return profileUserName.isEmpty ? userName : profileUserName
        } else {
            // userName：i18n_name(对应ORM的多语言姓名)，如果为空会取chatter.name(对应ORM的默认名Value)
            // nameWithAnotherName：如果别名为空，name_with_another_name = localized_name(i18n_name),否则会依据admin配置的展示规则拼接 别名 (localized_name) 或 localized_name (别名)
            ProfileUserNameUtil.logger.info("nameWithAnotherName isEmpty: \(nameWithAnotherName.isEmpty) userName isEmpty: \(userName.isEmpty)")
            return nameWithAnotherName.isEmpty ? userName : nameWithAnotherName
        }
    }
}
