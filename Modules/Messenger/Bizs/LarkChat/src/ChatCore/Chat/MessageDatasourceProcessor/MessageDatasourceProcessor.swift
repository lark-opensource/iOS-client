//
//  MessageDatasourceProcessor.swift
//  LarkChat
//
//  Created by ByteDance on 2023/10/17.
//

import Foundation
import LarkModel

protocol MessageDatasourceProcessor {
    associatedtype MessageCellVMType

    /// 还原至初始状态的 [CellVMType]
    func getCleanState() -> [CellVMType]

    /// 返回第一条消息前面的 [CellVMType]
    func processBeforFirst(message: LarkModel.Message) -> [CellVMType]

    /// 根据前后两条Message，算出应该插入哪些[CellVMType]
    func process(prev: LarkModel.Message, cur: LarkModel.Message) -> [CellVMType]

    func getCellDependency(isSingle: Bool, changeTopCorner: Bool, changeBottomCorner: Bool) -> ChatCellMetaModelDependency
}

protocol ChatMessageDatasourceProcessorDependency: AnyObject {
    var chat: () -> Chat { get }
    var readPositionBadgeCount: Int32? { get }
    var minMessagePosition: Int32 { get }
    var cellConfig: ChatCellConfig { get }
    var contentPadding: CGFloat { get }
    var container: BaseMessageContainer? { get }
}

class BaseChatMessageDatasourceProcessor: MessageDatasourceProcessor {
    typealias MessageCellVMType = CellVMType

    /// 5分钟内的消息为同一人发送，则只有第一条消息显示头像
    private let messageInSameGroupTimeLimit: TimeInterval = 300
    let needHourTimeLimit: TimeInterval = 1800

    private let isNewRecalledEnable: Bool

    weak var dependency: ChatMessageDatasourceProcessorDependency?

    private var normalCellStyleSystemTypes: [SystemContent.SystemType] {
        return SystemContent.SystemType.voipCallTypes
            + SystemContent.SystemType.byteViewTypes
            + SystemContent.SystemType.calendarTypes
    }

    init(isNewRecalledEnable: Bool) {
        self.isNewRecalledEnable = isNewRecalledEnable
    }

    /// 还原至初始状态的 [CellVMType]
    func getCleanState() -> [CellVMType] {
        return self.getStickToTopCellVMType()
    }

    /// 返回第一条消息前面的 [CellVMType]
    func processBeforFirst(message: LarkModel.Message) -> [CellVMType] {
        assertionFailure("need to be overrided")
        return []
    }

    func process(prev: LarkModel.Message, cur: LarkModel.Message) -> [CellVMType] {
        assertionFailure("need to be overrided")
        return []
    }

    func generateCellVMTypeForMessage(prev: LarkModel.Message?, cur: LarkModel.Message, mustBeSingle: Bool) -> CellVMType {
        var isSingle: Bool
        if mustBeSingle {
            isSingle = true
        } else {
            if let prev = prev,
               self.isMessagesInSameGroup(prev: prev, cur: cur) {
                //cur 和 prev在同一个group，则吸附，即isSingle是false
                isSingle = false
            } else {
                isSingle = true
            }
        }

        if isSingle {
            // 不吸附
            return .message(cur, self.getCellDependency(
                isSingle: true, changeTopCorner: false, changeBottomCorner: false
            ))
        } else {
            // 吸附
            return .message(cur, self.getCellDependency(
                isSingle: false, changeTopCorner: true, changeBottomCorner: false
            ))
        }
    }

    /// 首条消息前要展示的内容：loadMoreOld后会动态调整，只保证在数据源中首条消息前展示
    func getStickToTopCellVMType() -> [CellVMType] {
        var types: [CellVMType] = []

        guard let dependency = dependency else { return types }
        let chat = dependency.chat()
        if chat.needShowTopBanner,
            dependency.minMessagePosition <= chat.firstMessagePostion + 1,
           let topBannerTip = chat.topBannerTip {
            types.append(.topMsgTip(tip: topBannerTip))
        }

        if let featureIntroductions = dependency.container?.getFeatureIntroductions() {
            for (index, copyWriting) in featureIntroductions.enumerated() {
                if index == 0 {
                    types.append(.featureIntroduction(copyWriting: copyWriting, hasHeader: true))
                    continue
                }
                types.append(.featureIntroduction(copyWriting: copyWriting, hasHeader: false))
            }
        }
        return types
    }

    /// 两个气泡是否吸附
    func isMessagesInSameGroup(prev: LarkModel.Message, cur: LarkModel.Message) -> Bool {
        if let prevContent = prev.content as? SystemContent,
            !normalCellStyleSystemTypes.contains(prevContent.systemType) {
            // 如果前一个消息是系统消息样式，肯定不吸附
            return false
        }
        // 有话题回复的消息上下均不吸附
        if prev.threadMessageType == .threadRootMessage || cur.threadMessageType == .threadRootMessage {
            return false
        }
        // 有话题回复的消息上下均不吸附
        if prev.isFoldRootMessage || cur.isFoldRootMessage {
            return false
        }
        if prev.fromIdForUI != cur.fromIdForUI {
            return false
        }
        if prev.isEphemeral != cur.isEphemeral {
            return false
        }
        if isNewRecalledEnable, (prev.isRecalled || cur.isRecalled) {
            return false
        }
        return cur.createTime - prev.createTime <= messageInSameGroupTimeLimit
    }

    func getCellDependency(isSingle: Bool, changeTopCorner: Bool, changeBottomCorner: Bool) -> ChatCellMetaModelDependency {
        /// 单聊不显示名字和状态
        var config = self.dependency?.cellConfig ?? .default
        config.isSingle = isSingle
        config.changeTopCorner = changeTopCorner
        config.changeBottomCorner = changeBottomCorner
        return ChatCellMetaModelDependency(
            contentPadding: self.dependency?.contentPadding ?? 0,
            contentPreferMaxWidth: { [weak self] message in
                assert(self?.dependency?.container != nil, "please set container before use")
                return self?.dependency?.container?.getContentPreferMaxWidth(message) ?? 0
            },
            config: config
        )
    }
}
