//
//  DocsConfigManager.swift
//  SpaceKit
//
//  Created by litao_dev on 2020/3/15.
//  

import Foundation
import SuiteAppConfig

/// 用于Docs的配置化信息获取，主要是桥接了SuiteAppConfig，配合Lark配置化整体规划，从精简模式开始引入试行
/// 从Lark整体的规划，后续会把Mina配置，FeatureSwitch之类的开关和配置收归到SuiteAppConfig,
/// 最后保留SuiteAppConfig，其他渐渐被取代
/// update: 此方案已弃用，目前主端仅在精简模式下使用，且 CCM 所有功能在精简模式下都不可用，后续不再关心细分点位的开关状态
@available(*, deprecated)
final public class DocsConfigManager {
    /// 通过定义好的业务key来获取有关的配置，key的定义位置：https://bytedance.feishu.cn/docs/doccnDSKlJL5g0Hrporp4RqHHON，修改了配置需要请有关的的同学帮忙同步到后台
    /// - Parameter key: 业务key
    static func feature(for key: String) -> Feature {
        return AppConfigManager.shared.feature(for: key)
    }

    /// 获取某个key对应的feature是否打开，对于只有一层配置的key，推荐使用这个方法
    static func isFeatureOn(for key: String) -> Bool {
        if DocsSDK.isInDocsApp || DocsSDK.isInLarkDocsApp {
            return true
        }
        let ft = feature(for: key)
        return ft.isOn
    }
}

// MARK: - 精简模式配置
extension DocsConfigManager {
    enum LeanMode {
        static let leanModeKey = "leanMode"
        private static var leanMode: Feature {
            return feature(for: leanModeKey)
        }

        /// 精简模式是否开
        static var isOn: Bool {
            if DocsSDK.isInDocsApp
                || DocsSDK.isInLarkDocsApp
                || !AppConfigManager.shared.exist(for: leanModeKey) {
                return false
            }
            return leanMode.isOn
        }

        /// SDK数据保留时间，即space本地保留和展示的数据时间
        static var sdkDataTimeLimit: TimeInterval {
            return (leanMode.traits["sdkDataTimeLimit"] as? TimeInterval) ?? 24 * 60 * 60
        }
    }
}

// MARK: - Space 列表页相关配置
// 配置文档：https://bytedance.feishu.cn/docs/doccnDSKlJL5g0Hrporp4RqHHON
extension DocsConfigManager {
    /// Docs Space 是不是要显示文件夹
    public static var isShowFolder: Bool {
        return isFeatureOn(for: "ccm.folder")
    }
    /// 是否展示收藏
    public static var isShowStar: Bool {
        return isFeatureOn(for: "ccm.star")
    }
    /// 是否展示手动离线
    public static var isShowOffline: Bool {
        return isFeatureOn(for: "ccm.offline")
    }
    /// 是否展示pin 排序入口
    public static var isShowPinDragEntry: Bool {
        return isFeatureOn(for: "ccm.pin")
    }
    /// 是否展示知识库
    public static var isShowWiki: Bool {
        return isFeatureOn(for: "ccm.wiki")
    }
    /// 是否拉取全量数据
    public static var isfetchFullDataOfSpaceList: Bool {
        return isFeatureOn(for: "ccm.fetchFullData")
    }
    /// 是否使用数字下拉刷新控件，不使用的话，就用跟wiki首页一样的loading效果
    public static var isUseDigitalLoading: Bool {
        return isFeatureOn(for: "ccm.digitalLoading")
    }
}
