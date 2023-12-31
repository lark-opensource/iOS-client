//
//  EventEditRruleView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/18.
//

import UniverseDesignIcon
import UniverseDesignColor
import UIKit
import SnapKit
import CalendarFoundation

/// 日程重复性规则模块。包括 rule（规则）、endDate（截止时间） 两部分

protocol EventEditRruleViewDataType {
    // 是否可见
    var isVisible: Bool { get }
    // 规则描述
    var ruleStr: String { get }
    // 规则是否可编辑
    var isRuleEditable: Bool { get }
    // 是否展示箭头
    var isShowArrow: Bool { get }
    // 截止时间是否可见
    var endDateIsVisible: Bool { get }
    // 截止时间描述
    var endDateStr: String { get }
    // 截止时间是否合法
    var isEndDateValid: Bool { get }
    // 截止时间是否可编辑
    var isEndDateEditable: Bool { get }
    // 是否展示 tip
    var shouldShowTip: Bool { get }
    // Tip 提示文字
    var tipStr: String { get }
    // Tip 是否支持点击
    var isTipClickable: Bool { get }
    // 不可编辑的原因
    var notEditReason: EventEditViewModel.NotEditReason { get }
    // 重复性AI样式开关
    var rruleShowAIStyle: Bool { get }
    // 截止时间AI样式开关
    var endDateShowAIStyle: Bool { get }
}

final class EventEditRruleView: UIStackView, ViewDataConvertible {
    struct Config {
        static let endDateViewHeight: CGFloat = 48
        static let endDateViewInset: UIEdgeInsets = UIEdgeInsets(top: 12, left: 2, bottom: 12, right: 0)
        static let tipViewHeight: CGFloat = 55
        static let tipViewInset: UIEdgeInsets = UIEdgeInsets(top: 4, left: 2, bottom: 13, right: 0)
    }

    var ruleClickHandler: (() -> Void)? {
        didSet { ruleView.onClick = ruleClickHandler }
    }

    var ruleDeleteHandler: (() -> Void)? {
        didSet { ruleView.onAccessoryClick = ruleDeleteHandler }
    }

    var endDateClickHandler: (() -> Void)? {
        didSet { endDateView.onClick = endDateClickHandler }
    }

    var adjustEndDateClickHandler: (() -> Void)? {
        didSet { tipView.onClickHandler = adjustEndDateClickHandler }
    }

    var warningViewShowHandler: (() -> Void)?

    private struct RruleInvalidWarningViewData: EventEditDateInvalidWarningViewDataType {
        var warningStr: String
        var isClickable: Bool
    }

    var viewData: EventEditRruleViewDataType? {
        didSet {
            isHidden = !(viewData?.isVisible ?? false)

            let isRuleEditable = viewData?.isRuleEditable ?? false
            let isShowArrow = viewData?.isShowArrow ?? true

            let ruleContent = EventBasicCellLikeView.ContentTitle(
                text: viewData?.ruleStr ?? "",
                color: isRuleEditable ? UIColor.ud.N800 : UIColor.ud.textDisabled
            )
            ruleView.content = .title(ruleContent)
            ruleView.accessory = (isRuleEditable && isShowArrow) ? .type(.next(isRuleEditable ? .n3 : .n4)) : .none
            ruleView.icon = .customImageWithoutN3(isRuleEditable ? rruleImage : rruleImageDisabled)

            endDateView.isHidden = !(viewData?.endDateIsVisible ?? false)
            let isEndDateEditable = viewData?.isEndDateEditable ?? false
            let endDateColor: UIColor
            if let isEndDateValid = viewData?.isEndDateValid, !isEndDateValid {
                endDateColor = UIColor.ud.functionDanger500
            } else {
                endDateColor = isEndDateEditable ? UIColor.ud.N800 : UIColor.ud.textDisabled
            }
            let endDateContent = EventBasicCellLikeView.ContentTitle(
                text: viewData?.endDateStr ?? "",
                color: endDateColor
            )
            endDateView.content = .title(endDateContent)
            endDateView.accessory = .type(.next(isRuleEditable ? .n3 : .n4))
            tipView.isHidden = !(viewData?.shouldShowTip ?? false)
            if warningViewLastIsHidden, !tipView.isHidden {
                self.warningViewShowHandler?()
            }
            self.warningViewLastIsHidden = tipView.isHidden
            tipView.onClickHandler = adjustEndDateClickHandler
            tipView.viewData = RruleInvalidWarningViewData(
                warningStr: viewData?.tipStr ?? "",
                isClickable: viewData?.isTipClickable ?? false
            )
            
            ruleView.layoutAIBackGround(shouldShowAIBg: viewData?.rruleShowAIStyle ?? false,
                                        customHeight: 32,
                                        customRight: 38)
            endDateView.layoutAIBackGround(shouldShowAIBg: viewData?.endDateShowAIStyle ?? false,
                                           customHeight: 32,
                                           customRight: 38,
                                           customLeftByContentContainer: 4)
        }
    }

    private let ruleView = EventEditCellLikeView()
    private let endDateView = EventEditCellLikeView()
    private let tipView = EventDateInvalidWarningView(textFont: UIFont.systemFont(ofSize: 14))
    private var warningViewLastIsHidden = true
    private lazy var rruleImage = UDIcon.getIconByKeyNoLimitSize(.repeatOutlined).renderColor(with: .n3).withRenderingMode(.alwaysOriginal)
    private lazy var rruleImageDisabled = UDIcon.getIconByKeyNoLimitSize(.repeatOutlined).renderColor(with: .n4).withRenderingMode(.alwaysOriginal)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        axis = .vertical
        ruleView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        endDateView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds

        let rruleIcon = rruleImage
        ruleView.icon = .customImage(rruleIcon)
        ruleView.iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        addArrangedSubview(ruleView)
        ruleView.snp.makeConstraints {
            $0.height.equalTo(EventEditUIStyle.Layout.singleLineCellHeight)
        }

        endDateView.icon = .empty
        endDateView.accessory = .type(.next())
        endDateView.accessoryAlignment = .centerVertically
        endDateView.contentInset = Config.endDateViewInset
        addArrangedSubview(endDateView)
        endDateView.snp.makeConstraints {
            $0.height.equalTo(Config.endDateViewHeight)
        }

        tipView.isHidden = true
        tipView.icon = .empty
        tipView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        addArrangedSubview(tipView)

    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
