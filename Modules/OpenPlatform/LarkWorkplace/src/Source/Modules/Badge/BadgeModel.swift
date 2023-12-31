//
//  BadgeModel.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/12/21.
//

import Foundation
import RustPB
import LarkOPInterface
import LarkWorkplaceModel
import LKCommonsLogging

extension WPBadge: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.appId == rhs.appId
            && lhs.clientType == rhs.clientType
            && lhs.appAbility == rhs.appAbility
    }
}

extension WPBadge: CustomDebugStringConvertible {
    public var debugDescription: String {
        let dict: [String: String] = [
            "appId": appId,
            "clientType": "\(clientType.rawValue)",
            "appAbility": "\(appAbility.rawValue)",
            "version": "\(version)",
            "updateTime": "\(updateTime)",
            "badgeNum": "\(badgeNum)",
            "needShow": "\(needShow)"
        ]
        return dict.description
    }
}

extension WPBadge {
    /// 区分两个 AppBadgeNode 的 key，目前主要用于 rust 推送 badge merg 逻辑，后面需要整理下。
    func key() -> String {
        return "\(appId)_\(clientType)_\(appAbility)"
    }

    /// badge 展示时的过滤信息，不同形态同一个 UI 上只能展示一种。
    func workplaceBadgeKey() -> String {
        return "\(appId)_\(appAbility)"
    }

    // 转成 OpenAppBadgeNode
    func toOpenAppBadgeNode() -> Openplatform_V1_OpenAppBadgeNode {
        var badgeNode = Openplatform_V1_OpenAppBadgeNode()
        badgeNode.feature = toFeatureType()
        badgeNode.appID = appId
        badgeNode.needShow = needShow
        badgeNode.updateTime = String(updateTime)
        badgeNode.badgeNum = Int32(badgeNum)
        badgeNode.version = String(version)
        badgeNode.id = "\(id)"
        badgeNode.extra = extra ?? ""
        return badgeNode
    }

    // to feature type
    func toFeatureType() -> Openplatform_V1_CommonEnum.OpenAppFeatureType {
        switch appAbility {
        case .web:
            return .h5
        case .miniApp:
            return .miniApp
        @unknown default:
            assertionFailure("should not be here")
            return .h5
        }
    }

    /// badge是有效badge，可以显示的badge，需要被显示
    func countAble() -> Bool {
        let validAppType = (appAbility == .miniApp || appAbility == .web)
        return badgeNum > 0 && needShow && validAppType
    }
}

// 红点数据信息
typealias RspAppBadgeItemInfo = [WPBadge]
// 单个Item携带的红点数据
struct AppBadgeItemInfo: Codable, CustomDebugStringConvertible {
    // 应用的AppID
    let appID: String
    // 红点数据信息
    let badgeList: [WPBadge]
    // 工作台上面的原始类型
    let workplaceDisplayAbility: WPBadge.AppType
    // debug description
    var debugDescription: String {
        var output: [String] = []
        output.append("\(appID)")
        for node in badgeList {
            output.append("[\(node.debugDescription)]")
        }
        return output.joined(separator: " ")
    }

    static func convertDisplayAbility(_ ability: WPAppItem.AppAbility) -> WPBadge.AppType? {
        switch ability {
        case .miniApp:
            return .miniApp
        case .web:
            return .web
        case .bot, .widget, .native, .unknown:
            return nil
        @unknown default:
            return nil
        }
    }
}

// 整个工作台红点元数据,appID -> AppBadgeItemInfo
struct WorkPlaceBadgeInfo: Codable, CustomDebugStringConvertible {
    static let logger = Logger.log(WorkPlaceBadgeInfo.self)

