//
//  GuideDialogView.swift
//  LarkGuideUI
//
//  Created by zhenning on 2020/6/7.
//

import Foundation
import UIKit
import UniverseDesignTheme
import UniverseDesignColor

public protocol GuideDialogViewDelegate: AnyObject {
    func didClickClose(dialogView: GuideDialogView)
    func didClickBottomButton(dialogView: GuideDialogView)
}

public final class GuideDialogView: UIView {
    private var config: DialogConfig
    weak var delegate: GuideDialogViewDelegate?
    private var isTitleHidden: Bool {
        return titleLabel.text?.isEmpty ?? true
    }
    /// 容器
    private lazy var containerView: UIView = {
        let _containerView = UIView()
        _containerView.backgroundColor = Style.bgViewBackgroundColor
        _containerView.layer.cornerRadius = Layout.containerCornerRadius
        _containerView.layer.ud.setShadowColor(Style.bgViewShadowColor)
        _containerView.layer.shadowOpacity = Layout.bgViewShadowOpacity
        _containerView.layer.shadowOffset = Layout.bgViewShadowOffset
        return _containerView
    }()
    private(set) lazy var bannerView: UIImageView = {
        let _bannerView = UIImageView()
        _bannerView.contentMode = .scaleAspectFill
        _bannerView.isUserInteractionEnabled = false
        _bannerView.layer.masksToBounds = true
        return _bannerView
    }()
    private lazy var closeButton: UIButton = {
        let _closeButton = UIButton()
        _closeButton.setImage(Resources.closeIcon,
                              for: UIControl.State.normal)
        _closeButton.addTarget(self, action: #selector(didClickCloseBtn),
                               for: UIControl.Event.touchUpInside)
        return _closeButton
    }()
    private lazy var titleLabel: UILabel = {
        let _titleLabel = UILabel()
        _titleLabel.font = Style.titleFont
        _titleLabel.textColor = Style.textColor
        _titleLabel.textAlignment = .center
        _titleLabel.numberOfLines = 0
        return _titleLabel
    }()
    private lazy var detailLabel: UILabel = {
        let _detailLabel = UILabel()
        _detailLabel.font = Style.detailTextFont
        _detailLabel.textColor = Style.textColor
        _detailLabel.textAlignment = .center
        _detailLabel.numberOfLines = 0
        return _detailLabel
    }()
    private lazy var bottomButton: UIButton = {
        let _bottomButton = UIButton()
        _bottomButton.titleLabel?.font = Style.buttonTextFont
        _bottomButton.setTitle(self.config.buttonTitle, for: UIControl.State.normal)
        _bottomButton.setTitleColor(Style.buttonTextColor, for: UIControl.State.normal)
        _bottomButton.addTarget(self, action: #selector(didClickBottomBtn),
                                for: UIControl.Event.touchUpInside)
        _bottomButton.layer.cornerRadius = Layout.bottomCornerRadius
        _bottomButton.backgroundColor = Style.buttonBgColor
        return _bottomButton
    }()

    private var hasTitle: Bool {
        return !(config.title ?? "").isEmpty
    }
    private var hasDetial: Bool {
        return !(config.detail ?? "").isEmpty
    }

    init(dialogConfig: DialogConfig) {
        self.config = dialogConfig
        super.init(frame: .zero)
        setupUI()
        setupLayouts()
    }

    func setupUI() {
        self.backgroundColor = .clear

        self.addSubview(self.containerView)
        self.containerView.addSubview(self.bannerView)
        self.containerView.addSubview(self.closeButton)

        if let titleText = config.title {
            self.titleLabel.text = titleText
        }
        self.containerView.addSubview(self.titleLabel)

        self.detailLabel.text = config.detail
        self.containerView.addSubview(self.detailLabel)
        self.containerView.addSubview(self.bottomButton)
    }

