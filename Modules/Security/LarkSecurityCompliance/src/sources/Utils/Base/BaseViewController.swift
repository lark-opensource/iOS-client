//
//  BaseViewController.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/21.
//

import LarkUIKit
import UniverseDesignToast
import RxSwift
import RxCocoa

open class BaseViewController<T: ViewModel>: BaseUIViewController {

    public let viewModel: T

    public required init(viewModel: T) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        let coordinator = ViewModelCoordinatorImp(controller: self)
        viewModel.setupCoordinator(coordinator)
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad.onNext(())
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewDidAppear.onNext(())
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear.onNext(())
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.viewWillDisappear.onNext(())
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.viewDidDisappear.onNext(())
    }
}
