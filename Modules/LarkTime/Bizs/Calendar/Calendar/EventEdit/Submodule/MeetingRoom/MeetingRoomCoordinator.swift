//
//  EventMeetingRoomCoordinator.swift
//  Calendar
//
//  Created by 张威 on 2020/4/11.
//

import UIKit
import Foundation
import EventKit
import RxSwift
import RxCocoa
import LarkUIKit
import LarkContainer

/// 选择会议室

protocol EventMeetingRoomCoordinatorDelegate: AnyObject {

    /// 选中了某些会议室
    func coordinator(
        _ coordinator: EventMeetingRoomCoordinator,
        didSelectMeetingRooms meetingRooms: [CalendarMeetingRoom]
    )

    // 取消会议室可能需要的确认弹窗
    func coordinator(
        _ coordinator: EventMeetingRoomCoordinator,
        confirmAlertTextsForDeselectingMeetingRoom meetingRoom: CalendarMeetingRoom
    ) -> EventEditConfirmAlertTexts?

    /// 取消某个会议室
    func coordinator(
        _ coordinator: EventMeetingRoomCoordinator,
        didDeselectMeetingRoom meetingRoom: CalendarMeetingRoom
    )

    /// 完成
    func coordinatorDidFinish(_ coordinator: EventMeetingRoomCoordinator)

    // 一键调整被点击
    func autoJustTimeTapped(needRenewalReminder: Bool, rrule: EventRecurrenceRule?)
}

final class EventMeetingRoomCoordinator: UserResolverWrapper {
    struct Dependency {
        var eventModel: EventEditModel
        var selectedMeetingRooms: [CalendarMeetingRoom] = []
        var startDate: Date
        var endDate: Date
        var timeZoneId: String
        var rrule: EKRecurrenceRule?
        var eventConditions: (approveDisabled: Bool, formDisabled: Bool)
        var meetingRoomWithFormUnAvailableReason: String
        var meetingRoomApi: CalendarRustAPI?
        var tenantId: String
        var endDateEditable: Bool
    }

    let userResolver: UserResolver
    
    weak var delegate: EventMeetingRoomCoordinatorDelegate?
    var editType: EventEditViewController.EditType = .new
    private let navigationController: UINavigationController
    private let dependency: Dependency
    weak private var sourceViewController: UIViewController?
    private let rxHideUnavailable = BehaviorRelay(value: true)
    private var bag = DisposeBag()
    init(userResolver: UserResolver, navigationController: UINavigationController, dependency: Dependency) {
        self.userResolver = userResolver
        self.navigationController = navigationController
        self.dependency = dependency
    }

    func start() {
        sourceViewController = navigationController.topViewController
        let shellVC = LoadingShellViewController { [weak self] multiLevel, multiSelect in
            guard let self = self else { return UIViewController() }
            let viewModel = MeetingRoomContainerViewModel(userResolver: self.userResolver,
                                                          tenantID: self.dependency.tenantId,
                                                          rrule: self.dependency.rrule,
                                                          eventConditions: self.dependency.eventConditions,
                                                          meetingRoomWithFormUnAvailableReason: self.dependency.meetingRoomWithFormUnAvailableReason,
                                                          startDate: self.dependency.startDate,
                                                          endDate: self.dependency.endDate,
                                                          timezone: TimeZone(identifier: self.dependency.timeZoneId),
                                                          multiLevelResources: multiLevel,
                                                          enableMultiSelectMeetingRoom: multiSelect,
                                                          actionSource: .fullEventEditor,
                                                          endDateEditable: self.dependency.endDateEditable)
            viewModel.eventParam = CommonParamData(
                event: self.dependency.eventModel.getPBModel(),
                startTime: Int64(self.dependency.eventModel.startDate.timeIntervalSince1970)
            )

            let toVC = MeetingRoomContainerViewController(userResolver: self.userResolver,
                                                          viewModel: viewModel,
                                                          selectedMeetingRooms: self.dependency.selectedMeetingRooms,
                                                          meetingRoomApi: self.dependency.meetingRoomApi)
            toVC.editType = self.editType
            toVC.actionSource = .fullEventEditor
            toVC.delegate = self
            return toVC
        }
        let navigation = LkNavigationController(rootViewController: shellVC)
        navigation.modalPresentationStyle = .formSheet
        navigationController.present(navigation, animated: true, completion: nil)
    }

