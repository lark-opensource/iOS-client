//
//  EventDetailNavigationBarComponent.swift
//  Calendar
//
//  Created by Rico on 2021/3/16.
//

import UIKit
import SnapKit
import RxRelay
import RxSwift
import LarkUIKit
import RoundedHUD
import Foundation
import LarkCombine
import EENavigator
import LarkContainer
import LarkRustClient
import LarkAlertController
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignActionPanel
import CalendarFoundation
import UniverseDesignDialog

final class EventDetailNavigationBarComponent: UserContainerComponent, EventDetailComponentContext {

    typealias ViewModel = EventDetailNavigationBarViewModel

    @ScopedInjectedLazy
    var calendarDependency: CalendarDependency?

    private let bag = DisposeBag()
    let viewModel: EventDetailNavigationBarViewModel
    private var combineBag: Set<AnyCancellable> = []

    @ContextObject(\.state) var state

    init(viewModel: ViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(navigationBar)
        let barHeight = EventDetail.navigationBarHeight
        navigationBar.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(barHeight)
        }

        viewModel.getControllerForDelete = { [weak self] in
            guard let self = self else { return UIViewController() }
            return self.viewController
        }
        bindViewModel()

        navigationBar.presentStyle = presentStyle
    }

    private func bindViewModel() {

        guard let viewController = viewController else { return }

        // 视图数据绑定
        viewModel.rxViewData.compactMap { $0 }
            .bind(to: navigationBar.rx.viewData)
            .disposed(by: bag)

        viewModel.rxToast
            .bind(to: viewController.rx.toast)
            .disposed(by: bag)

        state.$navigationTitleAlpha
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] alpha in
                guard let self = self else { return }
                self.navigationBar.transformUI(with: alpha)
            }.store(in: &combineBag)

        /// 页面跳转
        viewModel.rxRoute.subscribeForUI(onNext: { [weak self] route in
            guard let self = self,
                  let viewController = self.viewController as? CalendarController
            else { return }

            switch route {
                // TODO: 带参数
            case let .url(url: url): self.userResolver.navigator.push(url, from: viewController)
            case let .edit(coordinator: c): c.start(from: viewController, source: self.navigationBar.editButton)
            case let .sharePanel(shareVC):
                shareVC.run(shareButton: self.navigationBar.shareButton, from: viewController)
            case let .actionSheet(title, confirm):
                self.presentActionSheet(title: title, confirm: confirm)
            case let .transferChat(organizer, confirm):
                self.calendarDependency?.jumpToSearchTransferUserController(eventOrganizerId: organizer, from: viewController, doTransfer: confirm)
            case let .transferDone(result, transferCompleted):
                self.handleTransferDone(result, transferCompleted: transferCompleted)
            case let .morePop(optionItems: items):
                let source = UDActionSheetSource(sourceView: self.navigationBar.moreButton,
                                                 sourceRect: self.navigationBar.moreButton.bounds,
                                                 arrowDirection: .up)
                let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(popSource: source))
                items.forEach { item in
                    actionSheet.addItem(UDActionSheetItem(title: item.title,
                                                          titleColor: item.type == .delete ? UDColor.functionDangerContentDefault : nil,
                                                          action: item.action))
                }
                actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel, action: nil)

                viewController.present(actionSheet, animated: true, completion: nil)
            case let .alertController(controller: controller):
                viewController.present(controller, animated: true, completion: nil)
            case let .larkAlertController(title: title, message: message):
                LarkAlertController.showConfirmAlert(title: title,
                                                     message: message,
                                                     controller: viewController)
            case let .shareForward(eventTitle: title,
                                   duringTime: time,
                                   shareIconName: icon,
                                   canAddExternalUser: canAddExternalUser,
                                   shouldShowHint: shouldShowHint,
                                   pickerCallBack: pickerCallBack):
                self.calendarDependency?.jumpToEventForwardController(from: viewController,
                                                                     eventTitle: title,
                                                                     duringTime: time,
                                                                     shareIcon: UIImage.cd.image(named: icon).withRenderingMode(.alwaysOriginal),
                                                                     canAddExternalUser: canAddExternalUser,
                                                                     shouldShowHint: shouldShowHint,
                                                                     pickerCallBack: pickerCallBack)
            case let .enterGroupApply(data: data):
                        let applyView = CalendarJoinGroupApplyView(tips: I18n.Calendar_G_ApplyToEnterGroupDesc)
                        let alertController = LarkAlertController()
                        alertController.setTitle(text: I18n.Calendar_G_ApplyToEnterGroup)
                        alertController.setContent(view: applyView)
                        alertController.addCancelButton(dismissCompletion: {
                            self.close()
                        })
                        alertController.addPrimaryButton(text: I18n.Calendar_Edit_Confirm, dismissCompletion: { [weak self] in
                            guard let self = self else { return }
                            self.viewModel.addingMeetingCollaboratorRequest(data: data, reason: applyView.textField.text ?? "")

                        })
                viewController.present(alertController, animated: true, completion: nil)
            case .dismiss: self.close()

            }

        }).disposed(by: bag)
    }

    private var presentStyle: EventDetailNavigationBar.PresentStyle {
        var isPushStyle = false
        if let viewController = self.viewController?.parent,
           let controllers = viewController.navigationController?.viewControllers {
            isPushStyle = controllers.contains(viewController) && (controllers.count > 1)
        }
        return isPushStyle ? .push : .present
    }

    private lazy var navigationBar: EventDetailNavigationBar = {
        let bar = EventDetailNavigationBar()
        bar.tappedAction = { [weak self] type in
            self?.handleTappedAction(type)
        }

        bar.toastAction = { [weak self] message in
            self?.showToast(message: message)
        }
        return bar
    }()
}

