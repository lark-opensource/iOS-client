//
//  WPTemplateHeader.swift
//  templateDemo
//
//  Created by  bytedance on 2021/3/12.
//

import LarkUIKit
import LarkInteraction
import UniverseDesignIcon
import UniverseDesignTag
import UIKit
import LKCommonsLogging

/// header-view交互协议
protocol HeaderViewDelegate: NSObjectProtocol {
    /// 标题点击
    func onTitleClick(_ view: WPTemplateHeader, url: String)
    /// 交互按钮点击
    func onActionClick(_ view: WPTemplateHeader)
}

final class WPTemplateHeader: UIView {
    static let logger = Logger.log(WPTemplateHeader.self)

    enum Style {
        case none
        case inside
        case outside
    }

    struct Content {
        let title: String
        let titleIconUrl: String

        let redirectUrl: String?

        var tagType: WPCellTagType
    }

    struct Setting {
        let style: Style
        let content: Content?
    }

    // MARK: - public

    /// 内部通用间隔
    static let inset: CGFloat = 4.0

    /// 标题是否内置
    var isTitleInner: Bool = false

    var showActionArea: Bool = false {
        didSet {
            actionArea.isHidden = !showActionArea
        }
    }

    weak var actionDelegate: HeaderViewDelegate?

    /// 目前主要用于 Block 的 Header
    func refresh(setting: Setting) {
        inner_refresh(setting: setting)
    }

    /// 目前主要用于模板化 Native 组件的 Header
    func refresh(model: GroupTitleComponent) {
        inner_refresh(model: model)
    }

    // MARK: - private

