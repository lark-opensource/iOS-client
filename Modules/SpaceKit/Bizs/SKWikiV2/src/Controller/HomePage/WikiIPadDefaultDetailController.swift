//
//  WikiIPadDefaultDetailController.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2023/9/27.
//

import UIKit
import SnapKit
import UniverseDesignEmpty
import UniverseDesignLoading
import SKResource

class WikiIPadDefaultDetailController: UIViewController {

    enum InitialState {
        case loading
        case empty
    }

    private lazy var loadingView = UDLoadingImageView(lottieResource: nil)
    private lazy var emptyView: UDEmptyView = {
        let config = UDEmptyConfig(titleText: BundleI18n.SKResource.CreationMobile_Wiki_PageDeleted_Toast, type: .noContent)
        let view = UDEmptyView(config: config)
        view.useCenterConstraints = true
        return view
    }()

    let initialState: InitialState

    init(initialState: InitialState) {
        self.initialState = initialState
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupUI() {
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        loadingView.play()

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyView.isHidden = true

        switch initialState {
        case .empty:
            showEmptyPage()
        case .loading:
            showLoading()
        }
    }

    func showEmptyPage() {
        loadingView.stop()
        loadingView.isHidden = true
        emptyView.isHidden = false
    }

    func showLoading() {
        emptyView.isHidden = true
        loadingView.isHidden = false
        loadingView.play()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection.horizontalSizeClass == .compact else { return }
        guard let navigationController else { return }
        if let index = navigationController.viewControllers.firstIndex(of: self) {
            navigationController.viewControllers.remove(at: index)
        }
    }
}
