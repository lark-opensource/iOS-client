//
//  EventDetailTableVideoMeetingComponent.swift
//  Calendar
//
//  Created by Rico on 2021/3/27.
//

import UIKit
import RxSwift
import RxRelay
import LarkUIKit
import EENavigator
import CalendarFoundation
import UniverseDesignToast
import LarkContainer

final class EventDetailTableVideoMeetingComponent: AttachableComponent {
    private let viewModel: EventDetailTableVideoMeetingViewModel

    private var api: CalendarByteViewApi? { viewModel.api }
    private let bag = DisposeBag()

    required init(userResolver: UserResolver, rxEventData: BehaviorRelay<CalendarEventData>) {
        self.viewModel = EventDetailTableVideoMeetingViewModel(userResolver: userResolver, rxEventData: rxEventData)
        super.init(userResolver: userResolver, rxEventData: rxEventData)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(videoMeetingView)
        videoMeetingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        bindViewModel()
        bindView()
    }

    private func bindViewModel() {

        guard viewController != nil else { return }

        if let viewData = viewModel.rxViewData.value {
            self.videoMeetingView.updateContent(viewData)
        }

        if let pstnNumData = viewModel.rxPstnNumViewData.value {
            self.videoMeetingView.updatePstnData(pstnNumData)
        }

        viewModel.rxViewData
            .compactMap { $0 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] viewData in
                guard let self = self else { return }
                self.videoMeetingView.updateContent(viewData)
            }).disposed(by: bag)

        viewModel.rxPstnNumViewData
            .compactMap { $0 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] pstnNumData in
                guard let self = self else { return }
                self.videoMeetingView.updatePstnData(pstnNumData)
            }).disposed(by: bag)

        viewModel.rxToast
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (toastStatus: ToastStatus) in
                guard let self = self else { return }
                switch toastStatus {
                case .tips(let info):
                    UDToast.showTips(with: info, on: self.viewController.view)
                case .success(let info):
                    UDToast.showSuccess(with: info, on: self.viewController.view)
                case .warning(let info):
                    UDToast.showWarning(with: info, on: self.viewController.view)
                case .failure(let info):
                    UDToast.showFailure(with: info, on: self.viewController.view)
                case .loading(let info, let disableUserInteraction):
                    UDToast.showLoading(with: info, on: self.viewController.view, disableUserInteraction: disableUserInteraction)
                case .remove:
                    UDToast.removeToast(on: self.viewController.view)
                }
            }).disposed(by: bag)

        viewModel.rxRoute
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] route in
                guard let self = self, let viewController = self.viewController else { return }
                switch route {
                case .meetingSetting(let instanceDetails):
                    self.api?.showVideoMeetingSetting(instanceDetails: instanceDetails, from: viewController)
                case let .pstnDetail(instanceDetails, meetingUrl, tenantID):
                    self.api?.showPSTNDetail(meetingUrl: meetingUrl, tenantID: tenantID, calendarType: self.viewModel.calendarEvent.source == .people ? .interview : .normal, instanceDetails: instanceDetails, from: viewController)
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
    }

    private func bindView() {
        videoMeetingView.dailInAction = { [weak self] in
            self?.viewModel.action(.dail)
        }

        videoMeetingView.videoMeetingAction = { [weak self] in
            self?.viewModel.action(.videoMeeting)
        }

        videoMeetingView.linkCopyAction = { [weak self] in
            self?.viewModel.action(.linkCopy)
        }

        videoMeetingView.morePhoneNumAction = { [weak self] in
            self?.viewModel.action(.morePhoneNumber)
        }

        videoMeetingView.settingItemAction = { [weak self] in
            self?.viewModel.action(.setting)
        }
    }

    private lazy var videoMeetingView: DetailVideoMeetingCellV2 = {
        let videoMeetingView = DetailVideoMeetingCellV2()
        return videoMeetingView
    }()
}

enum ToastStatus {
    case tips(String)
    case success(String)
    case warning(String)
    case failure(String)
    case loading(info: String, disableUserInteraction: Bool)
    case remove
}
