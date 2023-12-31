//
//  AppMenuAppRatingAdditionView.swift
//  TTMicroApp
//
//  Created by xingjinhao on 2021/12/23.
//

import UIKit
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignColor
import OPFoundation
import FigmaKit
import LarkOPInterface
import UniverseDesignFont


@objc
public enum AppRatingAdditionViewStyle: Int {
    case normal
    case userRating
}

@objc
/// 小程序菜单头部的附加视图，显示小程序评分或者普通样式
final class AppMenuAppRatingAdditionView: UIView {
    /// 当前菜单头部显示普通样式还是评分样式
    private var style: AppRatingAdditionViewStyle
    
    /// 附加视图的高度
    private var additionViewHeight: CGFloat { showUserRatingInfo ? 80 : 48 }
    /// 头像的大小
    private var iconWidthAndHeight: CGFloat { showUserRatingInfo ? 48 : 24 }
    /// 头像圆角
    private var iconImageCornerRadius: CGFloat { showUserRatingInfo ? 12 : 8 }
    /// 头像边框的宽度
    private var iconImageBorderWidht: CGFloat { showUserRatingInfo ? 1 / UIScreen.main.scale : 0 }
    /// 头像边框颜色
    private let iconImageBorderColor = UIColor.ud.N900.withAlphaComponent(0.1)
    /// 默认的应用头像
    private let defaultImage = UIImage.bdp_imageNamed("app_header_icon_default")
    
    /// 应用名称字号
    private var titleFont: UIFont { showUserRatingInfo ? .systemFont(ofSize: 17, weight: .medium) : .systemFont(ofSize: 16)}
    /// 应用名称高度
    private let titleHeight: CGFloat = 24
    /// 应用名称左边距
    private let titleLeftSpacing: CGFloat = 12
    /// 应用名称最小宽度
    private let minTitleWidth: CGFloat = 44
    /// 应用名称颜色
    private let titleColor = UIColor.ud.textTitle
    /// 默认的应用名称
    private let defaultName = BDPI18n.openPlatform_AppActions_LoadingDesc
    /// 当有权限视图时应用名称的右边距
    private let titleRightSpacingWhenDisplayPrivacyView: CGFloat = 16
    
    /// 引导文案字号
    private let guideTitleFont = UIFont.systemFont(ofSize: 14)
    /// 引导文案上边距
    private let guideTitleTopSpacing: CGFloat = 4
    /// 引导文案颜色
    private let guideTitleColor = UIColor.ud.textCaption
    
    /// 附加视图左边距
    private let additionViewLeftSpacing: CGFloat = 16
    /// 附加视图右边距
    private let additionViewRightSpacing: CGFloat = 16

    /// 评分星级视图左边距
    private let scoreStarViewLeftSpacing: CGFloat = 4
    /// 评分星级视图圆角弧度
    private let scoreStarCornerRadius: CGFloat = 4
    /// 评分星级视图长度
    private let scoreStarViewWidth: CGFloat = 42
    /// 评分星级视图高度
    private let scoreStarViewHeight: CGFloat = 18
    
    /// 我要评分视图右边距
    private let toAppRatingViewRightSpacing: CGFloat = 20
    /// 我要评分视图高度
    private let toAppRatingViewHeight: CGFloat = 20
    
    /// 根据style选择是否显示用户评分
    private var showUserRatingInfo: Bool {
        switch style {
        case .normal:
            return false
        case .userRating:
            return true
        }
    }

    /// 头像
    private var iconImageView: UIImageView?
    /// 名称
    private var titleView: UILabel?
    /// 小程序评分引导文案
    private var guideTitleView: UILabel?
    /// 权限附着视图
    private var appAdditionView: AppMenuAdditionView?
    /// 是否显示权限视图
    private var isShowAppAdditionView = false
    /// 评分展示星级视图
    private var scoreStarView: ScoreStarView?
    /// 评分跳转视图
    private var toAppRatingView: ToAppRatingView?
    /// 附加视图的数据模型
    private var model: AppMenuAppRatingAdditionViewModel
    
