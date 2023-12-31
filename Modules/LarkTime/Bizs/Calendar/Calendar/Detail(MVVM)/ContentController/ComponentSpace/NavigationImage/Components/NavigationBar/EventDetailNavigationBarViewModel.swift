//
//  EventDetailNavigationBarViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/3/17.
//

import RxRelay
import RxSwift
import RustPB
import Foundation
import LarkContainer
import LarkAppConfig
import CalendarFoundation
import UniverseDesignIcon
import UniverseDesignColor
import UIKit
import EventKit

final class EventDetailNavigationBarViewModel: EventDetailComponentViewModel {

    let rxRoute: PublishRelay<Route> = PublishRelay()
    let rxViewData = BehaviorRelay<EventDetailNavigationBarViewDataType?>(value: nil)
    let rxToast: PublishRelay<ToastStatus> = PublishRelay()

    let disposeBag = DisposeBag()

    var model: EventDetailModel { rxModel.value }

    var sharePanel: EventDetailShareCoordinator?

    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var appConfiguration: AppConfiguration?
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ContextObject(\.refreshHandle) var refreshHandle
    @ContextObject(\.rxModel) var rxModel
    @ContextObject(\.monitor) var monitor
    @ContextObject(\.payload) var payload

    // 为使用旧版删除逻辑开的口子，理论上弹窗应该ViewController自己触发
    var getControllerForDelete: (() -> UIViewController?)?

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)

        bindRx()
    }

    private func bindRx() {
        rxModel
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.buildViewData()
        })
        .disposed(by: disposeBag)
    }

    private func buildViewData() {
        let viewData = ViewData(textColor: model.auroraColor.textColor,
                                cornerImage: cornerImage,
                                hasMoreButton: hasMoreButton,
                                hasUndecrpytDeleteButton: hasUndecrpytDeleteButton,
                                titleText: title,
                                shareButtonStyle: shareButtonStyle,
                                editButtonStyle: editStyle)
        rxViewData.accept(viewData)
    }
}

extension EventDetailNavigationBarViewModel {

    var hasMoreButton: Bool {
        return (enableDelete || enableTransfer || enableReport || enableCopy) && !undecryptable
    }

    var hasUndecrpytDeleteButton: Bool {
        switch model {
        case .local:
            return false
        case .pb(let event, let instance):
            return event.calendarEventDisplayInfo.isDeletableBtnShow && undecryptable
        case .meetingRoomLimit:
            return false
        }
    }

    var undecryptable: Bool {
        switch model {
        case .local:
            return false
        case .pb(let event, let instance):
            return event.displayType == .undecryptable || instance.displayType == .undecryptable
        case .meetingRoomLimit:
            return false
        }
    }

    var editStyle: EventDetailNavigationBar.EditButtonStyle {

        switch model {
        case .meetingRoomLimit: return .none
        case let .local(local): return local.dt.isEditable ? .normal : .none
        case let .pb(event, _):
            let sdkResult = event.calendarEventDisplayInfo.isEditableBtnShow
            let result = sdkResult && (event.dt.isSchemaDisplay(key: .edit) ?? true)
            if !result {
                return .none
            }

            if let level = event.dt.schemaCompatibleLevel, level == .disableEdit {
                return .disabled
            }

            if event.calendarEventDisplayInfo.editBtnDisplayType == .shownExternalAccountExpired {
                return .disabled
            }

            return .normal
        }
    }

    var shareButtonStyle: EventDetailNavigationBar.ShareButtonStyle {
        guard let event = model.event else {
            return .hidden
        }

        if let schemaDisplay = event.dt.isSchemaDisplay(key: .share), !schemaDisplay {
            return .hidden
        }

        let displayType = event.calendarEventDisplayInfo.shareBtnDisplayType
        EventDetail.logInfo("share button display type: \(displayType)")
        switch displayType {
        case .hidden:
            return .hidden
        case .shareable:
            return .shareable
        case .forbiddenPrivate:
            return .forbidden(I18n.Calendar_G_NoPermitSharePrivate)
        case .forbiddenCalendarReader:
            return .forbidden(I18n.Calendar_G_NoPermitShareEvent)
        case .forbiddenEventCannotInviteAttendee:
            return .forbidden(I18n.Calendar_G_OrgDisallowShareEvent)
        default:
            return .hidden
        }
    }

    var hasShareButton: Bool {
        if case .shareable = shareButtonStyle { return true } else { return false }
    }

    var enableDelete: Bool {

        switch model {
        case .meetingRoomLimit: return false
        case let .local(local): return local.dt.isEditable
        case let .pb(event, _):
            let sdkResult = event.calendarEventDisplayInfo.isDeletableBtnShow
            let result = sdkResult && (event.dt.isSchemaDisplay(key: .delete) ?? true)
            return result
        }
    }

    var enableTransfer: Bool {
        guard let event = model.event else {
            return false
        }

        let sdkResult = event.calendarEventDisplayInfo.isTransferBtnShow
        let result = sdkResult && (event.dt.isSchemaDisplay(key: .transfer) ?? true)

        return result
    }

    var enableReport: Bool {
        if !FS.suiteReport(userID: self.userResolver.userID) {
            return false
        }

        if !FG.isReportEnabled {
            return false
        }

        guard let event = model.event else {
            return false
        }

        let sdkResult = event.calendarEventDisplayInfo.isReportBtnShow
        let result = sdkResult && (event.dt.isSchemaDisplay(key: .report) ?? true)
        return result
    }

