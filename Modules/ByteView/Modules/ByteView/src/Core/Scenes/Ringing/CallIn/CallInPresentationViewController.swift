//
//  CallInPresentationViewController.swift
//  ByteView
//
//  Created by liuning.cn on 2020/9/27.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation

final class CallInPresentationViewController: PresentationViewController {
    private let viewModel: CallInViewModel
    init(viewModel: CallInViewModel) {
        self.viewModel = viewModel
        super.init(router: viewModel.service.router, fullScreenFactory: { () -> UIViewController in
            let viewController = CallInViewController(viewModel: viewModel)
            return viewController
        }, floatingFactory: {
            viewModel.hasShownFloating = true
            if viewModel.callInType.isPhoneCall && Display.phone {
                let floatingViewModel = SimpleFloatingViewModel(session: viewModel.meeting)
                return SimpleFloatingViewController(viewModel: floatingViewModel)
            } else {
                let floatVM = FloatingPreMeetVM(session: viewModel.meeting,
                                                service: viewModel.service,
                                                avatarInfo: viewModel.avatarInfo,
                                                topic: viewModel.name,
                                                meetingStatus: viewModel.floatDescription)
                return FloatingPreMeetingVC(viewModel: floatVM)
            }
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
