//
//  EventEditDateRangeView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/5.
//
import UIKit
import RxCocoa
import RxSwift
import LarkUIKit
import UniverseDesignFont
import LarkTimeFormatUtils
import UniverseDesignIcon
import UniverseDesignColor

// MARK: DateRangeBaseView

// DateRangeBaseView: 包括开始时间和结束事件两个组件
final class EventEditDateRangeBaseView: UIView {
    struct UIConfig {
        var labelLeftPadding: CGFloat = 46
        var leftContainerCenterXOffset: CGFloat = -4
        var labelTopPadding: CGFloat = 13
        var labelBottomYOffset: CGFloat = -6
        var titleHeight: CGFloat = 24
        var subTitleHeight: CGFloat = 22
        var labelLeftAIPadding: CGFloat = 6
    }

    private lazy var arrowView = ArrowView()
    typealias DateRange = (start: Date, end: Date)

    typealias Components = (
        button: UIButton,
        backgroundView: UIView,
        titleLabel: UILabel,
        firstSubtitleLabel: UILabel,
        secondSubtitleLabel: UILabel
    )

    var dateRange: DateRange? {
        didSet { updateComponentsText() }
    }

    var isAllDay: Bool = false {
        didSet { updateComponentsText() }
    }

    var is12HourStyle: Bool = false {
        didSet { updateComponentsText() }
    }

    var timeZone: TimeZone = TimeZone.current {
        didSet { updateComponentsText() }
    }
    
    var startShouldShowAIStyle: Bool = false {
        didSet { updateStartAiHightLightStyle() }
    }
    
    var endShouldShowAIStyle: Bool = false {
        didSet { updateEndAiHightLightStyle() }
    }

    var startComponents: Components
    var endComponents: Components
    
    let startBgView = UIView()
    let endBgView = UIView()


    init(frame: CGRect,
         config: UIConfig = UIConfig()) {
        let startButton = UIButton()
        let startTitleLabel = UILabel()
        let startFirstSubtitleLabel = UILabel()
        let startSecondSubtitleLabel = UILabel()

        let endButton = UIButton()
        let endTitleLabel = UILabel()
        let endFirstSubtitleLabel = UILabel()
        let endSecondSubtitleLabel = UILabel()

        startComponents = (
            button: startButton,
            backgroundView: startBgView,
            titleLabel: startTitleLabel,
            firstSubtitleLabel: startFirstSubtitleLabel,
            secondSubtitleLabel: startSecondSubtitleLabel
        )

        endComponents = (
            button: endButton,
            backgroundView: endBgView,
            titleLabel: endTitleLabel,
            firstSubtitleLabel: endFirstSubtitleLabel,
            secondSubtitleLabel: endSecondSubtitleLabel
        )

        super.init(frame: frame)

        addSubview(startButton)
        startButton.snp.makeConstraints {
            $0.top.bottom.left.equalToSuperview()
            $0.right.equalTo(self.snp.centerX).offset(config.leftContainerCenterXOffset)
        }

        addSubview(endButton)
        endButton.snp.makeConstraints {
            $0.top.bottom.right.equalToSuperview()
            $0.left.equalTo(startButton.snp.right)
        }

        startButton.addSubview(startBgView)
        startBgView.isUserInteractionEnabled = false
        startBgView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(config.labelLeftPadding - config.labelLeftAIPadding)
            $0.top.bottom.equalToSuperview()
            $0.right.equalToSuperview().inset(24)
        }
        
