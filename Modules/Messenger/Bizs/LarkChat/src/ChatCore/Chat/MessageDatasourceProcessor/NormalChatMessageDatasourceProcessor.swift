//
//  NormalChatMessageDatasourceProcessor.swift
//  LarkChat
//
//  Created by ByteDance on 2023/10/17.
//

import Foundation
import LarkModel

class NormalChatMessageDatasourceProcessor: BaseChatMessageDatasourceProcessor {
    override func processBeforFirst(message: Message) -> [CellVMType] {
        var types: [CellVMType] = self.getStickToTopCellVMType()
        if message.isBadged,
           let readPositionBadgeCount = dependency?.readPositionBadgeCount,
            message.badgeCount == readPositionBadgeCount + 1 {
            // 以下是新消息气泡
            types.append(.signDate(message.createTime))
        } else {
            // 日期气泡
            types.append(.date(message.createTime))
        }
        types.append(.time(message.createTime))

        types.append(generateCellVMTypeForMessage(prev: nil, cur: message, mustBeSingle: true))
        return types
    }

    override func process(prev: Message, cur: Message) -> [CellVMType] {
        var types: [CellVMType] = []
        var mustBeSingle = false
        var isNewDay = false

        // 不在同一天，则显示日期：9月5日 11:00
        if let dateType = createDateViewModelIfNeeded(prev: prev, cur: cur) {
            types.append(dateType)
            mustBeSingle = true
            isNewDay = true
        }
        // 是否显示后两种情况 1.以下是新消息；2.以下是新消息 9月5日 11:00
        if let newMessageSignType = createShowNewMessageSignViewModelIfNeeded(cur: cur, isNewDay: isNewDay) {
            // 如果是第2种情况，因为已经显示日期了，则去掉上面if添加的日期
            if isNewDay { types.removeLast() }
            types.append(newMessageSignType)
            mustBeSingle = true
        }
        // 发送间隔超出一定时长，则显示时间：11:00
        if let timeType = createTimeViewModelIfNeeded(prev: prev, cur: cur) {
            types.append(timeType)
            mustBeSingle = true
        }

        types.append(generateCellVMTypeForMessage(prev: prev, cur: cur, mustBeSingle: mustBeSingle))
        return types
    }

    /// ================== PRIVATE ==================
    /// 是否需要显示date气泡
    private func createDateViewModelIfNeeded(prev: Message, cur: Message) -> CellVMType? {
        if Calendar.current.isDate(Date(timeIntervalSince1970: prev.createTime),
                                   inSameDayAs: Date(timeIntervalSince1970: cur.createTime)) {
            return nil
        }
        return .date(cur.createTime)
    }

    /// 是否需要显示以下是新消息气泡
    private func createShowNewMessageSignViewModelIfNeeded(cur: Message, isNewDay: Bool) -> CellVMType? {
        if cur.isBadged,
           let readPositionBadgeCount = dependency?.readPositionBadgeCount,
            readPositionBadgeCount + 1 == cur.badgeCount {
            return isNewDay ? .signDate(cur.createTime) : .sign
        }
        return nil
    }

    /// 是否需要显示时间气泡
    private func createTimeViewModelIfNeeded(prev: Message, cur: Message) -> CellVMType? {
        if cur.createTime - prev.createTime <= needHourTimeLimit {
            return nil
        }
        return .time(cur.createTime)
    }
}
