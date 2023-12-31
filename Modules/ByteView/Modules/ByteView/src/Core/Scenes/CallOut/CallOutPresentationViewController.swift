//
//  CallOutPresentationViewController.swift
//  ByteView
//
//  Created by liuning.cn on 2020/9/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation

final class CallOutPresentationViewController: PresentationViewController {
    private let viewModel: CallOutViewModel
    init(viewModel: CallOutViewModel) {
        self.viewModel = viewModel
        super.init(router: viewModel.service.router, fullScreenFactory: { () -> UIViewController in
            return CallOutViewController(viewModel: viewModel)
        }, floatingFactory: {
            viewModel.hasShownFloating = true
            return FloatingPreMeetingVC(viewModel: viewModel.floatVM)
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
