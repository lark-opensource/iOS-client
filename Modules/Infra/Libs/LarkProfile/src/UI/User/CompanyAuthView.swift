//
//  CompanyAuthView.swift
//  LarkProfileDev
//
//  Created by Hayden Wang on 2021/7/8.
//

import Foundation
import UIKit
import RichLabel
import UniverseDesignIcon
import EENavigator

public final class CompanyAuthView: UIStackView {
    var isAuth: Bool = false
    var isShowTagView: Bool = false
    var tapCallback: (() -> Void)?

    var textLabel: LKLabel = {
        let label = LKLabel()
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textTitle, .font: UIFont.systemFont(ofSize: 12)]
        label.numberOfLines = 2
        label.backgroundColor = .clear
        label.outOfRangeText = NSAttributedString(string: "...", attributes: attributes)
        label.textColor = UIColor.ud.textTitle
        label.textVerticalAlignment = .bottom
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    var tagView: AuthTagView = {
        let tagView = AuthTagView()
        return tagView
    }()

    var tapGesture: UITapGestureRecognizer?

    var newlineWrapper = UIView()

    public init() {
        super.init(frame: .zero)
        axis = .vertical
        addArrangedSubview(textLabel)
        addArrangedSubview(newlineWrapper)
        textLabel.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tagViewOnTapped))
        textLabel.addGestureRecognizer(tapGesture)

        self.tapGesture = tapGesture
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configUI(tenantName: String,
                         hasAuth: Bool,
                         isAuth: Bool,
                         tapCallback: (() -> Void)?) {

        self.isShowTagView = hasAuth
        self.tapCallback = tapCallback
        let attributedText = NSMutableAttributedString(
            string: tenantName,
            attributes: [
                .foregroundColor: UIColor.ud.textTitle
            ]
        )
        if hasAuth {
            let text = isAuth ? BundleI18n.LarkProfile.Lark_FeishuCertif_Verif : BundleI18n.LarkProfile.Lark_FeishuCertif_Unverif
            let font = UIFont.systemFont(ofSize: 12)
            let icon = isAuth ? UDIcon.verifyFilled.ud.withTintColor(UIColor.ud.udtokenTagTextSTurquoise) : nil
            let backgroundColor = isAuth ? UIColor.ud.udtokenTagBgTurquoise : UIColor.ud.udtokenTagNeutralBgNormal
            let textColor = isAuth ? UIColor.ud.udtokenTagTextSTurquoise : UIColor.ud.textCaption
            let attributedString = NSAttributedString(
                string: text,
                attributes: [
                    .foregroundColor: textColor,
                    .font: font
                ]
            )
            tagView.removeFromSuperview()
            tagView.snp.removeConstraints()

            tagView = AuthTagView()

            tagView.configUI(backgroundColor: backgroundColor,
                             icon: icon,
                             font: font,
                             attributedString: attributedString)

            tagView.frame.size = tagView.getSize()

            let attachment = LKAttachment(view: tagView)
            attachment.margin = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
            attachment.fontAscent = font.ascender
            attachment.fontDescent = font.descender
            attachment.verticalAlignment = .middle
            let attachmentStr = NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [
                    LKAttachmentAttributeName: attachment
                ]
            )
            self.isAuth = isAuth
            attributedText.append(attachmentStr)
        }
        self.textLabel.attributedText = attributedText
        self.textLabel.tapableRangeList = [NSRange(location: 0, length: tenantName.count)]
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.preferredMaxLayoutWidth = bounds.width
        textLabel.invalidateIntrinsicContentSize()
    }

    func adjustCustomViewPosition(newLine: Bool) {
        if newLine {
            newlineWrapper.isHidden = false
            tagView.removeFromSuperview()
            newlineWrapper.addSubview(tagView)
            tagView.snp.makeConstraints { make in
                make.top.bottom.leading.equalToSuperview()
                make.width.lessThanOrEqualToSuperview()
                make.size.equalTo(tagView.getSize())
            }
        } else {
            newlineWrapper.isHidden = true
        }
    }

    @objc
    func tagViewOnTapped() {
        self.tapCallback?()
    }
}

extension CompanyAuthView: LKLabelDelegate {

    func attributedLabel(_ label: LKLabel,
                         index: Int,
                         didSelectText text: String,
                         didSelectRange range: NSRange) -> Bool {
        return true
    }

    public func shouldShowMore(_ label: RichLabel.LKLabel, isShowMore: Bool) {
        guard isShowTagView else { return }
        self.adjustCustomViewPosition(newLine: isShowMore)
    }
}

// mine页专用tagView
final class AuthTagView: UIView {
    lazy var iconView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        return imageView
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 4
        self.layer.masksToBounds = true
        self.addSubview(label)
        self.addSubview(iconView)
    }

    func configUI(backgroundColor: UIColor,
                  icon: UIImage?,
                  font: UIFont,
                  attributedString: NSAttributedString) {
        let isShowIcon = icon != nil
        self.backgroundColor = backgroundColor
        if isShowIcon {
            iconView.frame = CGRect(x: 4, y: 3, width: 12, height: 12)
        }
        if let icon = icon {
            iconView.image = icon
        }
        let width = (attributedString.string  as NSString).boundingRect(
            with: CGSize(width: Int.max, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil).width
        label.frame = CGRect(x: iconView.frame.maxX + (isShowIcon ? 2 : 4), y: 0, width: width, height: 18)
        label.attributedText = attributedString
    }

    func getSize() -> CGSize {
        return CGSize(width: label.frame.maxX + 4, height: 18)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
