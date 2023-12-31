//
//  ChatWidgetsContainerView.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/1/8.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import SnapKit
import LarkUIKit
import LKCommonsLogging
import LKCommonsTracker
import Homeric
import LarkCore
import UniverseDesignColor
import LarkModel
import RustPB
import UniverseDesignIcon
import UniverseDesignToast
import LarkMessageCore
import EENavigator
import LarkSetting
import Swinject

/// widgets 卡片 UI 状态
enum ChatWidgetUIState {
    case fold        /// 完全折叠
    case single      /// 只展示第一张卡片
    case limitExpand /// 展开到极限态
}

final class ChatWidgetsContainerView: UIView, UITableViewDelegate, UITableViewDataSource {
    static let logger = Logger.log(ChatWidgetsContainerView.self, category: "ChatWidgetsContainerView")
    weak var targetVC: UIViewController?

    var hasWidget: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    /// 卡片是否展开
    private let expandSignal: ReplaySubject<Bool> = ReplaySubject<Bool>.create(bufferSize: 1)
    lazy var expandDriver: Driver<Bool> = {
        return expandSignal.asDriver(onErrorJustReturn: false)
    }()
    /// 卡片是否展开到极限态
    var expandLimitBehaviorRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    private let singleLimitHeight: CGFloat = 200 + UIConfig.cardPaddingTop
    var expandLimitHeight: CGFloat = 0
    private var heightStyle: ChatWidgetUIState = .single
    private let viewModel: ChatWidgetsViewModel
    private let disposeBag = DisposeBag()

    // MARK: - 子视图
    struct UIConfig {
        static let tableMargin: CGFloat = 12
        static let barHeight: CGFloat = 16
        static let cardPaddingTop: CGFloat = 8
        static let widgetThemeColor: UIColor = UIColor.ud.rgb(0x6979B2) & UIColor.ud.rgb(0x323954)
        static let widgetThemeGradientColors: [UIColor] = [UIConfig.widgetThemeColor, UIColor.ud.rgb(0xB2D1FF) & UIColor.ud.rgb(0x4F597C)]
    }

    private struct UIOutputIndentify {
        static let drag: String = "ChatWidget_Drag"
        static let multiSelect: String = "ChatWidget_MultiSelect"
        static let edit: String = "ChatWidget_Edit"
    }

    private lazy var gestureView: UIView = {
        let gestureView = ChatWidgetsBottomGestureView()
        gestureView.targetView = self.editFooter?.editButton
        gestureView.backgroundColor = UIColor.clear
        let panGes = UIPanGestureRecognizer(target: self, action: #selector(panGes))
        gestureView.addGestureRecognizer(panGes)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        gestureView.addGestureRecognizer(tapGestureRecognizer)
        return gestureView
    }()

    private lazy var editFooter: ChatWidgetsEditFooter? = {
        guard viewModel.userResolver.fg.staticFeatureGatingValue(with: "im.chat.widget.permission") else {
            return nil
        }
        return ChatWidgetsEditFooter(onTap: { [weak self] in
            guard let self = self else { return }
            let canManageWidgets = self.viewModel.canManageWidgets
            guard canManageWidgets.0 else {
                if let disableTip = canManageWidgets.1, let targetVC = self.targetVC {
                    UDToast.showTips(with: disableTip, on: targetVC.view)
                }
                return
            }
            self.isEditing = true
            IMTracker.Chat.Main.Click.ChatWidgetEdit(self.viewModel.getChat())
        })
    }()

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.gradientBgView.colors = UIConfig.widgetThemeGradientColors
        self.contentMaskView.colors = [UIColor.ud.bgFloat.withAlphaComponent(0), UIColor.ud.bgFloat]
        self.tableMaskView.colors = [UIColor.ud.rgb(0x9FBAEA).withAlphaComponent(0) & UIColor.ud.rgb(0x4F597C).withAlphaComponent(0),
                                     UIColor.ud.rgb(0x9EBFF5) & UIColor.ud.rgb(0x55628C).withAlphaComponent(0.5)]
    }

