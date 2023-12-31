//
//  EventDetailTableConflictView.swift
//  Calendar
//
//  Created by huoyunjie on 2023/10/18.
//

import Foundation
import UniverseDesignTag
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont
import SnapKit
import FigmaKit

protocol ConflictViewData {
    var conflictTimeStr: String? { get set }
    var conflictTag: String? { get set }
    var showJumpBtn: Bool { get set }
    var instancesViewData: DayNonAllDayViewDataType? { get set }
}

struct EventDetailTableConflictViewData: ConflictViewData {
    var conflictTimeStr: String?
    var conflictTag: String?
    var showJumpBtn: Bool = false
    var instancesViewData: DayNonAllDayViewDataType?
}

protocol EventDetailTableConflictViewDelegate: AnyObject, DayNonAllDayViewDelegate {
    /// 是否是冲突日程块
    func isConflictInstance(_ uniqueId: String) -> Bool
    /// 是否展示时间线
    func isShowTimeLine(_ view: EventDetailTableConflictView) -> Bool
    /// 是否是12小时制
    func is12HourStyle() -> Bool
    /// 触发跳转事件
    func onJumpAction(_ view: EventDetailTableConflictView)
    /// 获取根view，用于展开动画
    func getRootView() -> UIView
    /// view 宽度发生改变
    func boundsWidthChanged(_ view: EventDetailTableConflictView)
}

/// 冲突视图，内部自带点击扩展、时间红线的逻辑
class EventDetailTableConflictView: UIView {

    struct UIStyle {
        /// 一个小时的高度
        var hourGridHeight: CGFloat = 40
        /// 背景颜色
        var bgColor: UIColor = UDColor.bgBodyOverlay
        /// 顶部空白高度
        var topGridMargin: CGFloat {
            DayNonAllDayView.padding.top
        }
        /// 底部空白高度
        var bottomGridMargin: CGFloat {
            DayNonAllDayView.padding.bottom
        }
        /// 左边空白
        var leftGridMargin: CGFloat {
            0
        }
        /// 右边空白
        var rightGridMargin: CGFloat {
            0
        }
        /// 整天的高度
        var wholeDayHeight: CGFloat {
            topGridMargin + bottomGridMargin + hourGridHeight * 24
        }
        /// instanceView edgeInsets
        var edgeInsets: UIEdgeInsets {
            UIEdgeInsets(top: topGridMargin, left: leftGridMargin, bottom: bottomGridMargin, right: rightGridMargin)
        }
    }

    /// 页面状态
    enum Status {
        /// 默认状态（收起）
        case default_
        /// 展开状态
        case expand
    }

    /// 页面状态变更来源：点击 conflictView
    private var viewStatus: Status = .default_ {
        didSet {
            CATransaction.begin()
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.61, 1, 0.88, 1))
            defer { CATransaction.commit() }
            
