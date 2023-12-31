//
//  ChatCardComponent.swift
//  Todo
//
//  Created by 张威 on 2020/11/29.
//

import AsyncComponent
import EEFlexiable
import RustPB
import RichLabel
import UniverseDesignButton
import UniverseDesignColor
import UniverseDesignCardHeader
import UniverseDesignFont

// nolint: magic number
struct ChatCardRichTextInfo {
    var attrText: MutAttrText
    // 链接：用户 id
    var atMap = [NSRange: String]()
    // 链接：url
    var urlMap = [NSRange: String]()
    // 链接：todo
    var todoMap = [NSRange: String]()

    func attachToRichLabel(_ props: RichLabelProps, with linkHandler: ChatCardLinkHandler?) {
        props.attributedText = attrText

        var textLinkList = [LKTextLink]()
        for (range, urlStr) in urlMap {
            var textLink = LKTextLink(range: range, type: .link)
            textLink.linkTapBlock = { (_, _) in linkHandler?.onUrlTap?(urlStr) }
            textLinkList.append(textLink)
        }
        for (range, userId) in atMap {
            var textLink = LKTextLink(range: range, type: .link)
            textLink.linkTapBlock = { (_, _) in linkHandler?.onAtUserTap?(userId) }
            textLinkList.append(textLink)
        }
        for (range, guid) in todoMap {
            var textLink = LKTextLink(range: range, type: .link)
            textLink.linkTapBlock = { (_, _) in linkHandler?.onTodoTap?(guid) }
            textLinkList.append(textLink)
        }
        props.textLinkList = textLinkList
    }
}

struct ChatCardCheckboxInfo {
    var checkState: CheckboxState
    var enabledCheckAction: CheckboxEnabledAction?
    var disabledCheckAction: CheckboxDisabledAction?
    var isMilesone: Bool = false
}

struct ChatCardDailyReminderInfo {
    var guid: String
    var title: ChatCardRichTextInfo
    var timeContent: V3ListTimeInfo?
}

final class ChatCardLinkHandler {
    /// at 被点击
    var onAtUserTap: ((_ userId: String) -> Void)!
    /// url 被点击
    var onUrlTap: ((_ urlStr: String) -> Void)!
    /// todo 标题被点击
    var onTodoTap: ((_ guid: String) -> Void)!
}

/// 消息卡片

final class ChatCardComponentProps: ASComponentProps {

    struct RichTextInfo {
        var attrText: AttrText
        var atMap: [NSRange: Rust.RichText.Element.AtProperty]
        var linkMap: [NSRange: String]
    }

    struct DailyReminderItem {
        var title: ChatCardRichTextInfo
        var dueTimeText: String?
        var isOverDue: Bool?
        var onTap: (() -> Void)
    }

    var linkHandler: ChatCardLinkHandler?

    /// 底部被点击
    var onBottomTap: (() -> Void)?
    /// bottom - 文案 & enable
    var bottom: (text: String, isDisabled: Bool) = ("", false)
    /// 是否显示底部按钮
    var displayBottom: Bool = true
    /// followBtn - 文案 & 关注/取消关注
    var followBtn: (text: String, isFollow: Bool)?
    /// 关注按钮 & 底部按钮 font
    var buttonFont: UIFont = UDFont.body2
    /// followBtn被点击
    var onFollowBtnTap: (() -> Void)?
    /// 每日提醒
    var dailyReminderInfo: [ChatCardDailyReminderInfo] = []

    var headerText: String?
    var summaryInfo: ChatCardRichTextInfo?
    var checkboxInfo: ChatCardCheckboxInfo?
    var timeInfo: V3ListTimeInfo?
    var ownerInfo: ChatCardOwnerData?
    var openCenterInfo: (title: String, onTap: (() -> Void)?)?

    var preferMaxLayoutWidth: CGFloat?

    var needBottomPadding = false
}

class ChatCardComponent<C: AsyncComponent.Context>: ASComponent<ChatCardComponentProps, EmptyState, UIView, C> {
    // followBtn
    private lazy var followBtnComponent = makeButtonComponent()

    // bottomBtn
    private lazy var bottomBtnComponent = makeButtonComponent()

    private lazy var dailyRemindersComponent = makeDailyRemindersComponent()

    private lazy var dailyHeaderComponents = makeDailyHeaderComponents()
    private lazy var headerComponent = makeHeaderComponent()
    private lazy var summaryComponent = makeSummaryComponent()
    private lazy var ownerComponent = makeOwnerComponent()
    private lazy var timeComponent = makeTimeComponent()

    private lazy var openCenter = makeOpenCenterComponent()

