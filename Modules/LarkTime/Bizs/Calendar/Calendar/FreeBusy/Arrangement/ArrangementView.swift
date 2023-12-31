//
//  ArrangementView.swift
//  Calendar
//
//  Created by zhouyuan on 2019/4/2.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkUIKit
import UniverseDesignToast

protocol ArrangementViewProtocol {
    var startTime: Date { get set }
    var endTime: Date { get set }
    var firstWeekday: DaysOfWeek { get }
    var calendarInstanceMap: InstanceMap { get set }
    var workingHoursTimeRangeMap: [String: [WorkingHoursTimeRange]] { get }
    var privateCalMap: [String: Bool] { get set }
    var calendarIds: [String] { get }
    var headerViewModel: ArrangementHeaderViewModel { get }
    var footerViewModel: ArrangementFooterViewModel { get }
    func cellWidth(with rullerWidth: CGFloat, totalWidth: CGFloat) -> CGFloat
    func getUiStartTime() -> Date
    func getUiEndTime() -> Date
}

protocol ArrangementViewDelegate: AnyObject {
    func arrangementViewClosed(_ arrangementView: ArrangementView)

    func arrangementViewDone(_ arrangementView: ArrangementView)

    /// 时间改变 在同一天内
    func timeChanged(_ arrangementView: ArrangementView, startTime: Date, endTime: Date)

    /// 选小月历时间改变 需重新加载instance数据
    func dateChanged(_ arrangementView: ArrangementView, date: Date)

    /// 点击头像左移
    func moveAttendeeToFirst(_ arrangementView: ArrangementView, indexPath: IndexPath)

    func retry(_ arrangementView: ArrangementView)

    func timeZoneClicked()
}

final class ArrangementView: UIView {
    typealias Style = ArrangementPanel.Style
    weak var delegate: ArrangementViewDelegate?

    private let scrollViewInterconnection = ScrollViewInterconnection()
    private let headerView: ArrangementHeaderView
    private let footerView = ArrangementFooterView()
    private let navigationBar: ArrangementNavigationBar
    private let arrangementPanel: ArrangementPanel
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

    private lazy var timeZoneWrapper: TimeZoneWrapper = {
        var tz = TimeZoneWrapper()
        tz.timeZoneClicked = { [weak self] in
            self?.delegate?.timeZoneClicked()
        }
        return tz
    }()

    init(content: ArrangementViewProtocol, is12HourStyle: Bool) {
        self.navigationBar = ArrangementNavigationBar(date: content.getUiStartTime(),
                                                      firstWeekday: content.firstWeekday,
                                                      showCancelLeft: true)

        let rullerWidth = TimeIndicator.indicatorWidth(is12HourStyle: is12HourStyle)
        self.headerView = ArrangementHeaderView(leftMargin: rullerWidth, mode: .freeBusy)
        self.arrangementPanel = ArrangementPanel(
            intervalCoodinator: ArrangementIntervalCoodinator(startTime: content.getUiStartTime(), endTime: content.getUiEndTime(), is12HourStyle: is12HourStyle)
        )
        super.init(frame: .zero)
        setupNavigationBar(navigationBar, superView: self)
        layoutHeaderView(headerView, superView: self, upView: navigationBar, leftMargin: rullerWidth)
        if CalConfig.isMultiTimeZone {
            layoutTimeZone(width: rullerWidth)
        }
        layoutVerticalScrollView(verticalScrollView, upView: headerView)
        layoutArrangementPanel(arrangementPanel, superView: verticalScrollView)
        layoutFootView(footerView, superView: self, upView: verticalScrollView)

        scrollViewInterconnection.horizontalCompletelySynchronized(
            scrollViewA: arrangementPanel.horizontalScrollView(),
            scrollViewB: headerView.horizontalScrollView()
        )
        self.addSubview(loaddingWrapper)
        loaddingWrapper.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(headerView)
        }
        /// 小月历可下拉 不能遮挡
        bringSubviewToFront(navigationBar)
    }

    deinit {
        UDToast.removeToast(on: self)
    }

    func relayoutArrangementPanel(newWidth: CGFloat) {
        arrangementPanel.relayout(newWidth: newWidth)
        verticalScrollView.contentSize = CGSize(width: newWidth, height: Style.wholeDayHeight)
        headerView.relayoutForiPad(newWidth: newWidth)
    }

    func scrollToCenter(animated: Bool) {
        var y: CGFloat = arrangementPanel.intervalIndicatorFrame().minY - verticalScrollView.frame.height / 2.0
        if y < 0 { y = 0 }
        verticalScrollView.contentOffset = CGPoint(
            x: 0,
            y: y
        )
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

    func updateTimeLineViewFrame() {
        arrangementPanel.updateTimerLineFrame()
    }

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
                                    privateCalMap: model.privateCalMap)
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
    }

    private func layoutVerticalScrollView(_ scrollView: UIScrollView, upView: UIView) {
        addSubview(scrollView)
        scrollView.contentSize.width = upView.bounds.width
        scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(upView.snp.bottom)
            make.left.right.equalToSuperview()
        }
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
        footerView.delegate = self
        footerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(upView.snp.bottom)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
        }
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - ArrangementPanelDelegate
extension ArrangementView: ArrangementPanelDelegate {
    func intervalStateChanged(_ arrangementPanel: ArrangementPanel,
                              isHidden: Bool,
                              instanceMap: InstanceMap) {
        // do nothing
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
        normalErrorLog("Not available in Arranging")
    }
}

// MARK: - ArrangementFooterViewDelegate
extension ArrangementView: ArrangementFooterViewDelegate {
    func arrangementFooterViewTimeConfirmed() {
        self.delegate?.arrangementViewDone(self)
    }
}
