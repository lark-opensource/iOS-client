//
//  WebAppMenuAdditionExtendView.swift
//  WebBrowser
//
//  Created by 邓波 on 2022/1/12.
//

import ByteWebImage
import FigmaKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignIcon
import UIKit
import LarkOPInterface
import LKCommonsLogging
import WebBrowser

public protocol WebAppMenuAddtionProtocol {
    func updateModel(for model: WebAppMenuAdditionViewModel)
    func updateReviewInfo(for appReviewInfo: AppReviewInfo?)
}

public enum WebAppMenuAdditionStyle: String {
    case normal // 普通样式，只有icon和name
    case review // 带评分信息的样式
}

extension WebAppMenuAdditionStyle {
    /// 头部高度
    fileprivate var additionViewHeight: CGFloat {
        switch self {
        case .normal:
            return 48
        case .review:
            return 80
        }
    }
    /// 图片宽度和长度
    fileprivate var iconWidthAndHeight: CGFloat {
        switch self {
        case .normal:
            return 24
        case .review:
            return 48
        }
    }
    /// 图片圆角
    fileprivate var iconImageCornerRadius: CGFloat {
        switch self {
        case .normal:
            return 6
        case .review:
            return 12
        }
    }
    /// 应用名称字体大小
    fileprivate var titleFont: UIFont {
        switch self {
        case .normal:
            return .systemFont(ofSize: 16)
        case .review:
            return .systemFont(ofSize: 17, weight: .medium)
        }
    }
    /// 标签的左边距
    fileprivate var titleLeftSpacing: CGFloat {
        switch self {
        case .normal:
            return 8
        case .review:
            return 12
        }
    }
    /// 头部视图的边距
    fileprivate var additionViewSpacing: CGFloat {
        return 16
    }
}

/// 网页应用菜单头部视图，带头像和标题
public final class WebAppMenuAdditionExtendView: UIView, WebAppMenuAddtionProtocol {
    /// 默认的应用头像
    private let defaultImage = BundleResources.WebBrowser.web_app_header_icon
    /// 默认的应用名称
    private let defaultName = BundleI18n.EcosystemWeb.OpenPlatform_AppActions_LoadingDesc
    
    static let logger = Logger.ecosystemWebLog(WebAppMenuAdditionExtendView.self, category: "WebAppMenuAdditionExtendView")
    
    private var needShowReviewInfo: Bool {
        switch style {
        case .normal:
            return false
        case .review:
            return true
        }
    }

