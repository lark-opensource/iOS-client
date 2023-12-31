//
//  GroupFreeBusyController.swift
//  Calendar
//
//  Created by pluto on 2023/9/7.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import RoundedHUD
import EENavigator
import CalendarFoundation
import LarkContainer
import RustPB
import LarkGuide

final class GroupFreeBusyController: CalendarController, UserResolverWrapper {
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var newGuideManager: NewGuideService?

    lazy var groupFreeBusyView: GroupFreeBusyView = {
        let view = GroupFreeBusyView(content: viewModel.groupFreeBusyModel,
                                     is12HourStyle: viewModel.rxIs12HourStyle.value,
                                     getNewEventMinute: viewModel.defaultDurationGetter)
        return view
    }()
    
    private var needScrollToCurrentTime = true
    private var viewBoundsWidth: CGFloat = 0

    let viewModel: GroupFreeBusyViewModel
    let userResolver: UserResolver
    let disposeBag = DisposeBag()

    init(viewModel: GroupFreeBusyViewModel) {
        self.viewModel = viewModel
        self.userResolver = viewModel.userResolver
        super.init(nibName: nil, bundle: nil)
        
        viewModel.delegate = self
        groupFreeBusyView.delegate = self
        isNavigationBarHidden = true
        initNewEventHandle()
        regist12HoursChange()
        
        CalendarMonitorUtil.startTrackFreebusyViewInChatTime()
    }

    private func regist12HoursChange() {
        viewModel.rxIs12HourStyle.asDriver().skip(1).drive(onNext: { [weak self] (is12HourStyle) in
            self?.renewGroupFreeBusyView(is12HourStyle: is12HourStyle)
        }).disposed(by: disposeBag)
    }

    private func layoutViews() {
        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(groupFreeBusyView)

        groupFreeBusyView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        groupFreeBusyView.setTimeZoneStr(timeZoneStr: viewModel.groupFreeBusyModel.getTzDisplayName())
        groupFreeBusyView.updateCurrentUiDate(uiDate: viewModel.groupFreeBusyModel.getUiCurrentDate())
    }

    private func renewGroupFreeBusyView(is12HourStyle: Bool) {
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingService.shared().stateManager.activate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingService.shared().stateManager.inActivate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewBoundsWidth = view.bounds.width
        bindViewData()
        layoutViews()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        groupFreeBusyView.hideLoading(shouldRetry: false, failed: false)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        groupFreeBusyView.relayoutArrangementPanelAndHeader(newWidth: self.view.frame.width)
    }

