//
//  MsgCardAvatarElement.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2023/8/29.
//

import Foundation
import LKRichView
import LarkBizAvatar

fileprivate struct AvatarStyle {
    static let avatarSize: CGFloat = 40
    static let avatarOffset: CGFloat = 16
    static let titleLeading: CGFloat = 12
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
        avatar.setAvatarByIdentifier(person.id ?? "", avatarKey: person.avatarKey ?? "", placeholder: BundleResources.LarkMessageCard.universal_card_avatar)
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


struct MoreInfo {
    let moreSize: CGFloat
    let moreColor: UIColor
    let moreTextColor: UIColor
    let moreTextFont: UIFont
    let moreMaxCount: Int
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


class UniversalCardAvatarElement: LKRichAttachment {

    var verticalAlign: VerticalAlign = .middle

    var padding: Edges?
    let size: CGSize
    let person: Person

    init(size: CGSize, person: Person) {
        self.size = size
        self.person = person
    }

    func getAscent(_ mode: WritingMode) -> CGFloat {
        switch mode {
            case .horizontalTB: return 0
            case .verticalLR, .verticalRL: return 0
        }
    }

    lazy var avatar: BizAvatar = {
        let avatar = BizAvatar()
        avatar.layer.cornerRadius = size.width / 2
        avatar.avatar.clipsToBounds = true
        avatar.setAvatarByIdentifier(person.id ?? "", avatarKey: person.avatarKey ?? "", placeholder: BundleResources.LarkMessageCard.universal_card_avatar)
        return avatar
    }()

    func createView() -> UIView { avatar }

    @objc
    private func onTap(_ target: Any) { }
}


class UniversalCardAvatarListElement: LKRichAttachment {

    var verticalAlign: VerticalAlign = .middle

    var padding: Edges?
    var size: CGSize
    let limitWidth: CGFloat
    let avatarSize: CGFloat
    let persons: [Person]
    let moreInfo: MoreInfo

    init(limitWidth: CGFloat, persons: [Person], avatarSize: CGFloat, moreInfo: MoreInfo) {
        self.avatarSize = avatarSize
        self.persons = persons
        self.moreInfo = moreInfo
        self.limitWidth = limitWidth
        self.size = CGSize(width: limitWidth, height: avatarSize)
    }

    func getAscent(_ mode: WritingMode) -> CGFloat {
        switch mode {
            case .horizontalTB: return 0
            case .verticalLR, .verticalRL: return 0
        }
    }

    func createView() -> UIView {
        let containerView = UIView()
        let limitWidth = self.limitWidth
        let maxCount = 5
        // 是否已经完成计算
        var isFinished = false

        var previousFrame = CGRect.zero

        for (index, person) in persons.enumerated() {
            // 从上一个的 2/3 处开始
            let originX = index == 0 ? 0 : previousFrame.origin.x + 2/3 * avatarSize
            let origin = CGPoint(
                x: originX,
                y: previousFrame.origin.y
            )
            let frame = CGRect(origin: origin, size: CGSize(width: avatarSize, height: avatarSize))

            // 若当前是最后一个
            if index == persons.count - 1 && index < 5 {
                let avatar = BizAvatar()
                avatar.layer.cornerRadius = size.width / 2
                avatar.avatar.clipsToBounds = true
                avatar.frame = frame
                avatar.setAvatarByIdentifier(person.id ?? "", avatarKey: person.avatarKey ?? "", placeholder: BundleResources.LarkMessageCard.universal_card_avatar)
                containerView.addSubview(avatar)
                break
            }

            // 若不是最后一个
            guard !isFinished || index < maxCount else {
                break
            }


            // 当前的 avatar 加上 More 可以放得下
            if originX + avatarSize < limitWidth - avatarSize * (2/3), index < 5 {
                let avatar = MaskAvatar(
                    avatarSize: avatarSize,
                    person: person,
                    frame: frame
                )
                previousFrame = frame
                containerView.addSubview(avatar)
            }
            // 当前的 avatar 加上 More 放不下
            else {
                isFinished = true
                let more = MoreAvatar(
                    avatarSize: avatarSize,
                    count: persons.count - index,
                    moreInfo: moreInfo,
                    frame: CGRect(origin: origin, size: CGSize(width: avatarSize, height: avatarSize))
                )
                containerView.addSubview(more)
            }
        }

        return containerView
    }

    @objc
    private func onTap(_ target: Any) { }
}
