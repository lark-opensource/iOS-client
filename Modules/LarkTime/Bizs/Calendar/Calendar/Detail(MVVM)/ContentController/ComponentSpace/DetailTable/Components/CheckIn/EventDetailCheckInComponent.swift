//
//  EventDetailCheckInComponent.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/20.
//

import Foundation
import LarkContainer
import OpenCombine
import LarkUIKit
import UniverseDesignToast
import CalendarFoundation

class EventDetailCheckInComponent: UserContainerComponent {

    let viewModel: EventDetailCheckInViewModel
    var bag: Set<AnyCancellable> = []

    init(viewModel: EventDetailCheckInViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(checkInView)
        checkInView.snp.edgesEqualToSuperView()

        bindViewModel()
    }

    private func bindViewModel() {
        if let viewData = viewModel.viewData.value {
            checkInView.viewData = viewData
        }

        viewModel.viewData
            .assignUI(to: \.viewData, on: checkInView)
            .store(in: &bag)
    }

    private lazy var checkInView: EventDetailCheckInView = {
        let view = EventDetailCheckInView()
        view.onClick = { [weak self] in
            guard let self = self,
                  let viewData = self.viewModel.viewData.value,
                  !viewData.arrowHidden else { return }
            if !viewData.arrowActive {
                UDToast.showTips(with: viewData.disableReason, on: self.viewController.view)
            } else {
                self.jumpToCheckInInfo()
            }
        }
        return view
    }()

    private func jumpToCheckInInfo() {
        CalendarTracerV2.EventDetail.traceClick {
            $0.click("open_check_info").target("cal_check_info_view")
            $0.event_type = self.viewModel.model.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.viewModel.model.instance, event: self.viewModel.model.event))
        }

        let vm = EventCheckInInfoViewModel(userResolver: self.userResolver,
                                           calendarID: Int64(self.viewModel.model.calendarId) ?? 0,
                                           key: self.viewModel.model.key,
                                           originalTime: self.viewModel.model.originalTime,
                                           startTime: self.viewModel.model.startTime)
        let vc = EventCheckInInfoViewController(viewModel: vm, userResolver: userResolver)
        let navi = LkNavigationController(rootViewController: vc)
        navi.modalPresentationStyle = .formSheet
        viewController.navigationController?.present(navi, animated: true)
    }
}
