//
//  WPTemplateModel.swift
//  templateDemo
//
//  Created by  bytedance on 2021/3/12.
//

import Foundation
import SwiftyJSON
import LarkContainer

// 模板组件类型
enum ModuleType: Int, Codable {
    case common = 1             // 用户常用
    case recommend = 2          // 租户推荐
    case customCategory = 3     // 租户 admin 自定义分组
    case officialCategory = 4   // 官方分类
    case appList = 5            // 应用列表
    case commonAndRecommend = 6 // 常用+推荐
    case blockList = 7          // block 列表
}

/// Schema模型
struct SchemaModel: Codable {
    /// schema版本号
    let schemaVersion: String
    /// shcema实体
    let schema: RootModel
}

/// 根节点模型
struct RootModel: Codable {
    /// ID 信息
    let id: String
    /// 组件名
    let componentName: String
    /// 移动端Style
    let mobileStyles: JSON?
    /// 属性值
    let props: JSON?
    /// 子节点
    let children: [JSON]
}

/// 背景图数据结构 在 RootModel.props.backgroundProps 中
struct BackgroundPropsModel: Codable {
    struct Background: Codable {
        struct ImageModel: Codable {
            /// 图片链接
            let url: String
            /// 图片Key
            let key: String
            /// fsUnit 是 sdk 的 Media_V1_MGetResourcesRequest 里拼接域名的一种策略，一般端上不写
            /// sdk 会帮我们补全，而且URL是http的图片不用关心这个
            let fsUnit: String
        }
        /// light mode
        let light: ImageModel?
        /// dark mode
        let dark: ImageModel?
    }
    /// 编译器参数，端上暂不关心
    let settingProps: JSON?
    /// 背景属性
    let background: Background
}


/// 偏好设置
struct PreferPropsModel: Codable {
    // 是否展示无权限block，true为不展示，false表示展示
    let isHideBlockForNoAuth: Bool
}

/// 配置信息模型
final class ConfigModel: Codable {
    /// 是否展示页面Title
    let showPageTitle: Bool
    /// 导航按钮集合
    var naviButtons: [HeaderNaviButton] = []

    init(showTitle: Bool, withDefault: Bool = false) {
        self.showPageTitle = showTitle
        if withDefault {
            setDefaultButtons()
        }
    }

    /// 设置默认按钮
    private func setDefaultButtons() {
        naviButtons.removeAll()
        naviButtons.append(HeaderNaviButton(key: InnerNaviIcon.search.rawValue, iconUrl: nil, schema: nil))     // 搜索
        naviButtons.append(HeaderNaviButton(key: InnerNaviIcon.setting.rawValue, iconUrl: nil, schema: nil))    // 设置
    }

    /// 判断两个config是否相同
    func isEqual(to config: ConfigModel) -> Bool {
        if config.showPageTitle == self.showPageTitle {
            if config.naviButtons.count == self.naviButtons.count {
                for i in 0..<self.naviButtons.count {
                    if !self.naviButtons[i].isEqual(to: config.naviButtons[i]) {
                        return false
                    }
                }
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}

/// 导航按钮model
struct HeaderNaviButton: Codable {
    let key: String
    let iconUrl: String?
    let schema: String?

    /// 判断两个导航按钮是否相等
    func isEqual(to button: HeaderNaviButton) -> Bool {
        return key == button.key && iconUrl == button.iconUrl && schema == button.schema
    }
}

/// 分组组件类型
enum GroupComponentType: String {
    // swiftlint:disable identifier_name
    /// Block组件
    case Block
    /// 常用推荐应用组件
    case CommonAndRecommend
    /// 获取ComponetName相对应的Component
    // swiftlint:enable identifier_name
    func getComponent(userResolver: UserResolver? = nil) -> GroupComponent {
        switch self {
        case .CommonAndRecommend:
            return CommonAndRecommendComponent(userResolver: userResolver)
        case .Block:
            return BlockLayoutComponent()
        }
    }

    func transToModuleType() -> ModuleType? {
        switch self {
        case .CommonAndRecommend:   return .commonAndRecommend
        case .Block:                return .blockList
        }
    }
}

/// 叶子组件类型
enum NodeComponentType: String {
    // swiftlint:disable identifier_name
    /// Block组件
    case Block
    /// 分组标题组件
    case GroupTitle
    /// 常用、推荐组件
    case CommonIconApp
    /// 分组背景组件
    case GroupBackground
    /// 常用应用区域tips
    case CommonTips
    // swiftlint:enable identifier_name
}

struct ComponentModuleReqParam: Codable {
    let moduleType: ModuleType
    let componentId: String
    let params: String
}

struct ComponentModule: Codable {
    var moduleType: ModuleType?
    var componentId: String?
    var data: String?
    var code: Int?
    var msg: String?
}
