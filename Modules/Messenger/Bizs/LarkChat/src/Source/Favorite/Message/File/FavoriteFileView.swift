//
//  FavoriteFileView.swift
//  LarkChat
//
//  Created by bytedance on 2020/12/28.
//

import Foundation
import UIKit
import LarkMessengerInterface
import LarkContainer
import LarkMessageCore

// 自己撑开高度，宽度由外界指定
final class FavoriteFileView: UIView {
    enum Cons {
        static var titleFont: UIFont { UIFont.ud.body0 }
        static var sizeFont: UIFont { UIFont.ud.caption1 }
        static var vMargin: CGFloat { 15.5 }
        static var hMargin: CGFloat { 16 }
        static var titleSizeSpacing: CGFloat { 6 }
        static var iconSize: CGSize {
            let size = ceil(titleFont.lineHeight + sizeFont.lineHeight + titleSizeSpacing)
            return CGSize(width: size, height: size)
        }
    }

    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let sizeLabel = UILabel()
    private let noPermisssionlabel = UILabel()

    var tapBlock: ((FavoriteFileView, UIWindow) -> Void)?

    init() {
        super.init(frame: CGRect.zero)

        backgroundColor = .clear

        addSubview(iconImageView)
        iconImageView.layer.masksToBounds = true
        iconImageView.layer.cornerRadius = 4
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.snp.makeConstraints { (make) in
            make.size.equalTo(Cons.iconSize)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.top.equalToSuperview().offset(Cons.vMargin)
            make.bottom.equalToSuperview().offset(-Cons.vMargin)
        }

        addSubview(nameLabel)
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.font = Cons.titleFont
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconImageView)
            make.left.equalTo(iconImageView.snp.right).offset(Cons.hMargin)
            make.right.lessThanOrEqualToSuperview().offset(-Cons.hMargin)
        }

        addSubview(sizeLabel)
        sizeLabel.textColor = UIColor.ud.N500
        sizeLabel.font = Cons.sizeFont
        sizeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(Cons.hMargin)
            make.right.lessThanOrEqualToSuperview().offset(-Cons.hMargin)
            make.bottom.equalTo(iconImageView)
        }

        self.addSubview(noPermisssionlabel)
        noPermisssionlabel.text = BundleI18n.LarkChat.Lark_IM_UnableToPreview_Button
        noPermisssionlabel.textColor = UIColor.ud.textPlaceholder
        noPermisssionlabel.font = UIFont.systemFont(ofSize: 12)
        noPermisssionlabel.textAlignment = .left
        noPermisssionlabel.lineBreakMode = .byTruncatingTail
        noPermisssionlabel.snp.makeConstraints { (make) in
            make.width.height.equalToSuperview()
            make.top.equalTo(iconImageView)
            make.left.equalTo(iconImageView.snp.right).offset(Cons.hMargin)
        }

        layer.cornerRadius = 8
        layer.borderWidth = 0.5
        layer.ud.setBorderColor(UIColor.ud.N300)

        lu.addTapGestureRecognizer(action: #selector(fileViewTapped))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(resolver: Resolver, icon: UIImage, name: String, size: String, hasPermissionPreview: Bool, dynamicAuthorityEnum: DynamicAuthorityEnum) {
        if !(hasPermissionPreview && dynamicAuthorityEnum.authorityAllowed) {
            showNoPermissionPreviewLayer()
            noPermisssionlabel.text = ChatSecurityControlServiceImpl.getNoPermissionSummaryText(permissionPreview: hasPermissionPreview,
                                                                                                dynamicAuthorityEnum: dynamicAuthorityEnum,
                                                                                                sourceType: .file)
        } else {
            hideNoPermissionPreviewLayer()
        }
        iconImageView.image = icon
        nameLabel.text = name
        sizeLabel.text = size
    }

    private func showNoPermissionPreviewLayer() {
        nameLabel.textColor = UIColor.ud.textPlaceholder
        noPermisssionlabel.isHidden = false
        sizeLabel.isHidden = true
    }

    private func hideNoPermissionPreviewLayer() {
        nameLabel.textColor = UIColor.ud.N900
        noPermisssionlabel.isHidden = true
        sizeLabel.isHidden = false
    }

    @objc
    private func fileViewTapped() {
        guard let window = self.window else {
            assertionFailure()
            return
        }
        tapBlock?(self, window)
    }
}
