//
//  BaseComponentModel.swift
//  templateDemo
//
//  Created by  bytedance on 2021/3/23.
//

import Foundation
import SwiftyJSON
import UniverseDesignIcon
import ECOProbe
import LKCommonsLogging

// MARK: 分组组件
protocol GroupComponent: AnyObject {
    /// 组件ID
    var componentID: String { get }
    /// 组件状态
    var componentState: ComponentState { get set }
    /// 上一次加载时的组件状态
    var lastComponentState: ComponentState? { get set }
    /// 分组类型
    var groupType: GroupComponentType { get }
    /// 描述布局的参数
    var layoutParams: BaseComponentLayout? { get }
    /// 分组下的叶子组件集合
    var nodeComponents: [NodeComponent] { get }
    /// 分组下的附加叶子组件集合
    var extraComponents: [NodeComponentType: NodeComponent] { get }

    /// 将JSON解析为 分组组件（但是不一定是其本身，case: Single 组件parse的返回是其child）
    func parse(json: JSON) -> GroupComponent
    /// 获取全部子节点
    func getAllNodes() -> [NodeComponent]

    // MARK: - module data -------->

    /// 官方组件数据对应的请求参数
    var moduleReqParam: ComponentModuleReqParam? { get }

    /// 使用json数据更新模块数据（也就是一个group），返回是否更新成功
    func updateModuleData(_ json: JSON, isPortalPreview: Bool) -> Bool

    /// 更新组件状态
    func updateGroupState(_ newState: ComponentState)

    // -------- module data <--------

    // MARK: - 交互相关 ----->
    /// 组件曝光上报
    func exposePost()
    /// 组件加载成功埋点
    func monitorComponentShow(trace: OPTraceProtocol?)
    // ------- 交互相关 ------
    
    /// 删除分组下的组件
    /// - Parameters:
    ///   - index: 组件下标
    ///   - notAuth: 是否因为未被授权
    func removeComponent(at index: Int, for notAuth: Bool)
}

extension GroupComponent {
    var moduleReqParam: ComponentModuleReqParam? {
        guard let type = groupType.transToModuleType() else {
            return nil
        }
        return ComponentModuleReqParam(moduleType: type, componentId: componentID, params: "{}")
    }

    func updateModuleData(_ json: JSON, isPortalPreview: Bool = false) -> Bool {
        // 未实现时，默认更新失败
        return false
    }

    func getAllNodes() -> [NodeComponent] {
        return nodeComponents
    }

    func exposePost() {}

    func monitorComponentShow(trace: OPTraceProtocol?) {}
}

// MARK: 叶子组件
protocol NodeComponent {
    /// 组件类型（有相对应的View来渲染，这里相当于是model）
    var type: NodeComponentType { get }
    /// 描述布局的参数
    var layoutParams: BaseComponentLayout? { get }
    /// 将JSON解析为 分组组件（但是不一定是其本身，case: Single 组件parse的返回是其child）
    func parse(json: JSON) -> NodeComponent
    /// 更新组件状态（默认态 / 编辑态）
    func updateEditState(isEditing: Bool)
}

extension NodeComponent {
    func parse(json: JSON) -> NodeComponent { return self }
    func updateEditState(isEditing: Bool) {}
}

// MARK: 组件布局
/// 组件布局时需要的参数（用于自定义布局）
class BaseComponentLayout {
    /// 宽度模式
    private(set) var width: String
    /// 高度模式
    private(set) var height: String
    /// margin系列
    let marginTop: Int
    let marginLeft: Int
    let marginBottom: Int
    let marginRight: Int

    init(width: String, height: String, margins: [Int]) {
        self.width = width
        self.height = height
        self.marginTop = margins[0]
        self.marginRight = margins[1]
        self.marginBottom = margins[2]
        self.marginLeft = margins[3]
    }

