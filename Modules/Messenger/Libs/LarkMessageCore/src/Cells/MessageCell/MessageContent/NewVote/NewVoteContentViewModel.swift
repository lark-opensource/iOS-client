//
//  NewVoteContentViewModel.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/4/2.
//

import Foundation
import AsyncComponent
import LarkMessageBase
import LarkModel
import LarkUIKit
import UIKit
import RustPB
import LarkCore
import EEFlexiable
import LarkVote
import LKCommonsLogging
import EENavigator
import RxSwift
import Swinject
import LarkContainer
import LarkSDKInterface
import LarkAccountInterface
import UniverseDesignToast
import LarkRustClient
import UniverseDesignActionPanel
import UniverseDesignIcon

public typealias VotedInfo = RustPB.Vote_V1_VotedInfo
public typealias Voter = RustPB.Basic_V1_Chatter

// VM 最小依赖
public protocol NewVoteContentViewModelContext: PageContext {
    func getContentPreferMaxHeight(_ message: Message) -> CGFloat
    var scene: ContextScene { get }
}

public class NewVoteContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: NewVoteContentViewModelContext>: MessageSubViewModel<M, D, C> {
    public override var identifier: String {
        return "new_vote"
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

    @PageContext.InjectedLazy private var voteService: LarkVoteService?

    private let logger = Logger.log("NewVoteContentViewModel")
    let disposeBag = DisposeBag()

    public var contentPreferMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message)
    }

    public var contentPreferMaxHeight: CGFloat {
        return context.getContentPreferMaxHeight(message)
    }

    public var hasBottomMargin: Bool {
        return message.reactions.isEmpty
    }

    var voteMessageContent: VoteContent {
        get {
            return (message.content as? VoteContent) ?? .transform(pb: RustPB.Basic_V1_Message())
        }
        set {
            message.content = newValue
        }
    }

    // 投票信息
    private var votedInfo: VotedInfo {
        get {
            return message.votedInfo ?? VotedInfo()
        }
        set {
            message.votedInfo = newValue
        }
    }

    // 投票人
    private var voters: [String: Voter] {
        get {
            return message.voters
        }
        set {
            message.voters = newValue
        }
    }

    // 本地选中的item, 记录cell indetifier
    public var customSelectedItems: [Int] = []

    public var contentCellProps: [LarkVoteContentCellProps] = []

    var maxSelectCnt: Int {
        return Int(voteMessageContent.maxPickNum)
    }

    var minSelectCnt: Int {
        return Int(voteMessageContent.minPickNum)
    }

    // 总的已投票人数
    var totalVoteCnt: Int {
        return Int(votedInfo.votedNumber)
    }

    var voteClose: Bool {
        get {
            return voteMessageContent.status == .close
        }
        set {
            voteMessageContent.status = newValue ? .close : .open
        }
    }

    var isVoted: Bool {
        if message.fromChatter?.type == .bot {
            return true
        }
        return votedInfo.isVoted
    }

    var showResult: Bool {
        return voteClose || isVoted
    }

    // 是否允许折叠
    private(set) var flodEnable: Bool = true

    var isSponsor: Bool {
        return String(voteMessageContent.initiator) == self.context.currentUserID
    }

    var isPublic: Bool {
        return voteMessageContent.isPublic
    }

    // MARK: - Text

    // Vote Title Text
    var title: String {
        return voteMessageContent.topic
    }

    // Vote Type Text
    var voteTagInfos: [String] {
        var tagInfos: [String] = []
        if maxSelectCnt > 1 {
            tagInfos.append(BundleI18n.LarkMessageCore.Lark_IM_Poll_Detail_MultipleAnswers_Label)
        } else {
            tagInfos.append(BundleI18n.LarkMessageCore.Lark_IM_Poll_Detail_SingleAnswer_Label)
        }
        if isPublic {
            tagInfos.append(BundleI18n.LarkMessageCore.Lark_IM_Poll_Detail_NonAnonymous_Label)
        } else {
            tagInfos.append(BundleI18n.LarkMessageCore.Lark_IM_Poll_Detail_Anonymous_Label)
        }
        return tagInfos
    }

    // Vote Result Text
    var voteResultText: String {
        if !showResult {
            return ""
        }
        var result: String = ""
        var voterNumText = BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_ExpectedParticipants_Text(votedInfo.voterNumber)
        var actualVoterNumText = BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_ActualParticipants_Text(totalVoteCnt)
        result = voterNumText + "   " + actualVoterNumText
        return result
    }

    // MARK: - Button
    var voteButtonTitle: String {
        if showResult {
            return ""
        } else {
            if voteButtonEnabled {
                return BundleI18n.LarkMessageCore.Lark_IM_Poll_Detail_VoteNow_Button
            } else {
                return BundleI18n.LarkMessageCore.Lark_IM_Poll_Detail_SelectAndVote_Button
            }
        }
    }

    var voteButtonEnabled: Bool {
        if customSelectedItems.count >= minSelectCnt && customSelectedItems.count <= maxSelectCnt {
            return true
        } else {
            return false
        }
    }

    var resendButtonTitle: String {
        if voteClose {
            return BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_PollEnded_Button
        } else {
            return BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_ResendPollMessageToChat_Button
        }
    }

    var resendButtonEnabled: Bool {
        return voteClose ? false : true
    }

    var closeButtonTitle: String {
        return voteClose ? "" : BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_EndPoll_Button
    }

    var closeButtonEnabled: Bool {
        return voteClose ? false : true
    }

    var showMoreButtonTitle: String {
        return BundleI18n.LarkMessageCore.Lark_IM_Poll_Detail_AllOptions_Button
    }

    init(metaModel: M,
         metaModelDependency: D,
         context: C,
         binder: ComponentBinder<C>,
         foldEnable: Bool = true) {
        self.flodEnable = foldEnable
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public func updateVoteInfo() {
        if contentCellProps.isEmpty {
            for option in self.voteMessageContent.options {
                var cell = LarkVoteContentCellProps()
                cell.itemTitle = option.content
                cell.identifier = Int(option.index)
                cell.isMutilSelect = self.maxSelectCnt > 1
                cell.avatarViewClickBlock = { [weak self] (identifier) in
                    self?.onItemAvatarsDidClick(identifier: identifier)
                }
                contentCellProps.append(cell)
            }
            // 防止顺序错乱
            contentCellProps = contentCellProps.sorted {
                $0.identifier < $1.identifier
            }
        }

        if !showResult {
            for cell in contentCellProps {
                cell.isSelected = self.customSelectedItems.contains(cell.identifier)
            }
        } else if contentCellProps.count == votedInfo.votedIndexInfo.count {
            // 总票数
            var totalCnt = votedInfo.votedIndexInfo.map({ Int($0.count) }).reduce(0, +)
            for itemInfo in votedInfo.votedIndexInfo {
                let index = Int(itemInfo.index)
                guard index < contentCellProps.count else {
                    return
                }
                var cell = contentCellProps[index]
                cell.showResult = self.showResult
                if totalCnt != 0 {
                    cell.itemPercentNum = CGFloat(itemInfo.count) / CGFloat(totalCnt)
                }
                let voteCountText = BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_NumberOfVotes_Text(itemInfo.count)
                let percentText = String(format: "%.2f%%", cell.itemPercentNum * 100)
                cell.itemResultText = voteCountText + "    " + percentText
                cell.isSelected = votedInfo.votedIndexes.contains(Int64(itemInfo.index))
                // 实名投票的信息
                if isPublic {
                    var avatarList: [AvatarInfo] = []
                    for index in 0 ..< itemInfo.users.count {
                        // 获取头像信息
                        let userID = String(itemInfo.users[index])
                        let avatarKey = self.voters[userID]?.avatar.key ?? ""
                        let avatarInfo = AvatarInfo(avatarKey: avatarKey, userId: userID)
                        avatarList.append(avatarInfo)
                    }
                    cell.avatarKeyList = avatarList
                    cell.itemCntNum = Int(itemInfo.count)
                }
            }
        }
    }
}

