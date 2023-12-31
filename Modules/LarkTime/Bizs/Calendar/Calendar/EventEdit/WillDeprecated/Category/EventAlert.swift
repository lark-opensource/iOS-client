//
//  UIAlert+Event.swift
//  Calendar
//
//  Created by zhu chao on 2018/7/30.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import RustPB
import LarkActionSheet
import RxSwift
import LarkUIKit
import LarkAlertController
import UniverseDesignActionPanel
import UniverseDesignDialog
import UniverseDesignIcon
import UniverseDesignColor

public typealias Span = CalendarEvent.Span
public typealias NotificationType = CalendarEvent.NotificationType

struct RecurrenceOptions: OptionSet {
    let rawValue: Int

    static let thisEvent = RecurrenceOptions(rawValue: 1 << 0)
    static let futureEvents = RecurrenceOptions(rawValue: 1 << 1)
    static let allEvents = RecurrenceOptions(rawValue: 1 << 2)

    static let all: RecurrenceOptions = [.thisEvent, .futureEvents, .allEvents]
    static let withoutFuture: RecurrenceOptions = [.thisEvent, .allEvents]
}

final class EventAlert {

    class func showDeleteRecurrenceSheet(canDeleteAll: Bool,
                                         isLocalEvent: Bool,
                                         subMessage: String? = nil,
                                         controller: UIViewController?,
                                         isOrganizer: Bool,
                                         update: @escaping ((Span, _ isUpgradeToChatBeforeAlert: Bool?) -> Void)) {
        var options: RecurrenceOptions = .withoutFuture
        if canDeleteAll {
            options = .all
        }
        self.showRecurrenceActionSheet(isDelete: true,
                                       isLocalEvent: isLocalEvent,
                                       subMessage: subMessage,
                                       controller: controller,
                                       isOrganizer: isOrganizer,
                                       options: options,
                                       update: update)
    }

    class func showDeleteExceptionSheet(isLocalEvent: Bool,
                                        subMessage: String? = nil,
                                        controller: UIViewController?,
                                        isOrganizer: Bool,
                                        calendarApi: CalendarRustAPI?,
                                        calendarId: String,
                                        key: String,
                                        update: @escaping ((Span, _ isUpgradeToChatBeforeAlert: Bool?) -> Void)) {
        var bag = DisposeBag()
        calendarApi?.getEvent(calendarId: calendarId,
                             key: key,
                             originalTime: 0).map({ $0.selfAttendeeStatus != .removed }).catchErrorJustReturn(false)
            .observeOn(MainScheduler.instance).subscribe(onNext: { (isExist) in
                bag = DisposeBag()
                if !isExist {
                    let title = isOrganizer ? I18n.Calendar_Event_SureCancelEvent : I18n.Calendar_Event_DeletedEventDesc
                    Self.showDeleteEventCalendarAlert(title: title, message: "", controller: controller, confirmAction: { _ in
                        update(.thisEvent, true)
                    }, cancelAction: nil)
                    return
                }
                self.showRecurrenceActionSheet(isDelete: true,
                                               isLocalEvent: isLocalEvent,
                                               subMessage: subMessage,
                                               controller: controller,
                                               isOrganizer: isOrganizer,
                                               options: .withoutFuture,
                                               update: update)
            }).disposed(by: bag)
    }

    class func showRecurrenceDeleteAllAlert(controller: UIViewController?,
                                            update: @escaping (() -> Void)) {
        let alertVC = LarkAlertController()
        alertVC.setTitle(text: I18n.Calendar_ConfirmDeleteRecur_Pop)
        alertVC.setContent(text: I18n.Calendar_ConfirmDeleteRecur_Explain)
        alertVC.addSecondaryButton(text: I18n.Calendar_Common_Cancel)
        alertVC.addDestructiveButton(text: I18n.Calendar_Common_Delete, numberOfLines: 0, dismissCompletion: {
            update()
        })

        controller?.present(alertVC, animated: true)
    }

