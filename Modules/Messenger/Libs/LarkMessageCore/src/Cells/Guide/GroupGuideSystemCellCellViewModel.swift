//
//  GroupGuideSystemCellViewModel.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2022/10/25.
//

import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import EENavigator
import LarkMessengerInterface
import ByteWebImage
import LKCommonsLogging
import LarkCore
import Homeric
import LKCommonsTracker

public struct GroupGuideActionButtonItem {
    /// 新群引导亮色模式passThrough
    public let lmIcon: ImagePassThrough
    /// 新群引导暗色模式passThrough
    public let dmIcon: ImagePassThrough
    /// 新群引导按钮文案
    public let text: String
    /// 新群引导按钮点击行为
    public let tapAction: (() -> Void)
}

open class GroupGuideSystemCellViewModel<C: GroupGuideSystemCellContext>: CellViewModel<C> {

    private lazy var logger = Logger.log(GroupGuideSystemCellViewModel.self,
                                   category: "Module.LarkMessageCore.GroupGuideSystemCellViewModel")

    override open var identifier: String {
        return "group-guide-system"
    }

    open private(set) var metaModel: CellMetaModel
    open var message: Message {
        return metaModel.message
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    /// 新群引导数据实体
    private var guideContent: SystemContent.SystemGuideContent {
        ((message.content as? SystemContent) ?? SystemContent.transform(pb: .init())).systemExtraContent.guideContent
    }

    /// 主标题
    public var title: String {
        return guideContent.title.localizedText
    }

    /// 副标题
    public var subTitle: String {
        return guideContent.subTitle.localizedText
    }

    /// 亮色插画 Passthrough
    public var lmImagePassThrough: ImagePassThrough {
        var passThrough = ImagePassThrough()
        passThrough.key = guideContent.lmImage.key
        passThrough.fsUnit = guideContent.lmImage.fsUnit
        return passThrough
    }

    /// 暗色插画 Passthrough
    public var dmImagePassThrough: ImagePassThrough {
        var passThrough = ImagePassThrough()
        passThrough.key = guideContent.dmImage.key
        passThrough.fsUnit = guideContent.dmImage.fsUnit
        return passThrough
    }

    /// 按钮
    public var buttunItems: [GroupGuideActionButtonItem] {
        // 按钮最多三个
        return guideContent.items.prefix(3).map { btnTranstorm(pbBtnItem: $0) }
    }

    private func btnTranstorm(pbBtnItem: SystemContent.SystemGuideActionButton) -> GroupGuideActionButtonItem {
        /* 点击事件, 目前的新群点击事件全部为applink跳转 */
        let tapAction: (() -> Void)
        let url: URL? = URL(string: pbBtnItem.action.url.ios) ?? URL(string: pbBtnItem.action.url.common)
        let id: String = pbBtnItem.id
        if let url = url {
            tapAction = { [weak self] in
                guard let self = self else { return }
                // APPLink 跳转
                self.context.navigator(type: .open, url: url, params: nil)
                // 埋点上报
                var params = IMTracker.Param.chat(self.metaModel.getChat())
                params += ["click": id, "target": "none"]
                Tracker.post(TeaEvent("im_chat_onboarding_click", params: params))
            }
        } else {
            self.logger.error("get action url failed",
                              additionalData: ["MessageID": self.metaModel.message.id,
                                               "ChatID": self.metaModel.getChat().id])
            tapAction = {}
        }
        /* 按钮Icon Passthrough */
        var lmIcon = ImagePassThrough()
        lmIcon.key = pbBtnItem.lmIcon.key
        lmIcon.fsUnit = pbBtnItem.lmIcon.fsUnit
        var dmIcon = ImagePassThrough()
        dmIcon.key = pbBtnItem.dmIcon.key
        dmIcon.fsUnit = pbBtnItem.dmIcon.fsUnit

        return GroupGuideActionButtonItem(lmIcon: lmIcon,
                                          dmIcon: dmIcon,
                                          text: pbBtnItem.text.localizedText,
                                          tapAction: tapAction)
    }

    public init(metaModel: CellMetaModel, context: C) {
        self.metaModel = metaModel
        super.init(context: context, binder: GroupGuideSystemCellComponentBinder(context: context))
        self.calculateRenderer()
    }
}

final class GroupGuideSystemCellComponentBinder<C: GroupGuideSystemCellContext>: ComponentBinder<C> {
    let props = GroupGuideSystemCellComponent<C>.Props()
    let style = ASComponentStyle()

    lazy var _component: GroupGuideSystemCellComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: GroupGuideSystemCellComponent<C> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? GroupGuideSystemCellViewModel<C> else {
            assertionFailure()
            return
        }
        props.title = vm.title
        props.subTitle = vm.subTitle
        props.lmImagePassThrough = vm.lmImagePassThrough
        props.dmImagePassThrough = vm.dmImagePassThrough
        props.chatComponentTheme = vm.chatComponentTheme
        props.buttonItems = vm.buttunItems
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        self._component = GroupGuideSystemCellComponent(props: props, style: style, context: context)
    }
}
