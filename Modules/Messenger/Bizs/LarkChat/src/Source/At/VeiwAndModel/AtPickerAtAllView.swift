//
//  AtPickerAtAllView.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/3/3.
//

import UIKit
import Foundation
import LarkCore
import LarkModel
import LarkTag
import SnapKit
import LarkUIKit

/// 用于显示@所有人
final class AtPickerAtAllView: UIView {
    static var defaultAtAllId = "all"

    var onTap: (() -> Void)?

    private let avatarImageView = UIImageView(image: Resources.contact_at_all)
    private let nameLabel = UILabel()
    private let subTitleLabel = UILabel()

    init(usersCount: Int, showChatUserCount: Bool, width: CGFloat) {
        super.init(frame: AtPickerAtAllView.defaultFrame(width))
        self.backgroundColor = UIColor.ud.bgBody
        self.subTitleLabel.text = BundleI18n.LarkChat.Lark_Legacy_NotifyAllMembersInChat

        addSubview(avatarImageView)
        avatarImageView.layer.cornerRadius = 24
        avatarImageView.layer.masksToBounds = true
        avatarImageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(48).priority(.required)
            maker.left.equalTo(12)
            maker.centerY.equalToSuperview()
        }

        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.textColor = UIColor.ud.N900
        if showChatUserCount {
            nameLabel.text = "\(BundleI18n.LarkChat.Lark_Legacy_AllPeople)(\(usersCount))"
        } else {
            nameLabel.text = "\(BundleI18n.LarkChat.Lark_Legacy_AllPeople)"
        }
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(avatarImageView.snp.right).offset(12)
            maker.top.equalToSuperview().offset(12)
        }

        subTitleLabel.textColor = UIColor.ud.N500
        subTitleLabel.font = UIFont.systemFont(ofSize: 14)
        subTitleLabel.text = BundleI18n.LarkChat.Lark_Legacy_NotifyAllMembersInChat
        addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(nameLabel)
            maker.top.equalTo(nameLabel.snp.bottom).offset(7)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIColor.ud.N300.withAlphaComponent(0.5)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.5)
        onTap?()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.5)
    }

    static func defaultFrame(_ width: CGFloat) -> CGRect {
        return CGRect(origin: .zero, size: CGSize(width: width, height: 68))
    }
}

/// @群外的人的Section，因为有两个Title所以单独写一个
struct AtPickerOutChatSection: ChatChatterSection {
    private(set) var showHeader: Bool
    private(set) var title: String?
    private(set) var subTitle: String?
    private(set) var indexKey: String
    var items: [ChatChatterItem]
    var sectionHeaderClass: AnyClass

    init(title: String?,
         subTitle: String?,
         indexKey: String? = nil,
         items: [ChatChatterItem],
         sectionHeaderClass: AnyClass) {

        self.title = title
        self.subTitle = subTitle
        self.indexKey = indexKey ?? title ?? ""
        self.items = items
        self.showHeader = true
        self.sectionHeaderClass = sectionHeaderClass
    }
}

extension GrayTableHeader: ChatChatterSectionHeaderProtocol {
    public func set(_ item: ChatChatterSection) {
        if let defaultItem = item as? ChatChatterSectionData {
            self.title.text = defaultItem.title
        } else if let outItem = item as? AtPickerOutChatSection {
            self.title.text = outItem.title
            self.subTitle.text = outItem.subTitle
        }
    }
}
