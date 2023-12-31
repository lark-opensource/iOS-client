//
//  FocusModeCell.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/13.
//

import Foundation
import UIKit
import SnapKit
import FigmaKit
import LarkUIKit
import EENavigator
import LarkEmotion
import LarkInteraction
import Homeric
import LarkRichTextCore
import LKCommonsTracker
import LarkNavigator
import LarkContainer
import LarkSDKInterface

protocol FocusModeCellDelegate: AnyObject {
    func focusCellDidSelect(_ cell: FocusModeCell, period: FocusPeriod)
    func focusCellDidDeselect(_ cell: FocusModeCell)
    func focusCellDidTapExpandButton(_ cell: FocusModeCell)
    func focusCellDidTapConfigButton(_ cell: FocusModeCell)
}

enum FocusModeCellState {
    /// 从关闭中转为开启的中间状态
    case opening
    /// 已开启的状态
    case opened
    /// 从开启转为关闭的中间状态
    case closing
    /// 已关闭的状态
    case closed
    /// 从开启转为开启的中间状态（更新了生效时间）
    case reopening

    /// 是否是点亮的状态（opened、closing、reopening）
    var isSelected: Bool {
        switch self {
        case .opened, .closing, .reopening: return true
        case .closed, .opening: return false
        }
    }

    var isLoading: Bool {
        switch self {
        case .closing, .opening, .reopening: return true
        case .closed, .opened: return false
        }
    }
}

final class FocusModeCell: UITableViewCell, UserResolverWrapper {

    @ScopedInjectedLazy
    var userSettings: UserGeneralSettings?
    /// 当前是否为 24 小时制
    var is24Hour: Bool {
        return userSettings?.is24HourTime.value ?? false
    }


    weak var delegate: FocusModeCellDelegate?

    var allPeriod: [FocusPeriod] = []

    var selectionState: FocusModeCellState = .closed {
        didSet {
            // 只设置 TitleView，DetailView 随着真实数据返回刷新
            titleView.selectionState = selectionState
            detailView.selectionState = selectionState
        }
    }

    /// 是否为手动展开状态
    var isExpanded: Bool = false {
        didSet {
            titleView.isExpanded = isExpanded
            detailView.isHidden = !isExpanded
        }
    }

    func toggleExpandWithAnimation() {
        setExpandWithAnimation(!isExpanded)
    }

    func setExpandWithAnimation(_ isExpand: Bool) {
        if isExpanded {
            UIView.animate(withDuration: 0.3) {
                self.isExpanded = false
            }
        } else {
            isExpanded = true
        }
    }

    /// 当前 Cell 展示的 Focus 状态
    var focusStatus: UserFocusStatus?

    func configure(with focus: UserFocusStatus, isActive: Bool, isExpanded: Bool = false) {
        allPeriod = focus.availablePeriods
        // 保存数据
        focusStatus = focus
        selectionState = isActive ? .opened : .closed
        titleView.titleLabel.text = focus.title
        titleView.iconView.config(with: focus)
        titleView.silentTag.isHidden = !focus.isNotDisturbMode
        if focus.isSystemStatus {
            titleView.subtitleLabel.text = focus.systemValidInterval.systemStatusTime(isActive: isActive, is24Hour: is24Hour)
            detailView.setPeriods(list: focus.availablePeriods, selected: isActive ? focus.selectedPeriod : nil)
        } else if isActive {
            titleView.subtitleLabel.text = focus.effectiveInterval.validUntilTime(is24Hour: is24Hour)
            detailView.setPeriods(list: focus.availablePeriods, selected: focus.selectedPeriod)
        } else {
            titleView.subtitleLabel.text = focus.lastSelectedDuration.displayName
            var availablePeriods = focus.availablePeriods
            // 清洗数据：未激活的状态，不显示自定义时间（）
            availablePeriods = availablePeriods.map { period in
                switch period {
                case .customized:   return .customized(time: nil)
                default:            return period
                }
            }
            detailView.setPeriods(list: availablePeriods, selected: nil)
        }
        self.isExpanded = isExpanded
    }

