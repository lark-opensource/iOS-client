//
//  EventDetailTableOtherMeetingComponent.swift
//  Calendar
//
//  Created by tuwenbo on 2022/11/21.
//

import UIKit
import RxSwift
import LarkContainer
import LarkUIKit
import SnapKit
import EENavigator
import UniverseDesignActionPanel
import CalendarFoundation
import UniverseDesignToast
import LarkEMM

final class EventDetailTableOtherMeetingComponent: UserContainerComponent {

    private let viewModel: EventDetailTableOtherMeetingViewModel

    private let bag = DisposeBag()

    init(viewModel: EventDetailTableOtherMeetingViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(meetingView)
        meetingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        bindViewModel()
        bindView()
    }

    private func bindViewModel() {

        guard let viewController = viewController else { return }

        if let viewData = viewModel.rxViewData.value {
            self.meetingView.updateContent(viewData)
        }
        viewModel.rxViewData
            .compactMap { $0 }
            .subscribeForUI(onNext: { [weak self] viewData in
                guard let self = self else { return }
                self.meetingView.updateContent(viewData)
                self.view.isHidden = viewData.isMeetingInvalid
            }).disposed(by: bag)

        viewModel.rxToast
            .bind(to: viewController.rx.toast)
            .disposed(by: bag)

        viewModel.rxRoute
            .subscribeForUI(onNext: { [weak self] route in
                guard let self = self,
                        let viewController = self.viewController else { return }
                switch route {
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
                case let .applink(url, vcType):
                    self.openApplink(url: url, linkType: vcType)
                case let .selector(parsedMeetingLinks):
                    self.showMeetingPicker(parsedMeetingLinks: parsedMeetingLinks)
                }
            }).disposed(by: bag)
    }

    private func bindView() {
        meetingView.dailInAction = { [weak self] in
            self?.viewModel.action(.dail)
        }

        meetingView.videoMeetingAction = { [weak self] in
            self?.viewModel.action(.videoMeeting)
        }

        meetingView.linkCopyAction = { [weak self] in
            self?.viewModel.action(.linkCopy)
        }

        meetingView.morePhoneNumAction = { [weak self] in
            self?.viewModel.action(.morePhoneNumber)
        }
    }

    private lazy var meetingView: DetailOtherMeetingView = {
        let meetingView = DetailOtherMeetingView()
        return meetingView
    }()

    private func generateMeetingLinkCellData(vcLinks: [ParsedEventMeetingLink], baseVC: UIViewController) -> [MeetingLinkCellData] {
        let meetingLinkCellData = vcLinks.map {
            MeetingLinkCellData(parsedLinkData: $0,
                                onClick: { [weak self] link in
                guard let self = self, let url = URL(string: link.vcLink) else { return }
                baseVC.dismiss(animated: true)
                self.openApplink(url: url, linkType: link.vcType)
                CalendarTracerV2.EventDetail.traceClick(commonParam: CommonParamData(instance: self.viewModel.rxModel.value.instance,
                                                                            event: self.viewModel.event)) {
                    $0.click("enter_vc")
                    $0.vchat_type = String(describing: link.vcType)
                    $0.link_type = "parse"
                }
            },
                                onCopy: { [weak self] vcLink in
                guard let self = self else { return }
                SCPasteboard.generalPasteboard(shouldImmunity: true).string = vcLink
                UDToast.showTips(with: BundleI18n.Calendar.Calendar_VideoMeeting_VCLinkSuccess, on: baseVC.view)
            })
        }
        return meetingLinkCellData
    }

    private func showMeetingPicker(parsedMeetingLinks: [ParsedEventMeetingLink]) {
        if Display.pad {
            let vc = ParsedLinkViewController()
            let meetingLinks = generateMeetingLinkCellData(vcLinks: parsedMeetingLinks, baseVC: vc)
            let meetingSelectorView = MeetingSelectorView(meetingLinks: meetingLinks)
            vc.addContentView(meetingSelectorView, title: BundleI18n.Calendar.Calendar_Detail_JoinVC)

            let nav = LkNavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .formSheet
            nav.update(style: .custom(UIColor.ud.bgFloat))
            viewController.present(nav, animated: true, completion: nil)
        } else {
            let meetingSelectorVC = ActionPanelContentViewController()
            let meetingLinks = generateMeetingLinkCellData(vcLinks: parsedMeetingLinks, baseVC: meetingSelectorVC)
            let meetingSelectorView = MeetingSelectorView(meetingLinks: meetingLinks)

            let selectorViewHeight = meetingSelectorView.estimateHeight()
            meetingSelectorVC.addContentView(meetingSelectorView, contentHeight: selectorViewHeight, title: BundleI18n.Calendar.Calendar_Detail_JoinVC)

            let screenHeight = Display.height
            let actionPanelOriginY = max(screenHeight - CGFloat((selectorViewHeight + 140)), screenHeight * 0.2)
            let actionPanel = UDActionPanel(
                customViewController: meetingSelectorVC,
                config: UDActionPanelUIConfig(
                    originY: actionPanelOriginY,
                    canBeDragged: false,
                    backgroundColor: UIColor.ud.bgFloatBase
                )
            )
            viewController.present(actionPanel, animated: true, completion: nil)
        }
    }

    private func openApplink(url: URL, linkType: Rust.ParsedMeetingLinkVCType) {
        guard let viewController = self.viewController else { return }
        if linkType == .lark {
            userResolver.navigator.open(url, from: viewController)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

}