    private class func showRecurrenceActionSheet(isDelete: Bool,
                                                 isLocalEvent: Bool,
                                                 subMessage: String? = nil,
                                                 controller: UIViewController?,
                                                 isOrganizer: Bool,
                                                 options: RecurrenceOptions = .all,
                                                 update: @escaping ((Span, _ isUpgradeToChatBeforeAlert: Bool?) -> Void)) {
        assertLog(Thread.isMainThread)
        let actionSheet: UDActionSheet

        if let title = subMessage,
           !title.isEmpty {
            actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
            actionSheet.setTitle(title)
        } else {
            actionSheet = UDActionSheet(config: UDActionSheetUIConfig())
        }
        if options.contains(.thisEvent) {
            actionSheet.addItem(UDActionSheetItem(title: recurrenceTip(with: isDelete,
                                                                       span: .thisEvent,
                                                                       isOrganizer: isOrganizer),
                                                  action: {
                update(.thisEvent, nil)
                operationLog(optType: CalendarOperationType.saveThis.rawValue)
            }))
        }
        if options.contains(.futureEvents) {
            actionSheet.addItem(UDActionSheetItem(title: recurrenceTip(with: isDelete,
                                                                       span: .futureEvents,
                                                                       isOrganizer: isOrganizer),
                                                  action: {
                update(.futureEvents, nil)
                operationLog(optType: CalendarOperationType.saveFollow.rawValue)
            }))
        }
        if options.contains(.allEvents), !isLocalEvent {
            actionSheet.addItem(UDActionSheetItem(title: recurrenceTip(with: isDelete,
                                                                       span: .allEvents,
                                                                       isOrganizer: isOrganizer),
                                                  action: {
                update(.allEvents, nil)
                operationLog(optType: CalendarOperationType.saveAll.rawValue)
            }))
        }
        actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel)
        if Display.pad {
            actionSheet.modalPresentationStyle = .formSheet
        }
        controller?.present(actionSheet, animated: true, completion: nil)
    }

    private class func recurrenceTip(with isDelete: Bool, span: Span, isOrganizer: Bool) -> String {
        switch span {
        case .thisEvent:
            if !isDelete {
                return BundleI18n.Calendar.Calendar_Edit_UpdateThisEventOnly
            } else {
                if isOrganizer {
                    return BundleI18n.Calendar.Calendar_Edit_DeleteThisEventOnly
                }
                return BundleI18n.Calendar.Calendar_Alert_RemoveThisEventOnly
            }
        case .futureEvents:
            return isDelete ? BundleI18n.Calendar.Calendar_Detail_DeleteFollowingEvent : BundleI18n.Calendar.Calendar_Edit_UpdateFollowingEvent
        case .allEvents:
            if !isDelete {
                return BundleI18n.Calendar.Calendar_Detail_UpdateAllEvent
            } else {
                if isOrganizer {
                    return BundleI18n.Calendar.Calendar_Edit_DeleteAllEvents
                }
                return BundleI18n.Calendar.Calendar_Alert_RemoveAllEvents
            }
        @unknown default:
            assertionFailureLog()
            return ""
        }
    }

    class func showAlert(title: String,
                         message: String,
                         controller: UIViewController?,
                         confirmAction: (() -> Void)?,
                         cancelAction: (() -> Void)?) {
        let dialog = UDDialog()
        var isMoreThanTwoLines: Bool = false
        let containerWidth = UDDialog.Layout.dialogWidth - 44
        if title.getWidth(font: UIFont.ud.title3(.fixed)) > 2 * containerWidth { isMoreThanTwoLines = true }
        dialog.setTitle(text: title, alignment: isMoreThanTwoLines ? .left : .center)
        dialog.setContent(text: message)
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Common_Confirm, dismissCompletion: confirmAction)

        controller?.present(dialog, animated: true, completion: nil)
    }

    class func showCancelReplyRSVPAlert(title: String,
                                        controller: UIViewController?,
                                        acknowledgeAction: (() -> Void)?) {
        let alert = UIAlertController(title: title,
                                      message: "",
                                      preferredStyle: .alert)
        let acknowledge = UIAlertAction(title: BundleI18n.Calendar.Calendar_Common_GotIt,
                                        style: .cancel) { (_) in
                                            acknowledgeAction?()
        }
        alert.addAction(acknowledge)
        controller?.present(alert, animated: true, completion: nil)

    }

    /// 创建群聊
    class func showCreateMeetingAlert(title: String, message: String, controller: UIViewController?, confirmAction: @escaping (() -> Void)) {
        showAlert(title: title,
                  message: message,
                  controller: controller,
                  confirmAction: confirmAction,
                  cancelAction: nil)
    }

    /// 加入群聊
    class func showJoinMeetingAlert(controller: UIViewController?, confirmAction: @escaping (() -> Void)) {
        showAlert(title: BundleI18n.Calendar.Calendar_Meeting_EnterMeetingAlert,
                  message: BundleI18n.Calendar.Calendar_Meeting_EnterGroupAndJoinEventAlert,
                  controller: controller,
                  confirmAction: confirmAction,
                  cancelAction: nil)
    }

    class func showNewStyleAlert(title: String,
                                     message: String,
                                     controller: UIViewController?,
                                     confirmAction: (() -> Void)?,
                                     cancelAction: (() -> Void)?) {

        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(text: message)
        alertController.addSecondaryButton(text: BundleI18n.Calendar.Calendar_Common_Cancel)
        alertController.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Common_Confirm, dismissCompletion: {
            confirmAction?()
        })

        controller?.present(alertController, animated: true)

    }

    class func showAlert(title: String? = nil,
                         message: String? = nil,
                         confirmText: String = I18n.Calendar_Common_Confirm,
                         cancelText: String? = I18n.Calendar_Common_Cancel,
                         confirmHandler: (() -> Void)? = nil,
                         cancelHandler: (() -> Void)? = nil) -> UIViewController {
        let alertVC = UDDialog(config: UDDialogUIConfig())
        if let title = title {
            alertVC.setTitle(text: title)
        }
        if let message = message {
            alertVC.setContent(text: message)
        }
        if let cancelText = cancelText, !cancelText.isEmpty {
            alertVC.addSecondaryButton(text: cancelText, dismissCompletion: {
                cancelHandler?()
            })
        }
        alertVC.addPrimaryButton(text: confirmText, dismissCompletion: {
            confirmHandler?()
        })
        return alertVC
    }

    class func showDeleteEventCalendarAlert(title: String,
                                            message: String,
                                            controller: UIViewController?,
                                            confirmAction: ((_ isUpgradeToChatinAlert: Bool?) -> Void)?,
                                            cancelAction: (() -> Void)?,
                                            isOrganizer: Bool = false) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.addSecondaryButton(text: isOrganizer ? BundleI18n.Calendar.Calendar_Event_DeleteEventGoBack_Button : BundleI18n.Calendar.Calendar_Common_Cancel)
        alertController.setContent(text: message)
        alertController.addDestructiveButton(text: isOrganizer ? BundleI18n.Calendar.Calendar_Event_CancelButton : BundleI18n.Calendar.Calendar_Event_Remove,
                                             dismissCompletion: {
            confirmAction?(nil)
        })
        controller?.present(alertController, animated: true)
    }

    class func showUnsubscribeOwnedCalendarAlert(controller: UIViewController?, confirmAction: @escaping (() -> Void)) {
        showNewStyleAlert(title: I18n.Calendar_Edit_UnsubscribePop,
                          message: I18n.Calendar_Edit_UnsubscribePopExplain,
                          controller: controller,
                          confirmAction: confirmAction,
                          cancelAction: nil)
    }

    class func showDeleteOwnedCalendarAlert(controller: UIViewController?, confirmAction: @escaping (() -> Void)) {
        showNewStyleAlert(title: BundleI18n.Calendar.Calendar_Setting_DeleteConfirmTitle,
                  message: BundleI18n.Calendar.Calendar_Setting_DeleteCalendarPopUpWindow,
                  controller: controller,
                  confirmAction: confirmAction,
                  cancelAction: nil)
    }

    class func showDismissModifiedCalendarAlert(controller: UIViewController?, confirmAction: @escaping (() -> Void)) {
        showNewStyleAlert(title: BundleI18n.Calendar.Calendar_Edit_UnSaveTip,
                  message: "",
                  controller: controller,
                  confirmAction: confirmAction,
                  cancelAction: nil)
    }

    class func showPublishCalendarMemberAlert(controller: UIViewController?, confirmAction: @escaping (() -> Void)) {
        showNewStyleAlert(
            title: BundleI18n.Calendar.Calendar_Setting_SetCalendarToPublicTitle,
            message: BundleI18n.Calendar.Calendar_Setting_MobileSetCalendarToPublicDetail,
            controller: controller,
            confirmAction: confirmAction,
            cancelAction: nil
        )
    }

    class func showNewCalCannotSaveAlert(controller: UIViewController) {
        let alertVC = LarkAlertController()
        alertVC.setTitle(text: BundleI18n.Calendar.Calendar_Setting_CannotSave)
        alertVC.setContent(text: BundleI18n.Calendar.Calendar_Setting_AddCalendarTitlePopWindow, color: UIColor.ud.N600)
        alertVC.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Common_Confirm)
        controller.present(alertVC, animated: true)
    }
}

