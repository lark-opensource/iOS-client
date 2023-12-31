//
//  WPHomeDataStructure.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/12/21.
//

import Foundation
import SwiftyJSON
import LKCommonsLogging

// MARK: - server 服务端返回数据结构
struct WPPortalTemplate: Codable {
    struct LowCodeData: Codable {
        let md5: String
        let templateFileUrl: String
        let backupTemplateUrls: [String]?
        let minClientVersion: String?
    }

    struct WebData: Codable {
        let refAppId: String
        let refAppData: String?
    }

    struct UpdateInfo: Codable {
        enum UpdateType: String, Codable {
            /// 提示更新
            case prompt
            /// 静默更新
            case silent
            /// 强制更新
            case force
        }
        /// 更新类型
        let updateType: UpdateType
        /// 更新标题
        let updateTitle: String
        /// 更新说明
        let updateRemark: String
    }

    let data: String?
    let iconKey: String?
    let name: String?
    let id: String
    let tplType: String
    /// 预览接口使用
    let tplId: String?

    /// 工作台模版更新信息  5.12
    let updateInfo: UpdateInfo?
}

// MARK: - client - 客户端构建的「门户」抽象数据结构
struct WPPortal: Codable {
    static let logger = Logger.log(WPPortal.self)

    enum PortalType: String, Codable {
        case normal = "WPNormal"
        case lowCode = "LowCodeTpl"
        case web = "H5Tpl"
    }

    /// 门户类型
    let type: PortalType

    /// 服务端给的原始数据
    let template: WPPortalTemplate?
}

extension WPPortal {
    var badgeLoadType: BadgeLoadType {
        switch type {
        case .normal:
            return .appCenter
        case .lowCode, .web:
            return .workplace(nil)
        }
    }
}

extension WPPortal {
    /// 构建一个普通门户
    static func normalPortal() -> WPPortal {
        WPPortal(type: .normal, template: nil)
    }

    /// 构建一个模板门户
    static func templatePortal(with template: WPPortalTemplate) -> WPPortal? {
        guard let type = PortalType(rawValue: template.tplType) else {
            Self.logger.error("[portal] template type not support: \(template.tplType)")
            return nil
        }
        return WPPortal(type: type, template: template)
    }

    /// 获取门户的标题
    var title: String {
        guard let tmpl = template else {
            if type == .normal {
                /// 普通工作台，返回“工作台”
                return BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Title
            } else {
                /// 目前除了普通工作台都有模板，正常不应该走进这里
                assertionFailure()
                return ""
            }
        }

        /// 非普通类型的工作台，使用模板返回的标题
        return tmpl.name ?? BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Title
    }
}

extension WPPortal: Equatable {
    static func == (lhs: WPPortal, rhs: WPPortal) -> Bool {
        guard lhs.type == rhs.type else {
            return false
        }
        switch lhs.type {
        case .normal:
            return true
        case .lowCode:
            if let dataA = WPHomeVCInitData.LowCode(lhs), let dataB = WPHomeVCInitData.LowCode(rhs) {
                return dataA == dataB
            }
            return false
        case .web:
            if let dataA = WPHomeVCInitData.Web(lhs), let dataB = WPHomeVCInitData.Web(rhs) {
                return dataA == dataB
            }
            return false
        }
    }

    func isSameID(with another: WPPortal) -> Bool {
        guard type == another.type else {
            // 类型不一样，必定不是同一个门户
            return false
        }
        guard type != .normal else {
            // 普通门户，都视为同一个
            return true
        }
        guard let id1 = template?.id, let id2 = another.template?.id else {
            // 其它门户，类型相同、ID 相同则视为同一个门户
            return false
        }
        return id1 == id2
    }

