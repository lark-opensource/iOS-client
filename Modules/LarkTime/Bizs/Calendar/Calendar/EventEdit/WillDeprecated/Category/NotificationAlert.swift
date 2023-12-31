//
//  NotificationAlert.swift
//  Calendar
//
//  Created by zhouyuan on 2019/1/18.
//  Copyright © 2019 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import RustPB

enum NotificationOption {
    case cancel
    case notificationType(NotificationType)
}

struct NotificationBoxParam {
    /// 通知不通知弹窗类型
    let notificationInfos: (timeChanged: Bool, type: NotificationBoxType)
    let meetingRule: CalendarRustAPI.MeetingEventSpecialRule
    let mailRule: CalendarRustAPI.MailAttendeeSpecialRule
    let chatRule: CalendarRustAPI.MeetingChatSpecialRule
    let canCreateRSVPCard: Bool
    let inviteRSVPChat: Basic_V1_Chat?
}

typealias NotificationBoxTypeGetter = (
    _ operationType: EventOperationType,
    _ span: CalendarEvent.Span,
    _ event: Rust.Event,
    _ originalEvent: Rust.Event?,
    _ instanceStartTime: Int64?,
    _ newSimpleAttendees: Rust.EventSimpleAttendee?,
    _ originalSimepleAttendees: Rust.EventSimpleAttendee?,
    _ groupSimpleAttendees: [String: [Rust.IndividualSimpleAttendee]]?,
    _ shareToChatId: String?,
    _ attendeeTotalNum: Int32?
) -> Observable<NotificationBoxParam>

final class NotificationAlert {

    /// 删除普通日程
    class func showDeleteNotification(controller: UIViewController?,
                                      event: Rust.Event,
                                      span: CalendarEvent.Span,
                                      instanceStartTime: Int64,
                                      isFromDetail: Bool,
                                      notificationBoxTypeGetter: NotificationBoxTypeGetter?,
                                      showDeleteMeetingMinuteWarning: Bool = false,
                                      handle: @escaping (Bool?, NotificationOption) -> Void) {
        var disposbag = DisposeBag()
        notificationBoxTypeGetter?(.opDeleteEvent, span, event, nil, instanceStartTime, event.attendees.toEventSimpleAttendee(), nil, nil, nil, 0)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (notificationBoxParam) in
                var disposbagForHint = DisposeBag()
                let signal = PublishSubject<NotificationBoxParam>()
                signal.observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (param) in
                        var mailSubTitle: String?
                        if param.mailRule == .addMailAttendeesDefaultReceiveNotificationSubtitile {
                            mailSubTitle = I18n.Calendar_CalMail_InvitePopUpWindowSubtitle
                        }
                        switch param.notificationInfos.type {
                        case .deleteWithOtherAttendees:
                            var subtitle: String?
                            if showDeleteMeetingMinuteWarning {
                                subtitle = BundleI18n.Calendar.Calendar_MeetingMinutes_PopUpWindow
                            }
                            let cancelTitle = isFromDetail ? BundleI18n.Calendar.Calendar_MobileDeleteEventPopupUp_KeepEventButton : BundleI18n.Calendar.Calendar_Detail_BackToEdit
                            showNotificationOptionAlert(
                                title: BundleI18n.Calendar.Calendar_Event_DeleteEventDesc,
                                subTitle: subtitle,
                                subTitleMailText: mailSubTitle,
                                actionButtons: actionButtons(cancelTitle: cancelTitle, handle: handle),
                                controller: controller
                            )
                            CalendarTracerV2.EventDeleteNotification.traceView {
                                $0.mergeEventCommonParams(commonParam: CommonParamData(event: event, startTime: instanceStartTime))
                            }
                        case .deleteMeeting:
                            let cancelTitle = isFromDetail ? BundleI18n.Calendar.Calendar_MobileDeleteEventPopupUp_KeepEventButton : BundleI18n.Calendar.Calendar_Detail_BackToEdit
                            showNotificationOptionAlert(
                                title: BundleI18n.Calendar.Calendar_Event_DeleteEventDesc,
                                subTitle: nil,
                                showSubtitleCheckButton: false,
                                subTitleMailText: mailSubTitle,
                                actionButtons: actionButtons(cancelTitle: cancelTitle, handle: handle),
                                controller: controller
                            )
                            CalendarTracerV2.EventDeleteNotification.traceView {
                                $0.mergeEventCommonParams(commonParam: CommonParamData(event: event, startTime: instanceStartTime))
                            }
                        @unknown default:
                            handle(false, .notificationType(.defaultNotificationType))
                        }
                        disposbagForHint = DisposeBag()
                    }, onError: { _ in
                        handle(false, .notificationType(.defaultNotificationType))
                    }).disposed(by: disposbagForHint)
                signal.onNext(notificationBoxParam)
                disposbag = DisposeBag()
            }, onError: { _ in
                handle(false, .notificationType(.defaultNotificationType))
            }).disposed(by: disposbag)
    }

    private class func actionButtons(
        cancelTitle: String = BundleI18n.Calendar.Calendar_Detail_BackToEdit,
        handle: @escaping (Bool?, NotificationOption) -> Void
        ) -> [ActionButton] {

        let actionButton1 = ActionButton(
            title: BundleI18n.Calendar.Calendar_Detail_Send,
            titleColor: UIColor.ud.primaryContentDefault
        ) { isChecked, disappear in
            disappear {
                handle(isChecked, .notificationType(.sendNotification))
            }
        }
        let actionButton2 = ActionButton(
            title: BundleI18n.Calendar.Calendar_Detail_DontSend
        ) { isChecked, disappear in
            disappear {
                handle(isChecked, .notificationType(.noNotification))
            }
        }
        let actionButton3 = ActionButton(title: cancelTitle) { isChecked, disappear in
            disappear {
                handle(isChecked, .cancel)
            }
        }
        return [actionButton1, actionButton2, actionButton3]
    }

    private class func showNotificationOptionAlert(title: String,
                                                   subTitle: String? = nil,
                                                   showSubtitleCheckButton: Bool = false,
                                                   subTitleMailText: String? = nil,
                                                   actionButtons: [ActionButton],
                                                   controller: UIViewController?) {
        let confirmVC = NotificationOptionViewController()
        confirmVC.setTitles(titleText: title, subTitleText: subTitle, showSubtitleCheckButton: showSubtitleCheckButton, subTitleMailText: subTitleMailText)
        actionButtons.forEach { (actionButton) in
            confirmVC.addAction(actionButton: actionButton)
        }
        confirmVC.show(controller: controller)
    }
}