    init(json: JSON) {  // ⚠️ 硬解问题，转成 CGFloat 使用更方便
        self.width = json["width"].string ?? "fill_perent"  // 💡style无参数时，默认值
        self.height = json["height"].string ?? "150"
        self.marginTop = json["marginTop"].int ?? 0
        self.marginRight = json["marginRight"].int ?? 0
        self.marginBottom = json["marginBottom"].int ?? 0
        self.marginLeft = json["marginLeft"].int ?? 0
    }

    /// 更新高度值
    func updateHeight(_ height: CGFloat) {
        self.height = "\(height)"
    }
}

enum ComponentState: String {
    /// 组件加载中
    case loading
    /// 组价加载失败
    case loadFailed
    /// 组件正常运行中
    case running
    /// 内部应用数量为空
    case noApp
    /// 组件不支持
    case notSupport
}

/// **************************************************
///         叶子组件（最终渲染）
/// **************************************************

// MARK: 子节点组件

/// 分组标题组件
final class GroupTitleComponent: NodeComponent {
    var type: NodeComponentType { .GroupTitle }

    /// 标题 (对于常用组件，如果子标题数量大于1，优先展示子标题)
    let title: Title
    /// 子标题列表
    let subTitle: [Title]
    /// 选中的子标题索引
    var selectedSubTitleIndex: Int = 0
    /// 是否是内置标题
    var isInnerTitle: Bool = false
    /// 菜单选项（来自模板配置）
    var menuItemsFromSchema: [ActionMenuItem] = []
    /// 布局参数
    var layoutParams: BaseComponentLayout?

    init(title: Title, subTitle: [Title] = []) {
        self.title = title
        self.subTitle = subTitle
    }

    func parse(json: JSON) -> NodeComponent { return self }

    struct Title {
        /// 标题
        var text: String
        /// 图标url
        var iconUrl: String?
        /// 标题颜色
        var textColor: UIColor = UIColor.ud.textTitle
        /// 跳转链接
        var schema: String?
    }
}

/// 分组背景组件
final class GroupBackgroundComponent: NodeComponent {
    var layoutParams: BaseComponentLayout?
    var type: NodeComponentType = .GroupBackground
    /// 背景颜色（如果没有end颜色时，作为纯色背景）
    let backgroundStartColor: UIColor
    /// 渐变色的结束颜色
    var backgroundEndColor: UIColor?
    /// 背景圆角值
    let backgroundRadius: CGFloat

    /// 纯色背景
    init(color: String, radius: CGFloat) {
        self.backgroundRadius = radius
        // swiftlint:disable init_color_with_token
        self.backgroundStartColor = hexStringToUIColor(hex: color)
        // swiftlint:enable init_color_with_token
    }

    /// 渐变背景
    init(startColor: String, endColor: String, radius: CGFloat) {
        self.backgroundRadius = radius
        self.backgroundStartColor = hexStringToUIColor(hex: startColor)
        self.backgroundEndColor = hexStringToUIColor(hex: endColor)
    }

    func parse(json: JSON) -> NodeComponent {
        return self
    }
}

// MARK: 解析辅助类

/// 分组解析辅助
enum ParseGroupHelper {
    static let logger = Logger.log(ParseGroupHelper.self)

