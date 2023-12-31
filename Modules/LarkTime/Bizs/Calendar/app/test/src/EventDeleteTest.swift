////
////  EventDeleteTest.swift
////  CalendarDemo
////
////  Created by heng zhu on 2019/4/7.
////
//
//import XCTest
//@testable import Calendar
//import RustPB
//import RxSwift
//
//struct EventDeleteAPIMock: EventDeleteAPI {
//    func judgeNotificationBoxType(operationType: EventOperationType, span: CalendarEvent.Span, event: CalendarEventEntity, originalEvent: CalendarEventEntity?, instanceStartTime: Int64?) -> Observable<NotificationBoxParam> {
//        return PublishSubject<(NotificationBoxParam)>()
//    }
//
//    func judgeNotificationBoxType(operationType: EventOperationType,
//                                  span: CalendarEvent.Span,
//                                  event: CalendarEventEntity,
//                                  originalEvent: CalendarEventEntity?,
//                                  instanceStartTime: Int64?) -> Observable<(NotificationBoxType, MeetingEventSpecialRule, MailAttendeeSpecialRule)> {
//        return PublishSubject<(NotificationBoxType, MeetingEventSpecialRule, MailAttendeeSpecialRule)>()
//    }
//
//    func isAttendeeInOtherRelatedEvents(calendarId: String,
//                                        key: String) -> Observable<Bool> {
//        return PublishSubject<Bool>()
//    }
//    func judgeNotificationBoxType(
//        operationType: EventOperationType,
//        span: CalendarEvent.Span,
//        event: CalendarEventEntity,
//        originalEvent: CalendarEventEntity?,
//        instanceStartTime: Int64?) -> Observable<(NotificationBoxType, MeetingEventSpecialRule)> {
//        return PublishSubject<(NotificationBoxType, MeetingEventSpecialRule)>()
//    }
//}
//
//struct EventDeleteDataMock: EventDeleteProtocol {
//    var isCrossTenant: Bool
//    var hasMeetingMinuteUrl: Bool
//    var isInvitedAttendee: Bool
//    var isRecurrence: Bool
//    var isEditable: Bool
//    var isLocalEvent: Bool
//    var canDeleteAll: Bool
//    var isMeeting: Bool
//    var isException: Bool
//    var calendarId: String
//    var notificationType: NotificationType
//    var key: String
//    var startTime: Int64
//}
//
//class EventDeleteTest: XCTestCase, EventDeleteAble {
//    var checker: ExternalAccountChecker
//
//    var eventDeleteAPI: EventDeleteAPI = EventDeleteAPIMock()
//    var disposeBag: DisposeBag = DisposeBag()
//
//    func getEvent() -> CalendarEventEntity {
//        var calendarEventPB = CalendarEvent()
//        calendarEventPB.id = "213"
//        return PBCalendarEventEntity(pb: calendarEventPB)
//    }
//
//    func getController() -> UIViewController {
//        return UIViewController()
//    }
//
//    //删除普通日程
//    func testDeleteNomarl() {
//        var deleteModel = EventDeleteDataMock(isCrossTenant: false,
//                                              hasMeetingMinuteUrl: false,
//                                              isInvitedAttendee: false,
//                                              isRecurrence: false,
//                                              isEditable: true,
//                                              isLocalEvent: false,
//                                              canDeleteAll: true,
//                                              isMeeting: true,
//                                              isException: false,
//                                              calendarId: "sdfsd",
//                                              notificationType: .defaultNotificationType,
//                                              key: "111",
//                                              startTime: 123)
//        //case 1
//        //有完整编辑权限的，会触发通知不通知逻辑
//        //会议弹窗 Calendar_Meeting_DeleteEventAndDismissGroupAlert
//        handleDeleteEvent(
//            deleteModel: deleteModel,
//            deleteEvent: { (span, notification) in
//                XCTAssertEqual(span, .noneSpan)
//                XCTAssertEqual(notification, .defaultNotificationType)
//            },
//            isFromDetail: true,
//            showDeleteNotification: { (_, _, _, _, _, _, handle: @escaping (Bool, NotificationOption) -> Void) in
//                handle(true, NotificationOption.notificationType(.defaultNotificationType))
//            },
//            showDeleteExceptionSheet: { (_, _, _, _, _, _, _, update: @escaping (Span) -> Void) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteRecurrenceSheet: { (_, _, _, _, update: @escaping ((Span) -> Void)) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteAlert: { (title, message, _, confirmAction: (() -> Void)?, _) in
//                XCTAssertEqual(title, BundleI18n.Calendar.Calendar_Meeting_DeleteEventConfirm)
//                XCTAssertEqual(message, BundleI18n.Calendar.Calendar_Meeting_DeleteEventAndDismissGroupAlert)
//                confirmAction?()
//            })
//
//        //case 2
//        //有完整编辑权限的，会触发通知不通知逻辑
//        //非会议弹窗 Calendar_Meeting_DeleteEventConfirm
//        deleteModel.isMeeting = false
//        deleteModel.canDeleteAll = true
//        handleDeleteEvent(
//            deleteModel: deleteModel,
//            deleteEvent: { (span, notification) in
//                XCTAssertEqual(span, .noneSpan)
//                XCTAssertEqual(notification, .defaultNotificationType)
//            },
//            isFromDetail: true,
//            showDeleteNotification: { (_, _, _, _, _, _, handle: @escaping (Bool, NotificationOption) -> Void) in
//                handle(true, NotificationOption.notificationType(.defaultNotificationType))
//            },
//            showDeleteExceptionSheet: { (_, _, _, _, _, _, _, update: @escaping (Span) -> Void) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteRecurrenceSheet: { (_, _, _, _, update: @escaping ((Span) -> Void)) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteAlert: { (title, message, _, confirmAction: (() -> Void)?, _) in
//                XCTAssertEqual(title, BundleI18n.Calendar.Calendar_Meeting_DeleteEventConfirm)
//                XCTAssertEqual(message, "")
//                confirmAction?()
//            })
//
//        //case 3
//        //没有完整编辑权限的，不会触发通知不通知
//        //会议弹窗 BundleI18n.Calendar.Calendar_Alert_DeleteAndLeaveGroupAlert
//        deleteModel.canDeleteAll = false
//        deleteModel.isMeeting = true
//        handleDeleteEvent(
//            deleteModel: deleteModel,
//            deleteEvent: { (span, notification) in
//                XCTAssertEqual(span, .noneSpan)
//                XCTAssertEqual(notification, .defaultNotificationType)
//            },
//            isFromDetail: true,
//            showDeleteNotification: { (_, _, _, _, _, _, handle: @escaping (Bool, NotificationOption) -> Void) in
//                XCTAssertTrue(false)
//                handle(true, NotificationOption.notificationType(.defaultNotificationType))
//            },
//            showDeleteExceptionSheet: { (_, _, _, _, _, _, _, update: @escaping (Span) -> Void) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteRecurrenceSheet: { (_, _, _, _, update: @escaping ((Span) -> Void)) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteAlert: { (title, message, _, confirmAction: (() -> Void)?, _) in
//                XCTAssertEqual(title, BundleI18n.Calendar.Calendar_Alert_DeleteAndLeaveGroupAlert)
//                XCTAssertEqual(message, "")
//                confirmAction?()
//            })
//        //case 4
//        //没有完整编辑权限的，不会触发通知不通知
//        //非会议弹窗 BundleI18n.Calendar.Calendar_Meeting_DeleteEventConfirm
//        deleteModel.canDeleteAll = false
//        deleteModel.isMeeting = false
//        handleDeleteEvent(
//            deleteModel: deleteModel,
//            deleteEvent: { (span, notification) in
//                XCTAssertEqual(span, .noneSpan)
//                XCTAssertEqual(notification, .defaultNotificationType)
//            },
//            isFromDetail: true,
//            showDeleteNotification: { (_, _, _, _, _, _, handle: @escaping (Bool, NotificationOption) -> Void) in
//                XCTAssertTrue(false)
//                handle(true, NotificationOption.notificationType(.defaultNotificationType))
//            },
//            showDeleteExceptionSheet: { (_, _, _, _, _, _, _, update: @escaping (Span) -> Void) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteRecurrenceSheet: { (_, _, _, _, update: @escaping ((Span) -> Void)) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteAlert: { (title, message, _, confirmAction: (() -> Void)?, _) in
//                XCTAssertEqual(title, BundleI18n.Calendar.Calendar_Meeting_DeleteEventConfirm)
//                XCTAssertEqual(message, "")
//                confirmAction?()
//            })
//    }
//
//    //删除重复性日程
//    func testDeleteRepeat() {
//
//        //case 1
//        //有完整编辑权限的，会触发通知不通知
//        //会议 & span == .allEvents,  弹窗 Calendar_Meeting_DeleteEventConfirm Calendar_Meeting_DeleteEventAndDismissGroupAlert
//        var deleteModel = EventDeleteDataMock(isCrossTenant: false,
//                                              hasMeetingMinuteUrl: false,
//                                              isInvitedAttendee: false,
//                                              isRecurrence: true,
//                                              isEditable: true,
//                                              isLocalEvent: false,
//                                              canDeleteAll: true,
//                                              isMeeting: true,
//                                              isException: false,
//                                              calendarId: "sdfsd",
//                                              notificationType: .defaultNotificationType,
//                                              key: "111",
//                                              startTime: 123)
//        handleDeleteEvent(
//            deleteModel: deleteModel,
//            deleteEvent: { (span, notification) in
//                XCTAssertEqual(span, .allEvents)
//                XCTAssertEqual(notification, .defaultNotificationType)
//            },
//            isFromDetail: true,
//            showDeleteNotification: { (_, _, _, _, _, _, handle: @escaping (Bool, NotificationOption) -> Void) in
//                handle(true, NotificationOption.notificationType(.defaultNotificationType))
//            },
//            showDeleteExceptionSheet: { (_, _, _, _, _, _, _, update: @escaping (Span) -> Void) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteRecurrenceSheet: { (_, _, _, _, update: @escaping ((Span) -> Void)) in
//                update(.allEvents)
//            },
//            showDeleteAlert: { (title, message, _, confirmAction: (() -> Void)?, _) in
//                XCTAssertEqual(title, BundleI18n.Calendar.Calendar_Meeting_DeleteEventConfirm)
//                XCTAssertEqual(message, BundleI18n.Calendar.Calendar_Meeting_DeleteEventAndDismissGroupAlert)
//                confirmAction?()
//            })
//
//        //case 2
//        //有完整编辑权限的，会触发通知不通知
//        //非会议 弹窗 Calendar_Meeting_DeleteEventConfirm
//        deleteModel.canDeleteAll = true
//        deleteModel.isMeeting = false
//
//        handleDeleteEvent(
//            deleteModel: deleteModel,
//            deleteEvent: { (span, notification) in
//                XCTAssertEqual(span, .thisEvent)
//                XCTAssertEqual(notification, .defaultNotificationType)
//            },
//            isFromDetail: true,
//            showDeleteNotification: { (_, _, _, _, _, _, handle: @escaping (Bool, NotificationOption) -> Void) in
//                handle(true, NotificationOption.notificationType(.defaultNotificationType))
//            },
//            showDeleteExceptionSheet: { (_, _, _, _, _, _, _, update: @escaping (Span) -> Void) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteRecurrenceSheet: { (_, _, _, _, update: @escaping ((Span) -> Void)) in
//                update(.thisEvent)
//            },
//            showDeleteAlert: { (title, message, _, confirmAction: (() -> Void)?, _) in
//                XCTAssertEqual(title, BundleI18n.Calendar.Calendar_Meeting_DeleteEventConfirm)
//                XCTAssertEqual(message, "")
//                confirmAction?()
//            })
//
//        //case 3
//        //没有完整编辑权限的，不会触发通知不通知
//        //会议 & span == .allEvents 弹窗 Calendar_Alert_DeleteAndLeaveGroupAlert
//        deleteModel.canDeleteAll = false
//        deleteModel.isMeeting = true
//
//        handleDeleteEvent(
//            deleteModel: deleteModel,
//            deleteEvent: { (span, notification) in
//                XCTAssertEqual(span, .allEvents)
//                XCTAssertEqual(notification, .defaultNotificationType)
//            },
//            isFromDetail: true,
//            showDeleteNotification: { (_, _, _, _, _, _, handle: @escaping (Bool, NotificationOption) -> Void) in
//                handle(true, NotificationOption.notificationType(.defaultNotificationType))
//            },
//            showDeleteExceptionSheet: { (_, _, _, _, _, _, _, update: @escaping (Span) -> Void) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteRecurrenceSheet: { (_, _, _, _, update: @escaping ((Span) -> Void)) in
//                update(.allEvents)
//            },
//            showDeleteAlert: { (title, message, _, confirmAction: (() -> Void)?, _) in
//                XCTAssertEqual(title, BundleI18n.Calendar.Calendar_Alert_DeleteAndLeaveGroupAlert)
//                XCTAssertEqual(message, "")
//                confirmAction?()
//            })
//
//        //case 4
//        //没有完整编辑权限的，不会触发通知不通知
//        //非会议 弹窗 Calendar_Meeting_DeleteEventConfirm
//        deleteModel.canDeleteAll = false
//        deleteModel.isMeeting = false
//
//        handleDeleteEvent(
//            deleteModel: deleteModel,
//            deleteEvent: { (span, notification) in
//                XCTAssertEqual(span, .allEvents)
//                XCTAssertEqual(notification, .defaultNotificationType)
//            },
//            isFromDetail: true,
//            showDeleteNotification: { (_, _, _, _, _, _, handle: @escaping (Bool, NotificationOption) -> Void) in
//                handle(true, NotificationOption.notificationType(.defaultNotificationType))
//            },
//            showDeleteExceptionSheet: { (_, _, _, _, _, _, _, update: @escaping (Span) -> Void) in
//                XCTAssertTrue(false)
//                update(.noneSpan)
//            },
//            showDeleteRecurrenceSheet: { (_, _, _, _, update: @escaping ((Span) -> Void)) in
//                update(.allEvents)
//            },
//            showDeleteAlert: { (title, message, _, confirmAction: (() -> Void)?, _) in
//                XCTAssertEqual(title, BundleI18n.Calendar.Calendar_Meeting_DeleteEventConfirm)
//                XCTAssertEqual(message, "")
//                confirmAction?()
//            })
//    }
//
//    //删除例外日程
//    func testDeleteException() {
//        //case 1
//        //有完整编辑权限的，会触发通知不通知
//        var deleteModel = EventDeleteDataMock(isCrossTenant: false,
//                                              hasMeetingMinuteUrl: false,
//                                              isInvitedAttendee: false,
//                                              isRecurrence: false,
//                                              isEditable: true,
//                                              isLocalEvent: false,
//                                              canDeleteAll: true,
//                                              isMeeting: true,
//                                              isException: true,
//                                              calendarId: "sdfsd",
//                                              notificationType: .defaultNotificationType,
//                                              key: "111",
//                                              startTime: 123)
//        handleDeleteEvent(
//            deleteModel: deleteModel,
//            deleteEvent: { (span, notification) in
//                XCTAssertEqual(span, .allEvents)
//                XCTAssertEqual(notification, .defaultNotificationType)
//            },
//            isFromDetail: true,
//            showDeleteNotification: { (_, _, _, _, _, _, handle: @escaping (Bool, NotificationOption) -> Void) in
//                handle(true, NotificationOption.notificationType(.defaultNotificationType))
//            },
//            showDeleteExceptionSheet: { (_, _, _, _, _, _, _, update: @escaping (Span) -> Void) in
//                update(.allEvents)
//            },
//            showDeleteRecurrenceSheet: { (_, _, _, _, update: @escaping ((Span) -> Void)) in
//                XCTAssertTrue(false)
//                update(.allEvents)
//            },
//            showDeleteAlert: { (title, message, _, confirmAction: (() -> Void)?, _) in
//                XCTAssertEqual(title, BundleI18n.Calendar.Calendar_Meeting_DeleteEventConfirm)
//                XCTAssertEqual(message, "")
//                confirmAction?()
//            })
//
//        //case 2
//        //没有有完整编辑权限的，不会触发通知不通知
//        deleteModel.canDeleteAll = false
//        handleDeleteEvent(
//            deleteModel: deleteModel,
//            deleteEvent: { (span, notification) in
//                XCTAssertEqual(span, .allEvents)
//                XCTAssertEqual(notification, .defaultNotificationType)
//            },
//            isFromDetail: true,
//            showDeleteNotification: { (_, _, _, _, _, _, handle: @escaping (Bool, NotificationOption) -> Void) in
//                XCTAssertTrue(false)
//                handle(true, NotificationOption.notificationType(.defaultNotificationType))
//            },
//            showDeleteExceptionSheet: { (_, _, _, _, _, _, _, update: @escaping (Span) -> Void) in
//                update(.allEvents)
//            },
//            showDeleteRecurrenceSheet: { (_, _, _, _, update: @escaping ((Span) -> Void)) in
//                XCTAssertTrue(false)
//                update(.allEvents)
//            },
//            showDeleteAlert: { (title, message, _, confirmAction: (() -> Void)?, _) in
//
//                XCTAssertEqual(title, BundleI18n.Calendar.Calendar_Meeting_DeleteEventConfirm)
//                XCTAssertEqual(message, "")
//                confirmAction?()
//            })
//    }
//
//}