extension LarkAlertController {
    class func showConfirmAlert(title: String,
                                message: String,
                                controller: UIViewController,
                                confirmTitle: String = BundleI18n.Calendar.Calendar_Common_Confirm,
                                confirmAction: (() -> Void)? = nil) {

        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(text: message)
        alertController.addPrimaryButton(text: confirmTitle, dismissCompletion: {
            confirmAction?()
        })
        controller.present(alertController, animated: true)
    }
}

// MARK: 会议室审批

extension LarkAlertController {
    typealias ApprovalDisplayInfo = (title: String, trigger: Int64?)

    fileprivate final class MeetingRoomApprovalDisplayInfoView: UIView {
        private(set) lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.ud.body0(.fixed)
            label.textColor = UIColor.ud.N900
            label.textAlignment = .left
            label.numberOfLines = 0
            return label
        }()

        private(set) lazy var subtitleLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.ud.body2(.fixed)
            label.textAlignment = .left
            label.textColor = UIColor.ud.N600
            label.numberOfLines = 1
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            stackView.axis = .vertical
            stackView.alignment = .fill
            stackView.distribution = .equalSpacing
            stackView.spacing = 4

            addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(horizontal: 12, vertical: 10))
            }

            backgroundColor = UIColor.ud.bgFloatOverlay
            layer.cornerRadius = 4
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class func generalMeetingRoomAlert(
        title: String,
        itemInfos: [ApprovalDisplayInfo]
    ) -> LarkAlertController {
        let infos = Array(itemInfos.prefix(2))

        let infoViews = infos.map { info -> MeetingRoomApprovalDisplayInfoView in
            let infoView = MeetingRoomApprovalDisplayInfoView()
            infoView.titleLabel.text = info.title
            if let trigger = info.trigger {
                let value = Double(trigger) / 3600.0
                infoView.subtitleLabel.text = BundleI18n.Calendar.Calendar_Rooms_OverReserveTimeApprove(num: String(format: "%g", value))
            } else {
                infoView.subtitleLabel.isHidden = true
            }
            return infoView
        }

        let stackView = UIStackView(arrangedSubviews: infoViews)
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill

        if itemInfos.count > 2 {
            let countLabel = UILabel()
            countLabel.numberOfLines = 2
            countLabel.textColor = UIColor.ud.textTitle
            countLabel.font = UIFont.systemFont(ofSize: 16)
            countLabel.text = BundleI18n.Calendar.Calendar_Plural_MeetingRoom(number: itemInfos.count)
            stackView.addArrangedSubview(countLabel)
        }

        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(view: stackView)
        return alertController
    }

    class func showAddApproveInfoAlert(
        from controller: UIViewController,
        title: String,
        itemTitles itemsNeededToBeApproved: [ApprovalDisplayInfo],
        disposeBag: DisposeBag,
        cancelText: String,
        cancelAction: (() -> Void)?,
        confirmAction: ((String) -> Void)? = nil
    ) {
        guard !itemsNeededToBeApproved.isEmpty else {
            assertionFailure()
            confirmAction?("")
            return
        }

        let infos = Array(itemsNeededToBeApproved.prefix(2))

        let infoViews = infos.map { info -> MeetingRoomApprovalDisplayInfoView in
            let infoView = MeetingRoomApprovalDisplayInfoView()
            infoView.titleLabel.text = info.title
            if let trigger = info.trigger {
                let value = Double(trigger) / 3600.0
                infoView.subtitleLabel.text = BundleI18n.Calendar.Calendar_Rooms_OverReserveTimeApprove(num: String(format: "%g", value))
            } else {
                infoView.subtitleLabel.isHidden = true
            }
            return infoView
        }

        let stackView = UIStackView(arrangedSubviews: infoViews)
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill

        if itemsNeededToBeApproved.count > 2 {
            let countLabel = UILabel()
            countLabel.numberOfLines = 2
            countLabel.textColor = UIColor.ud.textTitle
            countLabel.font = UIFont.systemFont(ofSize: 16)
            countLabel.text = BundleI18n.Calendar.Calendar_Plural_MeetingRoom(number: itemsNeededToBeApproved.count)
            stackView.addArrangedSubview(countLabel)
        }

        let textView = KMPlaceholderTextView()
        textView.placeholder = BundleI18n.Calendar.Calendar_Approval_PopupReason
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textView.textColor = UIColor.ud.textTitle
        textView.layer.cornerRadius = 4
        textView.layer.borderWidth = 1
        textView.layer.ud.setBorderColor(UIColor.ud.textDisabled)
        textView.layer.masksToBounds = true

        stackView.addArrangedSubview(textView)
        stackView.setCustomSpacing(16, after: infoViews.last!)

        textView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(infos.count > 2 ? 38 : 90)
        }

        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(view: stackView)
        alertController.addSecondaryButton(text: cancelText, dismissCompletion: {
            cancelAction?()
        })
        let confirmButton = alertController.addPrimaryButton(
            text: BundleI18n.Calendar.Calendar_Common_Save,
            dismissCheck: {
                guard let text = textView.text,
                    !text.trimmingCharacters(in: .whitespaces).isEmpty else {
                    return false
                }
                return true
            },
            dismissCompletion: {
                let text = textView.text?.trimmingCharacters(in: .whitespaces) ?? ""
                confirmAction?(text)
            }
        )
        confirmButton.setTitleColor(UIColor.ud.primaryFillSolid03, for: .disabled)
        controller.present(alertController, animated: true)

        textView.rx.text.bind { [weak confirmButton] text in
            confirmButton?.isEnabled = !(text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        }.disposed(by: disposeBag)
    }

    class func showAlertWithCheckBox<T>(
        from controller: UIViewController,
        title: String,
        allConfirmTypes: [T],
        event: Rust.Event,
        disposeBag: DisposeBag,
        subTitle: String? = nil,
        content: String? = nil,
        checkBoxTitle: String? = nil,
        defaultSelectType: T? = nil,
        cancelAction: (() -> Void)? = nil,
        confirmAction: ((_ checked: Bool,_ type: T?) -> Void)? = nil
    ) where T: SelectConfirmInfo {
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)

        var confirm: () -> Void = { confirmAction?(false, nil) }
        if let checkBoxTitle = checkBoxTitle {
            let wrapper = UIView()
            let checkBox = CheckBoxView(title: checkBoxTitle)
            wrapper.addSubview(checkBox)
            checkBox.snp.makeConstraints {
                $0.top.bottom.centerX.equalToSuperview()
                $0.left.greaterThanOrEqualToSuperview()
                $0.right.lessThanOrEqualToSuperview()
            }
            alertController.setContent(view: wrapper)
            confirm = { confirmAction?(checkBox.isSelected(), nil) }
        } else {
            if let subTitle = subTitle {
                let wrapper = UIView()
                let titleView = NotiTitleView(title: subTitle)
                wrapper.addSubview(titleView)

                if let selectType = defaultSelectType {
                    let selectConfirmView = SelectConfirmView<T>()
                    titleView.snp.makeConstraints {
                        $0.top.centerX.equalToSuperview()
                        $0.left.greaterThanOrEqualToSuperview()
                        $0.right.lessThanOrEqualToSuperview()
                    }

                    wrapper.addSubview(selectConfirmView)
                    selectConfirmView.snp.makeConstraints { make in
                        make.top.equalTo(titleView.snp.bottom).offset(8)
                        make.centerX.equalToSuperview()
                        make.height.equalTo(30)
                        make.bottom.equalToSuperview()
                        make.left.greaterThanOrEqualToSuperview()
                        make.right.lessThanOrEqualToSuperview()
                    }
                    selectConfirmView.type = selectType

                    selectConfirmView.rx.tap.asDriver()
                    .drive(onNext: { [weak selectConfirmView, weak alertController] _ in
                        guard let selectConfirmView = selectConfirmView, let alertController = alertController else { return }

                        selectConfirmView.isSeleted = true

                        let actionSheet = UDActionSheet(config: .init())
                        actionSheet.setCancelItem(text: BundleI18n.Calendar.Calendar_Common_Cancel) { [weak selectConfirmView] in
                            selectConfirmView?.isSeleted = false
                        }

                        for confirmType in allConfirmTypes {
                            let isSelectType = selectConfirmView.type == .some(confirmType)
                            let titleColor = isSelectType ? UDColor.primaryContentDefault : UDColor.textTitle
                            let item = UDActionSheetItem(title: confirmType.title(),
                                                         titleColor: titleColor) { [weak selectConfirmView] in
                                selectConfirmView?.type = confirmType
                                selectConfirmView?.isSeleted = false

                                if let type = confirmType as? SelectConfirmType {
                                    switch type {
                                    case .calendarAssistant:
                                        CalendarTracerV2.EventCreateConfirm.traceClick {
                                            $0.click("switch_to_bot")
                                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: event))
                                        }
                                    case .newMeetingGroup:
                                        CalendarTracerV2.EventCreateConfirm.traceClick {
                                            $0.click("switch_to_new_group")
                                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: event))
                                        }
                                    case .p2pChatName(_):
                                        CalendarTracerV2.EventCreateConfirm.traceClick {
                                            $0.click("switch_to_1v1")
                                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: event))
                                        }
                                    case .reuseGroupName(_):
                                        CalendarTracerV2.EventCreateConfirm.traceClick {
                                            $0.click("switch_to_chat")
                                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: event))
                                        }
                                    }
                                }
                            }
                            actionSheet.addItem(item)
                        }

                        actionSheet.rx.deallocated.subscribeForUI(onNext: { [weak selectConfirmView] (_) in
                            selectConfirmView?.isSeleted = false
                        }).disposed(by: disposeBag)

                        alertController.present(actionSheet, animated: true)

                    }).disposed(by: disposeBag)

                    alertController.setContent(view: wrapper)
                    confirm = { [weak selectConfirmView] in
                        confirmAction?(false, selectConfirmView?.type)
                    }
                } else {
                    if let content = content {
                        let contentView = NotiTitleView(title: content)
                        wrapper.addSubview(contentView)

                        titleView.snp.makeConstraints {
                            $0.top.centerX.equalToSuperview()
                            $0.left.greaterThanOrEqualToSuperview()
                            $0.right.lessThanOrEqualToSuperview()
                        }

                        contentView.snp.makeConstraints {
                            $0.top.equalTo(titleView.snp.bottom).offset(8)
                            $0.left.greaterThanOrEqualToSuperview()
                            $0.right.lessThanOrEqualToSuperview()
                            $0.bottom.centerX.equalToSuperview()
                        }

                    } else {
                        titleView.snp.makeConstraints {
                            $0.top.bottom.centerX.equalToSuperview()
                            $0.left.greaterThanOrEqualToSuperview()
                            $0.right.lessThanOrEqualToSuperview()
                        }
                    }

                    alertController.setContent(view: wrapper)

                    confirm = { confirmAction?(false, nil) }
                }
            }
        }
        alertController.addSecondaryButton(text: I18n.Calendar_Common_Cancel, dismissCompletion: {
            cancelAction?()
        })

        alertController.addPrimaryButton(
            text: I18n.Calendar_Common_Confirm,
            dismissCompletion: { confirm() }
        )
        controller.present(alertController, animated: true)
    }
}

