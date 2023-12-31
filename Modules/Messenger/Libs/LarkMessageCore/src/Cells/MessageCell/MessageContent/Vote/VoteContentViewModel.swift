//
//  VoteContentViewModel.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/21.
//

import Foundation
import AsyncComponent
import LarkMessageBase
import LarkModel
import UIKit
import RustPB
import LarkCore

public typealias SelectProperty = RustPB.Basic_V1_RichTextElement.ProgressSelectOptionProperty

// VM 最小依赖
public protocol VoteContentViewModelContext: ViewModelContext {
    func sendAction(actionID: String, params: [String: String], messageID: String)
}

public class VoteContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VoteContentViewModelContext>: MessageSubViewModel<M, D, C> {
    public override var identifier: String {
        return "vote"
    }

    public override var contentConfig: ContentConfig? {
        var contentConfig = ContentConfig(
            hasMargin: false,
            backgroundStyle: .white,
            maskToBounds: true,
            supportMutiSelect: true,
            hasBorder: true
        )
        contentConfig.isCard = true
        return contentConfig
    }

    public var contentPreferMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message)
    }

    public var hasBottomMargin: Bool {
        return message.reactions.isEmpty
    }

    public var title: String = ""
    public var footerText: String = ""

    // 单选/多选
    public var maxPickNum: Int = 1
    public var minPickNum: Int = 1

    public var buttonEnableTitle: String = ""
    public var buttonDisableTitle: String = ""

    // raw data
    public var rawItems: [SelectProperty] = []

    // 本地选中的item
    public var customSelectedItems: [SelectProperty] = []
    public var buttonActionID: String?
}

