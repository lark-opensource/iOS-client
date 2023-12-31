//
//  PassportGray.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/1/10.
//

import Foundation
import RxSwift
import LarkContainer
import LarkStorage
import LKCommonsLogging

enum PassportGrayKey: String, CaseIterable {

    // 如果需要设置默认值，在defaultValue()里面追加，默认为false
    // 在这里新增技术开关时，请尽量带上相关信息：
    // 开关功能、作者、上线版本、预期移除版本

    // 统一did开关
    case enableUniversalDid = "uni_did"

    // enterApp流程用户列表逻辑调整开关 / jinjian.au / v6.5 上线 / 当前版本全量后下线
    case enableEnterAppUserListFixing = "enable_enter_app_user_list_fixing"
    case enableSSOManualTransferDialog = "sso_manual_transfer_dialog"
    
    // 是否开启LarkGlobal注册流程离线化 / zhaokejie / v7.3上线 / 功能全量后下线
    case enableLarkGlobalOffline = "enable_lark_global_offline"
    
    // 开启敏感JsAPI调用来源域名检测 / zhaokejie / v7.1 上线 / 回收数据后功能全量下线
    case enableSensitiveJsApiCheck = "enable_sensitive_js_api_check"

    // 用户态迁移-Rust部分 / jinjian.au / v7.3 / 功能全量后下线
    case enableUserScopeTransitionRust = "enable_user_scope_transition_rust"
    // 用户态迁移-Account服务部分 / jinjian.au / v7.4 / 功能全量后下线
    case enableUserScopeTransitionAccount = "enable_user_scope_transition_account"

    // 灰度开关的默认值，默认false
    func defaultValue() -> Bool {
        switch self {
        default:
            return false
        }
    }
}

final class PassportGray {

    public static let shared = PassportGray()

    private static let logger = Logger.log(PassportGray.self, category: "PassportGray")

    @Provider var client: HTTPClient

    private lazy var grayMap: [String: Bool] = PassportStore.value(forKey: PassportStore.PassportStoreKey.passportGaryMap) ?? [:] {
        didSet {
            PassportStore.set(grayMap, forKey: PassportStore.PassportStoreKey.passportGaryMap)
            PassportGrayDelegateRegistry.factories.forEach { factory in
                factory.delegate.grayConfigDidSet(map: grayMap)
            }
        }
    }

    private init() {}

    public func getGrayValue(key: PassportGrayKey) -> Bool {
        if Thread.isMainThread {
            //直接返回
            return grayMap[key.rawValue] ?? key.defaultValue()
        } else {
            //子线程同步到主线程获取
            var grayValue: Bool = key.defaultValue()
            DispatchQueue.main.sync {
                grayValue = grayMap[key.rawValue] ?? key.defaultValue()
            }
            return grayValue
        }
    }

}

extension PassportGray {

    public func refreshConfig() {
        let request = ConfigRequest<V3.CommonResponse<[String: PassportGrayItem]>>(pathSuffix: APPID.grayConfig.apiIdentify())
        request.domain = .passportAccounts(usingPackageDomain: true)//gray接口需要包域名
        request.method = .post
        request.body = ["gray_keys": PassportGrayKey.allCases.map { $0.rawValue }]
        client.send(request, success: { [weak self] (resp, _) in
            if let data = resp.dataInfo {
                data.forEach { (key, grayItem) in
                    if grayItem.code == 0 {
                        self?.grayMap[key] = grayItem.isOn
                    }
                }
            }
        }, failure: { error in
            Self.logger.error("Failed to load config: \(error)")
        })
    }

    public func resetData() {
        self.grayMap = [:]
    }
}
