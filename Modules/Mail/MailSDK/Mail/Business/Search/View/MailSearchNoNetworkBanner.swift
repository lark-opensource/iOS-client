//
//  MailSearchNoNetworkBanner.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/11/30.
//

import Foundation
import FigmaKit
import UniverseDesignIcon

class NiblessView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  @available(*, unavailable, message: "Loading this view from a nib is unsupported")
  required init?(coder aDecoder: NSCoder) {
    fatalError("Loading this view from a nib is unsupported")
  }
}

final class MailSearchNoNetworkBanner: NiblessView {
    struct Param {
        let title: String
        let actionText: String
        let icon: UIImage
    }
    private let iconView = UIImageView()
    private lazy var actionLabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.textAlignment = .right
        return label
    }()
    private let titleLabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    private let content = UIView()

    private lazy var blurView: BackgroundBlurView = {
        let view = BackgroundBlurView()
        view.blurRadius = 20
        view.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.75)
        return view
    }()

    
    let textMargin: CGFloat = 12.0
    let textTopPadding: CGFloat = 14.0
    let IconMargin: CGFloat = 20.0
    let IconTopPadding: CGFloat = 15.0
    let IconAndTitleMargin: CGFloat = 8.0
    let IconWidth: CGFloat = 18.0
    let actionTextHeight: CGFloat = 20.0
    var needWarp: Bool = false
    
    var viewWidth: CGFloat
    var scene: MailSearchScene
    var bannerHeight: CGFloat = 0.0
    let param: Param = Param(title: BundleI18n.MailSDK.Mail_OfflineSearch_NoInternetOnlySearchLocalMails_Banner,
                             actionText: BundleI18n.MailSDK.Mail_OfflineSearch_NoInternetOnlySearchLocalMailsRetry_Button,
                             icon: UDIcon.cloudFailedOutlined.ud.withTintColor(.ud.iconN2))
    var didTapHeader: (() -> Void)?

    init(viewWidth: CGFloat, scene: MailSearchScene) {
        self.viewWidth = viewWidth
        self.scene = scene
        super.init(frame: .zero)
        calculateHeight()
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        titleLabel.text = scene == .inSearchTab ? BundleI18n.MailSDK.Mail_ASLOfflineSearch_ResultsLimited_Text : param.title
        actionLabel.text = param.actionText
        iconView.image = param.icon
        lu.addTapGestureRecognizer(action: #selector(didClickHeader), target: self)
        if scene == .inSearchTab {
            addSubview(blurView)
            blurView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            content.backgroundColor = .clear
        } else {
            content.backgroundColor = UIColor.ud.bgFloatOverlay
        }
        addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        content.addSubview(iconView)
        content.addSubview(titleLabel)
        content.addSubview(actionLabel)
        
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textTitle
        actionLabel.font = UIFont.systemFont(ofSize: 14)
        actionLabel.textColor = UIColor.ud.textLinkNormal
        if needWarp {
            titleLabel.snp.makeConstraints { make in
                make.top.equalTo(textTopPadding)
                make.left.equalTo(iconView.snp.right).offset(8)
                make.right.equalToSuperview().offset(-textMargin)
            }
            actionLabel.textAlignment = .left
            actionLabel.snp.makeConstraints { (make) in
                make.right.equalToSuperview().inset(16)
                make.left.equalTo(titleLabel.snp.left)
                make.top.equalTo(titleLabel.snp.bottom).offset(4)
                make.height.equalTo(20)
            }
        } else {
            actionLabel.textAlignment = .right
            actionLabel.snp.makeConstraints { (make) in
                make.right.equalToSuperview().offset(-textMargin)
                make.centerY.equalToSuperview()
                make.height.equalTo(actionTextHeight)
            }
            titleLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(iconView.snp.right).offset(8)
                make.right.equalTo(actionLabel.snp.left).offset(-textMargin)
            }
        }
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(IconMargin)
            if needWarp {
                make.top.equalTo(IconTopPadding)
            } else {
                make.centerY.equalToSuperview()
            }
            make.size.equalTo(CGSize(width: IconWidth, height: IconWidth))
        }
    }
    
    private func calculateHeight() {
        let textHeight: CGFloat = 68
        let title = scene == .inSearchTab ? BundleI18n.MailSDK.Mail_ASLOfflineSearch_ResultsLimited_Text : param.title
        let titleWidth = title.getTextWidth(font: UIFont.systemFont(ofSize: 14), height: textHeight)
        let actionTextWidth = param.actionText.getTextWidth(font: UIFont.systemFont(ofSize: 14), height: textHeight)
        if IconMargin + IconWidth + IconAndTitleMargin + titleWidth + textMargin + actionTextWidth + textMargin > viewWidth {
            needWarp = true
        }
        if needWarp {
            let bannerMinHeight: CGFloat = 68.0
            let paddingBottom: CGFloat = 12
            let gap: CGFloat = 8
            let paddingTop: CGFloat = 12
            let textMaxWidth = viewWidth - IconMargin - IconWidth - IconAndTitleMargin - textMargin
            let titleHeight = title.getTextHeight(font: UIFont.systemFont(ofSize: 14),
                                                        width: textMaxWidth)
            bannerHeight = max(paddingBottom + titleHeight + gap + actionTextHeight + paddingTop, bannerMinHeight)
        } else {
            bannerHeight = CGFloat(48.0)
        }
    }

    @objc
    private func didClickHeader() {
        didTapHeader?()
    }
}
