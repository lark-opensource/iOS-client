//
//  UserUniversalSettingService.swift
//  LarkSDKInterface
//
//  Created by zhangxingcheng on 2021/7/8.
//

import Foundation
import RustPB
import RxSwift

public enum UserUniversalSettingKey {

}

public extension UserUniversalSettingKey {
    enum ChatLastPostionSetting: Int64 {
        case recentLeft = 1
        case lastUnRead = 2
    }
}

public typealias UserUniversalSettingValue = RustPB.Basic_V1_UniversalUserSetting.OneOf_Value

/**消息转发类*/
public protocol UserUniversalSettingService {
    /**通过key获取*/
    func getUniversalUserSetting(key: String) -> UserUniversalSettingValue?
    func getIntUniversalUserSetting(key: String) -> Int64?
    func getStringUniversalUserSetting(key: String) -> String?
    func getBoolUniversalUserSetting(key: String) -> Bool?
    /**通过信号获取（oneof value）*/
    func getIntUniversalUserObservableSetting(key: String) -> Observable<Int64?>
    func getStringUniversalUserObservableSetting(key: String) -> Observable<String?>
    func getBoolUniversalUserObservableSetting(key: String) -> Observable<Bool?>
    func getUniversalUserObservableSetting(key: String) -> Observable<RustPB.Basic_V1_UniversalUserSetting.OneOf_Value?>
    /**通过values更新本地对应key的状态*/
    func setUniversalUserConfig(values: [String: UserUniversalSettingValue]) -> Observable<Void>
    /**拉取远端数据*/
    func setupUserUniversalInfo()
}