    /// 头像视图
    private lazy var iconImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.layer.masksToBounds = true
        imgView.layer.ux.setSmoothCorner(radius: style.iconImageCornerRadius)
        imgView.layer.ux.setSmoothBorder(width: 1 / UIScreen.main.scale, color: UIColor.ud.lineDividerDefault)
        return imgView
    }()

    /// 标签视图
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = style.titleFont
        return label
    }()
    
    /// 评分文案
    private lazy var reviewDescLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    /// 评分分数
    private lazy var reviewScoreContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.Y100
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }()
    private lazy var reviewScoreIcon: UIImageView = {
        UIImageView(image: UDIcon.collectFilled.ud.withTintColor(UIColor.ud.colorfulYellow))
    }()
    private lazy var reviewScoreLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.udtokenTagTextSYellow
        label.font = .systemFont(ofSize: 12, weight: .medium)
        return label
    }()
    
    /// 评分按钮
    private lazy var reviewButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(jumpToReview), for: .touchUpInside)
        return button
    }()
    
    /// 评分按钮右侧箭头
    private lazy var reviewArrowIcon: UIImageView = {
        let icon = UIImageView(image: UDIcon.rightSmallCcmOutlined.ud.withTintColor(UIColor.ud.iconN2))
        icon.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(jumpToReview))
        icon.addGestureRecognizer(tap)
        return icon
    }()

    @objc
    private func jumpToReview(sender: Any) {
        guard let handler = reviewHandler else {
            WebAppMenuAdditionExtendView.logger.error("no review handler")
            return
        }
        handler()
    }
    
    private var model: WebAppMenuAdditionViewModel
    private var style: WebAppMenuAdditionStyle
    
    public var reviewHandler: (() -> Void)?

    public init(model: WebAppMenuAdditionViewModel, style: WebAppMenuAdditionStyle) {
        self.model = model
        self.style = style
        super.init(frame: .zero)
        setupSubviews()
        updateSubviewsConstraint()
        updateModel(for: model)
        updateReviewInfo(for: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(reviewDescLabel)
        addSubview(reviewScoreContainer)
        reviewScoreContainer.addSubview(reviewScoreIcon)
        reviewScoreContainer.addSubview(reviewScoreLabel)
        addSubview(reviewButton)
        addSubview(reviewArrowIcon)
    }
    
    private func updateSubviewsConstraint() {
        self.snp.makeConstraints { make in
            make.height.equalTo(style.additionViewHeight)
        }
        iconImageView.snp.makeConstraints { make in
            make.leading.equalTo(style.additionViewSpacing)
            make.width.height.equalTo(style.iconWidthAndHeight)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            if needShowReviewInfo {
                make.top.equalTo(self.iconImageView).offset(2)
            } else {
                make.centerY.equalTo(self.iconImageView)
            }
            make.leading.equalTo(iconImageView.snp.trailing).offset(style.titleLeftSpacing)
            make.trailing.lessThanOrEqualToSuperview().offset(-style.additionViewSpacing)
        }
        reviewDescLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
        reviewScoreContainer.snp.makeConstraints { make in
            make.leading.equalTo(reviewDescLabel.snp.trailing).offset(4)
            make.centerY.equalTo(reviewDescLabel)
            make.size.equalTo(CGSize(width: 42, height: 18))
            make.trailing.lessThanOrEqualTo(reviewButton.snp.leading).offset(-4)
        }
        reviewScoreIcon.snp.makeConstraints { make in
            make.leading.equalTo(4.5)
            make.size.equalTo(CGSize(width: 11, height: 10.5))
            make.centerY.equalToSuperview()
        }
        reviewScoreLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(reviewScoreIcon.snp.trailing).offset(4.5)
        }
        reviewArrowIcon.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.trailing.equalToSuperview().offset(-style.additionViewSpacing)
            make.centerY.equalTo(reviewDescLabel)
        }
        reviewButton.snp.makeConstraints { make in
            make.centerY.equalTo(reviewDescLabel)
            make.trailing.equalTo(reviewArrowIcon.snp.leading).offset(-2)
            make.height.equalTo(20)
        }
    }

    public func updateModel(for model: WebAppMenuAdditionViewModel) {
        self.model = model
        updateIcon(for: model.iconKey)
        updateName(for: model.name)
    }

    private func updateName(for name: String?) {
        titleLabel.text = name ?? self.defaultName
    }

    private func updateIcon(for key: String?) {
        guard let key = key else {
            iconImageView.image = self.defaultImage
            return
        }
        iconImageView.bt.setLarkImage(with: .avatar(key: key, entityID: "", params: .init(sizeType: .size(style.iconWidthAndHeight))))
    }
    
    public func updateReviewInfo(for appReviewInfo: AppReviewInfo?) {
        // 普通样式时，全部隐藏
        guard needShowReviewInfo else {
            hideReviewUI(true)
            return
        }
        
        // 评分样式时，如果没有评分信息，展示未评分UI
        guard let appReviewInfo = appReviewInfo else {
            showUnreviewUI()
            return
        }
        
        if appReviewInfo.isReviewed {
            showReviewedUI(appReviewInfo: appReviewInfo)
        } else {
            showUnreviewUI()
        }
    }
    
    private func hideReviewUI(_ hidden: Bool) {
        reviewDescLabel.isHidden = hidden
        reviewScoreContainer.isHidden = hidden
        reviewButton.isHidden = hidden
        reviewArrowIcon.isHidden = hidden
    }
    
    private func showUnreviewUI() {
        reviewDescLabel.isHidden = false
        reviewDescLabel.text = BundleI18n.EcosystemWeb.OpenPlatform_AppRating_NotRatedYet
        reviewScoreContainer.isHidden = true
        reviewButton.isHidden = false
        reviewButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        reviewButton.setTitle(BundleI18n.EcosystemWeb.OpenPlatform_AppRating_GoToRateLink, for: .normal)
        reviewArrowIcon.isHidden = true
        reviewArrowIcon.snp.updateConstraints { make in
            make.width.height.equalTo(0)
        }
    }
    
    private func showReviewedUI(appReviewInfo: AppReviewInfo) {
        hideReviewUI(false)
        reviewDescLabel.text = BundleI18n.EcosystemWeb.OpenPlatform_AppRating_MyRatingTtl
        reviewScoreLabel.text = String(format: "%.1f", Float(appReviewInfo.score))
        reviewButton.setTitleColor(UIColor.ud.textCaption, for: .normal)
        reviewButton.setTitle(BundleI18n.EcosystemWeb.OpenPlatform__AppRating_UpdateRatingLink, for: .normal)
        reviewArrowIcon.snp.updateConstraints { make in
            make.width.height.equalTo(16)
        }
    }
}

extension WebAppMenuAdditionExtendView: MenuForecastSizeProtocol {
    public func forecastSize() -> CGSize {
        // 这个view只会在iphone上使用，所以这里暂时先使用UIScreen
        return CGSize(width: UIScreen.main.bounds.width, height: style.additionViewHeight)
    }

    public func reallySize(for suggestionSize: CGSize) -> CGSize {
        forecastSize()
    }
}