extension EventDetailNavigationBarComponent: NavigationViewSharable {
    func provideView(for key: NavigationViewSharableKey) -> UIView? {
        let map = [NavigationViewSharableKey.navigationBar: navigationBar]
        return map[key]
    }
}

// MARK: - Action
extension EventDetailNavigationBarComponent {
    private func handleTappedAction(_ actionType: EventDetailNavigationBar.NavigationTappedType) {
        let actionHandler: [EventDetailNavigationBar.NavigationTappedType: () -> Void] = [
            .close: closeTapped,
            .edit: editTapped,
            .more: moreTapped,
            .delete: deleteTapped,
            .share: shareTapped
        ]
        actionHandler[actionType]?()
    }

    private func closeTapped() {
        close()
    }

    private func editTapped() {
        viewModel.action(.edit)
    }

    private func moreTapped() {
        viewModel.action(.more)
    }

    private func deleteTapped() {
        viewModel.action(.delete)
    }

    private func shareTapped() {
        viewModel.action(.share)
    }

    private func close() {
        switch presentStyle {
        case .present: self.viewController?.dismiss(animated: true, completion: nil)
        case .push: self.viewController?.popSelf()
        }
    }

    private func handleTransferDone(_ result: Result<UIViewController, Error>, transferCompleted: @escaping () -> Void) {
        guard let viewController = self.viewController else { return }
        switch result {
        case let .success(pickerController):
            if let view = userResolver.navigator.mainSceneWindow {
                if Display.pad {
                    viewController.presentingViewController?.dismiss(animated: true, completion: {
                        UDToast.showSuccess(with: BundleI18n.Calendar.Calendar_Transfer_TransferSuccessed, on: view)
                        transferCompleted()
                    })
                } else {
                    viewController.navigationController?.popViewController(animated: false)
                    pickerController.dismiss(animated: true, completion: {
                        UDToast.showSuccess(with: BundleI18n.Calendar.Calendar_Transfer_TransferSuccessed, on: view)
                        transferCompleted()
                    })
                }
            }
        case let .failure(error):
            UDToast.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Transfer_TransferFailed, on: viewController.view)
        }
    }

    private func showToast(message: String) {
        UDToast.showTips(with: message, on: viewController.view)
    }

}

// MARK: - ActionSheet
extension EventDetailNavigationBarComponent {
    private func presentActionSheet(title: String, confirm: @escaping () -> Void) {
        guard let viewController = self.viewController else { return }
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.addSecondaryButton(text: BundleI18n.Calendar.Calendar_Common_Cancel)
        alertController.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Common_Confirm, dismissCompletion: confirm)
        viewController.present(alertController, animated: true)
    }
}

extension EventDetail {
    static let navigationBarHeight = UIApplication.shared.statusBarFrame.height + 44
}
