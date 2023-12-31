//
//  EventDetailTableVideoLiveComponent.swift
//  Calendar
//
//  Created by Rico on 2021/4/22.
//

import Foundation
import SnapKit
import LarkCombine
import RoundedHUD
import LarkContainer
import LarkUIKit
import EENavigator
import RxSwift
import RxRelay
import CalendarFoundation

final class EventDetailTableVideoLiveComponent: UserContainerComponent {

    let viewModel: EventDetailTableVideoLiveViewModel
    var bag: Set<AnyCancellable> = []
    let rxBag = DisposeBag()

    init(viewModel: EventDetailTableVideoLiveViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(liveHostView)
        liveHostView.snp.edgesEqualToSuperView()

        bindViewModel()
        bindView()
    }

    private func bindViewModel() {

        guard let viewController = viewController else { return }

        viewModel.viewData
            .compactMap { $0 }
            .receive(on: DispatchQueue.main.ocombine)
            .sink(receiveValue: { [weak self] (viewData) in
                guard let self = self else { return }
                self.liveHostView.updateContent(viewData)
            })
            .store(in: &bag)

        viewModel.rxToast
            .bind(to: viewController.rx.toast)
            .disposed(by: rxBag)

        viewModel.rxRoute
            .subscribeForUI(onNext: { [weak self] route in
                guard let self = self, let viewController = self.viewController else { return }
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
                }
            }).disposed(by: rxBag)
    }

    private func bindView() {
        liveHostView.tapAction = { [weak self] in
            guard let self = self else { return }
            self.viewModel.action(.tapVideo)
        }
    }

    private lazy var liveHostView: DetailVideoLiveHostCellV2 = {
        let liveHostView = DetailVideoLiveHostCellV2()
        return liveHostView
    }()
}