        startButton.addSubview(startTitleLabel)
        startTitleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(config.labelLeftPadding)
            $0.right.equalToSuperview()
            $0.height.equalTo(24)
            $0.top.equalToSuperview().inset(1)
        }

        startFirstSubtitleLabel.font = UIFont.cd.regularFont(ofSize: 14)
        startButton.addSubview(startFirstSubtitleLabel)
        startFirstSubtitleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(config.labelLeftPadding)
            $0.height.equalTo(config.subTitleHeight)
            $0.top.equalTo(startTitleLabel.snp.bottom).offset(-2)
        }

        startSecondSubtitleLabel.font = UIFont.cd.regularFont(ofSize: 14)
        startButton.addSubview(startSecondSubtitleLabel)
        startSecondSubtitleLabel.snp.makeConstraints {
            $0.left.equalTo(startFirstSubtitleLabel.snp.right).offset(6)
            $0.height.equalTo(config.subTitleHeight)
            $0.top.equalTo(startFirstSubtitleLabel)
        }

        startFirstSubtitleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        startSecondSubtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        endButton.addSubview(endBgView)
        endBgView.isUserInteractionEnabled = false
        endBgView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(config.labelLeftPadding - config.labelLeftAIPadding)
            $0.top.bottom.equalToSuperview()
            $0.right.equalToSuperview().inset(24)
        }
        
        endButton.addSubview(endTitleLabel)
        endTitleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(config.labelLeftPadding)
            $0.right.equalToSuperview()
            $0.height.equalTo(24)
            $0.top.bottom.equalTo(startTitleLabel)
        }

        endFirstSubtitleLabel.font = UIFont.cd.regularFont(ofSize: 14)
        endButton.addSubview(endFirstSubtitleLabel)
        endFirstSubtitleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(config.labelLeftPadding)
            $0.height.equalTo(config.subTitleHeight)
            $0.top.bottom.equalTo(startFirstSubtitleLabel)
        }

        endSecondSubtitleLabel.font = UIFont.cd.regularFont(ofSize: 14)
        endButton.addSubview(endSecondSubtitleLabel)
        endSecondSubtitleLabel.snp.makeConstraints {
            $0.left.equalTo(endFirstSubtitleLabel.snp.right).offset(6)
            $0.height.equalTo(config.subTitleHeight)
            $0.top.bottom.equalTo(startSecondSubtitleLabel)
        }

        endFirstSubtitleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        endSecondSubtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        self.addSubview(arrowView)
        arrowView.snp.makeConstraints {
            $0.height.equalTo(32)
            $0.width.equalTo(9)
            $0.top.equalToSuperview().inset(6)
            $0.centerX.equalToSuperview().offset(-2)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let hideSecondSubtitleLabel =
            startComponents.secondSubtitleLabel.frame.maxX >= startComponents.button.frame.width - 16
            || endComponents.secondSubtitleLabel.frame.maxX >= endComponents.button.frame.width - 16
        startComponents.secondSubtitleLabel.isHidden = hideSecondSubtitleLabel
        endComponents.secondSubtitleLabel.isHidden = hideSecondSubtitleLabel

    }

    fileprivate func updateComponentsText() {
        guard let dateRange = dateRange else {
            startComponents.titleLabel.text = nil
            startComponents.firstSubtitleLabel.text = nil
            startComponents.secondSubtitleLabel.text = nil
            endComponents.titleLabel.text = nil
            endComponents.firstSubtitleLabel.text = nil
            endComponents.secondSubtitleLabel.text = nil
            return
        }
        var showYear = false
        if isAllDay {
            showYear = true
        } else {
            var calendar = Calendar.gregorianCalendar
            calendar.timeZone = timeZone
            let currentDate = Date()
            showYear = !calendar.isDate(currentDate, equalTo: dateRange.start, toGranularity: .year)
                        || !calendar.isDate(currentDate, equalTo: dateRange.end, toGranularity: .year)
        }

        func fillText(into components: Components, with date: Date) {
            var customOptions = Options(
                timeZone: timeZone,
                is12HourStyle: is12HourStyle,
                timeFormatType: showYear ? .long : .short,
                timePrecisionType: .minute,
                datePrecisionType: .day
            )

            let dateAttr = NSAttributedString(string: TimeFormatUtils.formatDate(from: date, with: customOptions))
            let timeStr = TimeFormatUtils.formatTime(from: date, with: customOptions)
            // 判断西文字体
            let timeFont = UDFontAppearance.isCustomFont ? UDFont.systemFont(ofSize: 16, weight: .medium) : UIFont.cd.dinBoldFont(ofSize: 18)
            let timeAttr = NSMutableAttributedString(string: timeStr, attributes: [.font: timeFont])
            // 得到上午和下午的位置
            let amRange = (timeStr as NSString).range(of: I18n.Calendar_StandardTime_AM)
            let pmRange = (timeStr as NSString).range(of: I18n.Calendar_StandardTime_PM)
            // 上午下午特化为不同字体
            if amRange.length != 0 {
                timeAttr.addAttributes([.font: UIFont.ud.title3], range: amRange)
            } else if pmRange.length != 0 {
                timeAttr.addAttributes([.font: UIFont.ud.title3], range: pmRange)
            }
            // 获取缩写的星期文案
            customOptions.timeFormatType = .short
            let weekdayAttr = NSAttributedString(string: TimeFormatUtils.formatWeekday(from: date, with: customOptions))

            if isAllDay {
                components.titleLabel.attributedText = dateAttr
                components.firstSubtitleLabel.attributedText = weekdayAttr
                components.secondSubtitleLabel.attributedText = nil
            } else {
                components.titleLabel.attributedText = timeAttr
                components.firstSubtitleLabel.attributedText = dateAttr
                components.secondSubtitleLabel.attributedText = weekdayAttr
            }
        }

        fillText(into: startComponents, with: dateRange.start)
        fillText(into: endComponents, with: dateRange.end)

        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func updateStartAiHightLightStyle() {
        startBgView.backgroundColor = startShouldShowAIStyle ? UDColor.AIPrimaryFillTransparent01(ofSize: startBgView.bounds.size) : .clear
        startBgView.layer.cornerRadius = 8
        
    }
    
    private func updateEndAiHightLightStyle() {
        endBgView.backgroundColor = endShouldShowAIStyle ? UDColor.AIPrimaryFillTransparent01(ofSize: endBgView.bounds.size) : .clear
        endBgView.layer.cornerRadius = 8
    }
    
    final class ArrowView: UIView {
        var strokeColor: UIColor {
            didSet { setNeedsDisplay() }
        }

        init(strokeColor: UIColor = UIColor.ud.iconDisabled) {
            self.strokeColor = strokeColor
            super.init(frame: .zero)
            backgroundColor = .clear
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            let path = UIBezierPath()
            // 防止箭头顶点是平的需要将view的宽度扩大1，顶点的x坐标减少1
            path.move(to: CGPoint(x: bounds.centerRight.x - 1, y: bounds.centerRight.y))
            path.addLine(to: bounds.bottomLeft)
            path.move(to: bounds.topLeft)
            path.addLine(to: CGPoint(x: bounds.centerRight.x - 1, y: bounds.centerRight.y))
            strokeColor.setStroke()
            path.close()
            path.stroke()
        }
    }
}

