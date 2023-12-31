//
//  GroupFreeBusyView.swift
//  Calendar
//
//  Created by sunxiaolei on 2019/7/28.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkUIKit
import RoundedHUD
import RxSwift
import UniverseDesignToast

protocol GroupFreeBusyViewDelegate: AnyObject {
    func arrangementViewClosed(_ groupFreeBusyView: GroupFreeBusyView)

    /// 时间改变 在同一天内
    func timeChanged(_ groupFreeBusyView: GroupFreeBusyView, startTime: Date, endTime: Date)

    /// 选小月历时间改变 需重新加载instance数据
    func dateChanged(_ groupFreeBusyView: GroupFreeBusyView, date: Date)

    /// 点击头像左移
    func moveAttendeeToFirst(_ groupFreeBusyView: GroupFreeBusyView, indexPath: IndexPath)

    func retry(_ groupFreeBusyView: GroupFreeBusyView)

    func chooseButtonClicked()

    func timeZoneClicked()

    func getTimeZone() -> TimeZone
}

final class GroupFreeBusyView: UIView {
    typealias Style = ArrangementPanel.Style
    weak var delegate: GroupFreeBusyViewDelegate?
    private let disposeBag = DisposeBag()
    private let isHiddenPushlish = PublishSubject<Bool>()

    private let scrollViewInterconnection = ScrollViewInterconnection()
    private let headerView: ArrangementHeaderView
    private var heightConstraint: NSLayoutConstraint?
    private let footerView = ArrangementFooterView(hasConfirmButton: false)
    private let navigationBar: ArrangementNavigationBar
    private let arrangementPanel: ArrangementPanel
    private let is12HourStyle: Bool