    private lazy var gradientBgView: GradientView = {
        let gradientBgView = GradientView()
        gradientBgView.backgroundColor = UIColor.clear
        gradientBgView.locations = [0.0, 1.0]
        gradientBgView.layer.cornerRadius = 12
        let corner: UIRectCorner = [.bottomLeft, .bottomRight]
        gradientBgView.layer.maskedCorners = CACornerMask(rawValue: corner.rawValue)
        gradientBgView.clipsToBounds = true
        gradientBgView.automaticallyDims = false
        return gradientBgView
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.cornerRadius = 12
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = self.editFooter
        return tableView
    }()

    private lazy var barView: UIView = {
        let barView = UIView()
        barView.layer.cornerRadius = 2
        barView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.8)
        return barView
    }()

    private lazy var contentMaskView: GradientView = {
        let maskView = GradientView()
        maskView.backgroundColor = UIColor.clear
        maskView.locations = [0.0, 1.0]
        maskView.layer.cornerRadius = 12
        let corner: UIRectCorner = [.bottomLeft, .bottomRight]
        maskView.layer.maskedCorners = CACornerMask(rawValue: corner.rawValue)
        maskView.clipsToBounds = true
        maskView.automaticallyDims = false
        maskView.isUserInteractionEnabled = false
        return maskView
    }()

    private lazy var tableMaskView: GradientView = {
        let maskView = GradientView()
        maskView.backgroundColor = UIColor.clear
        maskView.locations = [0.0, 1.0]
        maskView.layer.cornerRadius = 12
        let corner: UIRectCorner = [.bottomLeft, .bottomRight]
        maskView.layer.maskedCorners = CACornerMask(rawValue: corner.rawValue)
        maskView.clipsToBounds = true
        maskView.automaticallyDims = false
        maskView.isUserInteractionEnabled = false
        return maskView
    }()

    private lazy var moreTipView: UIView = {
        let moreTipView = UIView()
        moreTipView.backgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.6)
        moreTipView.layer.cornerRadius = 12
        let corner: UIRectCorner = [.bottomLeft, .bottomRight]
        moreTipView.layer.maskedCorners = CACornerMask(rawValue: corner.rawValue)
        return moreTipView
    }()

    private lazy var solidBgView: UIView = {
        let solidBgView = UIView()
        solidBgView.backgroundColor = UIConfig.widgetThemeColor
        return solidBgView
    }()

    // MARK: - init
    init(viewModel: ChatWidgetsViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = true
    }

    // MARK: - layout containerSize
    func setup(_ size: CGSize) {
        self.observeViewModel()
        self.viewModel.containerSize = CGSize(width: size.width - UIConfig.tableMargin * 2, height: size.height)
        self.expandLimitHeight = size.height * 0.7 - UIConfig.barHeight - UIApplication.shared.statusBarFrame.height
        self.viewModel.setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = self.bounds.width - UIConfig.tableMargin * 2
        let vmSize = self.viewModel.containerSize
        if width != vmSize.width {
            self.viewModel.containerSize = CGSize(width: width, height: vmSize.height)
            self.viewModel.onResize()
        }
    }

    deinit {
        if hasWidget.value {
            if let lastStateWhenHide = lastStateWhenHide {
                self.viewModel.updateWidgetsExpandState(lastStateWhenHide)
                return
            }
            self.viewModel.updateWidgetsExpandState(self.heightStyle)
        }
    }

    // MARK: - UITableViewDelegate & UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.uiDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.viewModel.uiDataSource.count ?? 0 else {
            assertionFailure("保留现场！！！")
            return UITableViewCell()
        }
        let cellVM = self.viewModel.uiDataSource[indexPath.row]
        let cell = cellVM.dequeueReusableCardCell(tableView, cellId: cellVM.metaModel.widget.id) { [weak self] in
            guard let self = self else { return }
            guard self.editFooter != nil, self.viewModel.canManageWidgets.0 else { return }
            self.isEditing = true
            IMTracker.Chat.Main.Click.ChatWidgetPress(self.viewModel.getChat())
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < self.viewModel.uiDataSource.count ?? 0 else {
            assertionFailure("保留现场！！！")
            return
        }
        let cellVM = self.viewModel.uiDataSource[indexPath.row]
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            cellVM.willDisplay()
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ChatWidgetCardTableViewCell,
              let cellVM = self.viewModel.uiDataSource.first(where: { $0.metaModel.widget.id == cell.cellId }) else {
                  return
              }

        if !(tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            cellVM.didEndDisplay()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < self.viewModel.uiDataSource.count ?? 0 else {
            assertionFailure("保留现场！！！")
            return 0
        }
        return self.viewModel.uiDataSource[indexPath.row].render.size().height + UIConfig.cardPaddingTop
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < self.viewModel.uiDataSource.count ?? 0 else {
            assertionFailure("保留现场！！！")
            return 0
        }
        return self.viewModel.uiDataSource[indexPath.row].render.size().height + UIConfig.cardPaddingTop
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        switch self.heightStyle {
        case .fold, .single:
            self.tableMaskView.isHidden = true
        case .limitExpand:
            let scrollViewHeight = scrollView.bounds.size.height
            let contentHeight = scrollView.contentSize.height - (self.editFooter?.bounds.height ?? 0)
            if contentHeight > scrollViewHeight,
               contentHeight - scrollView.contentOffset.y > scrollViewHeight {
                self.tableMaskView.isHidden = false
            } else {
                self.tableMaskView.isHidden = true
            }
        }
    }

    // MARK: - 添加子视图
    private func setupView() {
        self.addSubview(self.solidBgView)
        self.addSubview(self.gradientBgView)
        self.addSubview(self.moreTipView)
        self.addSubview(self.tableView)
        self.addSubview(self.contentMaskView)
        self.addSubview(self.tableMaskView)
        self.addSubview(self.gestureView)
        self.addSubview(self.barView)

        tableMaskView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(60)
        }

        gestureView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(40)
        }
        solidBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        gradientBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        barView.snp.makeConstraints { make in
            make.width.equalTo(32)
            make.height.equalTo(4)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(6)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(UIConfig.tableMargin)
            /// update later
            make.height.equalTo(0)
            make.bottom.equalTo(barView.snp.top).offset(-6)
        }
        contentMaskView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(self.tableView)
            make.height.equalTo(36)
        }
        moreTipView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(30)
            make.height.equalTo(24)
            make.bottom.equalTo(barView.snp.top).offset(-6)
        }
    }

    func handleNaviBarPan(_ getsture: UIPanGestureRecognizer) {
        if self.heightStyle != .fold {
            return
        }
        self.panGes(getsture)
    }

    var originTableHeight: CGFloat = 0
    @objc
    func panGes(_ getsture: UIPanGestureRecognizer) {
        func pauseWhenDrag(_ pause: Bool) {
            self.viewModel.uiOutput(enable: !pause, indentify: UIOutputIndentify.drag)
        }

        func calculateUpdateTableHeight(_ offsetY: CGFloat) -> CGFloat {
            var updateTableHeight = self.originTableHeight + offsetY
            if updateTableHeight < 0 { updateTableHeight = 0 }
            let maxHeight = self.calculateLimitExpandHeight()
            if updateTableHeight > maxHeight { updateTableHeight = maxHeight }
            return updateTableHeight
        }

        guard let targetView = self.superview else { return }
        let point = getsture.translation(in: targetView)
        let velocity = getsture.velocity(in: targetView)
        switch getsture.state {
        case .began:
            self.moreTipView.alpha = 0
            self.contentMaskView.alpha = 0
            self.tableView.isScrollEnabled = false
            self.gradientBgView.isHidden = false
            self.solidBgView.isHidden = true
            self.tableMaskView.isHidden = true
            pauseWhenDrag(true)
            self.originTableHeight = self.tableView.bounds.size.height
            if velocity.y < 0, self.heightStyle == .fold {
                getsture.state = .cancelled
                return
            }
        case .changed:
            let updateTableHeight = calculateUpdateTableHeight(point.y)
            self.tableView.snp.updateConstraints { make in
                make.height.equalTo(updateTableHeight)
            }
        case .cancelled, .ended, .failed:
            let updateTableHeight = calculateUpdateTableHeight(point.y)
            /// 根据速度判断最终位置
            if velocity.y > 50 {
                if supportExpand(), updateTableHeight > calculateSingleHeight() {
                    switchAndTrack(.limitExpand)
                } else {
                    switchAndTrack(.single)
                }
                pauseWhenDrag(false)
                return
            }
            if velocity.y < -50 {
                if updateTableHeight > calculateSingleHeight() {
                    switchAndTrack(.single)
                } else {
                    switchAndTrack(.fold)
                }
                pauseWhenDrag(false)
                return
            }
            /// 根据松手位置判断最终位置
            if updateTableHeight <= 30 {
                switchAndTrack(.fold)
                pauseWhenDrag(false)
                return
            }
            if !self.supportExpand() {
                switchAndTrack(.single)
                pauseWhenDrag(false)
                return
            }
            let singleHeight = self.calculateSingleHeight()
            let limitExpandHeight = self.calculateLimitExpandHeight()
            if updateTableHeight > (limitExpandHeight - singleHeight) / 3 + singleHeight {
                switchAndTrack(.limitExpand)
            } else {
                switchAndTrack(.single)
            }
            pauseWhenDrag(false)
        case .possible:
            break
        }
    }

    @objc
    func tap(_ gesture: UITapGestureRecognizer) {
        switch self.heightStyle {
        case .fold:
            if !self.viewModel.uiDataSource.isEmpty {
                self.switchAndTrack(.single)
            }
        case .single:
            /// 是否支持展到 limitExpand
            if self.supportExpand() {
                self.switchAndTrack(.limitExpand)
            }
        case .limitExpand:
            self.switchAndTrack(.single)
        }
    }

    private var lastStateWhenHide: ChatWidgetUIState?
    func foldWhenHide() {
        switch self.heightStyle {
        case .fold:
            break
        case .single, .limitExpand:
            self.lastStateWhenHide = self.heightStyle
            self.switchToState(.fold, animated: false)
        }
    }

    private func switchAndTrack(_ state: ChatWidgetUIState) {
        var keepOffset: Bool = false
        switch (self.heightStyle, state) {
        case (.fold, .single), (.fold, .limitExpand), (.single, .limitExpand):
            trackChatWidgetFrame(false)
        case (.limitExpand, .single), (.limitExpand, .fold), (.single, .fold):
            trackChatWidgetFrame(true)
        case (.limitExpand, .limitExpand):
            keepOffset = true
        default:
            break
        }
        self.switchToState(state, animated: true, keepOffset: keepOffset)
        lastStateWhenHide = nil
    }

    private func calculateSingleHeight() -> CGFloat {
        guard let cellHeight = self.getFirstCardHeight() else {
            return 0
        }
        return min(cellHeight, self.singleLimitHeight)
    }

    private func calculateLimitExpandHeight() -> CGFloat {
        return min(getTableHeight(), expandLimitHeight)
    }

    /// 计算是否支持展开到极限态
    private func supportExpand() -> Bool {
        if self.viewModel.uiDataSource.count > 1 {
            return true
        }
        if let firstCardHeight = self.getFirstCardHeight(),
           firstCardHeight > self.singleLimitHeight {
            return true
        }
        if !self.viewModel.uiDataSource.isEmpty, self.editFooter != nil {
            return true
        }
        return false
    }

    /// 计算卡片列表内容高度
    private func getTableHeight() -> CGFloat {
        let contentHeight: CGFloat = self.viewModel.uiDataSource.reduce(0) { result, cellVM in
            var result = result
            result += cellVM.render.size().height + UIConfig.cardPaddingTop
            return result
        }
        return contentHeight + (self.editFooter?.bounds.height ?? 0)
    }

    /// 计算第一张卡片内容高度
    private func getFirstCardHeight() -> CGFloat? {
        guard let cellVM = self.viewModel.uiDataSource.first else { return nil }
        return cellVM.render.size().height + UIConfig.cardPaddingTop
    }

    /// single state 时更新子视图
    private func layoutWhenSingle() {
        guard let cellHeight = self.getFirstCardHeight() else {
            return
        }
        /// 高度和是否被截断
        var tableHeight: CGFloat = 0
        if cellHeight > self.singleLimitHeight {
            tableHeight = self.singleLimitHeight
            self.contentMaskView.alpha = 1
        } else {
            tableHeight = cellHeight
            self.contentMaskView.alpha = 0

        }
        /// 处理更多提示
        var barOffset: CGFloat = -6
        if self.viewModel.uiDataSource.count > 1 {
            barOffset = -14
            self.moreTipView.alpha = 1
        } else {
            self.moreTipView.alpha = 0
        }
        self.tableView.snp.updateConstraints { make in
            make.height.equalTo(tableHeight)
            make.bottom.equalTo(barView.snp.top).offset(barOffset)
        }
        self.tableView.isScrollEnabled = false
        self.gradientBgView.isHidden = false
        self.solidBgView.isHidden = true
        self.tableMaskView.isHidden = true
    }

    /// expandLimit state 时更新子视图
    private func layoutWhenExpandLimit() {
        self.contentMaskView.alpha = 0
        self.moreTipView.alpha = 0
        let tableHeight: CGFloat = min(getTableHeight(), expandLimitHeight)
        self.tableView.snp.updateConstraints { make in
            make.height.equalTo(tableHeight)
            make.bottom.equalTo(barView.snp.top).offset(-6)
        }
        self.tableView.isScrollEnabled = true
        self.gradientBgView.isHidden = false
        self.solidBgView.isHidden = true
        if self.getTableHeight() > self.expandLimitHeight {
            self.tableMaskView.isHidden = false
        } else {
            self.tableMaskView.isHidden = true
        }
    }

    /// folde state 时更新子视图
    private func layoutWhenFold() {
        self.moreTipView.alpha = 0
        self.contentMaskView.alpha = 0
        self.tableView.snp.updateConstraints { make in
            make.height.equalTo(0)
            make.bottom.equalTo(barView.snp.top).offset(-6)
        }
        self.tableView.isScrollEnabled = false
        self.gradientBgView.isHidden = true
        self.solidBgView.isHidden = false
        self.tableMaskView.isHidden = true
    }

    /// UI 状态切换
    private func switchToState(_ state: ChatWidgetUIState, animated: Bool, keepOffset: Bool = false) {
        if !self.subViewAlreadySetup { return }
        /// 这里清除上次键盘收起记录的状态
        self.lastState = nil
        self.expandSignal.onNext(state != .fold)
        self.expandLimitBehaviorRelay.accept(state == .limitExpand)

        let switchHandler: () -> Void = {
            switch state {
            case .fold:
                self.heightStyle = .fold
                self.layoutWhenFold()
            case .single:
                self.heightStyle = .single
                self.layoutWhenSingle()
            case .limitExpand:
                self.heightStyle = .limitExpand
                self.layoutWhenExpandLimit()
            }
        }

        if !animated {
            switchHandler()
            if !keepOffset {
                self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            }
            return
        }
        UIView.animate(withDuration: 0.25, animations: {
            switchHandler()
            self.superview?.layoutIfNeeded()
        }, completion: { _ in
            if !keepOffset {
                self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            }
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 处理键盘和多选场景
    /// 输入框弹起的时候 完全收起卡片 && 记录当前 state
    private var _keyboardContentIsFold: Bool = true
    func handleKeyboardContentHeightWillChange(_ isFold: Bool) {
        guard self._keyboardContentIsFold != isFold else { return }
        self._keyboardContentIsFold = isFold

        self.recordCurrentStateAndFold(!isFold)
    }

    /// 页面多选的时候 完全收起卡片 && 禁止卡片刷新
    private var _multiSelecting: Bool = false
    func handleMultiselect(_ multiSelecting: Bool) {
        guard self._multiSelecting != multiSelecting else { return }
        self._multiSelecting = multiSelecting

        self.gestureView.isUserInteractionEnabled = !multiSelecting
        self.viewModel.uiOutput(enable: !multiSelecting, indentify: UIOutputIndentify.multiSelect)
        self.recordCurrentStateAndFold(multiSelecting)
    }

    private var lastState: ChatWidgetUIState?
    private func recordCurrentStateAndFold(_ isRecord: Bool) {
        guard hasWidget.value else {
            return
        }
        if isRecord {
            let currentState = self.heightStyle
            self.switchToState(.fold, animated: true)
            self.lastState = currentState
        } else {
            if let lastState = self.lastState {
                self.lastState = nil
                switch lastState {
                case .fold:
                    self.switchToState(.fold, animated: true)
                case .single, .limitExpand:
                    self.switchToState(.single, animated: true)
                }
            }
        }
    }

    // MARK: - 监听数据并刷新
    func observeViewModel() {
        self.viewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                guard let self = self else { return }
                switch refreshType {
                case .refreshTable:
                    self.tableView.reloadData()
                }
                self.setupRefreshData()
                var heightForLog = ""
                self.viewModel.uiDataSource.forEach { cellVM in
                    heightForLog += " \(cellVM.render.size().height)"
                }
                Self.logger.info("widgetsTrace tableRefreshDriver \(self.viewModel.getChat().id) \(refreshType.describ) \(self.viewModel.uiDataSource.count) \(heightForLog)")
            }).disposed(by: self.disposeBag)

        self.viewModel.enableUIOutputDriver
            .filter({ return $0 })
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.setupRefreshData()
            }).disposed(by: self.disposeBag)

        self.viewModel.canManageWidgetsBehaviorRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] hasPermission in
                self?.editFooter?.setEnable(hasPermission)
            }).disposed(by: self.disposeBag)
    }

    /// 数据变更刷新 UI
    private var subViewAlreadySetup: Bool = false
    private func setupRefreshData() {
        self.hasWidget.accept(!self.viewModel.uiDataSource.isEmpty)
        self.lastState = nil

        if !self.subViewAlreadySetup {
            if self.viewModel.uiDataSource.isEmpty {
                return
            }
            self.subViewAlreadySetup = true
            self.setupView()
            let widgetStatusValue = self.viewModel.getChat().chatterExtraStates[Chat.ChatterExtraStatesType.widgetStatus]
            let expandWidgets = widgetStatusValue == nil || widgetStatusValue == Int32(RustPB.Basic_V1_Chat.WidgetState.expand.rawValue)
            if expandWidgets {
                self.switchToState(.single, animated: false)
            } else {
                self.switchToState(.fold, animated: false)
            }
            Self.logger.info("widgetsTrace expandWidgets \(self.viewModel.getChat().id) \(expandWidgets)")
            trackShowWidget()
            return
        }

        switch self.heightStyle {
        case .fold:
            return
        case .single:
            self.switchToState(.single, animated: false)
        case .limitExpand:
            if self.supportExpand() {
                self.switchToState(.limitExpand, animated: false)
                return
            }
            self.switchToState(.single, animated: false)
        }
    }

    // MARK: - 编辑
    private var isEditing: Bool = false {
        didSet {
            guard oldValue != isEditing else {
                return
            }
            if isEditing {
                guard let targetVC = self.targetVC else { return }
                let tableHieght = targetVC.view.bounds.height - self.convert(tableView.frame.origin, to: targetVC.view).y
                UIView.animate(withDuration: 0.25, animations: {
                    self.tableView.snp.updateConstraints { make in
                        make.height.equalTo(tableHieght)
                    }
                    self.superview?.layoutIfNeeded()
                }, completion: { _ in
                    self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                })
                self.presentEditVC()
            } else {
                self.switchToState(.single, animated: true)
            }
            self.viewModel.uiOutput(enable: !isEditing, indentify: UIOutputIndentify.edit)
        }
    }

    private func presentEditVC() {
        guard let targetVC = targetVC else { return }
        let sortAndDeleteViewModel = self.viewModel.initSortAndDeleteViewModel()
        let sortAndDeleteViewController = ChatWidgetsSortAndDeleteViewController(viewModel: sortAndDeleteViewModel) { [weak self] in
            self?.isEditing = false
        }
        viewModel.navigator.present(sortAndDeleteViewController, from: targetVC)
    }

    // MARK: - 埋点
    private func trackShowWidget() {
        let chat = self.viewModel.getChat()
        let widgetIds: [Int64] = self.viewModel.uiDataSource.map { $0.metaModel.widget.id }
        Tracker.post(TeaEvent("im_chat_top_widget_view",
                              params: ["widget_id": widgetIds],
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
        Tracker.post(TeaEvent("im_chat_widget_show_status",
                              params: ["status": "half_expand"],
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    private func trackChatWidgetFrame(_ isFold: Bool) {
        IMTracker.Chat.Main.Click.ChatWidgetFrame(
            self.viewModel.getChat(),
            widetIds: self.viewModel.uiDataSource.map { $0.metaModel.widget.id },
            isFold: isFold
        )
    }
}