    func setupLayouts() {
        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        bannerView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.bannerHeight)
        }
        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(Layout.closeButtonSize)
            make.top.equalTo(Layout.closeButtonPadding)
            make.trailing.equalTo(-Layout.closeButtonPadding)
        }
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(bannerView.snp.bottom).offset(Layout.titleTop)
            make.leading.equalToSuperview().offset(Layout.contentInset)
            make.trailing.equalToSuperview().offset(-Layout.contentInset)
        }
        detailLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        detailLabel.snp.makeConstraints { (make) in
            if isTitleHidden {
                make.top.equalTo(bannerView.snp.bottom).offset(Layout.detailTop)
            } else {
                make.top.equalTo(titleLabel.snp.bottom).offset(Layout.detailTop)
            }
            make.leading.equalToSuperview().offset(Layout.contentInset)
            make.trailing.equalToSuperview().offset(-Layout.contentInset)
        }
        bottomButton.snp.makeConstraints { (make) in
            make.top.equalTo(detailLabel.snp.bottom).offset(Layout.buttonTop)
            make.leading.equalTo(Layout.contentInset)
            make.trailing.equalTo(-Layout.contentInset)
            make.height.equalTo(Layout.buttonHeight)
            make.bottom.equalTo(-Layout.buttonBottom)
        }
    }

    override public var intrinsicContentSize: CGSize {
        var viewHeight: CGFloat = Layout.bannerHeight
        let textPrepareSize = CGSize(width: Layout.viewWidth - Layout.contentInset * 2,
                                     height: CGFloat.greatestFiniteMagnitude)
        let titleHeight = titleLabel.sizeThatFits(textPrepareSize).height
        let detailHeight = detailLabel.sizeThatFits(textPrepareSize).height
        if hasTitle {
            viewHeight += Layout.titleTop + titleHeight
        }
        if hasDetial {
            viewHeight += Layout.detailTop + detailHeight
        }
        viewHeight += Layout.buttonTop + Layout.buttonHeight + Layout.buttonBottom
        return CGSize(width: Layout.viewWidth, height: viewHeight)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func didClickCloseBtn() {
        self.delegate?.didClickClose(dialogView: self)
    }

    @objc
    func didClickBottomBtn() {
        self.delegate?.didClickBottomButton(dialogView: self)
    }
}

extension GuideDialogView {
    enum Layout {
        static let viewWidth: CGFloat = 300
        static let containerCornerRadius: CGFloat = 8
        static let contentInset: CGFloat = 20
        static let bannerHeight: CGFloat = 167
        static let titleTop: CGFloat = 16
        static let detailTop: CGFloat = 8
        static let closeButtonSize: CGSize = CGSize(width: 15, height: 15)
        static let closeButtonPadding: CGFloat = 15
        static let bottomCornerRadius: CGFloat = 6
        static let buttonTop: CGFloat = 24
        static let buttonHeight: CGFloat = 40
        static let buttonBottom: CGFloat = 20
        static let bgViewShadowOpacity: Float = 0.3
        static let bgViewShadowOffset: CGSize = CGSize(width: 0, height: 5)
    }
    enum Style {
        static let titleFont: UIFont = .systemFont(ofSize: 20.0, weight: UIFont.Weight(rawValue: 600))
        static let detailTextFont: UIFont = .systemFont(ofSize: 16.0, weight: UIFont.Weight(rawValue: 500))
        static let textColor: UIColor = UIColor.ud.primaryOnPrimaryFill
        static let buttonTextFont: UIFont = .systemFont(ofSize: 16.0, weight: UIFont.Weight(rawValue: 500))
        static let buttonTextColor: UIColor = UIColor.ud.udtokenTagTextBlue
        static let buttonBgColor: UIColor = UIColor.ud.primaryOnPrimaryFill
        static let bgViewShadowColor = UIColor.ud.shadowPriLg
        static let bgViewBackgroundColor = UIColor.ud.primaryFillHover
    }
}
