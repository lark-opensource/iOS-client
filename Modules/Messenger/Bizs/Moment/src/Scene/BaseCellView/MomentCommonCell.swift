//
//  MomentCommonCell.swift
//  Moment
//
//  Created by zc09v on 2021/1/6.
//

import UIKit
import Foundation
import AsyncComponent
import EETroubleKiller
import UniverseDesignColor
import LarkUIKit

/// 通用的消息相关的Cell
open class MomentCommonCell: UITableViewCell {
    public static let highlightViewKey = "MomentComponentKey_highlight_key"
    public static let highlightDuration: TimeInterval = 3

    /// cell的唯一标识符（例如消息id）
    public private(set) var cellId: String = ""

    private var renderer: ASComponentRenderer?

    /// 更新cell
    ///
    /// - Parameters:
    ///   - renderer: 渲染引擎（包含布局等信息）
    ///   - cellId: cell的唯一标识（例如消息id）
    public func update(with renderer: ASComponentRenderer, cellId: String) {
        self.cellId = cellId
        renderer.bind(to: self.contentView)
        UIView.setAnimationsEnabled(false)
        renderer.render(self.contentView)
        UIView.setAnimationsEnabled(true)
        self.renderer = renderer
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
    }

    /// 内容区域高亮
    public func highlightView(timeOffset: Double = 0.0) {
        if timeOffset >= MomentCommonCell.highlightDuration {
            return
        }
        let view = self.contentView
        let backgroundColor = UIColor.ud.Y100 & UIColor.ud.Y50
        //当timeOffset=0时，MomentCommonCell.highlightDuration的前一半时间backgroundColor.withAlphaComponent=1，后一半时间渐变为0。
        var secondKeyFrameStartTime = (MomentCommonCell.highlightDuration / 2 - timeOffset) / (MomentCommonCell.highlightDuration - timeOffset)
        var alphaComponentForBegin = 1.0
        if secondKeyFrameStartTime <= 0 {
            secondKeyFrameStartTime = 0
            alphaComponentForBegin = (MomentCommonCell.highlightDuration - timeOffset) / MomentCommonCell.highlightDuration * 2
        }
        view.backgroundColor = backgroundColor.withAlphaComponent(alphaComponentForBegin)
        UIView.animateKeyframes(withDuration: MomentCommonCell.highlightDuration - timeOffset, delay: 0, options: .allowUserInteraction, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: secondKeyFrameStartTime, animations: {
                view.backgroundColor = backgroundColor.withAlphaComponent(alphaComponentForBegin)
            })
            UIView.addKeyframe(withRelativeStartTime: secondKeyFrameStartTime, relativeDuration: 1.0 - secondKeyFrameStartTime, animations: {
                view.backgroundColor = backgroundColor.withAlphaComponent(0)
            })
        }, completion: { _ in
            view.backgroundColor = .clear
        })
    }

    /// 通过key获取cell上的view
    ///
    /// - Parameter key: 指定的cell的key
    /// - Returns: 对应的view
    public func getView(by key: String) -> UIView? {
        return renderer?.getView(by: key)
    }

    public override var frame: CGRect {
        didSet {
            if Display.pad {
                super.frame = MomentsViewAdapterViewController.computeCellFrame(originFrame: frame)
            }
        }
    }
}