    override init(props: ChatCardComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.justifyContent = .flexEnd
        style.flexDirection = .column
        style.alignContent = .stretch
        style.alignItems = .stretch
        style.backgroundColor = .ud.bgFloat
        super.init(props: props, style: style, context: context)

        _ = willReceiveProps(props, props)
        setSubComponents([
            dailyHeaderComponents.wrapper,
            ASLayoutComponent(
                style: {
                    let style = ASComponentStyle()
                    style.paddingLeft = 12
                    style.paddingRight = 12
                    style.justifyContent = .flexStart
                    style.flexDirection = .column
                    style.alignContent = .stretch
                    style.alignItems = .stretch
                    return style
                }(),
                [
                    headerComponent,
                    summaryComponent,
                    ownerComponent,
                    timeComponent,
                    dailyRemindersComponent,
                    followBtnComponent,
                    bottomBtnComponent,
                    openCenter
                ]
            )
        ])
    }

    override func willReceiveProps(_ old: ChatCardComponentProps, _ new: ChatCardComponentProps) -> Bool {
        style.paddingBottom = new.needBottomPadding ? 12 : 0

        if !new.dailyReminderInfo.isEmpty {
            let props = ChatCardDailyRemindersContainerProps()
            props.dailyReminderCellPropsList = new.dailyReminderInfo.map { info in
                let cellProps = ChatCardDailyReminderCellProps()
                cellProps.info = info
                cellProps.onTap = new.linkHandler?.onTodoTap
                return cellProps
            }
            dailyRemindersComponent.props = props
            dailyRemindersComponent.style.display = .flex
        } else {
            dailyRemindersComponent.style.display = .none
        }

        updateButtonComponents(new: new)

        if let openCenterInfo = new.openCenterInfo {
            let props = openCenter.props
            props.title = openCenterInfo.title
            props.onTap = openCenterInfo.onTap
            openCenter.props = props
            openCenter.style.display = .flex
        } else {
            openCenter.style.display = .none
        }

        if let headerText = new.headerText {
            if !new.dailyReminderInfo.isEmpty {
                // 每日通知场景，样式有些不同，仍然使用 oldHeaderComponents
                dailyHeaderComponents.wrapper.style.display = .flex
                headerComponent.style.display = .none

                let contentProps = dailyHeaderComponents.content.props
                contentProps.text = headerText
                dailyHeaderComponents.content.props = contentProps
            } else {
                dailyHeaderComponents.wrapper.style.display = .none
                headerComponent.style.display = .flex

                let props = headerComponent.props
                if let layoutWidth = new.preferMaxLayoutWidth {
                    props.preferMaxLayoutWidth = layoutWidth
                }
                props.text = headerText
                headerComponent.props = props
            }
        } else {
            dailyHeaderComponents.wrapper.style.display = .none
            headerComponent.style.display = .none
        }

        if let summary = new.summaryInfo, let checkboxInfo = new.checkboxInfo {
            let props = summaryComponent.props
            props.textInfo = summary
            props.linkHandler = new.linkHandler
            props.checkboxInfo = checkboxInfo
            props.preferMaxLayoutWidth = new.preferMaxLayoutWidth
            summaryComponent.props = props
            summaryComponent.style.display = .flex
        } else {
            summaryComponent.style.display = .none
        }

        if let owner = new.ownerInfo {
            let props = ownerComponent.props
            props.owner = owner
            ownerComponent.preferMaxLayoutWidth = new.preferMaxLayoutWidth
            ownerComponent.props = props
            ownerComponent.style.display = .flex
        } else {
            ownerComponent.style.display = .none
        }

        if let info = new.timeInfo {
            let props = timeComponent.props
            props.timeInfo = info
            props.style = .normal
            timeComponent.props = props
            timeComponent.style.display = .flex
        } else {
            timeComponent.style.display = .none
        }

        return true
    }

