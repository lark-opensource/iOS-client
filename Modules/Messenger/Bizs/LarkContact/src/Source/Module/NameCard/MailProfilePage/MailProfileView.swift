//
//  MailProfileView.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/27.
//

import Foundation
import UniverseDesignColor
import UniverseDesignFont
import LarkTag
import RichLabel
import LarkUIKit
import UIKit
import LarkProfile
import LarkContainer

final class MailProfileView: UIView {

    // MARK: UI Elements
    lazy var detailInfoView: MailProfileDetailInfoView = {
       return MailProfileDetailInfoView(frame: CGRect.zero, resolver: userResolver)
    }()

    lazy var navigationBar = MailProfileNaviBar()

    /// 列表容器，包含 Header，Tabs，VCs
    lazy var innerTableView: MailProfileTableView = {
        let tableView = MailProfileTableView(innerView: detailInfoView)
        return tableView
    }()

    /// Header 容器
    lazy var headerView = UIView()

    private lazy var gradientMaskLayer: CAGradientLayer = {
        let gradientMaskLayer = CAGradientLayer()
        return gradientMaskLayer
    }()

    private func setGradientMask() {
        gradientMaskLayer.locations = [0.0, 0.8]
        gradientMaskLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientMaskLayer.endPoint = CGPoint(x: 0.5, y: 1)
        let startColor = UIColor.ud.staticBlack.withAlphaComponent(0.16)
        let endColor = UIColor.ud.staticBlack.withAlphaComponent(0)
        gradientMaskLayer.colors = [startColor.cgColor, endColor.cgColor]
    }

    lazy var gradientMaskView: UIView = {
        let gradientMaskView = UIView()
        gradientMaskView.isUserInteractionEnabled = false
        return gradientMaskView
    }()

    /// 可拉伸背景图
    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    /// 个人信息容器
    private lazy var infoContentView: UIView = {
        let view = UIView()
        view.backgroundColor = Cons.infoBgColor
        if Cons.infoCornerRadius != 0 {
            view.layer.cornerRadius = Cons.infoCornerRadius
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        return view
    }()

    lazy var avatarWrapperView = UIView()

    private lazy var nameTagView = MailProfileNameTagView()

    private var defaultId: String = ""
    private var shouldUpdateDefaultIndex: Bool = false

    /// 包含：公司认证、状态标签、签名、CTA 按钮
    private lazy var infoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    /// 公司认证
    lazy var companyContainer = UIView()

    lazy var companyView = UIView()

    /// Tag 状态标签布局容器，处理上下 margin
    lazy var badgeContainer = UIView()

    lazy var customBadgeView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        return stack
    }()

    /// 个人签名布局容器，处理上下 margin
    private lazy var statusContainer = UIView()
    private let userResolver: UserResolver

    /// CTA 按钮布局容器，处理上下 margin
    private lazy var buttonsContainer: UIView = {
        let view = UIView()
        /*
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 3
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.ud.setLayerShadowColor(UIColor.ud.staticBlack)
         */
        return view
    }()

    lazy var buttonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 10
        return stack
    }()

    // MARK: Life Cycle
    init(frame: CGRect, resolver: UserResolver) {
        self.userResolver = resolver
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientMaskLayer.frame = gradientMaskView.bounds
        setGradientMask()
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(innerTableView)
        headerView.addSubview(backgroundImageView)
        headerView.addSubview(infoContentView)
        headerView.addSubview(avatarWrapperView)
        infoContentView.addSubview(nameTagView)
        infoContentView.addSubview(infoStack)
        infoStack.addArrangedSubview(companyContainer)
        infoStack.addArrangedSubview(badgeContainer)
        infoStack.addArrangedSubview(statusContainer)
        infoStack.addArrangedSubview(buttonsContainer)
        badgeContainer.addSubview(customBadgeView)
        buttonsContainer.addSubview(buttonsStack)
        backgroundImageView.addSubview(gradientMaskView)
        gradientMaskView.layer.insertSublayer(gradientMaskLayer, at: 0)
        addSubview(navigationBar)
    }

    func setupConstraints() {
        navigationBar.snp.remakeConstraints { make in
            make.top.left.trailing.equalToSuperview()
        }
        innerTableView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundImageView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(167)
            make.bottom.equalTo(infoContentView.snp.top).offset(Cons.infoCornerRadius)
        }
        avatarWrapperView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(Cons.avatarMargin)
            make.centerY.equalTo(infoContentView.snp.top)
            make.width.height.equalTo(Cons.avatarSize)
        }
        infoContentView.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(Cons.bgImageHeight - Cons.infoCornerRadius)
        }
        nameTagView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(Cons.avatarSize / 2 + 12)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
        }
        infoStack.snp.remakeConstraints { make in
            make.top.equalTo(nameTagView.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(16)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
        }
        buttonsStack.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
        customBadgeView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.bottom.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.height.equalTo(18)
        }
        gradientMaskView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupAppearance() {
        // 未绑定数据前，先隐藏几个项目
        badgeContainer.isHidden = true
        statusContainer.isHidden = true
        buttonsContainer.isHidden = true
        companyContainer.isHidden = true
    }
}

