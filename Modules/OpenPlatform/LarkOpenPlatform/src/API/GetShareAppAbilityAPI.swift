//
//  GetShareAppAbilityAPI.swift
//  LarkOpenPlatform
//
//  Created by Meng on 2020/11/25.
//

import Foundation
import SwiftyJSON
import LarkFoundation
import LarkUIKit
import LarkContainer

extension OpenPlatformAPI {
    public static func getShareAppInfoAPI(appId: String, resolver: UserResolver) -> OpenPlatformAPI {
        let platform = Display.pad ? PlatformType.iPad : PlatformType.iphone
        return OpenPlatformAPI(path: .getShareAppInfo, resolver: resolver)
            .appendParam(key: .cli_id, value: appId)
            .appendParam(key: .platform, value: platform.rawValue)
            .appendParam(key: .lark_version, value: Utils.appVersion)
            .setScope(.shareApp)
            .useSession()
            .useLocale()
    }
}

class GetShareAppInfoResponse: APIResponse {
    /// 应用id
    var appId: String? {
        return json["data"]["cli_id"].string
    }

    /// 应用名称
    var name: String? {
        return json["data"]["name"].string
    }

    /// 应用描述
    var desc: String? {
        return json["data"]["desc"].string
    }

    /// 国际化应用名称
    var i18nNames: [String: String] {
        return json["data"]["i18n_names"].dictionary?
            .reduce(into: [String: String](), { (result, map) in
                if let value = map.value.string {
                    result[map.key] = value
                }
            }) ?? [:]
    }

    /// 国际化应用描述
    var i18nDescs: [String: String] {
        return json["data"]["i18n_descs"].dictionary?
            .reduce(into: [String: String](), { (result, map) in
                if let value = map.value.string {
                    result[map.key] = value
                }
            }) ?? [:]
    }

    /// 应用icon
    var avatarKey: String? {
        return json["data"]["avatar_key"].string
    }

    /// extra信息
    var extra: ApplinkExtra {
        return ApplinkExtra(json: json["data"]["extra"])
    }

    /// 应用优先能力（计算开发者后台指定的「能力」 + 「默认能力顺序」）
    var appAbility: AppAbility? {
        return json["data"]["app_ability"].int.flatMap({ AppAbility(rawValue: $0) })
    }

    var resultCode: ResultCode? {
        return code.map({ ResultCode(rawValue: $0) })
    }
}

extension GetShareAppInfoResponse {
    enum AppAbility: Int, CustomStringConvertible {
        case gadget = 1
        case h5 = 2
        case bot = 3

        var description: String {
            switch self {
            case .gadget:
                return "gadget"
            case .h5:
                return "h5"
            case .bot:
                return "bot"
            }
        }
    }

    struct ApplinkExtra {
        private let json: JSON

        /// 默认支持的 PC 打开 mode
        var mode: String? {
            return json["mp_mode"].string
        }

        /// 是否支持 PC 小程序
        var supportPCMicroApp: Bool {
            return json["support_pc_mp"].bool ?? false
        }

        /// 是否支持 mobile 小程序
        var supportMobileMicroApp: Bool {
            return json["support_mobile_mp"].bool ?? false
        }

        /// 是否支持 PC WebApp
        var supportPCWebApp: Bool {
            return json["support_pc_web_app"].bool ?? false
        }

        /// 是否支持 mobile WebApp
        var supportMobileWebApp: Bool {
            return json["support_mobile_web_app"].bool ?? false
        }

        var supportPC: Bool {
            return supportPCMicroApp || supportPCWebApp
        }

        init(json: JSON) {
            self.json = json
        }
    }

    /// 用户可感知的code
    enum ResultCode: RawRepresentable, CustomStringConvertible {
        /// 成功（至少有应用可以查到）
        case success // = 0
        /// 无此应用
        case noApplication // = 11003
        /// 服务端错误, 用户不感知详细类型
        case server(Int)

        var rawValue: Int {
            switch self {
            case .success:
                return 0
            case .noApplication:
                return 11003
            case let .server(code):
                return code
            }
        }

        init(rawValue: Int) {
            switch rawValue {
            case 0:
                self = .success
            case 11003:
                self = .noApplication
            default:
                self = .server(rawValue)
            }
        }

        var isSuccess: Bool {
            if case .success = self {
                return true
            }
            return false
        }

        var description: String {
            return String(rawValue)
        }
    }
}