// MARK: DateRangeView for 编辑页-时间二级页

protocol EventEditDateRangeSwitchViewDateType {
    var startDate: Date { get }
    var endDate: Date { get }
    var isAllDay: Bool { get }
    var isEndDateValid: Bool { get }
    var timeZone: TimeZone { get }
    var is12HourStyle: Bool { get }
}

final class EventEditDateRangeSwitchView: UIView, ViewDataConvertible {

    var viewData: EventEditDateRangeSwitchViewDateType? {
        didSet {
            innerDateRangeView.dateRange = (viewData?.startDate ?? Date(), viewData?.endDate ?? Date())
            innerDateRangeView.timeZone = viewData?.timeZone ?? TimeZone.current
            innerDateRangeView.isAllDay = viewData?.isAllDay ?? true
            innerDateRangeView.is12HourStyle = viewData?.is12HourStyle ?? true
            updateComponentsColor()
        }
    }

    enum State: Int, RawRepresentable {
        case start = 101, end = 102
    }

    var selectedState: State {
        didSet { updateComponentsColor() }
    }

    var onSeletedStateChanged: ((_ state: State) -> Void)?

    private lazy var innerDateRangeView = EventEditDateRangeBaseView(frame: .zero)

    init(selectedState: State = .start) {
        self.selectedState = selectedState
        super.init(frame: .zero)

        addSubview(innerDateRangeView)
        innerDateRangeView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(3)
            $0.height.equalTo(42)
        }

        innerDateRangeView.startComponents.button.tag = State.start.rawValue
        innerDateRangeView.startComponents.button.addTarget(self, action: #selector(didStateContainerClick(_:)), for: .touchUpInside)
        innerDateRangeView.endComponents.button.tag = State.end.rawValue
        innerDateRangeView.endComponents.button.addTarget(self, action: #selector(didStateContainerClick(_:)), for: .touchUpInside)

        updateComponentsColor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateComponentsColor() {

        let isValid = viewData?.isEndDateValid ?? true

        switch self.selectedState {
        case .start:
            innerDateRangeView.startComponents.titleLabel.textColor = UIColor.ud.primaryContentDefault
            innerDateRangeView.startComponents.firstSubtitleLabel.textColor = UIColor.ud.primaryContentDefault
            innerDateRangeView.startComponents.secondSubtitleLabel.textColor = UIColor.ud.primaryContentDefault

            innerDateRangeView.endComponents.titleLabel.textColor = isValid ? UIColor.ud.textTitle : UIColor.ud.functionDangerContentPressed
            innerDateRangeView.endComponents.firstSubtitleLabel.textColor = isValid ? UIColor.ud.textTitle : UIColor.ud.functionDangerContentPressed
            innerDateRangeView.endComponents.secondSubtitleLabel.textColor = isValid ? UIColor.ud.textTitle : UIColor.ud.functionDangerContentPressed

        case .end:
            innerDateRangeView.startComponents.titleLabel.textColor = UIColor.ud.textTitle
            innerDateRangeView.startComponents.firstSubtitleLabel.textColor = UIColor.ud.textTitle
            innerDateRangeView.startComponents.secondSubtitleLabel.textColor = UIColor.ud.textTitle

            innerDateRangeView.endComponents.titleLabel.textColor = isValid ? UIColor.ud.primaryContentDefault : UIColor.ud.functionDangerContentPressed
            innerDateRangeView.endComponents.firstSubtitleLabel.textColor = isValid ? UIColor.ud.primaryContentDefault : UIColor.ud.functionDangerContentPressed
            innerDateRangeView.endComponents.secondSubtitleLabel.textColor = isValid ? UIColor.ud.primaryContentDefault : UIColor.ud.functionDangerContentPressed
        }
    }

    @objc
    private func didStateContainerClick(_ sender: UIButton) {
        guard let state = State(rawValue: sender.tag) else { return }
        guard state != selectedState else { return }
        selectedState = state
        onSeletedStateChanged?(state)
    }
}
