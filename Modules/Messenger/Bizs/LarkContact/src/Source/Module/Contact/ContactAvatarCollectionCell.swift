//
//  ContactAvatarCollectionCell.swift
//  LarkContact
//
//  Created by SuPeng on 5/14/19.
//

import Foundation
import UIKit
import LarkModel
import LarkCore
import LarkBizAvatar

public final class ContactAvatarCollectionCell: UICollectionViewCell {

    var cellID: String?

    private let avatarView = BizAvatar()
    private let avatarSize: CGFloat = 30

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(entityId: String, avatarKey: String) {
        avatarView.setAvatarByIdentifier(entityId, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
    }

    func set(mail: String) {
        let image = self.generateAvatarImage(withNameString: String(mail.prefix(2)).uppercased())
        avatarView.image = image
    }

    private func generateAvatarImage(withNameString string: String) -> UIImage? {
        var attribute = [NSAttributedString.Key: Any]()
        attribute[NSAttributedString.Key.foregroundColor] = UIColor.ud.primaryOnPrimaryFill
        attribute[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 20)
        let nameString = NSAttributedString(string: string, attributes: attribute)
        let stringSize = nameString.boundingRect(with: CGSize(width: 100.0, height: 100.0),
                                                 options: .usesLineFragmentOrigin,
                                                 context: nil)
        let padding: CGFloat = 10.0
        let width = max(stringSize.width, stringSize.height) + padding * 2
        let size = CGSize(width: width, height: width)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size),
                                cornerRadius: size.width / 2.0)
        UIColor.ud.colorfulBlue.setFill()
        path.fill()
        nameString.draw(at: CGPoint(x: (size.width - stringSize.width) / 2.0,
                                    y: (size.height - stringSize.height) / 2.0))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
