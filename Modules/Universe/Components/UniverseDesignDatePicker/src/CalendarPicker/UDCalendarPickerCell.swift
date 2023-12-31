//
//  UDCalendarPickerCell.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2021/3/17.
//

import Foundation
import UIKit
import UniverseDesignFont

/// Date 在当前页的位置
public enum DateOwner {
    /// 当页最后，即下一页的内容
    case nextPage
    /// 当前页
    case currentPage
    /// 当页最前面，即上一页的内容
    case previousPage
}

/// 月历 cell 状态，供业务方设置 cell 形态
public protocol CellState {
    /// dayCell 日期 text
    var text: String { get }
    /// dayCell 在当前页的位置
    var dateBelongsTo: DateOwner { get }
    /// cell 是否选中
    var isSelected: Bool { get }
}

public final class UDCalendarPickerCell: UICollectionViewCell {
    private var selectViewWidth: CGFloat = 32
    private var dayLabelFont: UIFont = UDFontAppearance.isCustomFont ? UDFont.systemFont(ofSize: 16) : UDFont.dinBoldFont(ofSize: 16)
    private var dayLabelTextColor: UIColor = UDDatePickerTheme.calendarPickerCurrentMonthTextColor
    private var dayLabelOuterTextColor: UIColor = UDDatePickerTheme.calendarPickerOuterMonthTextColor

    /// 日期 LabelText
    public var dayLabelText: String? {
        didSet {
            guard let text = dayLabelText, !text.isEmpty, text != oldValue else {
                return
            }
            dayLabel.text = dayLabelText
        }
    }

    public var type: DateOwner? {
        didSet {
            guard let type = type, type != .currentPage else {
                return
            }
            setupDayLabel(withColor: dayLabelOuterTextColor)
        }
    }

    private var dayLabel = UILabel()
    private var selectBgView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutSelectedBgView()
        layoutDayLable()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        layoutSelectedBgView()
        layoutDayLable()
    }

    /// 设置选中后背景圆圈的颜色
    /// - Parameter color: The color
    public func setupSelectedBgView(withColor color: UIColor) {
        selectBgView.backgroundColor = color
        selectBgView.isHidden = false
    }

    /// 设置日期字体颜色
    /// - Parameter color: The color
    public func setupDayLabel(withColor color: UIColor) {
        dayLabel.textColor = color
    }

    private func layoutSelectedBgView() {
        contentView.addSubview(selectBgView)
        let radius = min(contentView.bounds.width, contentView.bounds.height, selectViewWidth) / 2
        selectBgView.layer.cornerRadius = radius
        selectBgView.layer.allowsEdgeAntialiasing = true
        selectBgView.isHidden = true

        selectBgView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.height.width.equalTo(radius * 2)
        }
    }

    private func layoutDayLable() {
        contentView.addSubview(dayLabel)
        contentView.bringSubviewToFront(dayLabel)
        dayLabel.textAlignment = .center
        dayLabel.font = dayLabelFont
        dayLabel.textColor = dayLabelTextColor
        dayLabel.text = dayLabelText
        dayLabel.snp.makeConstraints {
            $0.center.equalTo(selectBgView)
        }
    }
}
