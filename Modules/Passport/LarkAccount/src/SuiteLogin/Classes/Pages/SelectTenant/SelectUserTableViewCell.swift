//
//  SelectUserTableViewCell.swift
//  LarkAccount
//
//  Created by dengbo on 2021/6/2.
//

import UIKit
import Kingfisher
import LKCommonsLogging
import SnapKit
import UniverseDesignCheckBox
import UniverseDesignIcon
import UniverseDesignTag

class V4SelectUserCellBase: UITableViewCell {
    var enableLabelWidthConstraintMaker: ConstraintMakerEditable?
    var enableLabelWidthConstraint: LayoutConstraint? {
        return enableLabelWidthConstraintMaker?.constraint.layoutConstraints.first
    }
}

class V4CardContainerView: UIView {

    static let enableBackgroundColor: UIColor = UIColor.ud.udtokenComponentOutlinedBg
    static let disableBackgroundColor: UIColor = UIColor.ud.udtokenInputBgDisabled
    
    convenience init() {
        self.init(frame: .zero)
        layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        layer.borderWidth = 1
        layer.cornerRadius = Common.Layer.commonCardContainerViewRadius
        backgroundColor = V4CardContainerView.enableBackgroundColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func updateSelection(_ selected: Bool) {
        backgroundColor = selected ? Self.disableBackgroundColor : Self.enableBackgroundColor
    }
}

class SelectUserTableViewCell: V4SelectUserCellBase, V3SelectTenantCellProtocol {

    private static let logger = Logger.log(SelectUserTableViewCell.self, category: "SuiteLogin.SelectUserTableViewCell")

    let avatarImageView: UIImageView = {
        let avatarImageView = UIImageView(frame: .zero)
        avatarImageView.layer.cornerRadius = Common.Layer.commonAvatarImageRadius
        avatarImageView.clipsToBounds = true
        return avatarImageView
    }()

    let titleLabel: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.numberOfLines = 1
        lbl.font = UIFont.boldSystemFont(ofSize: Layout.titileFontSize)
        lbl.textColor = UIColor.ud.textTitle
        lbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return lbl
    }()