    lazy var roundedContainer: UIView = {
        let view = SquircleView()
        view.cornerRadius = 20
        view.cornerSmoothness = .natural
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    lazy var titleView: FocusTitleView = {
        let view = FocusTitleView()
        // 绑定事件
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTitleview)))
        view.expandButton.addTarget(self, action: #selector(didTapExpandButton), for: .touchUpInside)
        return view
    }()

    lazy var detailView: FocusDetailView = {
        let view = FocusDetailView(userResolver: userResolver)
        // 绑定事件
        view.timeTagView.delegate = self
        view.settingButton.addTarget(self, action: #selector(didTapEditButton), for: .touchUpInside)
        return view
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(style: .default, reuseIdentifier: "FocusModeCell")
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(roundedContainer)
        roundedContainer.addSubview(stackView)
        stackView.addArrangedSubview(titleView)
        stackView.addArrangedSubview(detailView)
        roundedContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-26)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.bringSubviewToFront(titleView)
        // Cell 默认折叠
        detailView.isHidden = true

        if #available(iOS 13.4, *) {
            let action = PointerInteraction(style: PointerStyle(effect: .lift))
            titleView.addLKInteraction(action)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        // Handle hover state here
    }

    /// 点击了状态（打开或关闭）
    @objc
    func didTapTitleview() {
        switch selectionState {
        case .closed:
            turnOnStatusWithDefaultPeriod()
        case .opened:
            turnOffStatus()
        case .opening, .closing, .reopening:
            break
        }
    }

    // iPad 上键盘选中效果
    public override func didUpdateFocus(in context: UIFocusUpdateContext,
                                        with coordinator: UIFocusAnimationCoordinator) {
        guard #available(iOS 15, *) else { return }
        if context.nextFocusedItem === self {
            let effect = UIFocusHaloEffect(roundedRect: roundedContainer.frame,
                                           cornerRadius: 20,
                                           curve: .continuous)
            effect.referenceView = roundedContainer
            effect.containerView = roundedContainer
            focusEffect = effect
        } else if context.previouslyFocusedItem === self {
            focusEffect = nil
        }
    }
}

extension FocusModeCell: TagListViewDelegate {

    /// 选择了状态的时间标签（打开或关闭状态）
    func tagListView(_ tagListView: TagListView, didSelectTag tagView: TagView, atIndex index: Int) {
        let tappedPeriod = allPeriod[index]
        if tagView.isSelected {
            // deselect cell
            turnOffStatusWithPeriodTag(tappedPeriod)
        } else {
            switch tappedPeriod {
            case .customized:
                // 点击了最后一个“其他时间”标签
                turnOnStatusWithCustomizedPeriod(sourceView: tagView)
            case .preset(let date):
                turnOnStatusWithDefaultPeriod()
            case .minutes30, .hour1, .hour2, .hour4, .untilTonight:
                // 点击了预设时间标签
                turnOnStatusWithSelectedPeriod(tappedPeriod)
            case .noEndTime:
                // 不会出现
                break
            }
        }
    }

    /// 点击了时间标签的 “>” 图标
    func tagListView(_ tagListView: TagListView, didTapAccessoryButtonForTag tagView: TagView, atIndex index: Int) {
        // nothing
    }
}

extension FocusModeCell {

    // MARK: Expand status

    @objc
    private func didTapExpandButton() {
        delegate?.focusCellDidTapExpandButton(self)
    }

    // MARK: Config status

    @objc
    private func didTapEditButton() {
        delegate?.focusCellDidTapConfigButton(self)
    }

    // MARK: Turn on

    private func turnOnStatusWithDefaultPeriod() {
        // Model 中存有上次选择的默认时间
        let period = focusStatus?.defaultPeriod ?? .hour1
        delegate?.focusCellDidSelect(self, period: period)
        focusStatus.map {
            FocusTracker.turnOnFocusStatus($0)
        }
    }

    private func turnOnStatusWithSelectedPeriod(_ period: FocusPeriod) {
        delegate?.focusCellDidSelect(self, period: period)
        focusStatus.map {
            FocusTracker.turnOnFocusStatus($0, withPeriod: period)
        }
    }

    private func turnOnStatusWithCustomizedPeriod(sourceView: UIView) {
        guard let status = focusStatus else { return }
        // 调起日期选择器，选择自定义时间
        guard let topViewController = self.parentViewController else { return }
        let datePicker = FocusDatePickerController(userResolver: userResolver, sourceView: sourceView)
        datePicker.onConfirm = { [weak self] date in
            guard let self = self else { return }
            let period: FocusPeriod = .customized(time: date)
            self.delegate?.focusCellDidSelect(self, period: .customized(time: date))
            FocusTracker.didTapConfirmButtonOnTimePicker(status, date: date)
        }
        datePicker.onCancel = {
            FocusTracker.didTapCancelButtonOnTimePicker(status)
        }
        userResolver.navigator.present(datePicker, from: topViewController)
        FocusTracker.turnOnFocusStatusWithCustomTag(status)
        FocusTracker.didShowTimePicker(status)
    }

    // MARK: Turn off

    /// 点击状态标题关闭状态
    public func turnOffStatus() {
        delegate?.focusCellDidDeselect(self)
        focusStatus.map {
            FocusTracker.turnOffFocusStatus($0)
        }
    }

    /// 点击时间标签关闭状态
    public func turnOffStatusWithPeriodTag(_ period: FocusPeriod) {
        delegate?.focusCellDidDeselect(self)
        focusStatus.map {
            FocusTracker.turnOffFocusStatus($0, withPeriod: period)
        }
    }
}
