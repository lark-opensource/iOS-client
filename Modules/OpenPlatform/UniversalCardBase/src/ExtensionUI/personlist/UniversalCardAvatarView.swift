//
//  UniversalCardAvatarView.swift
//  UniversalCardBase
//
//  Created by ByteDance on 2023/9/4.
//

import Foundation
import LarkBizAvatar

fileprivate struct AvatarStyle {
    static let avatarSize: CGFloat = 40
    static let avatarOffset: CGFloat = 16
    static let titleLeading: CGFloat = 12
}

struct MoreInfo {
    let moreSize: CGFloat
    let moreColor: UIColor
    let moreTextColor: UIColor
    let moreTextFont: UIFont
    let moreMaxCount: Int
}

class MaskAvatar: UIView {
    let avatarSize: CGFloat
    let person: Person

    init(avatarSize: CGFloat, person: Person, frame: CGRect) {
        self.avatarSize = avatarSize
        self.person = person
        super.init(frame: frame)
        self.addSubview(avatar)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var avatar: BizAvatar = {
        let avatar = BizAvatar()
        avatar.layer.cornerRadius = avatarSize / 2
        avatar.avatar.clipsToBounds = true
        avatar.setAvatarByIdentifier(person.id ?? "", avatarKey: person.avatarKey ?? "", placeholder: BundleResources.UniversalCardBase.universal_card_avatar)
        return avatar
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        // 设置子视图的 frame
        avatar.frame = bounds
        // 创建遮罩层
        let maskLayer = CAShapeLayer()
        // 设置圆的中心和半径
        let circleCenter = CGPoint(x: bounds.width + bounds.width / 6 - 3, y: bounds.height / 2)
        let circleRadius: CGFloat = bounds.width / 2
        // 创建圆的路径
        let maskPath = UIBezierPath(rect: bounds)
        let circlePath = UIBezierPath(arcCenter: circleCenter, radius: circleRadius, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
        maskPath.append(circlePath)
        maskPath.usesEvenOddFillRule = true
        // 将路径设置为遮罩层的路径
        maskLayer.path = maskPath.cgPath
        maskLayer.fillRule = .evenOdd
        // 将遮罩层设置为子视图的遮罩
        self.layer.mask = maskLayer
    }
}

class MoreAvatar: UIView {
    let avatarSize: CGFloat
    let moreInfo: MoreInfo
    let count: Int

    lazy var label: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        label.font = moreInfo.moreTextFont
        label.textColor = moreInfo.moreTextColor
        label.text = count > moreInfo.moreMaxCount ? "+\(moreInfo.moreMaxCount)" : "+\(count)"
        label.textAlignment = .center
        return label
    }()

    init(avatarSize: CGFloat, count: Int, moreInfo: MoreInfo, frame: CGRect) {
        self.avatarSize = avatarSize
        self.moreInfo = moreInfo
        self.count = count
        super.init(frame: frame)
        self.addSubview(label)
        self.backgroundColor = moreInfo.moreColor
        self.bounds.size = CGSize(width: avatarSize, height: avatarSize)
        self.layer.cornerRadius = avatarSize / 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