// MARK: - Action
private protocol Action { }
extension NewVoteContentViewModel: Action {
    // CheckBox点击事件
    public func onItemDidSelect(identifier: Int) {
        if self.customSelectedItems.contains(identifier) {
            if self.maxSelectCnt > 1 {
                self.customSelectedItems.removeAll(where: {
                    $0 == identifier
                })
            }
        } else {
            if self.maxSelectCnt <= 1 {
                self.customSelectedItems.removeAll()
            }
            self.customSelectedItems.append(identifier)
        }
        self.logger.info("select item change to: \(self.customSelectedItems.description)")
        self.binder.update(with: self)
    }

    public func onItemAvatarsDidClick(identifier: Int) {
        // 点击头像事件,跳转到Detail页
        guard let indexInfo = self.votedInfo.votedIndexInfo.first(where: { $0.index == identifier })  else { return }
        guard identifier < self.voteMessageContent.options.count else { return }
        guard let voteService = self.voteService else { return }
        let voteID = Int(voteMessageContent.uuid)
        let scopeID = self.voteMessageContent.scopeID
        let voteInitiatorID = String(self.voteMessageContent.initiator)
        let chatID = self.message.chatID
        let viewModel = NewVoteDetailInfoViewModel(voteID: voteID,
                                                   index: identifier,
                                                   scopeID: scopeID,
                                                   initiatorID: voteInitiatorID,
                                                   chatID: chatID,
                                                   voteService: voteService,
                                                   nav: self.context.navigator)
        let titleText = self.voteMessageContent.options[identifier].content
        let countText = "（\(indexInfo.count)）"
        let vc = NewVoteDetailInfoViewController(title: titleText, countText: countText, viewModel: viewModel)
        guard let targetVC = self.context.targetVC else { return }
        self.context.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: targetVC,
            prepare: { $0.modalPresentationStyle = .formSheet })
    }

    public func showMoreAction() {
        self.flodEnable = false
        self.binder.update(with: self)
    }

    public func sendAction() {
        let chat = self.metaModel.getChat()
        if chat.isInMeetingTemporary {
            if let targetVC = self.context.targetVC {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_TemporaryJoinMeetingFunctionUnavailableNotice_Desc, on: targetVC.view)
            }
            return
        }
        // 发送事件
        let voteID = Int(voteMessageContent.uuid)
        let params = self.customSelectedItems
        let scopID = self.voteMessageContent.scopeID
        self.logger.info("send vote with index : \(params.description), voteID: \(voteID)")
        guard !params.isEmpty else {
            return
        }
        voteService?.sendAction(voteID: voteID, scopID: scopID, params: params).subscribe(onNext: { [weak self] resp in
            guard let self = self else { return }
            self.logger.info("vote: \(voteID) send success!!!")
            guard resp.voteID == self.voteMessageContent.uuid,
                  let voteInfo = resp.entity.votedInfos[resp.voteID],
                  voteInfo.version > self.votedInfo.version else {
                      return
                  }
            self.votedInfo = voteInfo
            self.voters = resp.entity.chatters
            let chatID = self.message.chatID
            self.voters = resp.entity.chatChatters[chatID]?.chatters ?? resp.entity.chatters
            // 更新数据
            self.binder.update(with: self)
        }, onError: { [weak self] error in
            guard let self = self else { return }
            if case .businessFailure(errorInfo: let info) = error as? RCError {
                DispatchQueue.main.async {
                    if let window = self.context.targetVC?.view {
                        UDToast.showFailure(with: info.displayMessage, on: window)
                    }
                }
            }
            self.logger.info("vote: \(voteID) send fail with error >>> \(error)")
        }).disposed(by: disposeBag)
    }

    public func resendAction() {
        // 重发到本群
        let config = UDActionSheetUIConfig(isShowTitle: true)
        let actionSheet = UDActionSheet(config: config)
        let title = message.fromChatter?.type == .bot ? BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_ResendPollMessageToChat_Title
     : BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_ResendPollMessageToChat_Title2
        actionSheet.setTitle(title)
        actionSheet.addDefaultItem(text: BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_ResendPollMessageToChat_Resend_Button) { [weak self] in
            guard let self = self else { return }
            // 请求重新发送投票
            let voteID = Int(self.voteMessageContent.uuid)
            self.logger.info("resend vote to the group with voteID: \(voteID)")
            self.voteService?.resendAction(voteID: voteID).subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("vote: \(voteID) resend Success!!!")
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if case .businessFailure(errorInfo: let info) = error as? RCError {
                    DispatchQueue.main.async {
                        if let window = self.context.targetVC?.view {
                            UDToast.showFailure(with: info.displayMessage, on: window)
                        }
                    }
                }
                self.logger.error("vote: \(voteID) resend fail with error >>> \(error)")
            }).disposed(by: self.disposeBag)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_ResendPollMessageToChat_Cancel_Button)
        guard let targetVC = self.context.targetVC else { return }
        self.context.navigator.present(actionSheet, from: targetVC)
    }

    public func closeAction() {
        //  关闭投票事件
        let config = UDActionSheetUIConfig(isShowTitle: true)
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_EndPoll_Title)
        let item = UDActionSheetItem(
            title: BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_EndPoll_End_Button,
            titleColor: UIColor.ud.functionDangerContentDefault,
            style: .default,
            isEnable: true,
            action: { [weak self] in
                guard let self = self else { return }
                // 请求结束投票
                let voteID = Int(self.voteMessageContent.uuid)
                self.logger.info("request close vote with voteID: \(voteID)")
                self.voteService?.closeAction(voteID: voteID).subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.logger.info("vote: \(voteID) close Success!!!")
                    self.voteClose = true
                    self.binder.update(with: self)
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    if case .businessFailure(errorInfo: let info) = error as? RCError {
                        DispatchQueue.main.async {
                            if let window = self.context.targetVC?.view {
                                UDToast.showFailure(with: info.displayMessage, on: window)
                            }
                        }
                    }
                    self.logger.error("vote: \(voteID) close fail with error >>> \(error)")
                }).disposed(by: self.disposeBag)
            })
        actionSheet.addItem(item)
        actionSheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_IM_Poll_Result_EndPoll_Cancel_Button)
        guard let targetVC = self.context.targetVC else { return }
        self.context.navigator.present(actionSheet, from: targetVC)
    }
}