    /// 加载门户的核心数据是否相同（如 LowCode 的 md5，Web 的 refAppId）
    /// 主要用于判断两个相同的门户，是否需要给「门户更新」的提示
    func isSameCoreData(with another: WPPortal) -> Bool {
        guard isSameID(with: another) else {
            return false
        }
        switch type {
        case .normal:
            return true
        case .lowCode:
            if let dataA = WPHomeVCInitData.LowCode(self), let dataB = WPHomeVCInitData.LowCode(another) {
                return dataA.isSameCoreData(with: dataB)
            }
            return false
        case .web:
            if let dataA = WPHomeVCInitData.Web(self), let dataB = WPHomeVCInitData.Web(another) {
                return dataA.isSameCoreData(with: dataB)
            }
            return false
        }
    }
}

enum WPHomeVCInitData {

    static let logger = Logger.log(WPHomeVCInitData.self)

    struct Normal: Equatable {
        init?(_ portal: WPPortal) {
            guard portal.type == .normal else {
                WPHomeVCInitData.logger.error("[portal] normal portal parse err: \(portal)")
                return nil
            }
        }
    }

    struct LowCode: Codable, Equatable {
        let md5: String
        let templateFileUrl: String
        let backupTemplateUrls: [String]
        let minClientVersion: String?
        let id: String
        let iconKey: String?
        let name: String?

        init?(_ portal: WPPortal) {
            guard portal.type == .lowCode, let tmpl = portal.template, let dataStr = tmpl.data else {
                WPHomeVCInitData.logger.error("[portal] low code portal parse err: \(portal)")
                return nil
            }

            do {
                let data = try JSON(parseJSON: dataStr).rawData()
                let lowCodeData = try JSONDecoder().decode(WPPortalTemplate.LowCodeData.self, from: data)

                self.md5 = lowCodeData.md5
                self.templateFileUrl = lowCodeData.templateFileUrl
                self.backupTemplateUrls = lowCodeData.backupTemplateUrls ?? []
                self.minClientVersion = lowCodeData.minClientVersion
                /// 预览场景下，使用 tplId 作为 portalId，主要用户埋点和 trace
                if let tplId = tmpl.tplId {
                    self.id = tplId
                } else {
                    self.id = tmpl.id
                }
                self.iconKey = tmpl.iconKey
                self.name = tmpl.name
            } catch {
                WPHomeVCInitData.logger.error("[portal] low code portal data parse err: \(error)")
                assertionFailure()
                return nil
            }
        }

        func isSameCoreData(with another: LowCode) -> Bool {
            md5 == another.md5
        }
    }

    struct Web: Codable, Equatable {
        let refAppId: String
        let refAppData: String?
        let id: String
        let iconKey: String?
        let name: String?

        init?(_ portal: WPPortal) {
            guard portal.type == .web, let tmpl = portal.template, let dataStr = tmpl.data else {
                WPHomeVCInitData.logger.error("[portal] web portal parse err: \(portal)")
                return nil
            }

            do {
                let data = try JSON(parseJSON: dataStr).rawData()
                let webData = try JSONDecoder().decode(WPPortalTemplate.WebData.self, from: data)

                self.refAppId = webData.refAppId
                self.refAppData = webData.refAppData
                self.id = tmpl.id
                self.iconKey = tmpl.iconKey
                self.name = tmpl.name
            } catch {
                WPHomeVCInitData.logger.error("[portal] web portal data parse err: \(error)")
                assertionFailure()
                return nil
            }
        }

        func isSameCoreData(with another: Web) -> Bool {
            // refAppData 没有使用，只比较 refAppId
            refAppId == another.refAppId
        }
    }

    case normal(_ data: Normal)
    case lowCode(_ data: LowCode)
    case web(_ data: Web)

    init?(_ portal: WPPortal) {
        switch portal.type {
        case .normal:
            if let data = Normal(portal) {
                self = .normal(data)
            } else {
                return nil
            }
        case .lowCode:
            if let data = LowCode(portal) {
                self = .lowCode(data)
            } else {
                return nil
            }
        case .web:
            if let data = Web(portal) {
                self = .web(data)
            } else {
                return nil
            }
        }
    }
}
