//
//  EventDetailTableZoomMeetingComponent.swift
//  Calendar
//
//  Created by pluto on 2022-10-20.
//

import UIKit
import RxSwift
import LarkContainer
import LarkUIKit
import EENavigator
import CalendarFoundation
import LKCommonsLogging
import UniverseDesignToast

final class EventDetailTableZoomMeetingComponent: UserContainerComponent {

    private let logger = Logger.log(EventDetailTableZoomMeetingViewModel.self, category: "calendar.EventDetailTableZoomMeetingViewModel")
    private let viewModel: EventDetailTableZoomMeetingViewModel
    private let bag = DisposeBag()

    init(viewModel: EventDetailTableZoomMeetingViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(zoomMeetingView)
        zoomMeetingView.snp.edgesEqualToSuperView()
        bindViewModel()
        bindView()
    }

    private func bindViewModel() {
        guard let viewController = viewController else { return }

        if let viewData = viewModel.rxViewData.value {
            self.zoomMeetingView.updateContent(viewData)
        }

        viewModel.rxViewData
            .compactMap { $0 }
            .subscribeForUI(onNext: { [weak self] viewData in
                guard let self = self else { return }
                self.zoomMeetingView.updateContent(viewData)
            }).disposed(by: bag)

        viewModel.rxRoute
            .subscribe(onNext: { [weak self] route in
                guard let self = self,
                      let viewController = self.viewController else { return }
                switch route {
                case let .phoneNumberList(info):
                    let viewModel = ZoomMeetingPhoneListViewModel(zoomConfigInfo: info, userResolver: self.userResolver)
                    let vc = ZoomMeetingPhoneListViewController(viewModel: viewModel)

                    let navi = LkNavigationController(rootViewController: vc)
                    if Display.pad {
                        navi.modalPresentationStyle = .formSheet
                    } else {
                        navi.modalPresentationStyle = .fullScreen
                    }
                    navi.modalPresentationCapturesStatusBarAppearance = true
                    self.userResolver.navigator.present(navi, from: viewController)

                case .meetingSetting(let id):
                    let viewModel = ZoomDefaultSettingViewModel(meetingID: self.viewModel.videoMeeting.pb.zoomConfigs.meetingID, userResolver: self.userResolver)
                    let vc = ZoomDefaultSettingController(viewModel: viewModel, userResolver: self.userResolver)

                    viewModel.onSaveCallBack = {[weak self]  (meetingNo, password, meetingUrl) in
                        guard let self = self else { return }
                        self.viewModel.updateVideoMeeting(meetingNo: meetingNo, password: password, meetingUrl: meetingUrl)
                        UDToast.showTips(with: I18n.Calendar_Zoom_MeetInfoUpdated, on: self.viewController.view)
                    }

                    let nav = LkNavigationController(rootViewController: vc)
                    if Display.pad {
                        nav.modalPresentationStyle = .formSheet
                    }
                    self.userResolver.navigator.present(nav, from: viewController)
                case let .url(url):
                    if Display.pad {
                        self.userResolver.navigator.present(url,
                                                 context: ["from": "calendar"],
                                                 wrap: LkNavigationController.self,
                                                 from: viewController,
                                                 prepare: { $0.modalPresentationStyle = .fullScreen })
                    } else {
                        self.userResolver.navigator.push(url, context: ["from": "calendar"], from: viewController)
                    }
                }
            }).disposed(by: bag)

        viewModel.rxToast
            .bind(to: viewController.rx.toast)
            .disposed(by: bag)
    }

    private func bindView() {
        zoomMeetingView.dailInAction = { [weak self] in
            self?.viewModel.action(.dail)
        }

        zoomMeetingView.videoMeetingAction = { [weak self] in
            self?.viewModel.action(.videoMeeting)
        }

        zoomMeetingView.linkCopyAction = { [weak self] in
            self?.viewModel.action(.linkCopy)
        }

        zoomMeetingView.morePhoneNumAction = { [weak self] in
            self?.viewModel.action(.morePhoneNumber)
        }

        zoomMeetingView.settingItemAction = { [weak self] in
            self?.viewModel.action(.setting)
        }
    }

    private lazy var zoomMeetingView: EventDetailTableZoomMeetingCell = {
        let zoomMeetingView = EventDetailTableZoomMeetingCell()
        return zoomMeetingView
    }()
}
