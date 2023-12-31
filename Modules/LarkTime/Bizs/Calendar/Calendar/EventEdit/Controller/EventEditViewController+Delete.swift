//
//  EventEditViewController+Delete.swift
//  Calendar
//
//  Created by 张威 on 2020/4/8.
//

import UIKit
import RxSwift
import RxCocoa
import RoundedHUD
import CalendarFoundation

/// TODO: by zhangwei 04.16
/// 日程删除逻辑，基本上 copy 自 EventEditable

extension EventEditViewController: EventDeleteAble {

    var event: Rust.Event {
        guard let (event, _) = viewModel.getEntitiesForDeleting() else {
            assertionFailure()
            return Rust.Event()
        }
        return event.getPBModel()
    }

    var controller: UIViewController { navigationController ?? self }

    var calendarApi: CalendarRustAPI? { return viewModel.calendarApi }
}

extension EventEditViewController {

    func handleDelete() {
        guard let deleteModel = viewModel.getModelForDeleting() else {
            assertionFailure()
            return
        }
        guard let (event, instance) = viewModel.getEntitiesForDeleting() else {
            assertionFailure()
            return
        }

        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("delete_event")
            $0.target("cal_event_delete_confirm_view")
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: instance.toPB(), event: event.getPBModel()))
        }

        operationLog(optType: CalendarOperationType.del.rawValue)
        handleDeleteEvent(
            deleteModel: deleteModel,
            deleteEvent: { [weak self](span, notiType, isUpgradeToChatinAlert, isUpgradeToChatBeforeAlert) in
                self?.removeEvent(
                    instance: instance,
                    event: event,
                    span: span,
                    isUpgradeToChatinAlert: isUpgradeToChatinAlert,
                    isUpgradeToChatBeforeAlert: isUpgradeToChatBeforeAlert,
                    canDeleteAll: event.canDeleteAll(),
                    notificationType: notiType
                )
            },
            isFromDetail: false
        )
    }

    private func removeEvent(
        instance: CalendarEventInstanceEntity,
        event: CalendarEventEntity,
        span: CalendarEvent.Span,
        isUpgradeToChatinAlert: Bool? = nil,
        isUpgradeToChatBeforeAlert: Bool? = nil,
        canDeleteAll: Bool,
        notificationType: NotificationType
    ) {
        if canDeleteAll {// 创建者删除
            var event = event
            event.notificationType = notificationType
            let dissolveMeeting = !(isUpgradeToChatBeforeAlert ?? (isUpgradeToChatinAlert ?? true))
            self.deleteEvent(
                span: span,
                event: event,
                instance: instance,
                dissolveMeeting: dissolveMeeting
            )
        } else {
            self.deleteInvitedEvent(
                span: span,
                event: event,
                instance: instance
            )
        }
    }

    private func deleteEvent(
        span: CalendarEvent.Span,
        event: CalendarEventEntity,
        instance: CalendarEventInstanceEntity,
        dissolveMeeting: Bool
    ) {
        if !dissolveMeeting {
            CalendarTracer.shareInstance.calTransformWhenRemoveEvent()
        }
        viewModel.calendarApi?.removeEvent(
            event,
            instance: instance,
            span: span,
            scenarioToken: .deleteEventOnEventEditView,
            dissolveMeeting: dissolveMeeting
        )
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    self?.removeEventSuccess(event)
                },
                onError: { [weak self] error in
                    if let self = self {
                        RoundedHUD.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Common_DeleteFailedTip, on: self.view)
                    }
                }
            )
            .disposed(by: self.disposeBag)
    }

    private func deleteInvitedEvent(
        span: CalendarEvent.Span,
        event: CalendarEventEntity,
        instance: CalendarEventInstanceEntity
    ) {
        self.responseToEvent(
            withstatus: .removed,
            span: span,
            event: event,
            instance: instance,
            calendarApi: viewModel.calendarApi,
            messageId: nil
        )
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] (isRemoved, _, errorCodes) in
                    guard let self = self else { return }
                    if isRemoved {
                        self.removeEventSuccess(event)
                    } else {
                        RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_Common_DeleteFailedTip, on: self.view)
                    }
                    if errorCodes.contains(where: { ErrorType(rawValue: $0) == .invalidCipherFailedToSendMessage }) {
                        RoundedHUD.showFailure(with: I18n.Calendar_KeyNoToast_CannoReply_Pop, on: self.view)
                    }
                },
                onError: { [weak self] error in
                    if let self = self {
                        RoundedHUD.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Common_DeleteFailedTip, on: self.view)
                    }
                }
            )
            .disposed(by: self.disposeBag)
    }

    private func removeEventSuccess(_ event: CalendarEventEntity) {
        if event.isLocalEvent() {
            guard let ekEvent = event.getEKEvent() else {
                assertionFailure()
                return
            }
            delegate?.didFinishDeleteLocalEvent(ekEvent, from: self)
        } else {
            delegate?.didFinishDeleteEvent(event.getPBModel(), from: self)
        }
    }

    func clearNoUseZoomMeetingIfNeeded(_ isCancel: Bool) {
        let videoMeeting = viewModel.getVideoMeeting()
        // 未新创建过zoom会议
        guard let config = self.viewModel.localZoomConfigs else { return }

        if isCancel {
            // 取消场景
            switch editType {
            case .new:
                viewModel.deleteZoomMeeting(meetingID: config.meetingID)
            case .edit:
                // 编辑  原来是zoom不操作 原来不是zoom 删
                guard let originalConfig = self.viewModel.eventModelBeforeEditing?.videoMeeting.zoomConfigs else {
                    if event.rrule.isEmpty {
                        // 重复性例外不删
                        if event.originalTime != 0 { return }
                        viewModel.deleteZoomMeeting(meetingID: config.meetingID)
                        return
                    }
                    return
                }
            }
        } else {
            // 保存场景 最终未选择zoom
            if videoMeeting?.videoMeetingType != .zoomVideoMeeting {
                // 新建的日程 删 || 编辑的日程 非重复性 删
                switch editType {
                case .new:
                    viewModel.deleteZoomMeeting(meetingID: config.meetingID)
                case .edit:
                    if event.rrule.isEmpty {
                        // 重复性例外不删
                        if event.originalTime != 0 { return }
                        viewModel.deleteZoomMeeting(meetingID: config.meetingID)
                        return
                    }
                }
            }
        }
    }
}
