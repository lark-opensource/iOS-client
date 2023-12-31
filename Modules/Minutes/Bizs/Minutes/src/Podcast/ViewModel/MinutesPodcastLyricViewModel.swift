//
//  MinutesPodcastLyricViewModel.swift
//  Minutes
//
//  Created by yangyao on 2021/4/1.
//

import Foundation
import CoreGraphics
import UIKit
import MinutesFoundation
import MinutesNetwork
import YYText

class MinutesPodcastLyricViewModel {
    let subtitleItem: OverlaySubtitleItem
    var isCurrentLyric: Bool = false
    var isHitLyricHighlighted: Bool = false

    let pIndex: NSInteger

    var cellHeight: CGFloat = 0.0

    let leftMargin: CGFloat = 20
    let rightMargin: CGFloat = 20

    public var attributedText: NSMutableAttributedString {
        let color = isCurrentLyric ? .white : (isHitLyricHighlighted ? .white : UIColor(white: 1.0, alpha: 0.35))
        let attributedText = NSMutableAttributedString(string: subtitleItem.content, attributes: [.foregroundColor: color])
        attributedText.yy_font = isCurrentLyric ? UIFont.systemFont(ofSize: 26) : UIFont.systemFont(ofSize: 20)
        attributedText.yy_minimumLineHeight = MinutesPodcastLyricCell.LayoutContext.yyTextLineHeight
        return attributedText
    }

    var containerWidth: CGFloat

    var yyTextWidth: CGFloat {
        return containerWidth - leftMargin - rightMargin
    }

    var layout: YYTextLayout? {
        let size = CGSize(width: yyTextWidth, height: CGFloat.greatestFiniteMagnitude)
        let layout = YYTextLayout(containerSize: size, text: attributedText)
        return layout
    }

    lazy var lyricStartTime: String = {
        var timeStr = lyricStartTimeInterval.autoFormat() ?? ""
        return timeStr
    }()

    lazy var lyricStartTimeInterval: TimeInterval = {
        let time = TimeInterval(subtitleItem.startTime)
        let timeInterval = time / 1000
        return timeInterval
    }()

    init(containerWidth: CGFloat, subtitleItem: OverlaySubtitleItem, pIndex: NSInteger) {
        self.containerWidth = containerWidth
        self.subtitleItem = subtitleItem
        self.pIndex = pIndex
        calculateHeight()
    }

    public func checkInInCurrentLyricRange(_ time: NSInteger) -> Bool {
        return time >= subtitleItem.startTime && time < subtitleItem.stopTime
    }

    public func checkIsCurrentLyric(_ time: NSInteger) -> Bool {
        if time >= subtitleItem.startTime && time < subtitleItem.stopTime {
            isCurrentLyric = true
        } else {
            isCurrentLyric = false
        }

        calculateHeight()
        return isCurrentLyric
    }

    public func setIsCurrentLyric(_ isCurrent: Bool) {
        isCurrentLyric = isCurrent

        calculateHeight()
    }

    var yyTextViewHeight: CGFloat {
        return isCurrentLyric ? specialHeight : commonHeight
    }

    private lazy var commonHeight: CGFloat = {
        if let height = layout?.textBoundingSize.height {
            return height + MinutesPodcastLyricCell.LayoutContext.yyTextViewTopInset * 2
        }
        return 0.0
    }()

    private lazy var specialHeight: CGFloat = {
        if let height = layout?.textBoundingSize.height {
            return height + MinutesPodcastLyricCell.LayoutContext.yyTextViewTopInset * 2
        }
        return 0.0
    }()

    public func calculateHeight() {
        var height: CGFloat = 0.0
        let topAndBottom: CGFloat = isCurrentLyric ? MinutesPodcastLyricCell.LayoutContext.yyTextViewTopMarginLarge : MinutesPodcastLyricCell.LayoutContext.yyTextViewTopMarginLittle
        height += topAndBottom + yyTextViewHeight + topAndBottom
        cellHeight = height
    }
}