extension MailProfileView {

    // MARK: Public APIs

    /// 创建一个 UIImageView 并设为头像（头像点击事件由 Provider 处理）
    /// - Parameter imageView: 接受一个闭包是因为需要创建两个不同的实例
    func setAvatarView(_ imageView: UIView) {
        avatarWrapperView.subviews.forEach { view in
            view.removeFromSuperview()
        }
        avatarWrapperView.addSubview(imageView)
        imageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setNavigationBarAvatarView(_ imageView: UIView) {
        navigationBar.avatarView.customView = imageView
    }

    /// 设置用户的个人信息模块
    func setUserInfo(_ info: MailProfileUserInfo) {
        setUserName(info)
        setUserTags(info)
        setUserCompany(info)
    }

    /// 设置用户的 CTA 按钮
    func setCTAButtons(_ items: [ProfileCTAItem]) {
        buttonsContainer.isHidden = items.isEmpty
        buttonsStack.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        let style: ProfileCTAControl.Style = items.count == 1 ? .horizontal : .vertical
        for item in items {
            let button = ProfileCTAControl(item: item, style: style)
            buttonsStack.addArrangedSubview(button)
        }
    }

    /// 设置一个 ImageView 作为顶部背景图（换背景的逻辑由 Provider 处理）
    func setBackgroundImageView(_ imageView: UIImageView?) {
        guard let imageView = imageView else { return }
        for subview in backgroundImageView.subviews {
            subview.removeFromSuperview()
        }
        imageView.contentMode = .scaleAspectFill
        backgroundImageView.addSubview(imageView)
        imageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundImageView.addSubview(gradientMaskView)
        gradientMaskView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 设置背景图片
    func setBackgroundImage(_ image: UIImage?) {
        for subview in backgroundImageView.subviews {
            subview.removeFromSuperview()
        }
        backgroundImageView.image = image
    }

    /// 设置 Navigation Bar 上的按钮，按钮点击时间由 Provider 处理
    func setBarButtons(_ buttons: [UIButton]) {
        navigationBar.setRightButtons(buttons)
    }

    /// 设置页面状态：正常、空信息、无权限、网络错误
    func setInfoStatus(_ status: MailProfileTableView.ViewStatus) {
        innerTableView.viewStatus = status
    }

    /// 详细信息
    func setDetailInfo(datas: [MailProfileCellItem]) {
        self.detailInfoView.setData(data: datas)
    }

    private func setUserName(_ info: MailProfileUserInfo) {
        // 姓名
        navigationBar.titleLabel.text = info.name
        nameTagView.setName(info.name)
    }

    private func setUserTags(_ info: MailProfileUserInfo) {
        // 状态标签
        nameTagView.setTags(info.nameTag)
    }

    private func setUserCompany(_ info: MailProfileUserInfo) {
        // 公司
        if let companyView = info.companyView {
            companyContainer.isHidden = false
            for subview in companyContainer.subviews {
                subview.removeFromSuperview()
            }
            companyContainer.addSubview(companyView)
            companyView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(4)
                make.leading.trailing.bottom.equalToSuperview()
            }
        } else {
            companyContainer.isHidden = true
        }
    }
}

extension MailProfileView {
    enum Cons {
        static var infoBgColor: UIColor { UIColor.ud.bgBody }
        static var infoCornerRadius: CGFloat { 0 }
        static var nameFont: UIFont { UIFont.ud.title0 }
        static var statusFont: UIFont { UIFont.ud.body2 }
        static var avatarSize: CGFloat { 108 }
        static var avatarMargin: CGFloat { 16 }
        static var hMargin: CGFloat { 20 }
        static var bgAspectRatio: CGFloat { 2.34 }
        static var iPadViewSize: CGSize { CGSize(width: 420, height: 650) }
        static var bgImageHeight: CGFloat {
            if Display.pad {
                return ceil(iPadViewSize.width / bgAspectRatio)
            } else {
                return ceil(UIScreen.main.bounds.width / bgAspectRatio)
            }
        }
    }
}

extension LKLabel {
    func setPreferredLayoutWidth(_ width: CGFloat) {
        self.preferredMaxLayoutWidth = width
    }
}

// MARK: viewmodel info
struct MailProfileUserInfo {
    public var name: String
    public var nameTag: [UIView]
    public var companyView: UIView?

    public init(name: String,
                nameTag: [UIView] = [],
                companyView: UIView? = nil) {
        self.name = name
        self.nameTag = nameTag
        self.companyView = companyView
    }
}
