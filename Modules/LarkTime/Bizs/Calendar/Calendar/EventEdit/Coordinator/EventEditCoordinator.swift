//
//  EventEditCoordinator.swift
//  Calendar
//
//  Created by 张威 on 2020/2/23.
//

import UIKit
import LarkUIKit
import RxCocoa
import RxSwift
import EventKit
import LarkContainer
import EENavigator
import LarkActionSheet
import UniverseDesignToast
import CalendarFoundation
import LarkAssetsBrowser

protocol EventEditCoordinatorDelegate: AnyObject {

    // 取消编辑
    func coordinatorDidCancelEdit(_ coordinator: EventEditCoordinator)

    // 保存非本地日程
    func coordinator(_ coordinator: EventEditCoordinator, didSaveEvent pbEvent: Rust.Event, span: Span, extraData: EventEditExtraData?)

    func coordinator(_ coordinator: EventEditCoordinator, didSaveEvent pbEvent: Rust.Event, span: Span)

    // 删除非本地日程
    func coordinator(_ coordinator: EventEditCoordinator, didDeleteEvent pbEvent: Rust.Event)

    // 保存本地日程
    func coordinator(_ coordinator: EventEditCoordinator, didSaveLocalEvent ekEvent: EKEvent)

    // 删除非本地日程
    func coordinator(_ coordinator: EventEditCoordinator, didDeleteLocalEvent ekEvent: EKEvent)

}

extension EventEditCoordinatorDelegate {
    func coordinatorDidCancelEdit(_ coordinator: EventEditCoordinator) {}
    func coordinator(_ coordinator: EventEditCoordinator, didSaveEvent pbEvent: Rust.Event, span: Span) {}
    func coordinator(_ coordinator: EventEditCoordinator, didDeleteEvent pbEvent: Rust.Event) {}
    func coordinator(_ coordinator: EventEditCoordinator, didSaveLocalEvent ekEvent: EKEvent) {}
    func coordinator(_ coordinator: EventEditCoordinator, didDeleteLocalEvent ekEvent: EKEvent) {}
}

protocol EventEditDependency {
    var setting: Setting { get }
    var attendeeTotalLimit: Int { get }
    var departmentMemberUpperLimit: Int { get }
    var attendeeTimeZoneEnableLimit: Int { get }
    var calendarManager: CalendarManager? { get }
    var is12HourStyle: BehaviorRelay<Bool>? { get }
    var currentUser: CurrentUserInfo? { get }
    var calendarApi: CalendarRustAPI? { get }
    var timeZoneSelectService: TimeZoneSelectService? { get }
}

/// 职责：
///   - 提供 navigation 服务，VC 之间彼此隔离，即管理 ViewController 的层级
///   - 为 ViewController、ViewModel 提供注入
///   - 初始化 VC、ViewModel
///

public final class EventEditCoordinator: NSObject, UserResolverWrapper {

    public let userResolver: UserResolver

    @ScopedInjectedLazy var calendarInterface: CalendarInterface?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    enum ChildrenType: Int, Hashable {
        case meetingRoom = 1
        case timeZone
    }
    final class DependencyImpl: EventEditDependency, UserResolverWrapper {
        var setting: Setting = SettingService.shared().getSetting()
        var attendeeTotalLimit: Int = SettingService.shared().finalEventAttendeeLimit
        var departmentMemberUpperLimit: Int = SettingService.shared().settingExtension.departmentMemberUpperLimit
        var attendeeTimeZoneEnableLimit: Int = SettingService.shared().settingExtension.attendeeTimeZoneEnableLimit
        // TODO-userResolver
        @ScopedInjectedLazy(\CalendarDependency.is12HourStyle) var is12HourStyle: BehaviorRelay<Bool>?
        @ScopedInjectedLazy(\CalendarDependency.currentUser) var currentUser: CurrentUserInfo?
        @ScopedInjectedLazy var calendarManager: CalendarManager?
        @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
        @ScopedInjectedLazy var timeZoneSelectService: TimeZoneSelectService?

        let userResolver: UserResolver
        init(userResolver: UserResolver) {
            self.userResolver = userResolver
        }
    }

    weak var delegate: EventEditCoordinatorDelegate?

    weak var navigationController: UINavigationController?
    var eventViewController: EventEditViewController? {
        if editInput.isWebinarScene {
            let webinarVC = navigationController?.viewControllers.first as? WebinarEventEditViewController
            return webinarVC?.subViewControllers.first as? EventEditViewController

        } else {
            return navigationController?.viewControllers.first as? EventEditViewController
        }
    }

    let dependency: EventEditDependency
    var children: [ChildrenType: AnyObject] = [:]
    var actionSource: EventEditActionSource
    /// 创建完成后，是否自动切换到详情页
    var autoSwitchToDetailAfterCreate = false

