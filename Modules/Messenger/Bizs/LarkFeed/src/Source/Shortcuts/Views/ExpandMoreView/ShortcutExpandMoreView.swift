//
//  ShortcutExpandMoreView.swift
//  LarkFeed
//
//  Created by maozhenning on 2019/5/24.
//

import Foundation
import UIKit
import LarkUIKit
import RxCocoa
import RxSwift
import LarkBadge

/// 改为UICollectionViewCell，在置顶交换编辑态时，在交换的cell的下方
final class ShortcutExpandMoreView: UICollectionViewCell {

    private var viewModel: ShortcutExpandMoreViewModel
    private let disposeBag = DisposeBag()

    private let avatarView = ShortcutExpandMoreAvatarView()
    private let nameLabel = UILabel.lu.labelWith(fontSize: ShortcutLayout.labelFont.pointSize, textColor: UIColor.ud.textPlaceholder)

    init(frame: CGRect, viewModel: ShortcutExpandMoreViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        setupviews()
        bind()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupviews() {
        self.isHidden = true

        self.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(ShortcutLayout.avatarTopInset)
        }

        nameLabel.textAlignment = .center
        nameLabel.textColor = UIColor.ud.textPlaceholder
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(avatarView)
            make.top.equalTo(avatarView.snp.bottom).offset(6)
        }
    }

    private func bind() {
        viewModel.displayDriver.drive(onNext: { [weak self] display in
            guard let `self` = self else { return }
            self.isHidden = !display
            self.updateName()
            self.updateBadgeView()
        }).disposed(by: disposeBag)

        // 监听展开/收起的信号
        viewModel.expandedObservable
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] expand in
            // 这里指的是点击，非拖拽形成的动画
            guard let `self` = self else { return }
            self.updateName()
            self.updateBadgeView()
            self.updateAnimation(expand: expand)
        }).disposed(by: disposeBag)

        // 监听更新badge的信号
        viewModel.updateContentObservable
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self]  in
            guard let `self` = self else { return }
            self.updateBadgeView()
        }).disposed(by: disposeBag)
    }

    // 更新样式及badge值
    private func updateName() {
        nameLabel.text = viewModel.name
    }

    private func updateAnimation(expand: Bool) {
        let process = (expand ? 1 : 0) as CGFloat
        self.setBadgeAlpha(process: process)
        let transform = (expand ? 0 : 1) as CGFloat
        self.setRotate(process: transform, animationDuration: 0.25, shouldReverse: !expand)
    }

    private func updateBadgeView() {
        avatarView.badgeView.type = viewModel.badgeInfo.type
        avatarView.badgeView.style = viewModel.badgeInfo.style
    }

    /*
     更新旋转度
     如果是拖拽：process有小数，其他参数没有用
     如果是点击：process = 0 / 1，有动画时间，如果是展开，则Reversey也有值
     */
    func setRotate(process: CGFloat, animationDuration: Double, shouldReverse: Bool) {
        var vaildProcess = process
        vaildProcess = process > 1 ? min(process, 1) : max(process, 0)
        var rotationAngle = vaildProcess * .pi
        let rotationView = avatarView.backgroundView
        if animationDuration > 0 {
            /// 如果是收起，则逆时针旋转
            rotationAngle = shouldReverse ? (0.001 * .pi) : .pi
            UIView.animate(withDuration: animationDuration, animations: {
                rotationView.transform = CGAffineTransform(rotationAngle: rotationAngle)
            })
        } else {
            rotationView.transform = CGAffineTransform(rotationAngle: rotationAngle)
        }
    }

    // 更新badgeView的alpha
    private func setBadgeAlpha(process: CGFloat) {
        var vaildProcess = process
        vaildProcess = process > 1 ? min(process, 1) : max(process, 0)
        UIView.animate(withDuration: 0.2) {
            self.avatarView.badgeView.alpha = 1 - vaildProcess
        }
    }
}
