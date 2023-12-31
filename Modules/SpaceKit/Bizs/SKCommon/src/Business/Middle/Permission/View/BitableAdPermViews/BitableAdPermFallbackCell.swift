//
//  BitableAdPermFallbackCell.swift
//  SKCommon
//
//  Created by zhysan on 2023/9/19.
//

import SKFoundation
import SnapKit
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignLoading
import ByteWebImage
import SKResource
import RxCocoa
import RxSwift
import SKUIKit

private extension LinkShareEntityV2 {
    var isEnable: Bool {
        self != .close
    }
    
    var avatarIcon: UIImage? {
        switch self {
        case .close:
            return nil
        case .tenantCanRead, .tenantCanEdit, .partnerTenantCanRead, .partnerTenantCanEdit:
            return UDIcon.buildingOutlined.ud.withTintColor(UDColor.staticWhite).ud.resized(to: CGSize(width: 14, height: 14))
        case .anyoneCanRead, .anyoneCanEdit:
            return UDIcon.languageOutlined.ud.withTintColor(UDColor.staticWhite).ud.resized(to: CGSize(width: 14, height: 14))
        }
    }
}

private extension BitableAdPermUnitDataFallback {
    /// 底部是否需要显示默认协作者成员列表
    var shouldShowFallbackMembersSection: Bool {
        guard !isTemplate else {
            // 模板不显示
            return false
        }
        guard linkShareEntity.isEnable || !fallbackCollaborators.isEmpty else {
            // 没有打开链接分享，并且协作者为空时，不显示（列表没有数据）
            return false
        }
        if !linkShareEntity.isEnable, !UserScopeNoChangeFG.ZYS.baseAdPermAggressiveRolePreview {
            // 没有打开链接分享，并且 FG 控制不显示角色，不显示（没有展示内容）
            return false
        }
        return true
    }
}

protocol BitableAdPermFallbackCellDelegate: AnyObject {
    func fallbackCellCollaboratorDidTap(_ cell: BitableAdPermFallbackCell, collaborator: Collaborator)
    func fallbackCellCollaboratorMoreDidTap(_ cell: BitableAdPermFallbackCell)
    func fallbackCellConfigAreaDidTap(_ cell: BitableAdPermFallbackCell)
    func fallbackCellLinkAvatarDidPress(_ cell: BitableAdPermFallbackCell, linkEntity: LinkShareEntityV2, fromView: UIView)
}

final class BitableAdPermFallbackCell: BitableAdPermBaseCell {
    
    // MARK: - public
    
    static let defaultReuseID = "BitableAdPermFallbackCell"
    
    weak var delegate: BitableAdPermFallbackCellDelegate?
    
    var isLoading: Bool = false {
        didSet {
            if oldValue != isLoading {
                updateLoadingStyle()
            }
        }
    }
    
    var fallbackContext = BitableAdPermUnitDataFallback(
        linkShareEntity: .close,
        fallbackConfig: nil,
        currentFallbackRole: nil,
        fallbackCollaborators: [],
        isEditable: false,
        isTemplate: false
    ) {
        didSet {
            cellModelDidUpdate()
        }
    }
    
    func hideTooltipViewIfNeeded() {
        tipView.removeFromSuperview()
    }
    
    // MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        let shouldShowFallbackMembersSection = fallbackContext.shouldShowFallbackMembersSection
        rolesListView.snp.updateConstraints { make in
            make.height.equalTo(shouldShowFallbackMembersSection ? Const.avatarSize : 0)
            make.edges.equalToSuperview().inset(shouldShowFallbackMembersSection ? Const.listPadding : 0)
        }
        