    var suiteView: AssetPickerSuiteView?

    var editInput: EventEditInput
    let disposeBag = DisposeBag()
    private let legoInfo: EventEditLegoInfo
    private let interceptor: EventEditInterceptor
    private let title: String?
    init(userResolver: UserResolver,
         editInput: EventEditInput,
         dependency: EventEditDependency,
         actionSource: EventEditActionSource = .unknown,
         legoInfo: EventEditLegoInfo = .normal(),
         interceptor: EventEditInterceptor = .none,
         title: String? = nil) {
        self.userResolver = userResolver
        self.editInput = editInput
        self.dependency = dependency
        self.actionSource = actionSource
        self.legoInfo = legoInfo
        self.interceptor = interceptor
        self.title = title
    }

    /*
     source: 新建日程 - nil；编辑日程 - 编辑按钮，用于 iPad popOver 定位，必须要有
     */
    func start(from presentingViewController: UIViewController, source: UIView? = nil) {
        let disableEncrypt = SettingService.shared().tenantSetting?.disableEncrypt ?? false
        if SettingService.shared().tenantSetting == nil {
            SettingService.rxTenantSetting().subscribe().disposed(by: disposeBag)
        }

        operationLog(message: "start edit disableEncrypt = \(disableEncrypt)")

        switch editInput {
        // 新建lark日程
        case .createWithContext, .createWebinar:
            if disableEncrypt {
                UDToast.showTips(with: I18n.Calendar_NoKeyNoCreate_Toast, on: presentingViewController.view)
                return
            }
        case .editFrom(_, let instance), .copyWithEvent(_, let instance), .editWebinar(_, let instance):
            if instance.disableEncrypt {
                UDToast.showTips(with: I18n.Calendar_NoKeyNoOperate_Toast, on: presentingViewController.view)
                return
            }
        // 编辑本地日程
        case .editFromLocal:
            break
        }

        let spanFrontCoordinator = SpanFrontCoordinator(coordinator: self, userResolver: self.userResolver)
        spanFrontCoordinator.modalPresentationStyle = .overFullScreen
        presentingViewController.present(spanFrontCoordinator, animated: false) {
            spanFrontCoordinator.start(from: presentingViewController, source: source)
        }
    }

    func prepare(span: Rust.Span = .noneSpan) -> UIViewController {
        if editInput.isWebinarScene {
            return prepareForWebinar()
        } else {
            return prepareForEvent(span: span)
        }
    }

    private func prepareForWebinar() -> UIViewController {
        var title: String = BundleI18n.Calendar.Calendar_Edit_CreateAWebinarPage
        if case .editWebinar = editInput {
            title = I18n.Calendar_Edit_Webinar_PageTitle
        }
        let vc = WebinarEventEditViewController(userResolver: self.userResolver, title: title)
        vc.delegate = self
        let naviController = LkNavigationController(rootViewController: vc)
        navigationController = naviController
        navigationController?.modalPresentationStyle = .formSheet

        // 将 coordinator 关联到 naviController 中，由后者持有
        attachRef(to: naviController)
        return naviController
    }

    private func prepareForEvent(span: Rust.Span = .noneSpan) -> UIViewController {
        let viewModel = EventEditViewModel(
            userResolver: self.userResolver,
            input: editInput,
            actionSource: actionSource,
            setting: dependency.setting,
            attendeeTotalLimit: dependency.attendeeTotalLimit,
            departmentMemberUpperLimit: dependency.departmentMemberUpperLimit,
            attendeeTimeZoneEnableLimit: dependency.attendeeTimeZoneEnableLimit,
            rxIs12HourStyle: dependency.is12HourStyle,
            legoInfo: legoInfo,
            interceptor: interceptor,
            title: title,
            span: span
        )
        let vc = EventEditViewController(viewModel: viewModel, userResolver: self.userResolver)
        vc.editType = editInput.isFromCreating ? .new : .edit
        vc.delegate = self
        let naviController = LkNavigationController(rootViewController: vc)
        navigationController = naviController
        navigationController?.modalPresentationStyle = .formSheet
        if case .copyWithEvent = editInput,
           !Display.pad {
            // 复制日程场景 fullScreen 显示VC
            navigationController?.modalPresentationStyle = .overCurrentContext
        }

        // 将 coordinator 关联到 naviController 中，由后者持有
        attachRef(to: naviController)
        return naviController

    }

    func enter(from viewController: UIViewController, to nextViewController: UIViewController, present: Bool = false) {
        if present {
            let navigation = LkNavigationController(rootViewController: nextViewController)
            navigation.modalPresentationStyle = .formSheet
            viewController.navigationController?.present(navigation, animated: true, completion: nil)
        } else {
            viewController.navigationController?.pushViewController(nextViewController, animated: true)
        }
    }