    private func exit(from viewController: UIViewController) {
        if Display.pad {
            viewController.navigationController?.dismiss(animated: true, completion: nil)
            delegate?.coordinatorDidFinish(self)
            return
        }
        if navigationController.presentingViewController != nil {
            navigationController.dismiss(animated: true, completion: nil)
            delegate?.coordinatorDidFinish(self)
            return
        }

        if let sourceVC = sourceViewController, navigationController.viewControllers.contains(sourceVC) {
            navigationController.popToViewController(sourceVC, animated: true)
            delegate?.coordinatorDidFinish(self)
            return
        }
        assertionFailure()
    }

    private func jumpToMeetingRoomDetail(with calendarID: String, from: UIViewController) {
        CalendarTracer.shared.calClickMeetingRoomInfo(from: .fullEventEditor, with: .new)
        var context = DetailWithStatusContext()
        context.calendarID = calendarID
        context.startTime = dependency.startDate
        context.endTime = dependency.endDate
        context.rrule = dependency.rrule?.iCalendarString() ?? ""
        context.timeZone = dependency.timeZoneId
        let input: MeetingRoomDetailInput = .detailWithStatus(context)
        let viewModel = MeetingRoomDetailViewModel(input: input, userResolver: self.userResolver)
        let toVC = MeetingRoomDetailViewController(viewModel: viewModel, userResolver: self.userResolver)
        from.navigationController?.pushViewController(toVC, animated: true)
    }
}

// MARK: MeetingRoomContainerViewControllerDelegate
extension EventMeetingRoomCoordinator: MeetingRoomContainerViewControllerDelegate {
    func autoJustTimeTapped(needRenewalReminder: Bool, rrule: EventRecurrenceRule?) {
        self.delegate?.autoJustTimeTapped(needRenewalReminder: needRenewalReminder, rrule: rrule)
    }
    
    func didCancelEditMeetingRoom(from viewController: MeetingRoomContainerViewController) {
        exit(from: viewController)
    }

    func didSelectMeetingRooms(_ meetingRooms: [CalendarMeetingRoom], from viewController: UIViewController) {
        // 多选情况不跳转填写表单
        if meetingRooms.count == 1,
           let meetingRoom = meetingRooms.first,
           let resourceCustomization = meetingRoom.resourceCustomization {
            let formViewController = MeetingRoomFormViewController(resourceCustomization: resourceCustomization, userResolver: self.userResolver)
            formViewController.cancelSignal
                .subscribe(onNext: { [weak formViewController] in
                    formViewController?.navigationController?.popViewController(animated: true)
                    CalendarTracer.shared.formComplete(action: .cancel, nextPage: .chooseMeetingRoom)
                })
                .disposed(by: bag)
            formViewController.confirmSignal
                .subscribe(onNext: { [weak viewController, weak self] custom in
                    guard let self = self, let viewController = viewController else { return }
                    var meetingRoom = meetingRoom
                    meetingRoom.resourceCustomization = custom
                    CalendarTracer.shared.formComplete(action: .confirm, nextPage: .eventDetail)
                    self.delegate?.coordinator(self, didSelectMeetingRooms: [meetingRoom])
                    self.exit(from: viewController)
                })
                .disposed(by: bag)
            CalendarTracer.shared.enterFormViewController(source: .chooseMeetingRoom)
            viewController.show(formViewController, sender: self)
        } else {
            delegate?.coordinator(self, didSelectMeetingRooms: meetingRooms)
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click("add_resource_result")
                $0.is_new_create = editType == .new ? "true" : "false"
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: dependency.eventModel.getPBModel(), startTime: Int64(dependency.eventModel.startDate.timeIntervalSince1970 ?? 0) ))
            }
            exit(from: viewController)
        }
    }

    func didSelectMeetingRoomDetail(_ resourceID: String, from viewController: UIViewController) {
        jumpToMeetingRoomDetail(with: resourceID, from: viewController)
    }
}