        super.updateConstraints()
    }
    
    // MARK: - private
    
    private struct Const {
        static let headerPaddingUp: CGFloat = 12
        static let headerPaddingLR: CGFloat = 16
        static let headerPaddingDown: CGFloat = 8
        
        static let arrowSize: CGFloat = 16.0
        
        static let listPadding: CGFloat = 16.0
        static let listH: CGFloat = 32
        
        static let avatarSize: CGFloat = 32.0
        static let avatarSpace: CGFloat = 8.0
        static let avatarBorderWidth: CGFloat = 2.0
    }
    
    private let topWrapper = UIView()
    
    private let botWrapper = UIView()
    
    private let headerWrapper = UIView()
    
    private let leftLabel = UILabel().construct { it in
        it.numberOfLines = 0
        it.font = UDFont.headline
        it.textColor = UDColor.textTitle
        it.textAlignment = .left
    }
    
    private let rightWrapper = UIView()
    
    private let rightLabel = UILabel().construct { it in
        it.numberOfLines = 2
        it.font = UDFont.body0
        it.textColor = UDColor.textCaption
        it.textAlignment = .right
    }
    
    private let accessoryView = UIImageView().construct { it in
        it.image = UDIcon.rightOutlined.ud.withTintColor(UDColor.iconN3)
    }
    
    private lazy var loadingSpin: UDSpin = {
        let c1 = UDSpinIndicatorConfig(size: 24, color: UDColor.primaryContentDefault)
        let c2 = UDSpinConfig(indicatorConfig: c1, textLabelConfig: nil)
        return UDSpin(config: c2)
    }()
    
    private let spLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
        it.isUserInteractionEnabled = false
    }
    
    private let tipView = TooltipView()
    
    private let rolesListView = UIView()
    
    private func subviewsInit() {
        contentView.addSubview(topWrapper)
        contentView.addSubview(botWrapper)
        topWrapper.addSubview(headerWrapper)
        headerWrapper.addSubview(leftLabel)
        headerWrapper.addSubview(rightWrapper)
        rightWrapper.addSubview(rightLabel)
        rightWrapper.addSubview(accessoryView)
        botWrapper.addSubview(spLine)
        botWrapper.addSubview(rolesListView)
        
        topWrapper.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
        }
        headerWrapper.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Const.headerPaddingUp)
            make.left.right.equalToSuperview().inset(Const.headerPaddingLR)
            make.height.greaterThanOrEqualTo(32)
            make.bottom.equalToSuperview().inset(Const.headerPaddingDown)
        }
        leftLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2)
        }
        rightWrapper.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(leftLabel.snp.right).offset(10)
            make.right.equalToSuperview()
        }
        rightLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
        }
        accessoryView.snp.makeConstraints { make in
            make.width.height.equalTo(Const.arrowSize)
            make.left.equalTo(rightLabel.snp.right).offset(4)
            make.centerY.right.equalToSuperview()
        }
        
        botWrapper.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(topWrapper.snp.bottom)
        }
        spLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(Const.listPadding)
        }
        
        leftLabel.text = BundleI18n.SKResource.Bitable_AdvancedPermissionsInherit_NotAssignedRoles_ForOtherCollaborators_Title
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onConfigAreaClick(_:)))
        rightWrapper.addGestureRecognizer(tap)
    }
    
    private func cellModelDidUpdate() {
        if let config = fallbackContext.fallbackConfig, config.defaultConfig.accessStrategy == .forbidden {
            rightLabel.text = BundleI18n.SKResource.Bitable_AdvancedPermissionsInherit_NotAssignedRoles_NoPermissions_Option
        } else if let bindRole = fallbackContext.currentFallbackRole {
            rightLabel.text = bindRole.name
        } else {
            rightLabel.text = BundleI18n.SKResource.Bitable_AdvancedPermissions_AccessWith_SelectRole_Placeholder

        }
        
        if !fallbackContext.isEditable {
            rightLabel.textColor = UDColor.textDisabled
            accessoryView.image = UDIcon.rightOutlined.ud.withTintColor(UDColor.iconDisabled)
        } else {
            rightLabel.textColor = UDColor.textCaption
            accessoryView.image = UDIcon.rightOutlined.ud.withTintColor(UDColor.iconN3)
        }
        
        updateDisplayCollaboratorListIfNeeded()
    }
    
    private func updateLoadingStyle() {
        if isLoading {
            loadingSpin.removeFromSuperview()
            headerWrapper.addSubview(loadingSpin)
            loadingSpin.snp.makeConstraints { make in
                make.right.centerY.equalToSuperview()
            }
            rightLabel.isHidden = true
            accessoryView.isHidden = true
        } else {
            loadingSpin.removeFromSuperview()
            rightLabel.isHidden = false
            accessoryView.isHidden = false
        }
    }
    
    @objc
    private func onLinkAvatarClick(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began, let targetView = sender.view else {
            return
        }
        tipView.removeFromSuperview()
        contentView.addSubview(tipView)
        tipView.snp.makeConstraints { make in
            make.left.equalTo(targetView.snp.left).offset(-8)
            make.bottom.equalTo(targetView.snp.top).offset(-8)
        }
        
        delegate?.fallbackCellLinkAvatarDidPress(self, linkEntity: fallbackContext.linkShareEntity, fromView: targetView)
    }
    
    @objc
    private func onConfigAreaClick(_ sender: UITapGestureRecognizer) {
        guard fallbackContext.isEditable else {
            return
        }
        delegate?.fallbackCellConfigAreaDidTap(self)
    }
    
    private func updateDisplayCollaboratorListIfNeeded() {
        setNeedsUpdateConstraints()
        
        guard fallbackContext.shouldShowFallbackMembersSection else {
            botWrapper.isHidden = true
            return
        }
        botWrapper.isHidden = false
        rolesListView.subviews.forEach({ $0.removeFromSuperview() })
        
        let containerW = cellWidth - Const.listPadding * 2
        let maxDisplayCount = Int((containerW + Const.avatarSpace) / (Const.avatarSize + Const.avatarSpace))
        
        let needShowLink = fallbackContext.linkShareEntity.isEnable
        let needShowMore = fallbackContext.fallbackCollaborators.count > maxDisplayCount
        
        var avatarIndex = 0
        
        if needShowLink {
            // 添加「获得分享链接的协作者」头像
            let originX = CGFloat(avatarIndex) * (Const.avatarSize + Const.avatarSpace)
            let linkAvatar = UIImageView(image: fallbackContext.linkShareEntity.avatarIcon)
            linkAvatar.frame = CGRect(x: originX, y: 0, width: Const.avatarSize, height: Const.avatarSize)
            linkAvatar.contentMode = .center
            linkAvatar.clipsToBounds = true
            linkAvatar.isUserInteractionEnabled = true
            linkAvatar.layer.cornerRadius = Const.avatarSize * 0.5
            linkAvatar.layer.borderWidth = Const.avatarBorderWidth
            linkAvatar.layer.ud.setBorderColor(UDColor.B200)
            linkAvatar.backgroundColor = UDColor.B500
            rolesListView.addSubview(linkAvatar)
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onLinkAvatarClick(_:)))
            longPress.minimumPressDuration = 1.0
            let tap = UITapGestureRecognizer(target: nil, action: nil)
            linkAvatar.addGestureRecognizer(tap)
            linkAvatar.addGestureRecognizer(longPress)
            
            avatarIndex += 1
        }
        
        guard UserScopeNoChangeFG.ZYS.baseAdPermAggressiveRolePreview else {
            // 如果 FG 没打开，不显示具体的协作者，但是上面链接分享者的图标还是展示
            return
        }
        
        for (index, collaborator) in fallbackContext.fallbackCollaborators.enumerated() {
            if avatarIndex < maxDisplayCount {
                let x = CGFloat(avatarIndex) * (Const.avatarSize + Const.avatarSpace)
                if needShowMore && avatarIndex == maxDisplayCount - 1 {
                    // 这里使用 MoreAvatarView，目的是让视觉效果和协作者列表对齐
                    let moreNum = fallbackContext.fallbackCollaborators.count - index
                    let moreView = MoreAvatarView()
                    moreView.clipsToBounds = true
                    moreView.layer.cornerRadius = Const.avatarSize * 0.5
                    moreView.layer.borderWidth = 0
                    moreView.backgroundColor = UDColor.bgFiller
                    moreView.update(number: moreNum)
                    rolesListView.addSubview(moreView)
                    moreView.snp.makeConstraints { make in
                        make.left.equalToSuperview().offset(x)
                        make.top.equalToSuperview()
                        make.width.height.equalTo(Const.avatarSize)
                    }
                    break
                }
                let avatarBtn = UIButton(type: .custom)
                avatarBtn.clipsToBounds = true
                avatarBtn.layer.cornerRadius = Const.avatarSize * 0.5
                rolesListView.addSubview(avatarBtn)
                avatarBtn.snp.makeConstraints { make in
                    make.left.equalToSuperview().offset(x)
                    make.top.equalToSuperview()
                    make.width.height.equalTo(Const.avatarSize)
                }
                if collaborator.avatarURL.hasPrefix("http") {
                    avatarBtn.kf.setImage(
                        with: URL(string: collaborator.avatarURL),
                        for: .normal,
                        placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder
                    )
                } else if collaborator.avatarURL == "icon_tool_sharefolder" {
                    avatarBtn.setImage(
                        UDIcon.fileSharefolderColorful.ud.resized(to: CGSize(width: 20, height: 20)),
                        for: .normal
                    )
                } else {
                    avatarBtn.setImage(collaborator.avatarImage, for: .normal)
                }
                avatarBtn.rx.tap.subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.fallbackCellCollaboratorDidTap(self, collaborator: collaborator)
                }).disposed(by: disposeBag)
                
                avatarIndex += 1
            }
        }
    }
}