    @objc
    private func jumpToReview(sender: Any) {
        reviewHandler?()
    }
    public var reviewHandler: (() -> Void)?

    /// 权限视图的事件代理
    @objc public weak var privacyActionDelegate: AppMenuPrivacyDelegate? {
        didSet {
            self.appAdditionView?.privacyActionDelegate = privacyActionDelegate
        }
    }

    /// 初始化附加视图
    /// - Parameter model: 视图的数据模型
    @objc
    public init(model: AppMenuAppRatingAdditionViewModel, style: AppRatingAdditionViewStyle) {
        self.model = model
        self.style = style
        super.init(frame: .zero)
        setupSubviews()
        setupSubviewsStaticConstrain()
        updateModel(for: model)
        startNotifier()
        if (!showUserRatingInfo) {
            hideAppRatingSubViews()
        }
    }
    
    /// 根据appReviewInfo更新视图
    public func updateAppRatingInfo(with appReviewInfo: AppReviewInfo?) {
        /// 显示普通样式，不更新
        guard showUserRatingInfo else {
            hideAppRatingSubViews()
            return
        }
        /// 显示评分样式，更新UI
        guard let info = appReviewInfo else {
            return
        }
        self.guideTitleView?.isHidden = false
        self.toAppRatingView?.isHidden = false
        self.scoreStarView?.isHidden = !info.isReviewed
        self.toAppRatingView?.updateSubView(hasRating: info.isReviewed)
        self.guideTitleView?.text = info.isReviewed ? BDPI18n.openPlatform_AppRating_MyRatingTtl : BDPI18n.openPlatform_AppRating_NotRatedYet
        self.scoreStarView?.updateScore(score: info.score)
        
        self.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(jumpToReview))
        self.addGestureRecognizer(tap)
        setupSubviewsStaticConstrain()
    }
    
    /// 不显示小程序评分时，隐藏相关子视图
    private func hideAppRatingSubViews() {
        guard let titleView = titleView else {
            return
        }
        titleView.snp.makeConstraints {
            make in
            make.centerY.equalToSuperview()
        }
        self.guideTitleView?.isHidden = true
        self.scoreStarView?.isHidden = true
        self.toAppRatingView?.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateAppAdditionViewDynamicComstrain()
        iconImageView?.layer.ux.setSmoothCorner(radius: iconImageCornerRadius)
    }

    /// 更新数据模型
    /// - Parameter model: 新的数据模型
    @objc
    public func updateModel(for model: AppMenuAppRatingAdditionViewModel) {
        updateIcon(for: model.iconURL)
        updateName(for: model.name)
    }

    /// 更新名称
    /// - Parameter name: 新的名称
    private func updateName(for name: String?) {
        guard let label = self.titleView else {
            return
        }
        label.text = name ?? self.defaultName
    }

    /// 更新头像
    /// - Parameter url: 头像的url
    private func updateIcon(for url: String?) {
        guard let icon = self.iconImageView else {
            return
        }
        guard let urlString = url, let url = URL(string: urlString) else {
            icon.image = self.defaultImage
            return
        }
        // 建议不要直接使用BDWebImage
        BDPNetworking.setImageView(icon, url: url, placeholder: self.defaultImage)
    }
    

    /// 开始监听权限变化
    private func startNotifier() {
        self.appAdditionView?.startNotifier()
    }

    /// 初始化子视图
    private func setupSubviews() {
        setupIconImageView()
        setupTitleView()
        setupAppAdditionView()
        setupGuideTitleView()
        setupToAppRatingView()
        setupScoreStarView()
    }

    /// 初始化子视图的约束
    private func setupSubviewsStaticConstrain() {
        setupCurrentViewStaticConstrain()
        setupIconImageViewStaticConstrain()
        updateTitleViewDynamicConstrain()
        updateAppAdditionViewDynamicComstrain()
        setupToAppRatingViewConstrain()
        setupGuideTitleViewDynamicConstrain()
        setupScoreStarViewConstrain()
        
    }

    /// 初始化头像
    private func setupIconImageView() {
        if let iconImageView = self.iconImageView {
            iconImageView.removeFromSuperview()
            self.iconImageView = nil
        }

        let newIcon = OPThemeImageView()
        newIcon.contentMode = .scaleAspectFit
        newIcon.layer.borderWidth = self.iconImageBorderWidht
        newIcon.layer.borderColor = self.iconImageBorderColor.cgColor
        newIcon.layer.masksToBounds = true
        newIcon.layer.ux.setSmoothCorner(radius: iconImageCornerRadius)
        newIcon.layer.ux.setSmoothBorder(width: self.iconImageBorderWidht, color: UIColor.ud.lineDividerDefault)
        self.addSubview(newIcon)
        self.iconImageView = newIcon
    }

    /// 初始化应用名称标签
    private func setupTitleView() {
        if let titleView = self.titleView {
            titleView.removeFromSuperview()
            self.titleView = nil
        }
        let label = UILabel()
        label.textColor = self.titleColor
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.font = self.titleFont
        self.addSubview(label)
        self.titleView = label
    }
    
    /// 初始化引导文案标签
    private func setupGuideTitleView() {
        if let guideTitle = self.guideTitleView {
            guideTitle.removeFromSuperview()
            self.guideTitleView = nil
        }
        let label = UILabel()
        label.textColor = self.guideTitleColor
        label.textAlignment = .left
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.font = self.guideTitleFont
        self.addSubview(label)
        self.guideTitleView = label
    }
    
    /// 初始化评分星级视图
    private func setupScoreStarView() {
        if let scoreStarView = self.scoreStarView {
            scoreStarView.removeFromSuperview()
            self.scoreStarView = nil
        }
        let starView = ScoreStarView()
        starView.layer.cornerRadius = self.scoreStarCornerRadius
        self.addSubview(starView)
        self.scoreStarView = starView
    }
    
    /// 初始化我要评分视图
    private func setupToAppRatingView() {
        if let toAppRatingView = toAppRatingView {
            toAppRatingView.removeFromSuperview()
            self.toAppRatingView = nil
        }
        let toRatingView = ToAppRatingView()
        self.addSubview(toRatingView)
        self.toAppRatingView = toRatingView
    }
    
    /// 初始化评分星级视图约束
    private func setupScoreStarViewConstrain() {
        guard let starView = self.scoreStarView, let guideTitle = self.guideTitleView else {
            return
        }
        starView.snp.makeConstraints {
            make in
            make.centerY.equalTo(guideTitle.snp.centerY)
            make.leading.equalTo(guideTitle.snp.trailing).offset(self.scoreStarViewLeftSpacing)
            make.height.equalTo(self.scoreStarViewHeight)
        }
    }
    
    /// 初始化我要评分视图约束
    private func setupToAppRatingViewConstrain() {
        guard let toAppRatingView = toAppRatingView, let guideTitle = self.guideTitleView, let scoreStarView = self.scoreStarView else {
            return
        }
        toAppRatingView.snp.makeConstraints{
            make in
            make.centerY.equalTo(guideTitle.snp.centerY)
            make.leading.greaterThanOrEqualTo(scoreStarView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-self.toAppRatingViewRightSpacing)
            make.height.equalTo(self.toAppRatingViewHeight)
        }
    }
    
    /// 初始化权限视图
    private func setupAppAdditionView() {
        let privacyView = AppMenuAdditionView()
        privacyView.delegate = self
        self.appAdditionView = privacyView
    }

    /// 初始化当前自身的约束
    private func setupCurrentViewStaticConstrain() {
        self.snp.makeConstraints{
            make in
            make.height.equalTo(self.additionViewHeight)
        }
    }

    /// 初始化头像约束
    private func setupIconImageViewStaticConstrain() {
        guard let icon = self.iconImageView else {
            return
        }
        icon.snp.makeConstraints{
            make in
            make.leading.equalToSuperview().offset(self.additionViewLeftSpacing)
            make.width.height.equalTo(self.iconWidthAndHeight)
            make.centerY.equalToSuperview()
        }
    }
    
    /// 初始化引导文案约束
    private func setupGuideTitleViewDynamicConstrain() {
        guard let guideTitle = self.guideTitleView, let label = self.titleView else {
            return
        }
        let offset: CGFloat = 45 + self.widthForText(text: self.toAppRatingView?.textLabel?.text ?? "", font: UDFont.systemFont(ofSize: 14, weight: .medium), height: 100)
        guideTitle.snp.makeConstraints{
            make in
            make.leading.equalTo(label.snp.leading)
            make.trailing.lessThanOrEqualToSuperview().offset(-offset)
            make.top.equalTo(label.snp.bottom).offset(self.guideTitleTopSpacing)
        }
    }
    
    private func widthForText(text: String, font: UIFont, height: CGFloat) -> CGFloat {
        return (text as NSString).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height),
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: [.font: font],
                                                   context: nil).width
    }

    /// 更新标签约束
    private func updateTitleViewDynamicConstrain() {
        guard let label = self.titleView, let icon = self.iconImageView else {
            return
        }
        label.snp.remakeConstraints{
            make in
            make.leading.equalTo(icon.snp.trailing).offset(self.titleLeftSpacing)
            make.top.equalTo(icon.snp.top)
            if !self.isShowAppAdditionView {
                make.trailing.equalToSuperview().offset(-self.additionViewRightSpacing)
            }
            make.height.equalTo(self.titleHeight)
        }
    }
    
    /// 更新权限视图约束
    private func updateAppAdditionViewDynamicComstrain() {
        guard let label = self.titleView, let appAddition = self.appAdditionView, appAddition.superview != nil else {
            return
        }
        // 计算权限视图的长度，并设置最大长度，且让小程序名称有至少44px的显示宽度
        let allowMaxWidth = self.frame.width - (self.additionViewLeftSpacing + self.iconWidthAndHeight + self.titleLeftSpacing + self.minTitleWidth + titleRightSpacingWhenDisplayPrivacyView + self.additionViewRightSpacing)
        var reallySize = appAddition.forecastSize()
        var reallyWidth = min(max(0, allowMaxWidth), reallySize.width)
        var reallyHeight = reallySize.height
        reallySize = appAddition.reallySize(for: CGSize(width: reallyWidth, height: reallyHeight))
        reallyWidth = min(max(0, allowMaxWidth), reallySize.width)
        reallyHeight = reallySize.height
        appAddition.snp.remakeConstraints{
            make in
            make.leading.equalTo(label.snp.trailing).offset(self.titleRightSpacingWhenDisplayPrivacyView)
            make.trailing.equalToSuperview().offset(-self.additionViewRightSpacing)
            make.centerY.equalToSuperview()
            make.width.equalTo(reallyWidth)
            make.height.equalTo(reallyHeight)
        }
    }
}

