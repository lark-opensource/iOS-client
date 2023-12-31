//
//  EventDetailHeaderComponent.swift
//  Calendar
//
//  Created by Rico on 2021/3/16.
//

import UIKit
import Foundation
import RxRelay
import RxSwift
import LarkContainer
import UniverseDesignToast
import LarkUIKit
import EENavigator
import LarkAlertController
import LarkCombine
import CalendarFoundation

final class EventDetailHeaderComponent: UserContainerComponent, EventDetailComponentContext {

    @ScopedInjectedLazy private var calendarDependency: CalendarDependency?

    let viewModel: EventDetailHeaderViewModel
    private let bag = DisposeBag()
    private var combineBag: Set<AnyCancellable> = []

    init(viewModel: EventDetailHeaderViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    @ContextObject(\.state) var state

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(headerView)
        headerView.snp.edgesEqualToSuperView()

        headerView.didLayout = {[weak self] height in
            self?.state.headerHeight = height
        }

        bindViewModel()
        bindView()
    }

    private func bindViewModel() {

        guard let viewController = self.viewController else {
            return
        }

        viewModel.rxViewData
            .bind(to: headerView)
            .disposed(by: bag)

        viewModel.rxToast
            .bind(to: viewController.rx.toast)
            .disposed(by: bag)

        viewModel.rxRoute
            .subscribeForUI(onNext: {[weak self] route in
                guard let self = self, let viewController = self.viewController else { return }
                switch route {
                case let .url(url): self.userResolver.navigator.push(url, context: ["from": "calendar"], from: viewController)
                case let .urlPresent(url, style):
                    self.userResolver.navigator.present(url,
                                             context: ["from": "calendar"],
                                             wrap: LkNavigationController.self,
                                             from: viewController,
                                             prepare: { $0.modalPresentationStyle = style })
                    
                case let .chat(chatId, needApply):
                    if needApply {
                        self.calendarDependency?.jumpToJoinGroupApplyController(from: viewController, chatID: chatId, eventID: self.viewModel.model.event?.serverID ?? "")
                    } else {
                        self.calendarDependency?
                            .jumpToChatController(from: viewController,
                                                  chatID: chatId,
                                                  onError: { [weak self] in
                                guard let self = self, let vc = self.view.viewController() else { return }
                                UDToast().showFailure(with: BundleI18n.Calendar.Lark_Legacy_RecallMessage, on: vc.view)
                            }, onLeaveMeeting: {
                                //退出群组
                                viewController.navigationController?.popToRootViewController(animated: true)
                            })
                    }
                }
            }).disposed(by: bag)

        viewModel.rxMessage
            .subscribeForUI(onNext: { [weak self] message in
                guard let self = self,
                      let viewController = self.viewController else {
                    return
                }
                switch message {
                case let .alert(title, content, align):
                    let alertVC = LarkAlertController()
                    if let title = title {
                        alertVC.setTitle(text: title)
                    }
                    if let align = align {
                        alertVC.setContent(text: content, alignment: align)
                    } else {
                        alertVC.setContent(text: content)
                    }
                    alertVC.addPrimaryButton(text: I18n.Calendar_Event_GotIt)
                    viewController.present(alertVC, animated: true, completion: nil)
                case let .createMeeting(title, message, action):
                    EventAlert.showCreateMeetingAlert(title: title, message: message, controller: viewController, confirmAction: action)
                case let .alertController(alertController):
                    viewController.present(alertController, animated: true, completion: nil)
                case let .confirmAlert(title, message, confirmTitle):
                    if let confirm = confirmTitle {
                        LarkAlertController.showConfirmAlert(title: title, message: message, controller: viewController, confirmTitle: confirm, confirmAction: nil)
                    } else {
                        LarkAlertController.showConfirmAlert(title: title, message: message, controller: viewController)
                    }
                case let .joinMeeting(confirm):
                    EventAlert.showJoinMeetingAlert(controller: viewController, confirmAction: confirm)
                }

            }).disposed(by: bag)

        state.$headerViewOpaque
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] progress in
                self?.headerView.transfromToOpaque(with: progress)
            }.store(in: &combineBag)
    }

    private func bindView() {
        effectview.rx
            .tapGesture()
            .when([.recognized])
            .subscribe(onNext: { [weak self] _ in
                self?.alertTextView.hide()
                self?.effectview.removeFromSuperview()
            }).disposed(by: bag)
    }

    private lazy var headerView: EventDetailHeaderView = {
        let headerView = EventDetailHeaderView()
        headerView.delegate = self
        return headerView
    }()

    private lazy var effectview: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.alpha = 0.85
        return view
    }()

    private lazy var alertTextView = AlertTextView()
}

// MARK: - Action
extension EventDetailHeaderComponent: EventDetailHeaderFunctionViewDelegate {
    func headerView(_ headerview: EventDetailHeaderView, didTappedButton buttonType: EventDetailHeaderView.TappedButtonType) {
        switch buttonType {
        case .chat: viewModel.action(.meeting)
        case .doc: viewModel.action(.doc)
        }
    }

    func headerView(_ headerView: EventDetailHeaderView, didTappedText text: String) {
        guard let viewController = self.viewController else { return }
        let controllerView: UIView = viewController.view ?? .init()
        self.alertTextView.setText(text: text)
        effectview.frame = controllerView.frame
        controllerView.addSubview(effectview)
        alertTextView.show()
        if !controllerView.subviews.contains(alertTextView) {
            controllerView.addSubview(alertTextView)
        }
        controllerView.bringSubviewToFront(alertTextView)
        alertTextView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(120)
            make.left.equalToSuperview().offset(37)
            make.right.equalToSuperview().offset(-37)
        }
    }
}
