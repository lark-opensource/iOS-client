//
//  MessageSubViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/3/6.
//

import UIKit
import Foundation
import class LarkModel.Message
import AsyncComponent

public enum SubType: CaseIterable {
    // 外层框架
    case messageStatus
    case chatterStatus
    case reply
    case syncToChat
    case multiEditStatus
    case urgent
    case flag
    // 消息底部
    case dlpTip
    case riskFile
    case restrict
    case countDown
    case replyStatus
    case reaction
    case hangingReaction
    case pin
    case chatPin
    case urgentTip
    case audioForward
    case forward
    // 消息内容
    case content
    // text/post
    case urlPreview
    case docsPreview
    case tcPreview
    // MyAI：复制、插入等操作按钮
    case actionButton
    // MyAI：引用链接
    case referenceList
    // MyAI：快捷指令
    case quickActions
    // MyAI：点赞、踩、重新生成
    case feedbackRegenerate
    // 后面密聊subvm会独立注册，这个类型就不需要了
    case cryptoReply
    case replyThreadInfo
    case selectTranslate
    // 翻译icon 右下角
    case translateStatus
    // 消息被其他人自动翻译icon 右下角
    case autoTranslatedByReceiver
    case revealReplyInTread
}

// 话题样式配置
// 话题样式会默认统一加border
public struct ThreadStyleConfig {
    public let addBorderBySelf: Bool //true: 自己觉得是否绘制border,上层不统一处理
    public init(addBorderBySelf: Bool = false) {
        self.addBorderBySelf = addBorderBySelf
    }
}

/// 内容区域设置
public struct ContentConfig {
    /// 背景风格
    ///
    /// - white: 白色系（我发的或卡片之类的）
    /// - gray: 灰色系（其他人发的）
    /// - clear: 透明（特殊）
    public enum BackgroundStyle {
        case white
        case gray
        case clear
    }

    /// 边框风格
    /// hasBorder = true
    ///
    /// - card: 卡片类型消息使用
    /// - image: 图片视频使用
    /// - other: 非卡片类型，eg.表情、红包等
    public enum BorderStyle: Equatable {
        case card
        case image
        case other
        case custom(strokeColor: UIColor, backgroundColor: UIColor)
    }

    /// 内容中是否有边距
    public let hasMargin: Bool
    // 下边距
    public var hasPaddingBottom: Bool
    /// 背景风格（没有设置使用默认规则-自己发的白色，别人发的灰色）
    public let backgroundStyle: BackgroundStyle?
    /// 边框外不可见（针对文件剪切）
    public let maskToBounds: Bool
    /// 是否支持多选
    public let supportMutiSelect: Bool
    /// 是否支持选中
    public let selectedEnable: Bool
    /// 内容最大宽度（设置这个值之后，外层宽度固定）
    public let contentMaxWidth: CGFloat?
    /// 是否有边框(如公告、图片、地图等需要显示边框)
    public let hasBorder: Bool
    /// 边框风格
    public var borderStyle: BorderStyle?
    /// 是否是card类型
    public var isCard: Bool = false
    /// 是否隐藏content区域：独立卡片等场景会使用
    public var hideContent: Bool = false

    /// 话题样式配置
    public var threadStyleConfig: ThreadStyleConfig?

    public init(
        hasMargin: Bool = true,
        backgroundStyle: BackgroundStyle? = nil,
        maskToBounds: Bool = false,
        supportMutiSelect: Bool = false,
        selectedEnable: Bool = true,
        contentMaxWidth: CGFloat? = nil,
        hasPaddingBottom: Bool = true,
        hasBorder: Bool = false
    ) {
        self.init(hasMargin: hasMargin,
                  backgroundStyle: backgroundStyle,
                  maskToBounds: maskToBounds,
                  supportMutiSelect: supportMutiSelect,
                  selectedEnable: selectedEnable,
                  contentMaxWidth: contentMaxWidth,
                  hasPaddingBottom: hasPaddingBottom,
                  hasBorder: hasBorder,
                  hideContent: false,
                  threadStyleConfig: nil)
    }