extension AppMenuAppRatingAdditionView: MenuForecastSizeProtocol {
    public func forecastSize() -> CGSize {
        var labelWidth: CGFloat = 0
        if let label = self.titleView {
            labelWidth = label.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT))).width
        }
        var totalWidth = self.additionViewLeftSpacing + self.iconWidthAndHeight + self.titleLeftSpacing + labelWidth + self.additionViewRightSpacing
        if self.isShowAppAdditionView {
            let privacyWidth = self.appAdditionView?.forecastSize().width ?? 0
            totalWidth += (privacyWidth + titleRightSpacingWhenDisplayPrivacyView)
        }
        return CGSize(width: totalWidth, height: additionViewHeight)
    }
    
    public func reallySize(for suggestionSize: CGSize) -> CGSize {
        forecastSize()
    }
}

extension AppMenuAppRatingAdditionView: AlternateAnimatorDelegate {

    public func animationWillStart(for view: UIView) {
        //动画开始，将动画附着视图添加到自己的子视图中，并更新约束
        self.isShowAppAdditionView = true
        self.addSubview(view)
        updateTitleViewDynamicConstrain()
        updateAppAdditionViewDynamicComstrain()
    }

    public func animationDidEnd(for view: UIView) {
        //动画开始，将动画附着视图从子视图移除，并更新约束
        self.isShowAppAdditionView = false
        view.removeFromSuperview()
        updateTitleViewDynamicConstrain()
    }

