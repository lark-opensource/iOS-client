//
//  FlodChatterLayout.swift
//  LarkMessageCore
//
//  Created by Bytedance on 2022/9/23.
//

import Foundation
import UIKit

/// 头像 - 名字 - 数量之间的间距
let intervalBetweenAvatarAndName: CGFloat = 4.0
let intervalBetweenNameAndNumber: CGFloat = 3.0

/// 输入为[FlodChatter]，计算出每个Chatter占用的大小、frame
/// 注意：未支持padding、一行Chatter整体居中、Chatter名字最长撑满一行不折行
struct FlodChatterLayout {
    /// Layout配置
    struct Config {
        /// Chatter纵向之间的间距
        var intervalForVertical: CGFloat = 8.0
        /// Chatter横向之间的间距
        var intervalForHorizontal: CGFloat = 12.0
    }
    private let config: FlodChatterLayout.Config

    /// Layout后能渲染出来的Chatter，相对init传入的剔除了未渲染的
    private(set) var chatters: [FlodChatter] = []

    /// Layout结果，执行完func layout(size: CGSize)后值有效
    /// 所有、每个Chatter占用多少大小
    private(set) var contentSize: CGSize = .zero
    private(set) var chatterFrames: [FlodChatterFrame] = []

    init(chatters: [FlodChatter], config: FlodChatterLayout.Config = FlodChatterLayout.Config()) {
        self.chatters = chatters
        self.config = config
    }

    /// 注意，计算得到的的size.width = limitSize.width，这样做可以：
    /// 1. 减少Flex重新执行本layout的次数
    /// 2. 一行Chatter整体居中的效果：渲染时直接可以用计算好的chatterFrames，无需再根据实际view.size做调整
    mutating func layout(_ limitSize: CGSize) {
        // 之前算好的chatter占用的总高度，包含间距
        var allHeightForChatterFrames: CGFloat = 0
        // 当前行能展示下的所有ChatterFrame
        var chatterFramesForCurrentLine: [FlodChatterFrame] = []
        // 展示的总高度是否已经达到limitSize.height限制
        var allHeightForChatterOverLimitHeight: Bool = false

        // 对chatterFramesForCurrentLine中的chatterFrame进行布局
        func layoutChatterFramesForCurrentLine() {
            // 得到当前行所有chatter占用的最大高度
            var allChatterFrameMaxHeight: CGFloat = 0
            chatterFramesForCurrentLine.forEach { allChatterFrameMaxHeight = max(allChatterFrameMaxHeight, $0.contentFrame.height) }
            // 当前行Y方向上的起始点 = 之前算好的chatter占用的总高度 + 纵向间距
            let chatterOriginYOffset: CGFloat = self.chatterFrames.isEmpty ? 0 : (allHeightForChatterFrames + self.config.intervalForVertical)
            // 如果展示不了当前行，则无需展示，当前和后续的chatter也同步丢弃，直接返回结果
            if chatterOriginYOffset + allChatterFrameMaxHeight > limitSize.height {
                allHeightForChatterOverLimitHeight = true
                return
            }

            // 得到当前行所有chatter占用的总宽度，需要加上间距
            var allChatterFrameWidth: CGFloat = 0
            chatterFramesForCurrentLine.forEach { allChatterFrameWidth += $0.contentFrame.width }
            allChatterFrameWidth += CGFloat((chatterFramesForCurrentLine.count - 1)) * self.config.intervalForHorizontal
            // 得到布局第一个chatter的X起始点，做到整体居中展示效果
            var chatterOriginXOffset: CGFloat = (limitSize.width - allChatterFrameWidth) / 2

            // 设置chatter的头像、名称、数量origin
            for index in 0..<chatterFramesForCurrentLine.count {
                var chatterFrame = chatterFramesForCurrentLine[index]
                // 调整头像、名字、数字frame
                chatterFrame.contentFrame.origin = CGPoint(x: chatterOriginXOffset, y: chatterOriginYOffset + (allChatterFrameMaxHeight - chatterFrame.contentFrame.size.height) / 2)
                chatterFrame.adjustAvatarAndNameAndNumberFrame()

                // 添加进结果数组
                self.chatterFrames.append(chatterFrame)

                // chatterOriginXOffset修正，加上当前chatter的宽度 + 间距
                chatterOriginXOffset += (chatterFrame.contentFrame.size.width + self.config.intervalForHorizontal)
            }

            // 更新所有chatter占用的总高度
            allHeightForChatterFrames = chatterOriginYOffset + allChatterFrameMaxHeight
        }

        // 遍历所有的Chatter，开始布局计算
        self.chatters.forEach { chatter in
            // 展示的总高度是否已经达到limitSize.height限制，后续的chatter无需计算
            if allHeightForChatterOverLimitHeight { return }

            // 存储布局计算结果
            var chatterFrame = FlodChatterFrame()
            // 布局头像、名字、数字size；确认contentFrame
            chatterFrame.layoutAvatarAndNameAndNumberSize(chatter: chatter, limitSize: limitSize)

            // 看这个Chatter能否在当前行展示下，如果能展示下，则继续处理下一个Chatter
            if chatterFramesForCurrentLine.isEmpty { chatterFramesForCurrentLine = [chatterFrame]; return }
            // 这个Chatter的origin.x在什么位置 = MaxX(前一个Chatter) + 间距
            let originXForCurrChatter = (chatterFramesForCurrentLine.last?.contentFrame.maxX ?? 0) + self.config.intervalForHorizontal + chatterFrame.contentFrame.width
            if originXForCurrChatter <= limitSize.width {
                chatterFrame.contentFrame.origin.x = (chatterFramesForCurrentLine.last?.contentFrame.maxX ?? 0) + self.config.intervalForHorizontal
                chatterFramesForCurrentLine.append(chatterFrame)
                return
            }

            // 如果需要换行，则需要先把当前行的chatterFrame进行布局计算
            layoutChatterFramesForCurrentLine()
            // 展示的总高度是否已经达到limitSize.height限制，后续的chatter无需计算
            if allHeightForChatterOverLimitHeight { return }

            // 把当前chatter插入到下一行进行展示
            chatterFramesForCurrentLine = [chatterFrame]
        }

        // 展示的总高度是否已经达到limitSize.height限制，后续的chatter无需计算
        if !allHeightForChatterOverLimitHeight { layoutChatterFramesForCurrentLine() }

        // 设置所有Chatter占用的size
        self.contentSize = CGSize(width: limitSize.width, height: allHeightForChatterFrames)
        // 移除没有参与计算的chatter
        if self.chatterFrames.count != self.chatters.count {
            self.chatters = Array(self.chatters.prefix(self.chatterFrames.count))
        }
    }
}
