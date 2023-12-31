//
//  BusinessLoadingView.swift
//  ByteView
//
//  Created by chentao on 2019/12/3.
//

import UIKit
import SnapKit
import ByteViewCommon
import UniverseDesignEmpty
import UniverseDesignColor

open class BusinessLoadingView: UIView, AsyncLoadingProtocol {

    var tappedAction: (() -> Void)?

    private let loadingView: LoadingPlaceholderView = {
        let loading = LoadingPlaceholderView(style: .center)
        loading.isHidden = true
        loading.backgroundColor = .clear
        loading.text = I18n.View_VM_Loading
        loading.label.font = .systemFont(ofSize: 14)
        return loading
    }()

    lazy var serverErrorView: UDEmptyView = {
        let msg = I18n.View_G_CouldNotLoadTryReloading
        let text = LinkTextParser.parsedLinkText(from: msg)
        let linkTextComponent = text.components.first
        let labelHandler = { [weak self] in
            guard self?.tappedAction?() != nil else {
                return
            }
        }
        let emptyView = UDEmptyView(config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: NSAttributedString(string: text.result, config: .bodyAssist), operableRange: linkTextComponent?.range), imageSize: 100, spaceBelowImage: 16, spaceBelowTitle: 0, spaceBelowDescription: 0, type: .loadingFailure, labelHandler: labelHandler))
        emptyView.isHidden = true
        emptyView.backgroundColor = .clear

        return emptyView
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(loadingView)
        addSubview(serverErrorView)
        autolayoutSubviews()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func autolayoutSubviews() {
        loadingView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        serverErrorView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    public func showLoading() {
        playIfNeeded { [weak self] in
            guard let self = self else { return }
            self.serverErrorView.isHidden = true
            self.loadingView.isHidden = false
            self.bringSubviewToFront(self.loadingView)
        }
    }

    public func hideLoading() {
        stopIfNeeded { [weak self] in
            self?.removeFromSuperview()
        }
    }

    public func showFailed(retryAction: (() -> Void)?) {
        loadingView.isHidden = true
        serverErrorView.isHidden = false
        bringSubviewToFront(serverErrorView)
        self.tappedAction = retryAction
    }

    public override var isHidden: Bool {
        didSet {
            loadingView.isHidden = isHidden
        }
    }

}