// MARK: - MessageDetailViewModel
public final class MessageDetailNewVoteContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: NewVoteContentViewModelContext>: NewVoteContentViewModel<M, D, C> {
    override public var hasBottomMargin: Bool {
        return true
    }
}

// MARK: - MergeForwardNewVoteContentViewModel
public final class MergeForwardNewVoteContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: NewVoteContentViewModelContext>: NewVoteContentViewModel<M, D, C> {
    override public var hasBottomMargin: Bool {
        return true
    }

    public var downGradeText: String {
        return BundleI18n.LarkMessageCore.Lark_IM_Poll_PollMessage_Text
    }
}

// MARK: - PinViewModel
public final class PinNewVoteContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: NewVoteContentViewModelContext>: NewVoteContentViewModel<M, D, C> {
    override public var contentPreferMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message) - 2 * metaModelDependency.contentPadding
    }

    public var pinVoteContent: [ComponentWithContext<C>] {
        var result: [ComponentWithContext<C>] = []
        let maxLine = 4
        for (index, item) in voteMessageContent.options.enumerated() {
            // UILabel
            let labelProps = UILabelComponentProps()
            labelProps.text = index == (maxLine - 1) ? "..." : "\(item.content)"
            labelProps.font = UIFont.ud.body2
            labelProps.numberOfLines = 1
            labelProps.textColor = UIColor.ud.N500
            let labelStyle = ASComponentStyle()
            labelStyle.marginBottom = (index == voteMessageContent.options.count - 1) || index == (maxLine - 1) ? 0 : 2
            labelStyle.height = CSSValue(cgfloat: 18)
            labelStyle.marginRight = 16
            labelStyle.backgroundColor = UIColor.clear
            let labelComponent = UILabelComponent<C>(props: labelProps, style: labelStyle)
            // Checkbox
            let circleProps = NewVotePinCircleComponentProps()
            let circleStyle = ASComponentStyle()
            circleStyle.width = CSSValue(cgfloat: 8)
            circleStyle.height = CSSValue(cgfloat: 8)
            circleStyle.marginRight = CSSValue(cgfloat: 6)
            circleStyle.flexShrink = 0
            let circleComponent = NewVotePinCircleComponent<C>(props: circleProps, style: circleStyle)
            // container
            let style = ASComponentStyle()
            style.flexDirection = .row
            style.justifyContent = .flexStart
            style.alignItems = .center
            style.marginTop = 4
            if index == (maxLine - 1) {
                style.marginLeft = 14
                let cell = ASLayoutComponent(style: style, context: context, [labelComponent])
                result.append(cell)
                break
            } else {
                let cell = ASLayoutComponent(style: style, context: context, [circleComponent, labelComponent])
                result.append(cell)
            }
        }
        return result
    }

    public var pinVoteIcon: UIImage {
        return  UDIcon.getIconByKey(.voteColorful, iconColor: UIColor.ud.primaryOnPrimaryFill)
    }
}