    var badgeMap: [String: AppBadgeItemInfo] = [:]
    /// 工作台可以展示红点的应用
    var workplaceAppMap: [String: WorkPlaceBadge.BadgeSingleKey] = [:]
    // 是否包含对应的红点数据
    func badgeForApp(appID: String) -> AppBadgeItemInfo? {
        return badgeMap[appID]
    }
    // 插入红点数据
    enum UpdateBadgeType {
        case replace
        case merge
    }
    mutating func updateBadge(
        appID: String,
        badge: AppBadgeItemInfo,
        type: UpdateBadgeType = .replace
    ) {
        Self.logger.info("updateBadge for appID \(appID) type \(type) \(badge)")
        switch type {
        case .replace:
            /// 直接替换
            badgeMap[appID] = badge
        case .merge:
            /// 需要merge
            guard let oldItem = badgeMap[appID] else {
                badgeMap[appID] = badge
                return
            }
            /// 存在旧的, 那么需要进行merge
            var tempResult: [String: WPBadge] = [:]
            oldItem.badgeList.forEach { node in
                tempResult[node.key()] = node
            }
            badge.badgeList.forEach { node in
                /// 如果旧的node已经存在，并且比较新，那么直接跳过
                if let oldNode: WPBadge = tempResult[node.key()],
                   oldNode.version > node.version {
                    return
                }
                tempResult[node.key()] = node
            }
            let tempResultList = Array(tempResult.values)
            /// 真正merge结果
            let resultItem = AppBadgeItemInfo(
                appID: badge.appID,
                badgeList: tempResultList,
                workplaceDisplayAbility: badge.workplaceDisplayAbility
            )
            badgeMap[appID] = resultItem
            Self.logger.info("updateBadge for appID \(appID) type \(type) \(resultItem)")
        }
    }
    // to Report Badge List
    func toReportBadgeList() -> [OPBadge.GadgetBadgeNode] {
        var result: [OPBadge.GadgetBadgeNode] = []
        for (appid, badgeInfo) in badgeMap {
            for node in badgeInfo.badgeList {
                let type = OPBadge.AppAbility(rawValue: node.appAbility.rawValue) ?? .unknown
                let node = OPBadge.GadgetBadgeNode(
                    appId: appid,
                    type: type.description,
                    num: Int(node.badgeNum),
                    show: node.needShow
                )
                result.append(node)
            }
        }
        return result
    }

    func toBadgeNodeBrief() -> [TemplateBadgeNodeBrief] {
        return badgeMap.values.flatMap({ itemInfo in
            return itemInfo.badgeList.map({ TemplateBadgeNodeBrief(from: $0.toOpenAppBadgeNode()) })
        })
    }

    var debugDescription: String {
        var output: [String] = []
        for (appid, item) in badgeMap {
            output.append("[\(appid)]: \(item.debugDescription)")
        }
        output.append("workplace can display badge list")
        for (key, _) in workplaceAppMap {
            output.append("[\(key)]")
        }
        return output.joined(separator: "\n")
    }
    func isOldThan(otherBadgeInfo: WorkPlaceBadgeInfo) -> Bool {
        for (appId, myBadge) in badgeMap {
            if let otherBadge = otherBadgeInfo.badgeForApp(appID: appId) {
                for myBadgeNode in myBadge.badgeList {
                    if let otherBadgeNodeIndex = otherBadge.badgeList.firstIndex(of: myBadgeNode) as? Int {
                        let otherBadgeNode = otherBadge.badgeList[otherBadgeNodeIndex]
                        guard myBadgeNode.version <= otherBadgeNode.version else {
                            Self.logger.info("badge is not new", tag: "WorkPlaceBadgeInfo", additionalData: [
                                "myBadge": myBadge.debugDescription,
                                "otherBadge": otherBadgeInfo.debugDescription
                            ])
                            return false
                        }
                    }
                }
            }
        }
        return true
    }
}

extension Openplatform_V1_OpenAppBadgeNode {
    func toAppAbility() -> WPBadge.AppType {
        switch feature {
        case .h5:
            return .web
        case .miniApp:
            return .miniApp
        @unknown default:
            assertionFailure("should not be here")
            return .web
        }
    }

    func toAppBadgeNode() -> WPBadge {
        return WPBadge(
            appId: appID,
            clientType: .mobile, // 这个字段 rust 不存在，之前直接写死了，需要确认下这样做对吗
            appAbility: toAppAbility(),
            id: Int64(id) ?? 0,
            version: Int64(version) ?? 0,
            updateTime: Int64(updateTime) ?? 0,
            badgeNum: Int64(badgeNum) ?? 0,
            needShow: needShow,
            extra: extra
        )
    }

    func toTabAppBadge() -> OPBadge.GadgetBadgeNode {
        let type = OPBadge.AppAbility(rawValue: feature.rawValue) ?? .unknown
        return OPBadge.GadgetBadgeNode(
            appId: appID,
            type: type.description,
            num: Int(badgeNum),
            show: needShow
        )
    }

    func toAppBadgeAppFeatureType() -> AppBadgeAppFeatureType? {
        switch feature {
        case .h5:
            return .h5
        case .miniApp:
            return .miniApp
        @unknown default:
            assertionFailure("should not be here")
            return nil
        }
    }

    func toOPAppBadgeNode() -> LarkOPInterface.AppBadgeNode? {
        guard let featureType = toAppBadgeAppFeatureType() else { return nil }
        return LarkOPInterface.AppBadgeNode(
            feature: featureType,
            appID: appID,
            needShow: needShow,
            updateTime: updateTime,
            badgeNum: Int(badgeNum),
            extra: extra,
            version: version
        )
    }
}
