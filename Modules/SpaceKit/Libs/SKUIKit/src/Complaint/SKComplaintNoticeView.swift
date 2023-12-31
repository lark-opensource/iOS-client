//
//  SKComplaintNoticeView.swift
//  SKUIKit
//
//  Created by Weston Wu on 2022/1/25.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import SKResource
import SKFoundation

private extension SKComplaintNoticeView {
    enum Layout {
        static var labelLeftPadding: CGFloat { 40 }
        static var labelRightPadding: CGFloat { 16 }
        static var labelVerticalInset: CGFloat { 12 }
    }
}

public final class SKComplaintNoticeView: UIView {

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKeyNoLimitSize(.warningColorful)
        return view
    }()

    private lazy var titleLabel: UILabel = Self.createTitleLabel()

    private static func createTitleLabel() -> UILabel {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .left
        label.textColor = UDColor.textTitle
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.isUserInteractionEnabled = true
        return label
    }

    private var state: ComplaintState?
    public var overrideContent: [ComplaintState: String]?

    public var clickLabelHandler: ((ComplaintState) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UDColor.R100
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.left.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(14)
        }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Layout.labelVerticalInset)
            make.left.equalTo(iconView.snp.right).offset(8)
            make.right.equalToSuperview().inset(Layout.labelRightPadding)
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickLabel))
        titleLabel.addGestureRecognizer(tapGesture)
    }

    public func update(complaintState: ComplaintState) {
        state = complaintState
        let text: String = {
            if let overrideContent = overrideContent {
                return complaintState.overrideDetail(using: overrideContent)
            } else {
                return complaintState.detail
            }
        }()
        var linkText: String?
        if UserScopeNoChangeFG.TYP.appealingForbidden {
            switch complaintState {
            case .machineVerify:
                linkText = BundleI18n.SKResource.CreationMobile_appealing_folder_submit
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.errorColorful)
                backgroundColor = UDColor.R100
            case .verifying:
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.errorColorful)
                backgroundColor = UDColor.R100
            case .verifyFailed:
                linkText = BundleI18n.SKResource.CreationMobile_appealing_folder_submit
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.errorColorful)
                backgroundColor = UDColor.R100
            case .unchanged:
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.errorColorful)
                backgroundColor = UDColor.R100
            case .reachVerifyLimitOfDay:
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.errorColorful)
                backgroundColor = UDColor.R100
            case .reachVerifyLimitOfAll:
                linkText = BundleI18n.SKResource.CreationMobile_ECM_Folder_SubmitMaximumToast2
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.errorColorful)
                backgroundColor = UDColor.R100
            }
        } else {
            switch complaintState {
            case .machineVerify:
                linkText = BundleI18n.SKResource.CreationMobile_appealing_folder_submit
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.warningColorful)
                backgroundColor = UDColor.O100
            case .verifying:
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.infoColorful)
                backgroundColor = UDColor.B100
            case .verifyFailed:
                linkText = BundleI18n.SKResource.CreationMobile_appealing_folder_submit
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.errorColorful)
                backgroundColor = UDColor.R100
            case .unchanged:
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.warningColorful)
                backgroundColor = UDColor.O100
            case .reachVerifyLimitOfDay:
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.warningColorful)
                backgroundColor = UDColor.R100
            case .reachVerifyLimitOfAll:
                linkText = BundleI18n.SKResource.CreationMobile_ECM_Folder_SubmitMaximumToast2
                iconView.image = UDIcon.getIconByKeyNoLimitSize(.errorColorful)
                backgroundColor = UDColor.R100
            }
        }
        if let linkText = linkText {
            titleLabel.attributedText = Self.attributedString(detail: text, linkText: linkText)
        } else {
            titleLabel.attributedText = NSMutableAttributedString(string: text, attributes: ComplaintState.attributesForContent)
        }
    }

    private static func attributedString(detail: String, linkText: String) -> NSAttributedString {
        let content = NSMutableAttributedString(string: detail, attributes: ComplaintState.attributesForContent)
        let range = content.mutableString.range(of: linkText)
        content.addAttributes([
            .foregroundColor: UDColor.B400,
            .underlineColor: UIColor.clear
        ], range: range)
        return content
    }

    @objc
    private func didClickLabel() {
        guard let currentState = state else {
            return
        }
        clickLabelHandler?(currentState)
    }

    public static func calculateHeight(text: NSAttributedString, width: CGFloat) -> CGFloat {
        let newText = NSAttributedString(string: text.string, attributes: ComplaintState.attributesForContent)
        let width = width - Layout.labelLeftPadding - Layout.labelRightPadding
        let label = createTitleLabel()
        label.attributedText = newText
        let targetSize = label.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        return targetSize.height + Layout.labelVerticalInset * 2
    }
}
