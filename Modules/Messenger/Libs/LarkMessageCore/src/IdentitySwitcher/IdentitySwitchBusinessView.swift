//
//  ThreadBusinessView.swift
//  LarkThread
//
//  Created by 李勇 on 2020/11/6.
//

import Foundation
import UIKit
import LarkBizAvatar
import AvatarComponent

/// 事件代理
public protocol IdentitySwitchViewDelegate: AnyObject {
    /// 此视图被点击，内部不会有其他的额外操作
    func didSelect(businessView: IdentitySwitchBusinessView)
}

/// 展示在ThreadDetail键盘和发帖界面里用于展示当前发帖/回帖的身份，点击可弹出ThreadBusinessPickerView切换身份界面
public final class IdentitySwitchBusinessView: UIView {
    public weak var delegate: IdentitySwitchViewDelegate?
    /// viewModel
    public let viewModel: IdentitySwitchViewModel
    public var suggestHeight: CGFloat {
        return avatarWidth + avatarTopMargin + avatarBottomMargin
    }
    /// 头像
    public let avatarView = BizAvatar()
    /// 名字
    public let nameLable = UILabel()
    /// 箭头
    public let arrowView = UIImageView(image: BundleResources.identitySwitch)
    let avatarWidth: CGFloat = 24
    let avatarTopMargin: CGFloat = 10
    let avatarBottomMargin: CGFloat = 4
    let switchable: Bool
    let leftRightMargin: CGFloat
    public init(viewModel: IdentitySwitchViewModel, switchable: Bool, leftRightMargin: CGFloat) {
        self.viewModel = viewModel
        self.switchable = switchable
        self.leftRightMargin = leftRightMargin
        super.init(frame: .zero)
        self.avatarView.setAvatarByIdentifier(viewModel.anonymousEntityID, avatarKey: viewModel.anonymousAvatarKey)
        self.avatarView.layer.masksToBounds = true
        self.avatarView.layer.cornerRadius = 12
        self.addSubview(self.avatarView)
        self.avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(avatarWidth)
            make.top.equalTo(avatarTopMargin)
            make.bottom.equalTo(-avatarBottomMargin)
            make.left.equalTo(leftRightMargin)
        }

        self.nameLable.font = UIFont.systemFont(ofSize: 17)
        self.nameLable.textColor = UIColor.ud.textTitle
        self.nameLable.numberOfLines = 1
        self.nameLable.setContentHuggingPriority(.required, for: .horizontal)
        self.addSubview(self.nameLable)
        self.nameLable.snp.makeConstraints { (make) in
            make.centerY.equalTo(avatarView)
            make.left.equalTo(self.avatarView.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-leftRightMargin)
        }

        if switchable {
            self.addSubview(self.arrowView)
            self.arrowView.snp.makeConstraints { (make) in
                make.centerY.equalTo(avatarView)
                make.size.equalTo(CGSize(width: 10, height: 10))
                make.right.lessThanOrEqualTo(-leftRightMargin).priority(.required)
                make.left.equalTo(self.nameLable.snp.right).offset(4)
            }

            self.lu.addTapGestureRecognizer(action: #selector(didTap))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTap() {
        self.delegate?.didSelect(businessView: self)
    }

    /// 切换至匿名身份
    public  func switchToAnonymous() {
        self.avatarView.setAvatarByIdentifier(self.viewModel.anonymousEntityID, avatarKey: self.viewModel.anonymousAvatarKey)
        self.nameLable.text = self.viewModel.anonymousName
    }

    /// 切换至实名身份
    public  func switchToReal() {
        self.avatarView.setAvatarByIdentifier(self.viewModel.currUserID, avatarKey: self.viewModel.currAvatarKey)
        self.nameLable.text = self.viewModel.currName
    }

    /// 进入选择态
    public func enterSelectStatus() {
        guard switchable else { return }
        UIView.animate(withDuration: 0.2) {
            self.arrowView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        }
    }

    /// 结束选择态
    public func exitSelectStatus() {
        guard switchable else { return }
        UIView.animate(withDuration: 0.2) {
            self.arrowView.transform = CGAffineTransform(rotationAngle: 0)
        }
    }
}