    func exit(from viewController: UIViewController, fromPresent: Bool = false) {
        if fromPresent {
            viewController.navigationController?.dismiss(animated: true, completion: nil)
        } else {
            viewController.navigationController?.popViewController(animated: true)
        }
    }

}

extension EventEditCoordinator {

    private static var associatedKey = "associatedKey"

    private func attachRef(to vc: UIViewController) {
        objc_setAssociatedObject(vc, &Self.associatedKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func unattachRef(from vc: UIViewController) {
        objc_setAssociatedObject(vc, &Self.associatedKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

extension EventEditCoordinator: EventEditViewControllerDelegate {

    func didCancelEdit(from fromVC: EventEditViewController) {
        if let naviController = navigationController {
            unattachRef(from: naviController)
        }
        navigationController?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            fromVC.viewModel.meetingNotesModel?.deleteMeetingNotes(.cancelEdit)
            self.delegate?.coordinatorDidCancelEdit(self)
        }
    }

    func didFinishSaveEvent(_ pbEvent: Rust.Event, span: Span, from fromVC: EventEditViewController) {
        guard let naviController = navigationController else {
            assertionFailure()
            return
        }
        unattachRef(from: naviController)
        if autoSwitchToDetailAfterCreate,
           let detailVC = calendarInterface?.getEventContentController(with: pbEvent, scene: .calendarView),
           let rootVC = fromVC.presentingViewController {
            let naviVC = LkNavigationController(rootViewController: detailVC)
            naviVC.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            naviController.dismiss(animated: true) {
                rootVC.present(naviVC, animated: true)
            }
            self.delegate?.coordinator(self, didDeleteEvent: pbEvent)
        } else {
            naviController.dismiss(animated: true) {
                if let callback = self.interceptor.callBack {
                    callback(pbEvent.toMailEvent())
                }
                self.delegate?.coordinator(self, didSaveEvent: pbEvent, span: span, extraData: self.eventViewController?.viewModel.extraData)
            }
        }
    }

    func didFinishDeleteEvent(_ pbEvent: Rust.Event, from fromVC: EventEditViewController) {
        guard let naviController = navigationController else {
            assertionFailure()
            return
        }
        unattachRef(from: naviController)
        naviController.dismiss(animated: true) {
            self.delegate?.coordinator(self, didDeleteEvent: pbEvent)
        }
    }

    func didFinishSaveLocalEvent(_ ekEvent: EKEvent, from fromVC: EventEditViewController) {
        if let naviController = navigationController {
            unattachRef(from: naviController)
        }
        navigationController?.dismiss(animated: true) {
            self.delegate?.coordinator(self, didSaveLocalEvent: ekEvent)
        }
    }

    func didFinishDeleteLocalEvent(_ ekEvent: EKEvent, from fromVC: EventEditViewController) {
        if let naviController = navigationController {
            unattachRef(from: naviController)
        }
        navigationController?.dismiss(animated: true) {
            self.delegate?.coordinator(self, didDeleteLocalEvent: ekEvent)
        }
    }

}

// MARK: Webinar Delegate
extension EventEditCoordinator: WebinarEventEditViewControllerDelegate {
    func getEventEditViewController() -> EventEditViewController {
        let viewModel = EventEditViewModel(
            userResolver: self.userResolver,
            input: editInput,
            actionSource: actionSource,
            setting: dependency.setting,
            attendeeTotalLimit: dependency.attendeeTotalLimit,
            departmentMemberUpperLimit: dependency.departmentMemberUpperLimit,
            attendeeTimeZoneEnableLimit: dependency.attendeeTimeZoneEnableLimit,
            rxIs12HourStyle: dependency.is12HourStyle,
            legoInfo: legoInfo,
            interceptor: interceptor,
            title: title,
            span: .noneSpan
        )
        let vc = EventEditViewController(viewModel: viewModel, userResolver: self.userResolver)
        vc.editType = editInput.isFromCreating ? .new : .edit
        vc.delegate = self
        return vc
    }

    func getVCConfigController() -> UIViewController {
        let viewModel = EventEditViewModel(
            userResolver: self.userResolver,
            input: editInput,
            actionSource: actionSource,
            setting: dependency.setting,
            attendeeTotalLimit: dependency.attendeeTotalLimit,
            departmentMemberUpperLimit: dependency.departmentMemberUpperLimit,
            attendeeTimeZoneEnableLimit: dependency.attendeeTimeZoneEnableLimit,
            rxIs12HourStyle: dependency.is12HourStyle,
            legoInfo: legoInfo,
            interceptor: interceptor,
            title: title,
            span: .noneSpan
        )
        let vc = EventEditViewController(viewModel: viewModel, userResolver: self.userResolver)
        vc.editType = editInput.isFromCreating ? .new : .edit
        vc.delegate = self
        return vc
    }
}