    var addNewEvent: ((_ startTime: Date, _ endTime: Date) -> Void)?
    private let verticalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.contentSize = Style.viewSize
        scrollView.canCancelContentTouches = false
        scrollView.delaysContentTouches = false
        return scrollView
    }()

    private let loaddingWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    private lazy var loaddingView: LoadingView = {
        let loadding = LoadingView(displayedView: loaddingWrapper)
        return loadding
    }()

    private let monthBgView: UIView = UIView()
    private let hud = RoundedHUD()
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage.cd.image(named: "group_free_busy_add").withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()

    private lazy var timeZoneWrapper: TimeZoneWrapper = {
        var tz = TimeZoneWrapper()
        tz.timeZoneClicked = { [weak self] in
            self?.delegate?.timeZoneClicked()
        }
        return tz
    }()

    init(content: ArrangementViewProtocol,
         is12HourStyle: Bool,
         getNewEventMinute: @escaping () -> Int) {
        self.navigationBar = ArrangementNavigationBar(
            date: content.getUiStartTime(),
            firstWeekday: content.firstWeekday,
            showChooseButton: true)

        let rullerWidth = TimeIndicator.indicatorWidth(is12HourStyle: is12HourStyle)
        self.headerView = ArrangementHeaderView(leftMargin: rullerWidth, mode: .freeBusy)
        let intervalCoodinator = FreebusyIntervalCoodinator(startTime: content.getUiStartTime(),
                                                            title: BundleI18n.Calendar.Calendar_Edit_addEventNamedTitle,
                                                            isHiddenPushlish: isHiddenPushlish,
                                                            getNewEventMinute: getNewEventMinute,
                                                            is12HourStyle: is12HourStyle)
        self.arrangementPanel = ArrangementPanel(intervalCoodinator: intervalCoodinator)
        self.is12HourStyle = is12HourStyle
        super.init(frame: CGRect(x: 0, y: 0,
                                 width: UIScreen.main.bounds.width,
                                 height: UIScreen.main.bounds.height))
        intervalCoodinator.getTimeZone = { [weak self] in
            return self?.delegate?.getTimeZone() ?? TimeZone.current
        }
        setupNavigationBar(navigationBar, superView: self)
        layoutHeaderView(headerView, superView: self, upView: navigationBar, leftMargin: rullerWidth)
        if CalConfig.isMultiTimeZone {
            layoutTimeZone(width: rullerWidth)
        }
        layoutVerticalScrollView(verticalScrollView, upView: headerView)
        layoutArrangementPanel(arrangementPanel, superView: verticalScrollView)
        layoutFootView(footerView, superView: self, upView: verticalScrollView)
        layoutAddImage()

        navigationBar.choosenGroupMemberHandle = { [weak self] in
            self?.delegate?.chooseButtonClicked()
            CalendarTracer.shareInstance.groupFreeBusyChooseMember(type: "icon")
        }
        scrollViewInterconnection.horizontalCompletelySynchronized(
            scrollViewA: arrangementPanel.horizontalScrollView(),
            scrollViewB: headerView.horizontalScrollView()
        )
        self.addSubview(loaddingWrapper)
        loaddingWrapper.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(headerView)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(maskViewOnClick))
        monthBgView.addGestureRecognizer(tap)
        addSubview(monthBgView)
        monthBgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        monthBgView.isHidden = true

        /// 小月历可下拉 不能遮挡
        bringSubviewToFront(navigationBar)
        observerScroll(verticalScrollView: verticalScrollView)

        intervalCoodinator.addNewEvent = { [weak self] (startTime, endTime) in
            self?.addNewEvent?(startTime, endTime)
        }

        self.navigationBar.stateChangeHandle = { [weak self] (isExpand) in
            self?.monthBgView.isHidden = !isExpand
        }
    }

    func relayoutArrangementPanelAndHeader(newWidth: CGFloat) {
        arrangementPanel.relayout(newWidth: newWidth)
        verticalScrollView.contentSize = CGSize(width: newWidth, height: Style.wholeDayHeight)
        headerView.relayoutForiPad(newWidth: newWidth)
    }

    @objc
    private func maskViewOnClick() {
        self.navigationBar.closeDatePicker()
    }

    private func observerScroll(verticalScrollView: UIScrollView) {
        verticalScrollView.rx.didScroll
            .throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .asObservable()
            .subscribe(onNext: { [weak self] () in
//                self?.isHiddenPushlish.onNext(true)
            })
            .disposed(by: disposeBag)
    }

    func scrollToTime(time: Date, animated: Bool) {
        let offset = yOffsetWithDate(time,
                                     inTheDay: time,
                                     totalHeight: Style.hourGridHeight * 24,
                                     topIgnoreHeight: 0,
                                     bottomIgnoreHeight: 0)
        let rect = CGRect(x: 0, y: offset,
                          width: verticalScrollView.frame.width,
                          height: 20)
        scrollRectToVisibleCenter(verticalScrollView, visibleRect: rect, animated: animated)
    }

    private func scrollRectToVisibleCenter(_ scrollView: UIScrollView,
                                           visibleRect: CGRect,
                                           animated: Bool) {
        let centeredRect = CGRect(
            x: visibleRect.minX,
            y: visibleRect.minY - scrollView.frame.height / 2.0 + Style.topGridMargin * 2.0,
            width: scrollView.frame.width,
            height: scrollView.frame.height)
        scrollView.scrollRectToVisible(centeredRect, animated: animated)
    }

    func showLoading(shouldRetry: Bool) {
        if shouldRetry {
            loaddingWrapper.isHidden = false
            loaddingView.showLoading()
        } else {
            loaddingWrapper.isHidden = true
            UDToast.showLoading(with: BundleI18n.Calendar.Calendar_Edit_FindTimeLoading, on: self)
        }
    }

    func hideLoading(shouldRetry: Bool, failed: Bool) {
        if failed && shouldRetry {
            loaddingView.showFailed { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.retry(self)
            }
            return
        }
        if failed && !shouldRetry {
            UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Common_FailedToLoad, on: self)
            return
        }
        loaddingView.remove()
        UDToast.removeToast(on: self)
        loaddingWrapper.isHidden = true
    }

    func hideInterval() {
        isHiddenPushlish.onNext(true)
    }

    func showInterval() {
        isHiddenPushlish.onNext(false)
    }

    /// 内部update为UI操作
    func setHeaderViewInfo(model: ArrangementHeaderViewModel) {
        headerView.updateModel(model: model)
        headerView.movedToLeft = { [unowned self] (_, indexPath) in
            self.arrangementPanel.moveCellToLeft(indexPath: indexPath)
            self.delegate?.moveAttendeeToFirst(self, indexPath: indexPath)
        }
    }

    func reloadServerData(model: ArrangementViewProtocol) {
        arrangementPanel.reloadView(calendarIds: model.calendarIds,
                                    calendarInstanceMap: model.calendarInstanceMap,
                                    workingHoursTimeRangeMap: model.workingHoursTimeRangeMap,
                                    privateCalMap: model.privateCalMap
        )
        updateHeaderFooter(model: model)
    }

    func cleanInstance(calendarIds: [String], startTime: Date, endTime: Date) {
        arrangementPanel.cleanInstance(calendarIds: calendarIds,
                                       startTime: startTime,
                                       endTime: endTime)
    }

    func updateHeaderFooter(model: ArrangementViewProtocol) {
        footerView.updateContent(content: model.footerViewModel)
        headerView.updateModel(model: model.headerViewModel)
        if model.headerViewModel.cellModels.isEmpty {
            addButton.isHidden = false
        } else {
            addButton.isHidden = true
        }
    }

    private func layoutAddImage() {
        addSubview(addButton)
        addButton.addTarget(self, action: #selector(addButtonClicked), for: .touchUpInside)
        addButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).offset(60)
            make.left.equalToSuperview().offset(56)
            make.width.height.equalTo(40)
        }
    }

    private func layoutVerticalScrollView(_ scrollView: UIScrollView, upView: UIView) {
        addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(upView.snp.bottom)
            make.left.right.equalToSuperview()
        }
        scrollView.contentSize.width = upView.bounds.width
        scrollView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    private func layoutArrangementPanel(_ arrangementPanel: ArrangementPanel,
                                        superView: UIView) {
        arrangementPanel.delegate = self
        superView.addSubview(arrangementPanel)
    }

    private func layoutFootView(_ footerView: ArrangementFooterView,
                                superView: UIView,
                                upView: UIView) {
        superView.addSubview(footerView)
        footerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(upView.snp.bottom)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
        }
        footerView.isHidden = true
        self.heightConstraint = footerView.heightAnchor.constraint(equalToConstant: 0)
        self.heightConstraint?.isActive = true
    }

    private func setupNavigationBar(_ navigationBar: ArrangementNavigationBar,
                                    superView: UIView) {
        superView.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }

        navigationBar.closeHandle = { [unowned self] in
            self.delegate?.arrangementViewClosed(self)
        }

        navigationBar.didSelectDate = { [unowned self] date in
            self.delegate?.dateChanged(self, date: date)
        }
    }

    private func layoutHeaderView(_ headerView: ArrangementHeaderView,
                                  superView: UIView,
                                  upView: UIView,
                                  leftMargin: CGFloat) {
        superView.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).offset(44)
            make.left.equalToSuperview().offset(leftMargin)
        }
    }

    private func layoutTimeZone(width: CGFloat) {
        self.addSubview(timeZoneWrapper)
        timeZoneWrapper.snp.makeConstraints({make in
            make.left.equalToSuperview()
            make.width.equalTo(width)
            make.bottom.equalTo(headerView.snp.bottom).offset(-12)
        })
    }

    func setTimeZoneStr(timeZoneStr: String) {
        timeZoneWrapper.setTimeZoneStr(timeZoneStr: timeZoneStr)
    }

    func updateCurrentUiDate(uiDate: Date, with timeZone: TimeZone = .current) {
        navigationBar.updateCurrentUiDate(uiDate: uiDate, timeZone: timeZone)
        arrangementPanel.updateCurrentUiDate(uiDate: uiDate)
    }

    func headerFirstCell() -> UIView? {
        return headerView.firstCell()
    }

    @objc
    private func addButtonClicked() {
        CalendarTracer.shareInstance.groupFreeBusyChooseMember(type: "plus")
        delegate?.chooseButtonClicked()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - ArrangementPanelDelegate
extension GroupFreeBusyView: ArrangementPanelDelegate {
    func intervalStateChanged(_ arrangementPanel: ArrangementPanel,
                              isHidden: Bool,
                              instanceMap: InstanceMap) {
        self.footerView.isHidden = isHidden
        if isHidden {
            self.heightConstraint?.constant = 0
            self.heightConstraint?.isActive = true
        } else {
            self.heightConstraint?.constant = 80
            self.heightConstraint?.isActive = false
        }
    }

    func intervalFrameChangedByClick(newFrame: CGRect, superView: UIView) {
        if Display.pad {
            return
        }
        let rect = superView.convert(newFrame, to: self)
        let visibleRect = superView.convert(newFrame, to: verticalScrollView)
        if !verticalScrollView.frame.contains(rect) {
            scrollRectToVisibleCenter(verticalScrollView,
                                      visibleRect: visibleRect,
                                      animated: true)
        }
    }

    func timeChanged(_ arrangementPanel: ArrangementPanel, startTime: Date, endTime: Date) {
        self.delegate?.timeChanged(self, startTime: startTime, endTime: endTime)
    }

    func jumpToEventDetailVC(_ detailVC: UIViewController) {
        normalErrorLog("Not available in groupFreeBusy")
    }
}
