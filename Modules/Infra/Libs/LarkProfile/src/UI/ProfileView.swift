//
//  ProfileView.swift
//  LarkProfile
//
//  Created by Hayden Wang on 2021/7/5.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignFont
import LarkTag
import RichLabel
import LarkUIKit
import LarkFocus
import LarkContainer

class ProfileView: UIView {

    // MARK: UI Elements

    lazy var navigationBar = ProfileNaviBar()

    /// 列表容器，包含 Header，Tabs，VCs
    lazy var segmentedView: SegmentedTableView = {
        let tableView = SegmentedTableView()
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
    var backgroundImageView: UIImageView = .init(image: nil)

    /// 个人信息容器
    lazy var infoContentView: UIView = {
        let view = UIView()
        view.backgroundColor = Cons.infoBgColor
        if Cons.infoCornerRadius != 0 {
            view.layer.cornerRadius = Cons.infoCornerRadius
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        return view
    }()

    lazy var avatarWrapperView = UIView()

    /// 个人状态
    lazy var focusView: FocusDisplayView = {
        let view = FocusDisplayView(userResolver: userResolver)
        return view
    }()

    var nameTagView = NameTagView()

    lazy var aliasView = AliasView()

    private var defaultId: String = ""
    private var shouldUpdateDefaultIndex: Bool = false

    /// 包含：公司认证、状态标签、签名、CTA 按钮
    lazy var infoStack: UIStackView = {
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
    lazy var statusContainer = UIView()

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

    lazy var buttonsContainerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 9
        return stack
    }()

    lazy var buttonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 10
        return stack
    }()

    lazy var addContactView = AddContactView()
    lazy var applyCommunicationView = ProfileApplyCommunicationView()
    // MARK: Life Cycle

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: .zero)
        setup()
    }    

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientMaskLayer.frame = gradientMaskView.bounds
        setGradientMask()
    }

    func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    func setupBackgroundView() {
        backgroundImageView = UIImageView()
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.isUserInteractionEnabled = true
        backgroundImageView.clipsToBounds = true
        backgroundImageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        headerView.addSubview(backgroundImageView)
    }
    
    func setupSubviews() {
        addSubview(segmentedView)
        setupBackgroundView()
        headerView.addSubview(infoContentView)
        headerView.addSubview(avatarWrapperView)
        infoContentView.addSubview(nameTagView)
        infoContentView.addSubview(infoStack)
        infoContentView.addSubview(focusView)
        infoStack.addArrangedSubview(aliasView)
        infoStack.addArrangedSubview(companyContainer)
        infoStack.addArrangedSubview(badgeContainer)
        infoStack.addArrangedSubview(statusContainer)
        infoStack.addArrangedSubview(buttonsContainer)
        badgeContainer.addSubview(customBadgeView)
        buttonsContainer.addSubview(buttonsContainerStack)
        backgroundImageView.addSubview(gradientMaskView)
        gradientMaskView.layer.insertSublayer(gradientMaskLayer, at: 0)
        addSubview(navigationBar)
        addSubview(addContactView)
        addSubview(applyCommunicationView)
    }
    
    func setupConstraints() {
        navigationBar.snp.remakeConstraints { make in
            make.top.left.trailing.equalToSuperview()
        }
        segmentedView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundImageView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
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
        focusView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-20)
            make.leading.greaterThanOrEqualTo(avatarWrapperView.snp.trailing).offset(24)
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
        buttonsContainerStack.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
        customBadgeView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.bottom.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.height.equalTo(18)
        }
        addContactView.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        applyCommunicationView.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
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
        aliasView.isHidden = true
        focusView.isHidden = false
    }
    
    func setUserDescription(_ info: ProfileUserInfo) {
        // 个人签名
        if let statusView = info.descriptionView {
            statusContainer.isHidden = false
            for subview in statusContainer.subviews {
                subview.removeFromSuperview()
            }
            statusContainer.addSubview(statusView)
            statusView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(8)
                make.leading.trailing.bottom.equalToSuperview()
            }
        } else {
            statusContainer.isHidden = true
        }
    }
    
    /// 设置用户的个人信息模块
    func setUserInfo(_ info: ProfileUserInfo) {
        setUserName(info)
        setUserTags(info)
        setFocusStatus(info)
        setUserCompany(info)
        setUserCustomBadges(info)
        setUserDescription(info)
        setMetaUnitDescription(info)
        segmentedView.userID = info.id
    }

    func setUserName(_ info: ProfileUserInfo) {
        // 姓名
        if info.alias.isEmpty {
            navigationBar.titleLabel.text = info.name
            nameTagView.setName(info.name)
            aliasView.setAlias("")
        } else {
            navigationBar.titleLabel.text = info.alias
            nameTagView.setName(info.alias)
            aliasView.setAlias(info.name)
        }

        aliasView.isHidden = info.pronouns.isEmpty && info.alias.isEmpty
        aliasView.setPronouns(info.pronouns)
    }

    func setUserTags(_ info: ProfileUserInfo) {
        // 状态标签
        nameTagView.setTags(info.nameTag)
    }
}