    public init(
        hasMargin: Bool = true,
        backgroundStyle: BackgroundStyle? = nil,
        maskToBounds: Bool = false,
        supportMutiSelect: Bool = false,
        selectedEnable: Bool = true,
        contentMaxWidth: CGFloat? = nil,
        hasPaddingBottom: Bool = true,
        hasBorder: Bool = false,
        hideContent: Bool = false,
        threadStyleConfig: ThreadStyleConfig?
    ) {
        self.hasMargin = hasMargin
        self.backgroundStyle = backgroundStyle
        self.maskToBounds = maskToBounds
        self.supportMutiSelect = supportMutiSelect
        self.selectedEnable = selectedEnable
        self.contentMaxWidth = contentMaxWidth
        self.hasPaddingBottom = hasPaddingBottom
        self.hasBorder = hasBorder
        self.hideContent = hideContent
        self.threadStyleConfig = threadStyleConfig
    }
}

/// 消息子内容ViewModel（例如点赞、URL预览、Docs预览等）
open class MessageSubViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ViewModelContext>: NewMessageSubViewModel<M, D, C> {
    /// 负责绑定VM和Component，避免Component对VM造成污染
    public let binder: ComponentBinder<C>!
    weak var renderer: ASComponentRenderer?

    /// 通过Message和Binder初始化VM
    ///
    /// - Parameters:
    ///   - metaModel: 数据实体
    ///   - dependency: 数据依赖信息
    ///   - context: 上下文（提供全局能力和页面接口）
    ///   - binder: 绑定VM和Component
    public init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        self.binder = binder
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
        // binderAbility为weak持有，不会造成循环引用，新框架中binderAbility由Binder提供，旧框架中binderAbility由VM自己处理
        // 为了避免外部调用binderAbility中的方法失效，旧框架中也需要实现binderAbility
        self.binderAbility = self
        self.syncToBinder()
    }

    /// 定义如何向binder同步数据
    open func syncToBinder() {
        self.binder.update(with: self)
    }

    /// 初始化渲染引擎（父亲初始化或者重新设置的时候调用）
    ///
    /// - Parameter renderer: 渲染引擎
    public func initRenderer(_ renderer: ASComponentRenderer) {
        self.renderer = renderer
    }

    /// 局部更新component
    ///
    /// - Parameter component: 更新后的component
    public func update(component: Component, animation: UITableView.RowAnimation = .fade) {
        renderer?.update(component: component, rendererNeedUpdate: { [weak self] in
            guard let messageID = self?.message.id else {
                return
            }
            self?.context.reloadRow(by: messageID, animation: animation)
        })
    }

    /// https://bytedance.feishu.cn/docx/BeJvdWEg9onkyMxtoGrc63gPnzU
    /// 强制触发reloadRow，消息卡片等场景局部刷新导致整体高度变更时，有时候会和TableView的heightForRow有时序问题，
    /// 使得rendererNeedUpdate没有被触发，导致其他子组件位置不对，此处临时支持下forceUpdate，后续从框架层修复时序问题后可删除
    public func updateForced(component: Component, animation: UITableView.RowAnimation = .fade) {
        renderer?.update(component: component, rendererNeedUpdate: { [weak self] in
            guard let messageID = self?.message.id else {
                return
            }
            self?.context.reloadRow(by: messageID, animation: animation)
        }, forceUpdate: true)
    }

    public func updateComponentAndRoloadTable(component: Component) {
        renderer?.update(component: component, rendererNeedUpdate: { [weak self] in
            self?.context.reloadTable()
        })
    }

    /// 对应的Component
    public var component: ComponentWithContext<C> {
        return binder.component
    }
}

extension MessageSubViewModel: ComponentBinderAbility {
    /// 定义如何向binder同步数据
    public func syncToBinder(key: String?) {
        self.binder.update(with: self, key: key)
    }

    /// 局部更新component
    public func updateComponent(animation: UITableView.RowAnimation) {
        self.update(component: component, animation: animation)
    }

    public func updateComponentAndRoloadTable() {
        self.updateComponentAndRoloadTable(component: component)
    }
}
