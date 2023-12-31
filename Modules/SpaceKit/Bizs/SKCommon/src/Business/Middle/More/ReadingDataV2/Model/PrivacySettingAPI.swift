//
//  PrivacySettingAPI.swift
//  SKCommon
//
//  Created by peilongfei on 2023/12/20.
//  


import SKFoundation
import SwiftyJSON
import RxSwift
import SKInfra

protocol PrivacySettingAPIType {
    func requestAdminReadPrivacyStatus(token: String, type: Int) -> Single<Bool>
    func requestAdminAvatarStatus() -> Single<Bool>
    func requestPrivacySetting() -> Single<JSON?>
    func requestModifyPrivacySetting(isOn: Bool, model: SwitchSettingModel) -> Single<Bool>
}

class PrivacySettingAPI: PrivacySettingAPIType {

    func requestAdminReadPrivacyStatus(token: String, type: Int) -> Single<Bool> {
        let pageSize = 20
        let path = OpenAPI.APIPath.getReadRecordInfo + "?obj_type=\(type)&token=\(token)&get_view_count=\(true)&page_size=\(pageSize)"
        return DocsRequest<JSON>(path: path, params: nil)
            .set(method: .GET)
            .rxStart()
            .map({ json in
                if let code = json?["code"].int, code == 8 {
                    return false
                }
                return true
            })
            .catchError { error in
                DocsLogger.error("requestAdminReadPrivacyStatus failed!", error: error)
                if let err = error as? NSError, err.code == 8 {
                    return .just(false)
                }
                return .just(true)
            }
    }

    func requestAdminAvatarStatus() -> Single<Bool> {
        let path = OpenAPI.APIPath.getAdminTenantSetting
        let settingKey = "allow_config_show_collaboration_avatar"
        let params = ["settingKey": settingKey]
        return DocsRequest<JSON>(path: path, params: params)
            .set(method: .GET)
            .rxStart()
            .map({ json in
                if let code = json?["code"].int, code == 0 {
                    let avatarSetting = json?["data"]["setting"].array?.filter { setting in
                        return setting["settingKey"].string == settingKey
                    }.first
                    return avatarSetting?["enabled"].bool ?? false
                }
                return false
            })
            .do(onError: { error in
                DocsLogger.error("requestAdminAvatarStatus failed!", error: error)
            })
            .catchErrorJustReturn(false)
    }

    func requestPrivacySetting() -> Single<JSON?> {
        return DocsRequest<JSON>(path: OpenAPI.APIPath.getUserProperties, params: nil)
            .set(method: .GET)
            .rxStart()
            .map({ json in
                return json?["data"]["settings"]
            })
            .do(onError: { error in
                DocsLogger.error("requestPrivacySetting failed!", error: error)
            })
            .catchErrorJustReturn(nil)
    }

    func requestModifyPrivacySetting(isOn: Bool, model: SwitchSettingModel) -> Single<Bool> {
        let params = ["properties": [model.property: isOn]]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.setUserProperties, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .rxStart()
            .map({ json in
                if let code = json?["code"], code == 0 {
                    return true
                }
                return false
            })
            .do(onError: { error in
                DocsLogger.error("requestModifyPrivacySetting failed!", error: error)
            })
    }
}