    public func animationDidAddSubView(for targetView: UIView, subview: UIView) {
        // 当有新的动画视图添加到附着视图中时，可以设置子视图的布局方式
        // 右对齐
        subview.snp.makeConstraints{
            make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
        }
        // 需要强制刷新布局
        setNeedsLayout()
        layoutIfNeeded()
    }

    public func animationDidRemoveSubView(for targetView: UIView, subview: UIView) {
        // 需要强制刷新布局，才能使布局正确
        setNeedsLayout()
        layoutIfNeeded()
    }
}

private class ScoreStarView: UIView {
    /// scoreStarView的背景色
    private let bgColor = UIColor.ud.Y100
    /// scoreStarView自身长度
    private let viewWidth = 45
    /// scoreStarView自身宽度
    private let viewHeight = 25
    
    /// 分数字号
    private let scoreFont = UIFont.systemFont(ofSize: 12, weight: .medium)
    /// 分数字体颜色
    private let scoreColor = UIColor.ud.udtokenTagTextSYellow
    /// 分数左边距
    private let scoreLabelLeftSpacing = 4
    /// 分数右边距
    private let scoreLabelRightSpacing = 4
    
    /// 星级icon颜色
    private let starIconColor = UIColor.ud.colorfulYellow
    
    /// 星左边距
    private let starLeftSpacing = 4
    /// 星size
    private let starSize = 11
    
