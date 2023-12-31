//
//  UniversalCardAvatarListElement.swift
//  UniversalCardBase
//
//  Created by ByteDance on 2023/9/4.
//

import Foundation
import LKRichView
import LarkBizAvatar

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
        avatar.setAvatarByIdentifier(person.id ?? "", avatarKey: person.avatarKey ?? "", placeholder: BundleResources.UniversalCardBase.universal_card_avatar)
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
                avatar.setAvatarByIdentifier(person.id ?? "", avatarKey: person.avatarKey ?? "", placeholder: BundleResources.UniversalCardBase.universal_card_avatar)
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

