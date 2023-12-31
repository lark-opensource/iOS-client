//
//  FavoriteMessageCell.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/14.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LarkContainer
import LarkCore
import EENavigator
import LarkMessengerInterface
import ByteWebImage
import LarkBizAvatar

public class FavoriteMessageCell: FavoriteListCell {
    override class var identifier: String {
        return FavoriteMessageViewModel.identifier
    }
}

public class FavoriteMessageDetailCell: FavoriteDetailCell {

    enum Cons {
        static var nameFont: UIFont { UIFont.ud.body2 }
        static var detailFont: UIFont { UIFont.ud.caption1 }
        static var timeFont: UIFont { UIFont.ud.caption1 }
        static var avatarSize: CGFloat { nameFont.figmaHeight + detailFont.figmaHeight }
    }

    override public class var identifier: String {
        return FavoriteMessageViewModel.identifier
    }

    public var messageViewModel: FavoriteMessageViewModel? {
        return self.viewModel as? FavoriteMessageViewModel
    }

    public let contentInset: CGFloat = 16

    public var bubbleContentMaxWidth: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIScreen.main.bounds.width - 2 * contentInset
        } else {
            return self.bounds.width - 2 * self.contentInset
        }
    }

    public lazy var avatarView: BizAvatar = {
        let view = BizAvatar()
        view.layer.cornerRadius = Cons.avatarSize / 2
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.ud.bgFloatOverlay
        view.isUserInteractionEnabled = true
        view.lu.addTapGestureRecognizer(action: #selector(avatarViewTapped), target: self)
        return view
    }()

    public lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = Cons.nameFont
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    public lazy var detailLocationLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = Cons.detailFont
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        return label
    }()
    public lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = Cons.timeFont
        return label
    }()

    public lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    public lazy var container: UIView = {
        return UIView()
    }()

    public override func setupUI() {
        super.setupUI()
        self.backgroundColor = UIColor.clear

        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.top.left.equalTo(contentInset)
            make.width.height.equalTo(Cons.avatarSize)
        }

        self.contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(contentInset / 2)
            make.top.equalTo(contentInset)
            make.right.equalTo(-contentInset)
            make.height.equalTo(Cons.nameFont.figmaHeight)
        }

        self.contentView.addSubview(self.detailLocationLabel)
        self.detailLocationLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(contentInset / 2)
            make.bottom.equalTo(avatarView)
            make.height.equalTo(Cons.detailFont.figmaHeight)
        }
        self.detailLocationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        self.contentView.addSubview(self.timeLabel)
        self.timeLabel.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualTo(detailLocationLabel.snp.right).offset(10)
            make.right.equalTo(-contentInset)
            make.bottom.equalTo(avatarView)
            make.height.equalTo(Cons.timeFont.figmaHeight)
        }

        self.contentView.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.left.equalTo(contentInset)
            make.right.equalTo(-contentInset)
            make.top.equalTo(avatarView.snp.bottom).offset(contentInset)
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        self.contentView.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.left.equalTo(contentInset)
            make.right.bottom.equalTo(-contentInset)
            make.top.equalTo(line.snp.bottom).offset(contentInset)
        }
    }

    public override func updateCellContent() {
        super.updateCellContent()
        let key = self.messageViewModel?.fromChatter?.avatarKey ?? ""
        let entityId = self.messageViewModel?.fromChatter?.id ?? ""
        self.nameLabel.text = self.messageViewModel?.fromChatterDisplayName ?? ""
        self.detailLocationLabel.text = self.viewModel.detailLocation
        self.timeLabel.text = self.viewModel.detailTime
        self.avatarView.setAvatarByIdentifier(entityId, avatarKey: key, scene: .Favorite, avatarViewParams: .init(sizeType: .size(Cons.avatarSize)))
    }
}

extension FavoriteMessageDetailCell {
    @objc
    func avatarViewTapped() {
        guard let vm = self.messageViewModel, let fromChatter = vm.fromChatter else {
            return
        }
        // 消息来源是匿名 需要禁止头像点击事件
        if fromChatter.isAnonymous {
            return
        }

        guard let window = self.window else {
            assertionFailure()
            return
        }

        let body = PersonCardBody(chatterId: fromChatter.id)
        if Display.phone {
            vm.navigator.push(body: body, from: window)
        } else {
            vm.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: window,
                prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
    }
}