    /// 显示分数视图
    private var scoreLabel: UILabel?
    /// 显示星级视图
    private var starImage: UIImageView?
    
    init() {
        super.init(frame: CGRect.init(x: 0, y: 0, width: viewWidth, height: viewHeight))
        self.backgroundColor = self.bgColor
        setupScoreStarView()
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupScoreStarView() {
        setupStarImage()
        setupScoreLabel()
    }
    
    public func updateScore(score: Float) {
        scoreLabel?.text = String(format: "%.1f", score)
        setupStarImageConstrain()
        setupScoreLabelConstrain()
    }
        
    private func setupScoreLabel() {
        if let scoreLabel = self.scoreLabel {
            scoreLabel.removeFromSuperview()
            self.scoreLabel = nil
        }
        let scoreLabel = UILabel()
        scoreLabel.textColor = self.scoreColor
        scoreLabel.textAlignment = .left
        scoreLabel.numberOfLines = 1
        scoreLabel.font = self.scoreFont
        self.addSubview(scoreLabel)
        self.scoreLabel = scoreLabel
    }
    
    private func setupStarImage() {
        if let starImage = self.starImage {
            starImage.removeFromSuperview()
            self.starImage = nil
        }
        
        let starImage = UIImageView()
        starImage.contentMode = .scaleAspectFit
        starImage.layer.masksToBounds = true
        let starIcon = UDIcon.getIconByKey(.collectFilled, renderingMode: .alwaysOriginal, iconColor: self.starIconColor)
        starImage.image = starIcon
        self.addSubview(starImage)
        self.starImage = starImage
    }
    
    /// 初始化星级视图的约束
    private func setupStarImageConstrain() {
        guard let starImage = self.starImage else {
            return
        }
        starImage.snp.makeConstraints {
            make in
            make.height.width.equalTo(self.starSize)
            make.leading.equalToSuperview().offset(self.starLeftSpacing)
            make.centerY.equalToSuperview()
        }
    }
    
    /// 初始化分数label的约束
    private func setupScoreLabelConstrain() {
        guard let starImage = self.starImage, let scoreLabel = self.scoreLabel else {
            return
        }
        scoreLabel.snp.makeConstraints {
            make in
            make.leading.equalTo(starImage.snp.trailing).offset(self.scoreLabelLeftSpacing)
            make.trailing.equalToSuperview().offset(-self.scoreLabelRightSpacing)
            make.centerY.equalToSuperview()
        }
    }
}

final class ToAppRatingView: UIView {
    /// 字号
    private let ratingFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    /// 我要评分字体颜色
    private let toRatingFontColor = UIColor.ud.primaryContentDefault
    /// 更新评分字体颜色
    private let reRatingFontColor = UIColor.ud.textCaption
    /// 已有评分时textLabel右边距
    private let textLabelRightSpacing: CGFloat = 15
    /// 向右箭头icon
    private let rightIcon = UDIcon.rightSmallCcmOutlined.ud.withTintColor(UIColor.ud.iconN2)
    /// 向右箭头左边距
    private let rightIconLeftSpacing: CGFloat = 3
    /// 向右箭头size
    private let rightIconSize = 16
    /// 评分label
    var textLabel: UILabel?
    /// 向右箭头imageView
    private var rightIconView: UIImageView?

    
    init() {
        super.init(frame: .zero)
        setupLabel()
        setupRightIcon()
        setupTextLabelConstrain()
        setupRightIconConstrain()
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateSubView(hasRating: Bool) {
        if (hasRating) {
            self.rightIconView?.isHidden = false
            textLabel?.text = BDPI18n.openPlatform__AppRating_UpdateRatingLink
            textLabel?.textColor = self.reRatingFontColor
            textLabel?.snp.makeConstraints{
                make in
                make.trailing.equalToSuperview().offset(-self.textLabelRightSpacing)
                make.centerY.equalToSuperview()
            }
        } else {
            self.rightIconView?.isHidden = true
            textLabel?.text = BDPI18n.openPlatform_AppRating_GoToRateLink
            textLabel?.textColor = self.toRatingFontColor
        }
    }
        
    private func setupLabel() {
        if let label = self.textLabel {
            label.removeFromSuperview()
            self.textLabel = nil
        }
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 1
        label.font = self.ratingFont
        self.addSubview(label)
        self.textLabel = label
    }
    
    private func setupRightIcon() {
        if let rightIconView = self.rightIconView {
            rightIconView.removeFromSuperview()
            self.rightIconView = nil
        }
        let rightIconView = UIImageView()
        rightIconView.contentMode = .scaleAspectFit
        rightIconView.layer.masksToBounds = true
        rightIconView.image = self.rightIcon
        self.addSubview(rightIconView)
        self.rightIconView = rightIconView
    }
    
    private func setupTextLabelConstrain() {
        guard let label = self.textLabel else {
            return
        }
        label.snp.makeConstraints {
            make in
            make.leading.equalToSuperview()
        }
    }
    
    /// 初始化向右箭头视图的约束
    private func setupRightIconConstrain() {
        guard let rightIconView = self.rightIconView, let label = self.textLabel else {
            return
        }
        rightIconView.snp.makeConstraints {
            make in
            make.height.width.equalTo(self.rightIconSize)
            make.leading.equalTo(label.snp.trailing).offset(self.rightIconLeftSpacing)
            make.trailing.equalToSuperview()
            make.centerY.equalTo(label.snp.centerY)
        }
    }
}