    let subtitleLabel: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.numberOfLines = 1
        lbl.font = UIFont.boldSystemFont(ofSize: Layout.subtitleFontSize)
        lbl.textColor = UIColor.ud.textCaption
        return lbl
    }()

    let tagLabel: TagInsetLabel = {
        return TagInsetLabel(style: .blue)
    }()

    let tagView: UDTag = {
        let icon = UDIcon.getIconByKey(.verifyFilled,
                                       iconColor: UIColor.ud.udtokenTagTextSTurquoise,
                                       size: CGSize(width: 12, height: 12))
        var tag = UDTag(withIcon: icon, text: I18N.Lark_Passport_UserActiveVerification_JoinList_VerifiedLabel)
        tag.colorScheme = .turquoise
        tag.sizeClass = .mini
        return tag
    }()

    let actionLabel: InsetLabel = {
        return InsetLabel(style: .blue)
    }()

    let arrowImageView: UIImageView = {
        let imgView = UIImageView()
        let img = BundleResources.UDIconResources.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        imgView.image = img
        imgView.frame.size = img.size
        return imgView
    }()
    
    let checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple)
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()

    let container: V4CardContainerView

    var data: SelectUserCellData? {
        didSet {
            updateDisplay()
        }
    }

    var isEnableCanSelect: Bool {
        return data?.isValid ?? false
    }
    
    var showCheckBox: Bool = false {
        didSet {
            let show = showCheckBox
            if checkBox.isHidden != !show {
                checkBox.alpha = show ? 0 : 1.0
                checkBox.isHidden = false
                UIView.animate(withDuration: 0.25) { [weak self] in
                    self?.checkBox.alpha = show ? 1.0 : 0
                } completion: { [weak self] _ in
                    self?.checkBox.isHidden = !show
                }
            }
        }
    }

    func updateDisplay() {
        guard let data = data else {
            return
        }
        titleLabel.text = data.tenantName
        subtitleLabel.text = data.userName
        setImage(
            urlString: data.iconUrl,
            placeholder: data.defaultIcon
        )
        self.avatarImageView.layer.cornerRadius = Common.Layer.commonAvatarImageRadius
        if data.type == .normal {
            titleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(avatarImageView.snp.right).offset(CL.itemSpace)
                make.bottom.equalTo(avatarImageView.snp.centerY)
            }
            setSubtitleLine(hidden: false)
        } else {
            titleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(avatarImageView.snp.right).offset(CL.itemSpace)
                make.centerY.equalTo(avatarImageView.snp.centerY)
            }
            setSubtitleLine(hidden: true)
        }

        let status = V4UserItem.getStatus(from: data.status)
        if let tag = data.tag, !tag.isEmpty, !tagLabel.isHidden {
            tagLabel.text = tag
            switch status {
            case .enable:
                tagLabel.setStyle(.blue)
            case .forbidden:
                tagLabel.setStyle(.red)
            case .freeze:
                tagLabel.setStyle(.gray)
            case .unactivated:
                tagLabel.setStyle(.blue)
            case .unauthorized:
                tagLabel.setStyle(.gray)
            case .reviewing:
                tagLabel.setStyle(.purple)
            default:
                tagLabel.setStyle(.blue)
            }
        } else {
            tagLabel.text = nil
            tagLabel.isHidden = true
        }

        // 企业tag（飞书认证）和个人tag都显示，个人tag在前，企业tag在后
        tagView.isHidden = !data.isCertificated

        arrowImageView.isHidden = true
        actionLabel.isHidden = true
        self.enableLabelWidthConstraint?.constant = 0
        actionLabel.text = nil
        
        if isEnableCanSelect {
            if data.canEdit {
                checkBox.isSelected = data.isSelected
            } else if let buttonInfo = data.enableBtnInfo {
                actionLabel.isHidden = false
                actionLabel.text = buttonInfo.text
                let maxSize = InsetLabel.estimateWidth(forText: buttonInfo.text, inSize: bounds.size)
                self.enableLabelWidthConstraint?.constant = maxSize.width
            } else {
                arrowImageView.isHidden = false
            }
        }
        
        // Update disabled cell
        if isEnableCanSelect || actionLabel.isHidden == false {
            titleLabel.alpha = 1.0
            subtitleLabel.alpha = 1.0
            avatarImageView.alpha = 1.0
        } else {
            titleLabel.alpha = 0.5
            subtitleLabel.alpha = 0.5
            avatarImageView.alpha = 0.5
        }
    }

    func setSubtitleLine(hidden: Bool) {
        subtitleLabel.isHidden = hidden
        tagLabel.isHidden = hidden
    }

    func updateSelection(_ selected: Bool) {
        guard data != nil else {
            return
        }
        if isEnableCanSelect {
            container.updateSelection(selected)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.container = V4CardContainerView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.selectionStyle = .none
        contentView.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(Layout.shadowHeight * 2)
        }

        let subtitleStack = UIStackView()
        subtitleStack.axis = .horizontal
        subtitleStack.spacing = 4
        subtitleStack.addArrangedSubview(subtitleLabel)

        tagView.isHidden = true
        subtitleStack.addArrangedSubview(tagLabel)
        subtitleStack.addArrangedSubview(tagView)

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleStack)

        let mainStack = UIStackView()
        mainStack.axis = .horizontal
        mainStack.spacing = CL.itemSpace
        mainStack.alignment = .center

        container.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.leading.equalTo(CL.itemSpace)
            make.trailing.equalTo(-CL.itemSpace)
            make.centerY.equalToSuperview()
        }

        checkBox.isHidden = true
        mainStack.addArrangedSubview(checkBox)
        mainStack.setCustomSpacing(12, after: checkBox)

        avatarImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: Layout.avatarWidth, height: Layout.avatarWidth))
        }
        mainStack.addArrangedSubview(avatarImageView)
        mainStack.setCustomSpacing(CL.itemSpace, after: avatarImageView)

        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        mainStack.addArrangedSubview(textStack)

        actionLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        mainStack.addArrangedSubview(actionLabel)

        arrowImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: arrowImageView.frame.size.width, height: arrowImageView.frame.size.height))
        }
        mainStack.addArrangedSubview(arrowImageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(urlString: String, placeholder: UIImage) {
        guard let url = URL(string: urlString) else {
            self.avatarImageView.image = placeholder
            return
        }
        self.avatarImageView.kf.setImage(with: url,
                                         placeholder: placeholder)
    }
}

extension SelectUserTableViewCell {
    fileprivate struct Layout {
        static let verticalSpace: CGFloat = 15
        static let titileFontSize: CGFloat = 17
        static let subtitleFontSize: CGFloat = 14
        static let avatarWidth: CGFloat = 48
        static let tagItemSpace: CGFloat = 12
        static let tagHeight: CGFloat = 14
        static let nameHeight: CGFloat = 24
        static let tenantHeight: CGFloat = 20
        static let disableLabelLeft: CGFloat = 4
        static let shadowHeight: CGFloat = 2.0
        static let arrowHeight: CGFloat = 24.0
    }
}
