//
//  ReactionContainerView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/10/11.
//

import UIKit
import ByteViewCommon
import ByteViewUI

protocol ReactionContainerViewDataSource: AnyObject {
    // iPad 字幕避让逻辑：字幕显示时，将字幕所在的区域移除，不会在这部分生成新表情，否则全屏可以显示
    // iPhone 字幕避让逻辑：字幕显示时，新表情出生地整体高度上移（旧表情不变）
    var subtitleFrame: CGRect? { get }
}

class ReactionContainerView: UIView {
    private var reactionItems: [ReactionItem] = []
    private let emotion: EmotionDependency
    private let animator: ReactionAnimator
    weak var dataSource: ReactionContainerViewDataSource?

    // 以下变量用来实现屏幕尺寸变化时维持表情相对位置的逻辑
    private var xRatios: [CGFloat] = []
    private var yPositions: [CGFloat] = []
    private var lastFrame = CGRect.zero

    init(emotion: EmotionDependency, animator: ReactionAnimator) {
        self.emotion = emotion
        self.animator = animator
        super.init(frame: .zero)
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addReaction(userID: String, sender: String, reactionKey: String, count: Int, duration: TimeInterval) {
        if let existed = reactionItems.first(where: { $0.userID == userID && $0.reactionKey == reactionKey }) {
            // 如果是同一个用户发的同一个表情（连发），直接更新该表情的 count
            existed.view.update(senderName: sender, reactionKey: reactionKey, count: count)
            return
        }

        let reactionView = FloatReactionView(emotion: self.emotion)
        reactionView.update(senderName: sender, reactionKey: reactionKey, count: count)
        addSubview(reactionView)
        reactionView.layoutIfNeeded()
        reactionView.frame.origin = reactionPosition(reactionView, in: bounds)

        let reactionItem = ReactionItem(userID: userID, reactionKey: reactionKey, reactionView: reactionView)
        reactionItems.append(reactionItem)

        animator.showReaction(reactionView, duration: duration) {
            reactionView.removeFromSuperview()
            if let index = self.reactionItems.firstIndex(of: reactionItem) {
                self.reactionItems.remove(at: index)
            }
        }
    }

    func hideOtherUserReaction(currentUserId: String) {
        reactionItems = reactionItems.filter {
            if $0.userID != currentUserId {
                $0.view.removeFromSuperview()
                return false
            }
            return true
        }
    }

    func viewLayoutContextWillChange(to context: VCLayoutContext) {
        yPositions = []
        xRatios = []
        lastFrame = frame
        for reactionItem in reactionItems {
            yPositions.append(reactionItem.view.frame.minY)
            xRatios.append(reactionItem.view.frame.minX / frame.width)
            reactionItem.view.isHidden = true
        }
    }

    func viewLayoutContextDidChange() {
        for (i, reactionItem) in reactionItems.enumerated() {
            guard let xRatio = xRatios[safeAccess: i], let yPosition = yPositions[safeAccess: i] else { continue }
            let newOrigin = CGPoint(x: frame.width * xRatio, y: yPosition + (frame.height - lastFrame.height))
            reactionItem.view.frame.origin = newOrigin
            reactionItem.view.isHidden = false
        }
    }

    private func reactionPosition(_ reactionView: FloatReactionView, in bounds: CGRect) -> CGPoint {
        let subtitleFrame = dataSource?.subtitleFrame

        // -30: 最大连击数（999）超出 reactionView.bounds.width 的宽度，减掉这 22 保证整个 reaction 包括连击都不会超出屏幕
        let total = 0..<Int(bounds.width - reactionView.bounds.width - 22)
        // 避让最后发出的5个表情
        let reactionsToAvoid = reactionItems.suffix(5)
        var used = reactionsToAvoid.map { Int($0.view.frame.minX)..<Int($0.view.frame.maxX) }
        var shouldAvoidVertically = false

        if let subtitleFrame = subtitleFrame {
            shouldAvoidVertically = subtitleFrame.maxY > (bounds.height * 0.7)
            if shouldAvoidVertically && Display.pad {
                used.append(Int(subtitleFrame.minX)..<Int(subtitleFrame.maxX))
            }
        }
        used = used.sorted(by: { $0.lowerBound < $1.lowerBound })

        var available = ranges(total, outsideOf: used)
        if available.isEmpty {
            // 如果空间已经被用完，即重合不可避免，则随机取一个位置
            available.append(total)
        }

        // 首先在可用空间中找出最大空间
        let _selected = available.min { $0.count > $1.count } ?? total
        var selected = CGFloat(_selected.lowerBound)..<CGFloat(_selected.upperBound)
        if selected.upperBound - reactionView.bounds.width > selected.lowerBound {
            selected = selected.lowerBound..<(selected.upperBound - reactionView.bounds.width)
        }
        // 其次在当前最大空间内随机一个坐标
        let x = CGFloat.random(in: selected)
        var y = bounds.height - reactionView.bounds.height
        if Display.phone && shouldAvoidVertically {
            y -= VCScene.isLandscape ? 48 : 96
        }
        let res = CGPoint(x: x, y: y)
        return res
    }

    private func ranges(_ total: Range<Int>, outsideOf ranges: [Range<Int>]) -> [Range<Int>] {
        var res: [Range<Int>] = []
        var lastEnd = total.startIndex
        for range in ranges {
            if range.lowerBound > lastEnd {
                res.append(Range(uncheckedBounds: (lastEnd, range.lowerBound)))
            }
            if range.upperBound > lastEnd {
                lastEnd = range.upperBound
            }
        }
        if lastEnd < total.endIndex {
            res.append(Range(uncheckedBounds: (lastEnd, total.endIndex)))
        }
        return res
    }
}

private class ReactionItem: Equatable {
    var userID: String
    var reactionKey: String
    let view: FloatReactionView

    init(userID: String, reactionKey: String, reactionView: FloatReactionView) {
        self.userID = userID
        self.reactionKey = reactionKey
        self.view = reactionView
    }

    static func == (lhs: ReactionItem, rhs: ReactionItem) -> Bool {
        return lhs.userID == rhs.userID && lhs.reactionKey == rhs.reactionKey
    }
}
