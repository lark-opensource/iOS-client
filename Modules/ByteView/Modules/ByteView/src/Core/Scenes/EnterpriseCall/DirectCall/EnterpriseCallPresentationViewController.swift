//
//  EnterpriseCallPresentationViewController.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/7/1.
//

import UIKit

final class EnterpriseCallPresentationViewController: PresentationViewController {
    init(viewModel: EnterpriseCallViewModel) {
        super.init(router: viewModel.service.router, fullScreenFactory: { () -> UIViewController in
            return EnterpriseCallViewController(viewModel: viewModel)
        }, floatingFactory: {
            viewModel.isFromFloating = true
            let floatingViewModel = SimpleFloatingViewModel(session: viewModel.session)
            return SimpleFloatingViewController(viewModel: floatingViewModel)
        })
    }

    private var isFirstAppear = true
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstAppear {
            isFirstAppear = false
            Toast.unblockToastOnVCScene(showBlockedToast: true)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