    var enableCopy: Bool {
        guard let event = model.event else {
            return false
        }
        if model.isWebinar {
            return false
        }
        return event.calendarEventDisplayInfo.isCopyBtnShow
    }

    var currentUserInfo: CurrentUserInfo? {
        return calendarDependency?.currentUser
    }

    var cornerImage: UIImage? {
        let color: UIColor = UDColor.staticBlack20 & UDColor.staticWhite20

        if model.isFromGoogle {
            return UDIcon.getIconByKey(.googleFilled, iconColor: color).scaleNaviSize()
        } else if model.isFromExchange {
            return UDIcon.getIconByKey(.exchangeFilled, iconColor: color).scaleNaviSize()
        } else if model.isLocal {
            return UDIcon.getIconByKey(.cellphoneOutlined, iconColor: color).scaleNaviSize()
        } else {
            return nil
        }
    }

    var calendar: CalendarModel? {
        model.getCalendar(calendarManager: self.calendarManager)
    }

    var is12HourStyle: Bool {
        calendarDependency?.is12HourStyle.value ?? true
    }

    var title: String {
        model.displayTitle
    }
}

// MARK: - User Action
extension EventDetailNavigationBarViewModel {

    enum Action {
        case edit
        case share
        case more
        case delete
    }

    func action(_ action: Action) {
        switch action {
        case .edit: self.handleEditAction()
        case .share: self.handleShareAction()
        case .more: self.handleMoreAction()
        case .delete: self.delete()
        }
    }

}

// MARK: - Route
extension EventDetailNavigationBarViewModel {
    enum Route {
        case url(url: URL)
        case edit(coordinator: EventEditCoordinator)
        case sharePanel(viewController: EventDetailShareCoordinator)
//        case morePop(viewController: UIViewController)
        case morePop(optionItems: [OptionItem])
        case actionSheet(title: String, confirm: () -> Void)
        case transferChat(organizer: String, confirm: (String, String, UIViewController) -> Void)
        case transferDone(Result<UIViewController, Error>, transferCompleted: () -> Void)
        case alertController(controller: UIAlertController)
        case larkAlertController(title: String, message: String)
        case dismiss
        case shareForward(eventTitle: String,
                          duringTime: String,
                          shareIconName: String,
                          canAddExternalUser: Bool,
                          shouldShowHint: Bool,
                          pickerCallBack: ([String], String?, Error?, Bool) -> Void)
        case enterGroupApply(data: CalendarNotiGroupApplySavedData)
    }
}

// MARK: - ViewData

extension EventDetailNavigationBarViewModel {
    struct ViewData: EventDetailNavigationBarViewDataType {
        var textColor: UIColor
        var cornerImage: UIImage?
        var hasMoreButton: Bool
        var hasUndecrpytDeleteButton: Bool
        var titleText: String
        var shareButtonStyle: EventDetailNavigationBar.ShareButtonStyle
        var editButtonStyle: EventDetailNavigationBar.EditButtonStyle
    }
}

// MARK: - Edit Callback
extension EventDetailNavigationBarViewModel: EventEditCoordinatorDelegate {

    // 保存非本地日程
    func coordinator(_ coordinator: EventEditCoordinator, didSaveEvent pbEvent: Rust.Event, span: Span, extraData: EventEditExtraData? = nil) {
        EventDetail.logDebug("did save event callback: \(pbEvent.dt.description), span: \(span)")
        monitor.track(.success(.edit, model, [.editResult: "save"]))
        if span == .allEvents {
            refreshHandle.refresh()
            return
        }
        if let data = extraData?.extraApplyGroupData {
            rxRoute.accept(.enterGroupApply(data: data))
            CalendarTracerV2.ApplyJoinGroup.traceView {
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: pbEvent))
            }
        }

        if let observable = extraData?.deleteOriginalMeetingNotes {
            observable
                .subscribe(onNext: { [weak self] _ in
                    self?.refreshHandle.refreshByEdit(newEvent: pbEvent, span: span)
                }).disposed(by: disposeBag)
        }
        refreshHandle.refreshByEdit(newEvent: pbEvent, span: span)
    }

    // 删除非本地日程
    func coordinator(_ coordinator: EventEditCoordinator, didDeleteEvent pbEvent: Rust.Event) {
        EventDetail.logDebug("did delete event callback: \(pbEvent.dt.description)")
        monitor.track(.success(.edit, model, [.editResult: "delete"]))
        rxRoute.accept(.dismiss)
        localRefreshService?.rxEventNeedRefresh.onNext(())
        localRefreshService?.rxCalendarDetailDismiss.onNext(())
    }

    // 保存本地日程
    func coordinator(_ coordinator: EventEditCoordinator, didSaveLocalEvent ekEvent: EKEvent) {
        EventDetail.logDebug("did save local event callback: \(ekEvent.debugDescription)")
        monitor.track(.success(.edit, model, [.editResult: "save"]))
        refreshHandle.refresh(ekEvent: ekEvent)
    }

    // 删除非本地日程
    func coordinator(_ coordinator: EventEditCoordinator, didDeleteLocalEvent ekEvent: EKEvent) {
        EventDetail.logDebug("did delete local event callback: \(ekEvent.debugDescription)")
        monitor.track(.success(.edit, model, [.editResult: "delete"]))
        rxRoute.accept(.dismiss)
        localRefreshService?.rxEventNeedRefresh.onNext(())
        localRefreshService?.rxCalendarDetailDismiss.onNext(())
    }
}
