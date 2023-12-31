//
//  DayTimeScaleView.swift
//  Calendar
//
//  Created by 张威 on 2020/7/9.
//  Copyright © 2020 ByteDance. All rights reserved.
//

import UIKit
import LarkExtensions
import UniverseDesignFont

/// DayScene - NonAllDay - TimeScaleView

final class DayTimeScaleView: UIView {

    var formatter: ((TimeScale) -> String)? {
        didSet {
            updateLabelText()
            setNeedsLayout()
        }
    }

    var vPadding: (top: CGFloat, bottom: CGFloat) = (0, 0) {
        didSet {
            guard vPadding.top != oldValue.top || vPadding.bottom != oldValue.bottom else { return }
            setNeedsLayout()
        }
    }

    var heightPerHour: CGFloat = DayScene.UIStyle.Layout.timeScaleCanvas.heightPerHour {
        didSet {
            guard heightPerHour != oldValue else { return }
            setNeedsLayout()
        }
    }

    private(set) var fixedItems = [(label: UILabel, timeScale: TimeScale)]()
    private var selectedLabels = (from: UILabel(), to: UILabel())
    private var selectedRange: TimeScaleRange?
    private let textFonts = (
        // 整点
        onTheHour: UDFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
        // 非整点
        notOnTheHour: UDFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.calEventViewBg
        fixedItems = (0...24).map { hour in
            let label = UILabel()
            label.font = textFonts.onTheHour
            label.textColor = UIColor.ud.textPlaceholder
            let timeScale = TimeScale(refOffset: hour * TimeScale.pointsPerHour)
            return (label, timeScale)
        }
        fixedItems.forEach { addSubview($0.label) }
        addSubview(selectedLabels.from)
        addSubview(selectedLabels.to)
        selectedLabels.from.font = textFonts.notOnTheHour
        selectedLabels.to.font = textFonts.notOnTheHour
        selectedLabels.from.textColor = UIColor.ud.primaryFillHover
        selectedLabels.to.textColor = UIColor.ud.primaryFillHover
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private(set) var maxLabelWidth: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        fixedItems.forEach {
            setFrame(for: $0.label, with: $0.timeScale)
            $0.label.isHidden = false
            maxLabelWidth = max(maxLabelWidth, $0.label.frame.width)
        }
        if let timeScaleRange = selectedRange {
            selectedLabels.from.isHidden = false
            selectedLabels.to.isHidden = false
            setFrame(for: selectedLabels.from, with: timeScaleRange.lowerBound)
            setFrame(for: selectedLabels.to, with: timeScaleRange.upperBound)

            var fromVisibleRect = selectedLabels.from.frame
            fromVisibleRect.size.height = selectedLabels.from.font.pointSize
            fromVisibleRect.centerY = selectedLabels.from.frame.centerY

            var toVisibleRect = selectedLabels.to.frame
            toVisibleRect.size.height = selectedLabels.to.font.pointSize
            toVisibleRect.centerY = selectedLabels.to.frame.centerY

            for item in fixedItems {
                var itemVisibleRect = item.label.frame
                itemVisibleRect.size.height = item.label.font.pointSize
                itemVisibleRect.centerY = item.label.frame.centerY
                if itemVisibleRect.intersects(fromVisibleRect) || item.label.frame.intersects(toVisibleRect) {
                    item.label.isHidden = true
                }
            }
        } else {
            selectedLabels.from.isHidden = true
            selectedLabels.to.isHidden = true
        }
    }

    private func setFrame(for label: UILabel, with timeScale: TimeScale) {
        label.sizeToFit()
        var labelFrame = label.frame
        labelFrame.size = CGSize(width: ceil(labelFrame.width), height: ceil(labelFrame.height))
        labelFrame.centerY = vPadding.top
            + CGFloat(timeScale.offset - TimeScale.minOffset) / CGFloat(TimeScale.pointsPerHour) * heightPerHour
        labelFrame.centerX = bounds.width / 2
        label.frame = labelFrame
    }

    private func updateLabelText() {
        fixedItems.forEach { $0.label.text = formatter?($0.timeScale) }
        if let selectedRange = selectedRange {
            selectedLabels.from.text = formatter?(selectedRange.lowerBound)
            selectedLabels.to.text = formatter?(selectedRange.upperBound)
        }
        setNeedsLayout()
    }

    func setSelectedTimeScaleRange(_ timeScaleRange: TimeScaleRange?) {
        guard selectedRange != timeScaleRange else { return }
        selectedRange = timeScaleRange
        if let timeScaleRange = timeScaleRange {
            selectedLabels.from.text = formatter?(timeScaleRange.lowerBound)
            if timeScaleRange.lowerBound.offset % TimeScale.pointsPerHour == 0 {
                selectedLabels.from.font = textFonts.onTheHour
            } else {
                selectedLabels.from.font = textFonts.notOnTheHour
            }
            if timeScaleRange.upperBound.offset % TimeScale.pointsPerHour == 0 {
                selectedLabels.to.font = textFonts.onTheHour
            } else {
                selectedLabels.to.font = textFonts.notOnTheHour
            }
            selectedLabels.to.text = formatter?(timeScaleRange.upperBound)
        }
        setNeedsLayout()
    }
}

extension DayTimeScaleView: TimeScaleViewType {
    var edgeInsets: UIEdgeInsets {
        UIEdgeInsets(top: vPadding.top, left: 0, bottom: vPadding.bottom, right: 0)
    }
}