    /// 信息展示区域
    private(set) lazy var titleArea: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        return view
    }()

    /// 交互操作区域
    private(set) lazy var actionArea: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        return view
    }()

    /// 真实header高度
    private var headerRealHeight: CGFloat = 28.0

    /// 信息区点击热区
    private lazy var titleHotArea = HotAreaView()

    /// 交互区点击热区
    private lazy var actionHotArea = HotAreaView()

    /// 真实标题内容
    private lazy var realTitle = UIView()

    /// icon图标
    private var iconEdge: CGFloat = 20

    private lazy var iconImgView = { () -> WPMaskImageView in
        let icon = WPMaskImageView()
        icon.backgroundColor = UIColor.ud.bgFiller
        icon.clipsToBounds = true
        icon.layer.cornerRadius = 0
        icon.layer.borderWidth = 0
        icon.sqRadius = WPUIConst.AvatarRadius.xs6
        icon.sqBorder = WPUIConst.BorderW.pt1
        return icon
    }()

    /// 分组标题
    private lazy var titleLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.font = .systemFont(ofSize: 16, weight: .medium)
        headerLabel.numberOfLines = 1
        headerLabel.textAlignment = .left
        headerLabel.textColor = UIColor.ud.textTitle
        return headerLabel
    }()

    /// 标题跳转链接
    private var actionUrl: String?

    /// 跳转图标
    private lazy var redirectIcon = { () -> UIImageView in
        let icon = UIImageView()
        icon.image = UDIcon.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        return icon
    }()

    /// 操作区图标
    private lazy var actionIcon = { () -> UIImageView in
        let icon = UIImageView()
        icon.image = UDIcon.moreOutlined.ud.withTintColor(UIColor.ud.iconN3)
        return icon
    }()

    /// 推荐 tag
    private lazy var recommandTagView: UDTag = {
        let tagView = UDTag(text: "", textConfig: UDTagConfig.TextConfig())
        tagView.wp_updateType(.recommandBlock)
        return tagView
    }()

    // MARK: view initial
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(realTitle)
        realTitle.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(headerRealHeight)
        }

        realTitle.addSubview(titleArea)
        realTitle.addSubview(actionArea)

        titleArea.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            // make.right.lessThanOrEqualToSuperview().offset(-12)
            make.right.lessThanOrEqualTo(actionArea.snp.left).offset(-12)
        }

        actionArea.snp.makeConstraints { (make) in
            make.right.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }

        titleArea.addSubview(iconImgView)
        titleArea.addSubview(titleLabel)
        titleArea.addSubview(redirectIcon)

        iconImgView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Self.inset)
            make.height.width.equalTo(22)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(34)
            make.centerY.equalToSuperview()
        }

        redirectIcon.snp.makeConstraints { (make) in
            make.height.width.equalTo(14)
            make.left.equalTo(titleLabel.snp.right).offset(Self.inset)
            make.right.equalToSuperview().offset(-Self.inset)
            make.centerY.equalToSuperview()
        }

        actionArea.isHidden = false
        actionArea.addSubview(actionIcon)

        actionIcon.snp.makeConstraints { (make) in
            make.height.width.equalTo(14)
            make.center.equalToSuperview()
        }

        recommandTagView.isHidden = true
        addSubview(recommandTagView)
        recommandTagView.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.height.equalTo(18)
            make.left.equalTo(titleLabel.snp.right).offset(8)
        }

        setHotArea()
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        actionArea.addPointer(
            .init(
                effect: .highlight,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (CGSize(
                        width: size.width + highLightTextWidthMargin,
                        height: highLightCommonTextHeight
                    ), highLightCorner)
                }
            )
        )
    }

    private func inner_refresh(setting: Setting) {
        switch setting.style {
        case .inside:
            setupInnerStyle()
        case .outside:
            setupOutterStyle()
        case .none:
            break
        }
        if setting.style != .none, let model = setting.content {
            setupTitle(title: model.title, titleIconUrl: model.titleIconUrl, redirectUrl: model.redirectUrl)
        }
        recommandTagView.isHidden = setting.content?.tagType != .recommandBlock
    }

    private func inner_refresh(model: GroupTitleComponent) {
        if model.isInnerTitle {
            setupInnerStyle()
        } else {
            setupOutterStyle()
        }
        titleLabel.textColor = model.title.textColor
        showActionArea = !model.menuItemsFromSchema.isEmpty
        setupTitle(title: model.title.text, titleIconUrl: model.title.iconUrl ?? "", redirectUrl: model.title.schema)
        recommandTagView.isHidden = true
    }

    /// 设置标题内容
    private func setupTitle(title: String, titleIconUrl: String, redirectUrl: String? = nil) {
        /// 图标
        let titleLabelLeftMargin: CGFloat   // 标题距离左侧的距离，根据有无图标来判断
        if !titleIconUrl.isEmpty {    // 有图标
            if titleIconUrl.hasPrefix("https://") || titleIconUrl.hasPrefix("http://") {
                // URL 格式图片
                iconImgView.bt.setLarkImage(with: .default(key: titleIconUrl))
            } else {
                iconImgView.bt.setLarkImage(with: .avatar(
                    key: titleIconUrl,
                    entityID: "",
                    params: .init(sizeType: .size(iconEdge))
                ))
            }
            iconImgView.isHidden = false
            titleLabelLeftMargin = Self.inset + iconEdge + 8
        } else {    // 无图标
            iconImgView.isHidden = true
            titleLabelLeftMargin = Self.inset
        }
        /// 标题
        titleLabel.text = title
        titleLabel.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(titleLabelLeftMargin)
            make.centerY.equalToSuperview()
        }

        setupRedirector(redirectUrl: redirectUrl)
    }

    /// 设置标题跳转逻辑
    private func setupRedirector(redirectUrl: String?) {
        // 跳转图标
        actionUrl = redirectUrl
        if let str = redirectUrl, !str.isEmpty {
            redirectIcon.isHidden = false
            titleHotArea.isHidden = false
        } else {
            redirectIcon.isHidden = true
            titleHotArea.isHidden = true
        }

        let offset = redirectIcon.isHidden ? 8 : 22
        recommandTagView.snp.remakeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right).offset(offset)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.height.equalTo(18)
        }
    }

    /// 加载内部标题样式
    private func setupInnerStyle() {
        isTitleInner = true
        iconEdge = 20
        headerRealHeight = 30
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        realTitle.snp.remakeConstraints { (make) in
            make.height.equalTo(headerRealHeight)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(12)
        }
        setIconLayout(edge: iconEdge)
        // 设置热区
        titleHotArea.snp.remakeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(actionArea.snp.left).offset(-12)
        }
    }

    /// 加载外部标题样式
    private func setupOutterStyle() {
        isTitleInner = false
        iconEdge = 22
        headerRealHeight = 28
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        realTitle.snp.remakeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(headerRealHeight)
        }
        setIconLayout(edge: iconEdge)
        // 设置热区
        titleHotArea.snp.remakeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(titleArea.snp.right)
        }
    }

    /// 设置图标布局
    private func setIconLayout(edge: CGFloat) {
        iconImgView.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(Self.inset)
            make.height.width.equalTo(edge)
            make.centerY.equalToSuperview()
        }
    }

    /// 设置点击热区
    private func setHotArea() {
        /// 标题区热区
        titleHotArea.touchEvent = { [weak self] in
            self?.titleArea.backgroundColor = UIColor.ud.fillPressed
        }
        titleHotArea.cancelEvent = { [weak self] in
            self?.titleArea.backgroundColor = .clear
        }
        titleHotArea.clickEvent = { [weak self] in
            guard let `self` = self else {
                Self.logger.warn("header delegate missed, user tap not response")
                return
            }
            self.titleArea.backgroundColor = .clear
            Self.logger.info("header title is clicked")
            if let url = self.actionUrl {
                self.actionDelegate?.onTitleClick(self, url: url)
            }
        }
        addSubview(titleHotArea)
        titleHotArea.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(titleArea.snp.right)
        }
        /// 交互区热区
        actionHotArea.touchEvent = { [weak self] in
            self?.actionArea.backgroundColor = UIColor.ud.bgFiller
        }
        actionHotArea.cancelEvent = { [weak self] in
            self?.actionArea.backgroundColor = .clear
        }
        actionHotArea.clickEvent = { [weak self] in
            guard let `self` = self else {
                Self.logger.warn("header delegate missed, user tap not response")
                return
            }
            self.actionArea.backgroundColor = .clear
            Self.logger.info("header action is clicked")
            self.actionDelegate?.onActionClick(self)
        }
        addSubview(actionHotArea)
        actionHotArea.snp.makeConstraints { (make) in
            make.right.top.bottom.equalToSuperview()
            make.left.equalTo(actionArea.snp.left)
        }
    }
}

/// 点击热区View
private final class HotAreaView: UIView {
    /// 触碰事件
    var touchEvent: (() -> Void)?
    /// 完成点击
    var clickEvent: (() -> Void)?
    /// 取消点击
    var cancelEvent: (() -> Void)?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchEvent?()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        clickEvent?()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelEvent?()
    }
}

/// 专为点击按压态准备的View
private final class TouchEffectView: UIView {
    /// 触碰时的颜色
    var touchColor: UIColor = UIColor.ud.bgFiller
    /// 点击事件
    var clickEvent: (() -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = touchColor
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = .clear
        clickEvent?()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = .clear
    }
}