protocol SelectConfirmInfo: Equatable {
    func title() -> String
}

enum SelectConfirmType: SelectConfirmInfo {
    case newMeetingGroup
    case calendarAssistant
    case p2pChatName(name: String)
    case reuseGroupName(name: String)

    func title() -> String {
        switch self {
        case .newMeetingGroup:
            return I18n.Calendar_G_NewMeetingGroup_PickerButton
        case .calendarAssistant:
            return I18n.Calendar_Bot_CalAssistant
        case .p2pChatName(let name):
            return name
        case .reuseGroupName(let name):
            return name
        }
    }
}

class SelectConfirmView<T>: UIButton where T: SelectConfirmInfo {
    private let infoLable: UILabel = {
        let label = UILabel.cd.subTitleLabel(fontSize: 16)
        label.textColor = .ud.textTitle
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let upDoneImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.downBoldOutlined
        return imageView
    }()

    var isSeleted: Bool = false {
        didSet {
            if isSeleted {
                upDoneImage.image = UDIcon.upBoldOutlined
            } else {
                upDoneImage.image = UDIcon.downBoldOutlined
            }
        }
    }

    var type: T? {
        didSet {
            infoLable.text = type?.title() ?? ""
        }
    }

    init() {
        super.init(frame: .zero)

        layer.cornerRadius = 4

        addSubview(infoLable)
        addSubview(upDoneImage)

        infoLable.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalTo(upDoneImage.snp.left).offset(-8)
            make.top.bottom.equalToSuperview().inset(4)
        }

        upDoneImage.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
            make.right.equalToSuperview().offset(-9)
        }
        clipsToBounds = true
        let image = UIImage.cd.from(color: UDColor.fillPressed)
        setBackgroundImage(image.withRoundedCorners(radius: 4) ?? image, for: .highlighted)
        setBackgroundImage(UIImage.cd.from(color: UIColor.clear), for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