/// Action
private protocol Action { }
extension VoteContentViewModel: Action {
    // item点击事件
    public func onSelectItemDidClick(item: SelectProperty?) {
        guard let item = item else { return }
        if customSelectedItems.contains(item) {
            customSelectedItems.removeAll { $0 == item }
        } else {
            // 单选
            if maxPickNum <= 1 {
                customSelectedItems.removeAll()
            }
            customSelectedItems.append(item)
        }
        self.binder.update(with: self)
        update(component: binder.component)

        // Tracker
        guard let actionID = self.buttonActionID else { return }
        VoteContentTracker.trackClickVoteItem(voteId: actionID,
                                              isSingle: maxPickNum == 1,
                                              selectStatus: customSelectedItems.contains(item))
        IMTracker.Chat.Main.Click.Msg.Vote(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
    }

    public func onVoteButtonDidClick() {
        guard submitEnable, let actionID = self.buttonActionID else { return }
        var params: [String: String] = [:]
        for selectOption in customSelectedItems {
            params[selectOption.actionParamName] = selectOption.actionParamValue
        }
        context.sendAction(actionID: actionID, params: params, messageID: message.id)

        // Tracker
        VoteContentTracker.trackClickVoteSubmit(voteId: actionID,
                                                isSingle: params.count == 1,
                                                itemCount: params.count)
        IMTracker.Chat.Main.Click.Msg.Vote(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
    }
}

// MARK: - DataSource
private protocol DataSource { }
extension VoteContentViewModel: DataSource {
    var messageContent: CardContent {
        return (message.content as? CardContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    public var submitEnable: Bool {
        return customSelectedItems.count >= minPickNum
    }

    public var selectTypeLabelText: String {
        return maxPickNum > 1
            ? BundleI18n.LarkMessageCore.Lark_Legacy_MultipleSelection
            : BundleI18n.LarkMessageCore.Lark_Legacy_SingleSelection
    }

    public func pharseRichText() {
        self.rawItems = []
        let elements = messageContent.richText.elements
        let parentIDs = messageContent.richText.elementIds
        guard parentIDs.count == 3 else { return }
        // header
        if let element = elements[parentIDs[0]] {
            guard element.childIds.count == 1,
                let text = elements[element.childIds[0]],
                text.tag == .text else { return }
            self.title = text.property.text.content
        }
        // content
        if let element = elements[parentIDs[1]] {
            guard element.childIds.count == 1,
                let select = elements[element.childIds[0]],
                select.tag == .select else { return }

            // 更新 单选/多选
            self.maxPickNum = Int(select.property.select.maxPickNum)
            self.minPickNum = Int(select.property.select.minPickNum)

            for childID in select.childIds where !childID.isEmpty {
                guard let progress = elements[childID], progress.property.hasProgress else { break }
                self.rawItems.append(progress.property.progress)
            }
        }

        // footer
        if let element = elements[parentIDs[2]] {
            if element.tag == .p, element.childIds.count == 2 {
                guard let p1 = elements[element.childIds[0]],
                    let p2 = elements[element.childIds[1]] else { return }

                var text = ""
                for p1Child in p1.childIds {
                    guard let textNode = elements[p1Child], textNode.tag == .text else { return }
                    text += textNode.property.text.content
                }
                text += "\n"
                for p2Child in p2.childIds {
                    guard let textNode = elements[p2Child], textNode.tag == .text else { return }
                    text += textNode.property.text.content
                }
                footerText = text
            }

            // button
            if element.tag == .p, element.childIds.count == 1,
                let button = elements[element.childIds[0]],
                button.tag == .button {
                self.footerText = ""

                guard button.childIds.count == 2 else { return }
                self.buttonActionID = button.property.button.actionID

                if let buttonDisable = elements[button.childIds[0]], buttonDisable.tag == .text {
                    self.buttonDisableTitle = buttonDisable.property.text.content
                }
                if let buttonEnable = elements[button.childIds[1]], buttonEnable.tag == .text {
                    self.buttonEnableTitle = buttonEnable.property.text.content
                }
            }
        }
    }

    // 1 vote
    private func _voteNumberText(_ progress: SelectProperty) -> String {
        return progress.numberOfSelected > 1
            ? String(format: BundleI18n.LarkMessageCore.Lark_Legacy_MessageCardVoteTicketMulti,
                     "\(progress.numberOfSelected)")
            : String(format: BundleI18n.LarkMessageCore.Lark_Legacy_MessageCardVoteTicketSingle,
                     "\(progress.numberOfSelected)")
    }

    // 容器内放置的子Component
    public var content: [ComponentWithContext<C>] {
        var result: [ComponentWithContext<C>] = []

        for (index, item) in rawItems.enumerated() {
            let props = VoteItemComponentProps()
            props.itemProperty = item
            props.detail = item.content
            props.title = item.optionCase
            props.isSelected = item.selected
            props.voteNumberText = _voteNumberText(item)
            props.enable = !item.disable
            props.maxPickNum = maxPickNum
            props.key = item.optionCase
            if !item.disable {
                props.isSelected = customSelectedItems.contains(item)
            }
            props.onViewClicked = { [weak self] item in
                self?.onSelectItemDidClick(item: item)
            }

            if item.numberOfSelected == 0 || item.numberOfTotal == 0 {
                props.progressText = "00.0%"
                props.progressValue = 0
            } else {
                let percent = CGFloat(item.numberOfSelected) / CGFloat(item.numberOfTotal)
                props.progressText = "\(String(format: "%.1f", percent * 100))%"
                props.progressValue = percent
            }

            let style = ASComponentStyle()
            style.marginBottom = (index == rawItems.count - 1) ? 0 : 16
            result.append(VoteItemComponent<C>(props: props, style: style))
        }
        return result
    }
}

public final class MessageDetailVoteContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VoteContentViewModelContext>: VoteContentViewModel<M, D, C> {
    override public var hasBottomMargin: Bool {
        return true
    }
}

public final class PinVoteContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VoteContentViewModelContext>: VoteContentViewModel<M, D, C> {
    override public var contentPreferMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message) - 2 * metaModelDependency.contentPadding
    }

    public var pinVoteContent: [ComponentWithContext<C>] {
        var result: [ComponentWithContext<C>] = []
        let maxLine = 4
        for (index, item) in rawItems.enumerated() {
            let props = UILabelComponentProps()
            props.text = index == (maxLine - 1) ? "..." : "\(item.optionCase). \(item.content)"
            props.font = UIFont.ud.body2
            props.numberOfLines = 1
            props.textColor = UIColor.ud.N500
            let style = ASComponentStyle()
            style.marginBottom = (index == rawItems.count - 1) || index == (maxLine - 1) ? 0 : 2
            style.backgroundColor = UIColor.clear
            result.append(UILabelComponent<C>(props: props, style: style))
            if index == (maxLine - 1) {
                break
            }
        }
        return result
    }

    public var pinVoteIcon: UIImage {
        return BundleResources.pinVoteTip
    }
}
