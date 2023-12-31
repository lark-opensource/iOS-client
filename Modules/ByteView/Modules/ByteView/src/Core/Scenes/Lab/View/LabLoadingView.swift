//
//  LabLoadingView.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/7/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RichLabel
import ByteViewUI

class LabLoadingView: UIView {

    enum Status {
        case loading
        case failed
        case none
        case notAllowBackground
        case notAllowAnimoji
    }

    var status: Status = .loading {
        didSet {
            statusChanged()
        }
    }

    private lazy var loadingView: LoadingView = LoadingView(style: .blue)

    private lazy var loadingLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: I18n.View_MV_LoadingSpecialEffects, config: .bodyAssist)
        label.textColor = .ud.textCaption
        return label
    }()

    private lazy var loadingContainerView: UIView = {
        let stackView = UIStackView(arrangedSubviews: [loadingView, loadingLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8

        loadingView.snp.makeConstraints { maker in
            maker.size.equalTo(24)
        }
        return stackView
    }()

    private lazy var reloadLabel: LKLabel = {
        let label = LKLabel()
        label.backgroundColor = .clear
        return label
    }()

    private lazy var notAllowLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .ud.textPlaceholder
        label.isHidden = true
        return label
    }()

    var reloadHandler: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var lastSceneBounds: CGRect = .zero
    private func setupViews() {
        addSubview(loadingContainerView)
        loadingContainerView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        addSubview(reloadLabel)
        reloadLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        addSubview(notAllowLabel)
        notAllowLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        self.lastSceneBounds = VCScene.bounds
        resetReloadLabelLayout()
        self.vc.windowSceneLayoutContextObservable.addObserver(self) { [weak self] _, _ in
            guard let self = self else { return }
            let sceneBounds = VCScene.bounds
            if self.lastSceneBounds != sceneBounds {
                self.lastSceneBounds = sceneBounds
                self.resetReloadLabelLayout()
            }
        }
    }

    private func resetReloadLabelLayout() {
        var text = I18n.View_MV_InternetErrorTryAgain
        let maxWidth = VCScene.bounds.width - 16 * 2
        let font = UIFont.systemFont(ofSize: 14, weight: .regular)
        if let (content, range) = StringUtil.handleTextWithLineBreak(text, font: font, maxWidth: maxWidth) {
            text = content
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.colorfulBlue,
                              NSAttributedString.Key.backgroundColor: UIColor.clear,
                              NSAttributedString.Key.font: font]
            var link = LKTextLink(range: range,
                                  type: .link,
                                  attributes: attributes,
                                  activeAttributes: attributes,
                                  inactiveAttributes: attributes)
            link.linkTapBlock = { [weak self] (_, _) in
                self?.reloadHandler?()
            }
            reloadLabel.removeLKTextLink()
            reloadLabel.addLKTextLink(link: link)
        }
        reloadLabel.attributedText = NSAttributedString.init(string: text,
                                                             config: .bodyAssist,
                                                             alignment: .center,
                                                             lineBreakMode: .byWordWrapping,
                                                             textColor: UIColor.ud.textPlaceholder)
    }

    private func statusChanged() {
        switch status {
        case .loading:
            self.isHidden = false
            loadingContainerView.isHidden = false
            reloadLabel.isHidden = true
            notAllowLabel.isHidden = true
            loadingView.play()
        case .failed:
            self.isHidden = false
            loadingContainerView.isHidden = true
            reloadLabel.isHidden = false
            notAllowLabel.isHidden = true
            loadingView.stop()
        case .none:
            self.isHidden = true
            loadingView.stop()
        case .notAllowBackground:
            self.isHidden = false
            loadingContainerView.isHidden = true
            reloadLabel.isHidden = true
            notAllowLabel.isHidden = false
            notAllowLabel.text = I18n.View_G_HostNotAllowBackUseThisMeeting
            loadingView.stop()
        case .notAllowAnimoji:
            self.isHidden = false
            loadingContainerView.isHidden = true
            reloadLabel.isHidden = true
            notAllowLabel.isHidden = false
            loadingView.stop()
            notAllowLabel.text = I18n.View_G_HostNotAllowAvatarThisMeeting
        }
    }
}