            self.coverMaskView.isHidden = true
            UIView.animate(
                withDuration: 0.6,
                animations: {
                    /// 页面状态变更，重新刷新 conflictView
                    self.refreshConflictView()
                    self.delegate?.getRootView().layoutIfNeeded()
                }, completion: { _ in
                    /// 更新 maskView
                    self.refreshCoverMaskView()
                })
            
        }
    }

    var viewData: ConflictViewData? = nil {
        didSet {
            guard let viewData = viewData else { return }
            self.updateTitle(timeStr: viewData.conflictTimeStr ?? "",
                             tagStr: viewData.conflictTag,
                             showJumpBtn: viewData.showJumpBtn)
            self.updateInstancesView(viewData: viewData.instancesViewData)
            self.refreshCoverMaskView()
        }
    }

    weak var delegate: EventDetailTableConflictViewDelegate? {
        didSet {
            timeIndicator.formatter = timeIndicator.formatter
            instancesView.delegate = delegate
        }
    }

    /// instances 在 InstanceView 中的绘制区域
    var panelRect: CGRect {
        let rect: CGRect = instancesView.bounds
        let panelRect = CGRect(x: rect.minX,
                               y: rect.minY,
                               width: rect.width - 5,
                               height: rect.height)
            .inset(by: style.edgeInsets) /// 考虑 DayNonAllDayView 内部 padding
        return panelRect
    }
    
    override var bounds: CGRect {
        didSet {
            if oldValue.width != bounds.width {
                self.delegate?.boundsWidthChanged(self)
            }
        }
    }

    private lazy var conflictTimeLable: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = UDFont.caption0(.fixed)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var conflictTag: UDTag = {
        let config = UDTag.Configuration.text(
            "",
            tagSize: .mini,
            colorScheme: .red
        )
        let tag = UDTag(configuration: config)
        tag.isHidden = true
        return tag
    }()

    private lazy var jumpBtn: UIButton = {
        let button = UIButton()
        let icon = UDIcon.viewinchatOutlined.ud.withTintColor(UDColor.iconN3)
        button.setImage(icon, for: .normal)
        button.addTarget(self, action: #selector(jumpAction), for: .touchUpInside)
        button.isHidden = true
        button.increaseClickableArea(top: -8, left: -8, bottom: -8, right: -8)
        return button
    }()

    private(set) lazy var style = UIStyle()

    private var timeLineYOffset: Constraint?

    private lazy var timeLineView: UIView = {
        self.makeTimeLineView()
    }()

    private lazy var instancesView: DayNonAllDayView = {
        self.makeInstancesView()
    }()

    private lazy var timeIndicator: DayTimeScaleView = {
        self.makeTimeIndicator()
    }()

    private lazy var topTitleView: UIView = {
        self.makeTitleView()
    }()

    private lazy var bottomConflictView: UIScrollView = {
        self.makeConflictView()
    }()

    private var bgColor: UIColor {
        style.bgColor
    }
    
    private lazy var gradientPattern = GradientPattern(
        direction: .topToBottom,
        colors: [bgColor.withAlphaComponent(0),
                 bgColor.withAlphaComponent(0),
                 bgColor.withAlphaComponent(0.1),
                 bgColor.withAlphaComponent(0.95)],
        type: .linear,
        locations: [0, 0.7, 0.82, 1]
    )

    private lazy var coverMaskView: UIView = {
        let view = FKGradientView.fromPattern(gradientPattern)
        view.isUserInteractionEnabled = false
        return view
    }()

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let topTitle = topTitleView
        let bottomView = bottomConflictView
        let containerView = UIView()
        containerView.addSubview(topTitle)
        containerView.addSubview(bottomView)
        containerView.clipsToBounds = true

        topTitle.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        bottomView.snp.makeConstraints { make in
            make.top.equalTo(topTitle.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(defaultHeight)
        }

        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
        }

        addSubview(coverMaskView)
        coverMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.backgroundColor = bgColor
        self.layer.cornerRadius = 8
        self.clipsToBounds = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(expand))
        self.addGestureRecognizer(tap)
    }

    private func makeTimeLineView() -> UIView {
        let view = DayNonAllDayViewController.RedLineView()
        view.isHidden = true
        return view
    }

    private func makeInstancesView() -> DayNonAllDayView {
        let view = DayNonAllDayView(
            lineSpacing: style.hourGridHeight,
            lineColor: UDColor.lineDividerDefault,
            edgeInsets: style.edgeInsets
        )
        return view
    }

    private func makeTimeIndicator() -> DayTimeScaleView {
        let timeIndicator = DayTimeScaleView()
        timeIndicator.backgroundColor = .clear
        timeIndicator.heightPerHour = style.hourGridHeight
        timeIndicator.vPadding = (
            top: DayNonAllDayView.padding.top,
            bottom: DayNonAllDayView.padding.bottom
        )
        timeIndicator.formatter = { [weak self] timeScale in
            return DayNonAllDayViewModel.formattedText(for: timeScale, is12HourStyle: self?.delegate?.is12HourStyle() ?? false)
        }
        return timeIndicator
    }

    private func makeTitleView() -> UIView {
        let titleContainer = UIView()

        titleContainer.addSubview(conflictTimeLable)
        titleContainer.addSubview(conflictTag)
        titleContainer.addSubview(jumpBtn)

        conflictTimeLable.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        conflictTag.snp.makeConstraints { make in
            make.leading.equalTo(conflictTimeLable.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(jumpBtn.snp.leading).offset(-8)
            make.top.bottom.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        jumpBtn.snp.makeConstraints { make in
            make.size.equalTo(16)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        return titleContainer
    }

    private func makeConflictView() -> UIScrollView {
        let containerView = UIView()
        containerView.addSubview(timeIndicator)
        containerView.addSubview(instancesView)
        containerView.addSubview(timeLineView)

        timeIndicator.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(52)
            make.height.equalTo(instancesView.snp.height)
        }
        instancesView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.leading.equalTo(timeIndicator.snp.trailing).offset(6)
            make.height.equalTo(style.wholeDayHeight)
        }
        timeLineView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.equalTo(instancesView)
            make.trailing.equalTo(instancesView).inset(style.rightGridMargin)
            timeLineYOffset = make.top.equalTo(instancesView).constraint
        }

        let scrollView = UIScrollView()
        scrollView.contentSize.height = style.wholeDayHeight
        scrollView.isScrollEnabled = false
        scrollView.addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        return scrollView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.timeIndicator.layoutSubviews()
        adjustTimeScaleWidth()
    }
    
    private func adjustTimeScaleWidth() {
        self.timeIndicator.snp.updateConstraints { make in
            make.width.equalTo(self.timeIndicator.maxLabelWidth)
        }
    }
}

extension EventDetailTableConflictView {
    /// 更新顶部标题区域
    private func updateTitle(timeStr: String,
                     tagStr: String? = nil,
                     showJumpBtn: Bool = true
    ) {
        self.conflictTimeLable.text = timeStr
        self.conflictTag.text = tagStr
        self.conflictTag.isHidden = tagStr == nil
        self.jumpBtn.isHidden = !showJumpBtn
    }


