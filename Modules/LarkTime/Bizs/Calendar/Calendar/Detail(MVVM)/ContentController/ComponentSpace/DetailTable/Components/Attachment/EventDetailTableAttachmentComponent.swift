//
//  EventDetailTableAttachmentComponent.swift
//  Calendar
//
//  Created by Rico on 2021/4/21.
//

import UIKit
import LarkCombine
import LarkContainer
import LarkFoundation
import LarkUIKit
import EENavigator
import CalendarFoundation

final class EventDetailTableAttachmentComponent: UserContainerComponent {
    let viewModel: EventDetailTableAttachmentViewModel
    var bag: Set<AnyCancellable> = []

    @ScopedInjectedLazy
    var calendarDependency: CalendarDependency?

    init(viewModel: EventDetailTableAttachmentViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(attachmentView)
        attachmentView.snp.edgesEqualToSuperView()

        bindViewModel()
    }

    private func bindViewModel() {
        attachmentView.viewData = viewModel.viewData.value
        viewModel.viewData
            .assignUI(to: \.viewData, on: attachmentView)
            .store(in: &bag)

        viewModel.route
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] (route) in
                guard let self = self,
                      let viewController = self.viewController else { return }
                switch route {
                case .preview(let token):
                    self.calendarDependency?.jumpToAttachmentPreviewController(token: token, from: viewController)
                case .googleLink(let url):
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                case .urlLink(let url, let token):
                    if token.isEmpty {
                        guard let url = URL(string: url) else {
                            EventDetail.logError("cannot jump General url: \(url)")
                            return
                        }
                        self.userResolver.navigator.push(url, from: viewController)
                    } else {
                        self.calendarDependency?.jumpToAttachmentPreviewController(token: token, from: viewController)
                    }
                }
            }.store(in: &bag)
    }

    private lazy var attachmentView: EventDetailTableAttachmentView = {
        return EventDetailTableAttachmentView { [weak self] index in
            guard let self = self else { return }
            self.viewModel.clickAttachment(at: index)
        }
    }()
}
