//
//  RootViewController.swift
//  LarkAvatarDev
//
//  Created by qihongye on 2020/2/13.
//

import UIKit
import Foundation
import LarkAvatar
import SnapKit

class RootViewController: UIViewController {
    let iconBadge: LarkBadgeView = LarkBadgeView()
    let textBadge: LarkBadgeView = LarkBadgeView()
    let baseAvatarView: LarkBaseAvatarView = LarkBaseAvatarView()
    let avatarView: LarkAvatarView = LarkAvatarView()
    let avatarView1: LarkAvatarView = LarkAvatarView()
    let avatarView2: LarkAvatarView = LarkAvatarView()
    let avatarView3: LarkAvatarView = LarkAvatarView()
    let avatarView4: LarkAvatarView = LarkAvatarView()
    let avatarView5: LarkAvatarView = LarkAvatarView()
    let avatarView6: LarkAvatarView = LarkAvatarView()

    override func viewDidLoad() {
        view.addSubview(iconBadge)
        iconBadge.layer.borderColor = UIColor.red.cgColor
        iconBadge.layer.borderWidth = 1
        iconBadge.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.left.equalTo(10)
        }
        iconBadge.type = .icon(SetBadgeIcon(icon: UIImage(named: "invalidName")!))

        view.addSubview(textBadge)
        textBadge.layer.borderColor = UIColor.red.cgColor
        textBadge.layer.borderWidth = 1
        textBadge.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.left.equalTo(iconBadge.snp.right).offset(10)
        }
        textBadge.textEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textBadge.type = .text("99+")

        view.addSubview(baseAvatarView)
        baseAvatarView.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.left.equalTo(textBadge.snp.right).offset(10)
            make.width.height.equalTo(48)
        }
        baseAvatarView.image = UIImage(named: "invalidName")!
        baseAvatarView.setBadge(
            topRight: Badge(
                type: .text("99+"),
                border: Border(
                    width: 1.5,
                    color: UIColor.white
                ),
                textColor: UIColor.white,
                textFont: nil,
                backgroundColor: UIColor.red
            ),
            bottomRight: Badge(
                type: .icon(SetBadgeIcon(icon: UIImage(named: "invalidName")!)),
                border: Border(
                    width: 1.5,
                    color: UIColor.white
                )
            )
        )

        view.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.top.equalTo(150)
            make.left.equalTo(10)
            make.width.height.equalTo(48)
        }
        avatarView.setProps(LarkAvatarProps(
            avatarKey: "2e0d900112dee23451056",
            isUrgent: true,
            badge: BadgeProps(badgeStyle: .weakRemind, feedType: .done, count: 999, isAt: true, isRemind: true, isUrgent: true),
            miniIcon: MiniIconProps(.docs)
        ))

        view.addSubview(avatarView1)
        avatarView1.snp.makeConstraints { (make) in
            make.top.equalTo(200)
            make.left.equalTo(10)
            make.width.height.equalTo(48)
        }
        avatarView1.setProps(LarkAvatarProps(
            avatarKey: "2e0d900112dee23451056",
            isUrgent: true,
            badge: BadgeProps(badgeStyle: .weakRemind, feedType: .done, count: 999, isAt: false, isRemind: false, isUrgent: false),
            miniIcon: MiniIconProps(.micoApp)
        ))

        view.addSubview(avatarView2)
        avatarView2.snp.makeConstraints { (make) in
            make.top.equalTo(250)
            make.left.equalTo(10)
            make.width.height.equalTo(48)
        }
        avatarView2.setProps(LarkAvatarProps(
            avatarKey: "2e0d900112dee23451056",
            isUrgent: true,
            badge: BadgeProps(badgeStyle: .weakRemind, feedType: .inbox, count: 1000, isAt: false, isRemind: false, isUrgent: false),
            miniIcon: MiniIconProps(.micoApp)
        ))

        view.addSubview(avatarView3)
        avatarView3.snp.makeConstraints { (make) in
            make.top.equalTo(300)
            make.left.equalTo(10)
            make.width.height.equalTo(48)
        }
        avatarView3.setProps(LarkAvatarProps(
            avatarKey: "2e0d900112dee23451056",
            isUrgent: true,
            badge: BadgeProps(badgeStyle: .weakRemind, feedType: .inbox, count: 1, isAt: false, isRemind: true, isUrgent: false),
            miniIcon: MiniIconProps(.micoApp)
        ))
    }
}