    private func updateButtonComponents(new: ChatCardComponentProps) {
        // followBtn
        followBtnComponent.props.font = new.buttonFont
        if let info = new.followBtn {
            followBtnComponent.props.normalTitle = info.text
            followBtnComponent.props.disabledTitle = nil
            followBtnComponent.props.isDisabled = false
            followBtnComponent.props.normalTitleColor = info.isFollow ? UIColor.ud.textTitle : UIColor.ud.primaryContentDefault
            followBtnComponent.props.onTap = new.onFollowBtnTap
            followBtnComponent.style.border = Border(
                BorderEdge(
                    width: 1.0,
                    color: info.isFollow ? UIColor.ud.lineBorderCard : UIColor.ud.primaryContentDefault,
                    style: .solid
                )
            )
            followBtnComponent.style.display = .flex
        } else {
            followBtnComponent.style.display = .none
            followBtnComponent.props.backgroundColor = .clear
        }

        // bottomBtn
        bottomBtnComponent.props.font = new.buttonFont
        if new.bottom.isDisabled {
            bottomBtnComponent.props.normalTitle = nil
            bottomBtnComponent.props.disabledTitle = new.bottom.text
            bottomBtnComponent.props.isDisabled = true
            bottomBtnComponent.props.onTap = nil
            bottomBtnComponent.props.backgroundColor = .clear
        } else {
            bottomBtnComponent.props.normalTitle = new.bottom.text
            bottomBtnComponent.props.disabledTitle = nil
            bottomBtnComponent.props.isDisabled = false
            bottomBtnComponent.props.onTap = new.onBottomTap
            bottomBtnComponent.props.backgroundColor = .clear
        }

        if new.displayBottom {
            bottomBtnComponent.style.display = .flex
        } else {
            bottomBtnComponent.style.display = .none
        }
    }

}

extension ChatCardComponent {

    private func makeDailyRemindersComponent() -> ChatCardDailyRemindersContainerComponent<C> {
        let props = ChatCardDailyRemindersContainerProps()
        let style = ASComponentStyle()
        return ChatCardDailyRemindersContainerComponent<C>(props: props, style: style)
    }

    private func makeButtonComponent() -> ChatCardButtonComponent<C> {
        let props = ChatCardButtonComponentProps()
        props.isDisabled = true
        props.normalTitleColor = UIColor.ud.textTitle
        props.disabledTitleColor = UIColor.ud.N500

        let style = ASComponentStyle()
        style.marginTop = 12
        style.border = Border(
            BorderEdge(
                width: 1.0,
                color: UIColor.ud.lineBorderCard,
                style: .solid
            )
        )
        style.cornerRadius = 6
        style.height = CSSValue(cgfloat: 36.auto())
        return ChatCardButtonComponent<C>(props: props, style: style)
    }

    private func makeRichLabel(numberOfLines: Int, marginTop: CGFloat = 12) -> RichLabelComponent<C> {
        let props = RichLabelProps()
        props.numberOfLines = numberOfLines
        props.lineSpacing = 4
        props.outOfRangeText = AttrText(string: "\u{2026}", attributes: [.foregroundColor: UIColor.ud.textTitle])
        props.linkAttributes = [:]

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = CSSValue(cgfloat: marginTop)

        return RichLabelComponent(props: props, style: style)
    }

    private func makeDailyHeaderComponents() -> (wrapper: UDCardHeaderComponent<C>, content: UILabelComponent<C>) {
        let contentProps = UILabelComponentProps()
        contentProps.font = UDFont.headline
        contentProps.textColor = UIColor.ud.udtokenMessageCardTextIndigo
        let contentStyle = ASComponentStyle()
        contentStyle.backgroundColor = .clear
        let content = UILabelComponent<C>(props: contentProps, style: contentStyle)

        let wrapperProps = UDCardHeaderComponentProps()
        wrapperProps.colorHue = .indigo
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.height = CSSValue(cgfloat: 45.auto())
        wrapperStyle.paddingLeft = 12
        wrapperStyle.paddingRight = 12
        let wrapper = UDCardHeaderComponent<C>(props: wrapperProps, style: wrapperStyle)
        wrapper.setSubComponents([content])

        return (wrapper, content)
    }

    private func makeHeaderComponent() -> ChatCardHeaderComponent<C> {
        let props = ChatCardHeaderComponentProps()
        let style = ASComponentStyle()
        return ChatCardHeaderComponent(props: props, style: style)
    }

    private func makeSummaryComponent() -> ChatCardSummaryComponent<C> {
        let props = ChatCardSummaryComponentProps()
        let style = ASComponentStyle()
        return ChatCardSummaryComponent<C>(props: props, style: style)
    }

    private func makeOwnerComponent() -> ChatCardOwnerComponent<C> {
        let contentProps = ChatCardOwnerComponentProps()
        let contentStyle = ASComponentStyle()
        contentStyle.marginTop = CSSValue(cgfloat: 4)
        return ChatCardOwnerComponent<C>(props: contentProps, style: contentStyle)
    }

    private func makeTimeComponent() -> ChatCardTimeComponent<C> {
        let props = ChatCardTimeComponentProps()
        let style = ASComponentStyle()
        return ChatCardTimeComponent<C>(props: props, style: style)
    }

    private func makeOpenCenterComponent() -> ChatCardOpenCenterContainerComponent<C> {
        let props = ChatCardOpenCenterComponentProps()
        let style = ASComponentStyle()
        style.marginTop = 12
        return ChatCardOpenCenterContainerComponent(props: props, style: style)
    }

}
