//
//  DetailIntermediateView.swift
//  LarkThread
//
//  Created by lizhiqiang on 2020/3/29.
//

import Foundation
import LarkUIKit
import SkeletonView
import UIKit

final class DetailIntermediateView: UIView, ThreadAbnormalStatusView {
    let showKeyboard: Bool
    fileprivate var navBar: NavigationBar?

    var backBtn: UIButton? {
        return self.navBar?.backButton
    }

    init(showKeyboard: Bool, backButtonClickedBlock: @escaping () -> Void) {
        self.backButtonClickedBlock = backButtonClickedBlock
        self.showKeyboard = showKeyboard
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startLoading() {
        self.showAnimatedGradientSkeleton(usingGradient: gradient)
    }

    func stopLoading() {
        self.stopSkeletonAnimation()
    }

    private let backButtonClickedBlock: () -> Void
    private let gradient = SkeletonGradient(
        baseColor: UIColor.ud.N200,
        secondaryColor: UIColor.ud.N300.withAlphaComponent(0.7)
    )

    private func setupView() {
        backgroundColor = UIColor.ud.N00
        isSkeletonable = true

        let bar = NavigationBar()
        bar.backButtonClickedBlock = backButtonClickedBlock
        addSubview(bar)
        self.navBar = bar
        bar.snp.makeConstraints { (make) in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        let messageView = RootMessageView()
        addSubview(messageView)
        messageView.snp.makeConstraints { (make) in
            make.top.equalTo(bar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(108)
        }

        if self.showKeyboard {
            let keyboardView = KeyboardView()
            addSubview(keyboardView)
            keyboardView.snp.makeConstraints { (make) in
                make.bottom.leading.trailing.equalToSuperview()
                make.height.equalTo(80 + (Display.iPhoneXSeries ? 34 : 0))
            }
        }
    }
}

private final class NavigationBar: UIView {
    var backButtonClickedBlock: (() -> Void)?
    let backButton = UIButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        isSkeletonable = true

        let centerView = self.getSkeletonView()
        addSubview(centerView)
        centerView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(90)
            make.height.equalTo(16)
        }

        backButton.setImage(LarkUIKit.Resources.navigation_back_light, for: .normal)
        backButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
           make.centerY.equalTo(centerView)
           make.leading.equalTo(16)
        }

        let rightView = self.getSkeletonSmallCircleView()
        addSubview(rightView)
        rightView.snp.makeConstraints { (make) in
            make.trailing.equalTo(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        let rightSecondView = self.getSkeletonSmallCircleView()
        addSubview(rightSecondView)
        rightSecondView.snp.makeConstraints { (make) in
            make.trailing.equalTo(rightView.snp.leading).offset(-20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }

    @objc
    private func backButtonClicked() {
        backButtonClickedBlock?()
    }
}

private final class RootMessageView: UIView {
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        isSkeletonable = true

        let avatarView = self.getSkeletonSmallCircleView()
        avatarView.layer.cornerRadius = 20
        addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.leading.top.equalTo(16)
            make.width.height.equalTo(40)
        }

        let titleView = self.getSkeletonView()
        addSubview(titleView)
        titleView.snp.makeConstraints { (make) in
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.top.equalTo(avatarView.snp.top).offset(5)
            make.width.equalTo(105)
            make.height.equalTo(10)
        }

        let desView = self.getSkeletonView()
        addSubview(desView)
        desView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleView)
            make.top.equalTo(titleView.snp.bottom).offset(9.5)
            make.width.equalTo(36)
            make.height.equalTo(10)
        }

        let contentView = self.getSkeletonView()
        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.leading.equalTo(avatarView)
            make.top.equalTo(avatarView.snp.bottom).offset(16)
            make.width.equalTo(221.5)
            make.height.equalTo(10)
        }

        let desContentView = self.getSkeletonView()
        addSubview(desContentView)
        desContentView.snp.makeConstraints { (make) in
            make.leading.equalTo(avatarView)
            make.top.equalTo(contentView.snp.bottom).offset(16)
            make.width.equalTo(172)
            make.height.equalTo(10)
        }
    }
}

private final class KeyboardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        isSkeletonable = true
        backgroundColor = UIColor.ud.N00
        layer.shadowOffset = CGSize(width: 0, height: -0.5)
        layer.shadowOpacity = 1
        layer.shadowRadius = 5
        layer.shadowColor = UIColor.ud.N1000.withAlphaComponent(0.05).cgColor

        let intextView = self.getSkeletonView()
        addSubview(intextView)
        intextView.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.top.equalTo(14.5)
            make.width.equalTo(120)
            make.height.equalTo(16)
        }

        let rightView = self.getSkeletonSmallCircleView()
        addSubview(rightView)
        rightView.snp.makeConstraints { (make) in
            make.trailing.equalTo(-25.5)
            make.centerY.equalTo(intextView)
            make.width.height.equalTo(24)
        }

        let iconOneView = self.getSkeletonSmallCircleView()
        addSubview(iconOneView)
        iconOneView.snp.makeConstraints { (make) in
            make.leading.equalTo(25.5)
            make.top.equalTo(intextView.snp.bottom).offset(15.5)
            make.width.height.equalTo(24)
        }

        let iconTwoView = self.getSkeletonSmallCircleView()
        addSubview(iconTwoView)
        iconTwoView.snp.makeConstraints { (make) in
            make.leading.equalTo(iconOneView.snp.trailing).offset(51)
            make.top.equalTo(iconOneView)
            make.width.height.equalTo(24)
        }

        let iconThreeView = self.getSkeletonSmallCircleView()
        addSubview(iconThreeView)
        iconThreeView.snp.makeConstraints { (make) in
            make.leading.equalTo(iconTwoView.snp.trailing).offset(51)
            make.top.equalTo(iconOneView)
            make.width.height.equalTo(24)
        }

        let iconForthView = self.getSkeletonSmallCircleView()
        addSubview(iconForthView)
        iconForthView.snp.makeConstraints { (make) in
            make.leading.equalTo(iconThreeView.snp.trailing).offset(51)
            make.top.equalTo(iconOneView)
            make.width.height.equalTo(24)
        }
    }
}

extension UIView {
    func getSkeletonView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N200
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        view.isSkeletonable = true
        return view
    }

    func getSkeletonSmallCircleView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N200
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.isSkeletonable = true
        return view
    }
}