    /// 更新 instance 展示区域
    private func updateInstancesView(viewData: DayNonAllDayViewDataType?) {
        self.instancesView.unloadAllItems()
        self.instancesView.viewData = viewData
        self.refreshConflictView()
        self.refreshTimeLineView()
    }

    /// 刷新 conflictView
    private func refreshConflictView() {
        switch self.viewStatus {
        case .default_:
            refreshConflictViewWithDefault()
        case .expand:
            refreshConflictViewWithExpand()
        }
    }
    
    /// 默认高度下能够展示完当天所有日程，不展示蒙层
    var shouldHiddenCoverMaskView: Bool {
        guard let items = viewData?.instancesViewData?.items else { return true }
        let firstYoffSet = items.map(\.frame.minY).min() ?? 0
        let lastYoffSet = items.map(\.frame.maxY).max() ?? 0
        return lastYoffSet - firstYoffSet <= defaultHeight
    }

    /// 刷新蒙层view
    private func refreshCoverMaskView() {
        self.coverMaskView.isHidden = self.viewStatus == .expand || shouldHiddenCoverMaskView
    }

    /// 点击conflictView切换状态
    @objc
    private func expand() {
        switch self.viewStatus {
        case .default_:
            self.viewStatus = .expand
        case .expand:
            self.viewStatus = .default_
        }
    }

    /// 刷新时间红线
    private func refreshTimeLineView() {
        let current = Date()
        let today = current.dayStart(calendar: nil)
        let minutes = current.minutesSince(today)
        /// 时间线的y偏移量
        let yoffset = minutes * (style.hourGridHeight / 60.0) + panelRect.top
        timeLineYOffset?.update(offset: yoffset)
        timeLineView.isHidden = !(self.delegate?.isShowTimeLine(self) ?? false)
    }

    @objc
    private func jumpAction() {
        self.delegate?.onJumpAction(self)
    }
}

// MARK: ScrollVeiw
extension EventDetailTableConflictView {
    /// 默认状态下 scrollView 的高度
    private var defaultHeight: CGFloat {
        /// 整体高度 - top - spacing - titleHeight
        189 - 12 - 12 - 18
    }
    
    /// 最大的 Y 偏移绝对值
    private var maxYOffset: CGFloat {
        style.wholeDayHeight - defaultHeight
    }
    
    /// 最小的 Y 偏移绝对值
    private var minYOffset: CGFloat {
        0
    }
    
    /// 修复 offset，如果遇到时间展示截断的情况，进行 offset 修正，避免截断展示
    private func fixOffset(_ offset: CGFloat, isUseTop: Bool = true) -> CGFloat {
        var offset = offset
        self.timeIndicator.fixedItems.map(\.0).forEach { label in
            let range = (label.frame.minY...label.frame.maxY)
            if range.contains(offset) {
                offset = isUseTop ? label.frame.minY : label.frame.maxY
                return
            }
        }
        return offset
    }

    /// 默认状态下（未展开），当前日程距离顶部 40
    private func refreshConflictViewWithDefault() {
        guard self.viewStatus == .default_,
              let items = instancesView.viewData?.items,
              let delegate = delegate else {
            EventDetail.logWarn("conflictView items count: \(instancesView.viewData?.items.count ?? -1)")
            return
        }
        let currentInstance = items.first(where: {
            delegate.isConflictInstance($0.viewData.uniqueId)
        })
        let minY: CGFloat = currentInstance?.frame.minY ?? 0
        let yOffset = min(max(minY - 40, minYOffset), maxYOffset)

        self.updateConflictViewYOffset(fixOffset(yOffset))
        self.updateConflictViewHeight(defaultHeight)
    }

    /// 展开状态下，首尾日程距离 top bottom 40
    private func refreshConflictViewWithExpand() {
        guard self.viewStatus == .expand,
              let items = viewData?.instancesViewData?.items,
              !items.isEmpty else {
            return
        }
        let firstYoffSet = items.map(\.frame.minY).min() ?? 0
        let lastYoffSet = items.map(\.frame.maxY).max() ?? 0

        var bottomToTopOffset = min(lastYoffSet + 40, style.wholeDayHeight)
        var topOffset = min(max(firstYoffSet - 40, minYOffset), maxYOffset)
        
        topOffset = fixOffset(topOffset)
        bottomToTopOffset = fixOffset(bottomToTopOffset, isUseTop: false)

        self.updateConflictViewYOffset(topOffset)
        self.updateConflictViewHeight(bottomToTopOffset - topOffset)
    }

    /// 更新 scrollView contentOffset
    private func updateConflictViewYOffset(_ yOffset: CGFloat) {
        self.bottomConflictView.contentOffset = .init(x: 0, y: yOffset)
    }

    /// 更新 scrollView 展示高度
    private func updateConflictViewHeight(_ height: CGFloat) {
        let height = max(defaultHeight, height)
        self.bottomConflictView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }
}
