//
//  VMViewController.swift
//  ByteView
//
//  Created by kiri on 2020/7/26.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation

class VMViewController<ViewModel>: BaseViewController {
    private var shouldBindViewModelAfterLoaded = false

    final var viewModel: ViewModel! {
        didSet {
            if isViewLoaded {
                bindViewModel()
            } else {
                shouldBindViewModelAfterLoaded = true
            }
        }
    }

    convenience init(viewModel: ViewModel) {
        self.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
        self.shouldBindViewModelAfterLoaded = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        if shouldBindViewModelAfterLoaded {
            shouldBindViewModelAfterLoaded = false
            bindViewModel()
        }
    }

    /// override point for subclass. Do not call directly
    func setupViews() {}

    /// override point for subclass. Do not call directly
    func bindViewModel() {}
}