    private func bindViewData() {
        viewModel.groupFreeBusyModel.sunStateService.rxMapHasChanged
            .subscribeForUI(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.groupFreeBusyView.updateHeaderFooter(model: self.viewModel.groupFreeBusyModel)
            }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GroupFreeBusyController: GroupFreeBusyViewDelegate {
    func getTimeZone() -> TimeZone {
        return TimeZone(identifier: self.viewModel.groupFreeBusyModel.getTimeZone().identifier) ?? TimeZone.current
    }

    func arrangementViewClosed(_ groupFreeBusyView: GroupFreeBusyView) {
        dismiss(animated: true, completion: nil)
    }

    func timeChanged(_ groupFreeBusyView: GroupFreeBusyView, startTime: Date, endTime: Date) {
        viewModel.groupFreeBusyModel.changeTimeRange(startTime: startTime, endTime: endTime)
        groupFreeBusyView.updateHeaderFooter(model: viewModel.groupFreeBusyModel)
    }

    func dateChanged(_ groupFreeBusyView: GroupFreeBusyView, date: Date) {
        groupFreeBusyView.hideInterval()
        viewModel.groupFreeBusyModel.changeTimeRange(by: date)
        groupFreeBusyView.updateHeaderFooter(model: viewModel.groupFreeBusyModel)
        viewModel.loadInstanceData()
        groupFreeBusyView.setTimeZoneStr(timeZoneStr: viewModel.groupFreeBusyModel.getTzDisplayName())
        CalendarTracerV2.CalendarChat.traceClick {
            $0.click("day_change").target("none")
            $0.chat_id = viewModel.chatId
        }
    }

    func moveAttendeeToFirst(_ groupFreeBusyView: GroupFreeBusyView, indexPath: IndexPath) {
        viewModel.moveAttendeeFirst(indexPath: indexPath)
    }

    func retry(_ groupFreeBusyView: GroupFreeBusyView) {
        viewModel.loadChatFreeBusyChattersAndAttendee()
    }

    func chooseButtonClicked() {
        calendarDependency?.jumpToFreeBusyChatterController(from: self,
                                                            chatId: viewModel.chatId,
                                                            selectedChatters: viewModel.selectedChatters) { [weak self] chatters in
            CalendarTracer.shareInstance.groupFreeBusyChooseMemberCount(memberCount: chatters.count)
            guard let self = self else { return }
            if self.viewModel.createEventBody != nil {
                self.viewModel.selectedChatters = chatters
                self.viewModel.orderedChatters = (self.viewModel.orderedChatters.filter { chatters.contains($0) } + chatters).lf_unique()
                self.viewModel.loadAttendeeData(userIds: chatters)
                
            } else {
                self.viewModel.sortFreeBusyChatters(chatters: chatters)
            }
            if self.viewModel.selectedChatters.count != chatters.count {
                CalendarTracerV2.CalendarChat.traceClick {
                    $0.click("change_member").target("none")
                    $0.chat_id = self.viewModel.chatId
                }
            }
        }
    }

    func timeZoneClicked() {
        goSelectTimeZoneVC()
    }
}

extension GroupFreeBusyController {

    func goSelectTimeZoneVC() {
        let previousTimeZone = viewModel.groupFreeBusyModel.getTimeZone()
        let selectTz = BehaviorRelay(value: previousTimeZone)
        guard let timeZoneService = viewModel.timeZoneService else { return }
        let model = viewModel.groupFreeBusyModel
        let popupVC = getPopupTimeZoneSelectViewController(
            with: timeZoneService,
            selectedTimeZone: selectTz,
            anchorDate: model.startTime,
            onTimeZoneSelect: { [weak self] timeZone in
                guard let self = self else { return }
                if previousTimeZone.identifier != timeZone.identifier {
                    self.viewModel.groupFreeBusyModel.updateTzInfo(chatId: self.viewModel.chatId, timeZone: timeZone)
                    self.groupFreeBusyView.setTimeZoneStr(timeZoneStr: self.viewModel.groupFreeBusyModel.getTzDisplayName())
                    self.groupFreeBusyView.updateCurrentUiDate(
                        uiDate: self.viewModel.groupFreeBusyModel.getUiCurrentDate(),
                        with: TimeZone(identifier: timeZone.identifier) ?? .current
                    )
                    self.viewModel.loadInstanceData()
                }
            }
        )
        self.present(popupVC, animated: true, completion: nil)

        CalendarTracer.shareInstance.calClickTimeZoneEntry(from: .chat)
    }

}

extension GroupFreeBusyController: GroupFreeBusyViewModelDelegate {
    func hideLoading(shouldRetry: Bool, failed: Bool) {
        groupFreeBusyView.hideLoading(shouldRetry: shouldRetry, failed: failed)
    }
    
    func showLoading(shouldRetry: Bool) {
        groupFreeBusyView.showLoading(shouldRetry: shouldRetry)
    }

    
    func updateHeaderFooter() {
        groupFreeBusyView.setHeaderViewInfo(model: viewModel.groupFreeBusyModel.headerViewModel)
        groupFreeBusyView.updateHeaderFooter(model: viewModel.groupFreeBusyModel)
    }
    
    func checkScrollToCurrentTime() {
        guard needScrollToCurrentTime else { return }
        defer { needScrollToCurrentTime = false }
        if let createEventBody = viewModel.createEventBody {
            groupFreeBusyView.scrollToTime(time: viewModel.groupFreeBusyModel.calibrationDateForUI(date: createEventBody.startDate), animated: false)
            DispatchQueue.main.async {
                self.groupFreeBusyView.showInterval()
            }
        } else {
            groupFreeBusyView.scrollToTime(time: viewModel.groupFreeBusyModel.getUiCurrentDate(), animated: false)
        }
    }

    func getBoundsWidth() -> CGFloat {
        return viewBoundsWidth
    }
    
    func reloadViewWithInstanceData() {
        self.groupFreeBusyView.reloadServerData(model: self.viewModel.groupFreeBusyModel)
        self.viewWillLayoutSubviews()
    }
    
    func showGuide() {
        if self.viewIfLoaded?.window != nil,
           CalConfig.isMultiTimeZone,
           self.viewModel.groupFreeBusyModel.headerViewModel.shouldShowTimeString,
           let headerCell = self.groupFreeBusyView.headerFirstCell(),
           let newGuideManager = self.newGuideManager {
            GuideService.checkShowTzInfoGuide(controller: self, newGuideManager: newGuideManager, referView: headerCell)
        }
    }
    
    func cleanInstance(calendarIds: [String], startTime: Date, endTime: Date) {
        groupFreeBusyView.cleanInstance(calendarIds: calendarIds, startTime: startTime, endTime: endTime)
    }
}
