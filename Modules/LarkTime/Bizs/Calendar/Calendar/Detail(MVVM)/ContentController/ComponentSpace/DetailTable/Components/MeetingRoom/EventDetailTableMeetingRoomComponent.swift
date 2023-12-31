//
//  EventDetailTableMeetingRoomComponent.swift
//  Calendar
//
//  Created by Rico on 2021/4/8.
//

import UIKit
import SnapKit
import LarkCombine
import LarkContainer
import LarkUIKit
import EENavigator
import CalendarFoundation

final class EventDetailTableMeetingRoomComponent: UserContainerComponent {

    let viewModel: EventDetailTableMeetingRoomViewModel
    private var bag: Set<AnyCancellable> = []

    init(viewModel: EventDetailTableMeetingRoomViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(meetingRoomInfoView)
        meetingRoomInfoView.snp.edgesEqualToSuperView()

        bindViewModel()
    }

    private func bindViewModel() {
        if let viewData = viewModel.viewData.value {
            self.meetingRoomInfoView.updateContent(viewData)
        }

        viewModel.viewData
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] viewData in
                guard let self = self else { return }
                self.meetingRoomInfoView.updateContent(viewData)
            }
            .store(in: &bag)

        viewModel.route
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] route in
                guard let self = self, let viewController = self.viewController else { return }
                switch route {
                case let .appLink(appLink): self.userResolver.navigator.open(appLink, from: viewController)
                case let .roomInfo(roomDetailVM): self.jumpToRoomInfo(roomDetailVM)
                case let .showAll(vm):
                    let vc = SelectedMeetingRoomViewController(viewModel: vm, userResolver: self.userResolver)
                    viewController.navigationController?.pushViewController(vc, animated: true)
                }
            }.store(in: &bag)
    }

    private func jumpToRoomInfo(_ roomDetailVM: MeetingRoomDetailViewModel) {
        guard let navi = self.viewController?.navigationController else { return }
        let toVC = MeetingRoomDetailViewController(viewModel: roomDetailVM, userResolver: self.userResolver)
        if Display.pad {
            let navigation = LkNavigationController(rootViewController: toVC)
            navigation.modalPresentationStyle = .formSheet
            navi.present(navigation, animated: true, completion: nil)
        } else {
            navi.pushViewController(toVC, animated: true)
        }
    }

    private lazy var meetingRoomInfoView: DetailMeetingRoomCell = {
        let meetingRoomInfoView = DetailMeetingRoomCell { [weak self] (index, clickIcon) in
            guard let self = self else { return }
            self.viewModel.click(with: index, clickIcon: clickIcon)
        } showAllAction: { [weak self] in
            guard let self = self else { return }
            self.viewModel.clickShowAll()
        }
        return meetingRoomInfoView
    }()
}