    /// 我的常用 titile 解析
    /// - Parameter json: json
    /// - Returns: nodeComponent
    // ⚠️ 对于 5.13 及以前的版本，我的常用 title 解析使用的方法是： ParseGroupHelper.title，会导致：
    // 1. 只要 title 为空，5.13 之前不会错误设置 title header。
    // 2. 如果 title 不为空，且 props.showheader = false，5.13 之前不会错误设置 title header。
    // 3. 如果 title 不为空，且 props.showheader = true，5.13 之前会错误设置 title header。
    // 错误设置 title header 会重复设置两遍 header（supplement cell），导致 我的常用上方 margin 异常增加，会
    // 出现两个 header。因此为 我的常用 构造了新的 title 解析方法，并与三端+编辑器一同约定了特化的新字段，以避免
    // 5.13 及以下版本出现异常。
    static func commonHeaderTitle(json: JSON) -> NodeComponent? {
        Self.logger.info(
            "commonHeader title parsing.",
            additionalData: [
                "defaultLocal": json[PropsKey]["defaultLocale"].string ?? "",
                "is title nil": "\(json[PropsKey][CommonTitleKey].dictionary == nil)"
            ]
        )
        // 检查是否有标题属性，存在则生成对应的分组标题组件
        guard let titleDict = json[PropsKey][CommonTitleKey].dictionary else {
            // CommonTitleKey 如果为空对象，则使用默认文案兜底
            return nil
        }
        // 我的常用支持 空字符串 为合法title
        let title = json[PropsKey][CommonTitleKey].i18nText(with: json[PropsKey]["defaultLocale"].string)
        let iconUrl = json[PropsKey][TitleIconKey].string
        let schema = json[PropsKey][ActionSchemaKey].string
        // title 所有相关元素都为空时，不做兜底
        let titleComponent = GroupTitleComponent(title: .init(text: title, iconUrl: iconUrl, schema: schema))
        Self.logger.info("parse title success", additionalData: [
            "title": title
        ])
        return titleComponent
    }

    /// 解析生成 title 组件
    static func title(json: JSON) -> NodeComponent? {
        // 检查是否有标题属性，存在则生成对应的分组标题组件
        let title = json[PropsKey][TitleKey].i18nText(with: json[PropsKey]["defaultLocale"].string)
        guard !title.isEmpty else {
            return nil
        }
        if let showTitle = json[PropsKey][ShowHeader].bool, !showTitle {
            // 只有下发字段时，才隐藏header
            return nil
        }
        let titleComponent = GroupTitleComponent(title: .init(
            text: title,
            iconUrl: json[PropsKey][TitleIconKey].string,
            schema: json[PropsKey][ActionSchemaKey].string
        ))
        titleComponent.isInnerTitle = json[PropsKey][IsInnerTitle].boolValue
        if let menuItems = json[PropsKey][MenuItemsKey].array {
            for item in menuItems {
                let name = item[ActionNameKey].i18nText
                if let iconUrl = item[ActionIconUrlKey].string,
                   let key = item[ActionKeyKey].string {
                    let menuItem = ActionMenuItem(
                        name: name,
                        iconUrl: iconUrl,
                        key: key,
                        schema: item[ActionSchemaKey].string
                    )
                    titleComponent.menuItemsFromSchema.append(menuItem)
                }
            }
        }
        return titleComponent
    }

    /// 解析生成background组件
    static func background(json: JSON) -> NodeComponent? {
        // 检查是否展示组件，存在则生成对应的背景组件
        if let showBackground = json[PropsKey][ShowBackground].bool, showBackground {
            let backgroundRadius = json[StylesKey][BackgroundRadius].int ?? 0
            return GroupBackgroundComponent(color: "#FFFFFF", radius: CGFloat(backgroundRadius))
        }

        // 检查是否有背景属性，存在则生成对应的背景组件
        if let backgroundColor = json[StylesKey]["BackgroundColor"].string {
            let backgroundRadius = json[StylesKey]["BackgroundRadius"].int ?? 0 // 💡没有圆角属性时，提供「默认值」
            return GroupBackgroundComponent(color: backgroundColor, radius: CGFloat(backgroundRadius))
        } else if let backgroundStartColor = json[StylesKey]["BackgroundStartColor"].string,
                  let backgroundEndColor = json[StylesKey]["BackgroundEndColor"].string {
            let backgroundRadius = json[StylesKey]["BackgroundRadius"].int ?? 0 // 💡没有圆角属性时，提供「默认值」
            return GroupBackgroundComponent(
                startColor: backgroundStartColor,
                endColor: backgroundEndColor,
                radius: CGFloat(backgroundRadius)
            )
        } else {
            return nil
        }
    }
}