extension ProfileView {

    // MARK: Public APIs

    /// 创建一个 UIImageView 并设为头像（头像点击事件由 Provider 处理）
    /// - Parameter imageView: 接受一个闭包是因为需要创建两个不同的实例
    func setAvatarView(_ imageView: () -> UIView?) {
        avatarWrapperView.subviews.forEach { view in
            view.removeFromSuperview()
        }
        if let imageView = imageView() {
            avatarWrapperView.addSubview(imageView)
            imageView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    func setNavigationBarAvatarView(_ imageView: () -> UIView?) {
        navigationBar.avatarView.customView = imageView()
    }

    /// 设置用户的 CTA 按钮
    func setCTAButtons(_ items: [ProfileCTAItem]) {
        buttonsContainer.isHidden = items.isEmpty
        buttonsContainerStack.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        buttonsStack.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        let style: ProfileCTAControl.Style = items.count == 1 ? .horizontal : .vertical

        func setVerticalCTAControl(_ items: [ProfileCTAItem]) {
            if items.isEmpty {
                return
            }

            if items[items.count - 1].title.isEmpty {
                // 除最后一个折叠CTA，其他CTA都放在等宽排列的stack中
                for index in 0..<items.count - 1 {
                    let button = ProfileCTAControl(item: items[index], style: .vertical)
                    buttonsStack.addArrangedSubview(button)
                }
                // 最后一个CTA因为宽度特殊，需单独放在containerStack中
                let lastButton = ProfileCTAControl(item: items[items.count - 1], style: .vertical)
                lastButton.snp.remakeConstraints { make in
                    make.width.height.equalTo(48)
                }
                if items[items.count - 1].title.isEmpty {
                    lastButton.placeIconInTheMiddle()
                    lastButton.hideTextLabel()
                }
                buttonsContainerStack.addArrangedSubview(buttonsStack)
                buttonsContainerStack.addArrangedSubview(lastButton)
            } else {
                // 先放在等宽排列的buttonsStack中，再将buttonsStack加在container上
                for item in items {
                    let button = ProfileCTAControl(item: item, style: style)
                    buttonsStack.addArrangedSubview(button)
                }
                buttonsContainerStack.addArrangedSubview(buttonsStack)
            }
        }

        func setHorizontalCTAControl(_ items: [ProfileCTAItem]) {
            // 只有一个CTA时，直接把CTA放在containerStack
            for item in items {
                let button = ProfileCTAControl(item: item, style: .horizontal)
                buttonsContainerStack.addArrangedSubview(button)
            }
        }

        if style == .vertical {
            setVerticalCTAControl(items)
        } else {
            setHorizontalCTAControl(items)
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
    func setInfoStatus(_ status: ProfileStatus, reloadHandler: @escaping () -> Void) {
        switch status {
        case .normal:
            segmentedView.viewStatus = .normal
        case .empty:
            segmentedView.viewStatus = .empty
        case .noPermission:
            segmentedView.viewStatus = .noPermission
        case .error:
            segmentedView.viewStatus = .error(reload: reloadHandler)
        }
    }

    func setFocusStatus(_ info: ProfileUserInfo) {
        focusView.configure(with: info.focusList.topActive, isEditable: info.isSelf)
    }

    func setUserCompany(_ info: ProfileUserInfo) {
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

    func setUserCustomBadges(_ info: ProfileUserInfo) {
        // 自定义标签
        badgeContainer.isHidden = info.customBadges.isEmpty
        for subview in customBadgeView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        for newBadge in info.customBadges {
            customBadgeView.addArrangedSubview(newBadge)
        }
    }

    func setMetaUnitDescription(_ info: ProfileUserInfo) {
        addContactView.userDescription = info.metaUnitDescription
    }
}

public enum ProfileViewInfoData {
    public static var iPadViewSize: CGSize { CGSize(width: 420, height: 650) }
}

extension ProfileView {
    enum Cons {
        static var infoBgColor: UIColor { Display.pad ? UIColor.ud.bgFloat : UIColor.ud.bgBody }
        static var infoCornerRadius: CGFloat { 0 }
        static var nameFont: UIFont { UIFont.ud.title0 }
        static var statusFont: UIFont { UIFont.ud.body2 }
        static var avatarSize: CGFloat { 108 }
        static var avatarMargin: CGFloat { 16 }
        static var hMargin: CGFloat { 20 }
        static var bgAspectRatio: CGFloat { 375/160 }
        static var iPadViewSize: CGSize { ProfileViewInfoData.iPadViewSize }
        static var bgImageHeight: CGFloat {
            if Display.pad {
                return ceil(iPadViewSize.width / bgAspectRatio)
            } else {
                //避免此时拿到的屏幕宽度不正确，取两者的最小值
                let width = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
                return ceil(width / bgAspectRatio)
            }
        }
    }
}

extension LKLabel {

    func setPreferredLayoutWidth(_ width: CGFloat) {
        self.preferredMaxLayoutWidth = width
    }
}