final private class TooltipView: UIView {
    // MARK: - public
    
    // MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private let wrapperView: UIView = {
        let vi = UIView()
        vi.backgroundColor = UDColor.bgTips
        vi.clipsToBounds = true
        vi.layer.cornerRadius = 8.0
        return vi
    }()
    
    private let textLabel: UILabel = {
        let vi = UILabel()
        vi.font = UDFont.caption1
        vi.textColor = UDColor.staticWhite
        vi.text = BundleI18n.SKResource.Bitable_AdvancedPermissionsInherit_NotAssignedRoles_OtherWaysToGainRoles_NewCollaboratorsViaLink_Text
        return vi
    }()
    
    private let arrowView: UIImageView = {
        let vi = UIImageView()
        vi.image = BundleResources.SKResource.Bitable.base_tooltip_caret_down.ud.withTintColor(UDColor.bgTips)
        return vi
    }()
    
    private func subviewsInit() {
        layer.ud.setShadow(type: .s4Down)
        addSubview(wrapperView)
        addSubview(arrowView)
        wrapperView.addSubview(textLabel)
        
        wrapperView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
        }
        arrowView.snp.makeConstraints { make in
            make.top.equalTo(wrapperView.snp.bottom)
            make.width.equalTo(16)
            make.height.equalTo(6)
            make.bottom.equalToSuperview()
            make.left.equalTo(16)
        }
        
        textLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.edges.equalToSuperview().inset(UIEdgeInsets(horizontal: 12, vertical: 8))
        }
    }
}
