//
//  ReplyInThreadIntermediateView.swift
//  LarkThread
//
//  Created by ByteDance on 2022/5/22.
//

import Foundation
import LarkUIKit
import SkeletonView
import CoreGraphics
import UIKit

final class ReplyThreadIntermediateView: UIView, ThreadAbnormalStatusView {

    fileprivate var navBar: ReplyThreadIntermedeNavigationBar?

    var backBtn: UIButton? {
        return self.navBar?.backButton
    }

    init(backButtonClickedBlock: @escaping () -> Void) {
        self.backButtonClickedBlock = backButtonClickedBlock
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

        let bar = ReplyThreadIntermedeNavigationBar()
        bar.backButtonClickedBlock = backButtonClickedBlock
        addSubview(bar)
        bar.snp.makeConstraints { (make) in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        self.navBar = bar
        let rootMessageView = ReplyThreadRootMessageView()
        addSubview(rootMessageView)
        rootMessageView.snp.makeConstraints { (make) in
            make.top.equalTo(bar.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview()
        }
    }

}

private final class ReplyThreadRootMessageView: UIView {
    override var bounds: CGRect {
        didSet {
            if bounds.width != desContentViewWidth {
                desContentViewWidth = bounds.width
                let width = ceil((bounds.width * 0.4) / 10.0) * 10
                self._desContentView?.snp.updateConstraints { make in
                    make.width.equalTo(min(width, desContentViewWidth - 32))
                }
            }
        }
    }

    private var desContentViewWidth: CGFloat = 0
    private var _desContentView: UIView?

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
        avatarView.layer.cornerRadius = 18
        addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.top.equalTo(12)
            make.width.height.equalTo(36)
        }

        let titleView = self.getSkeletonView()
        addSubview(titleView)
        titleView.snp.makeConstraints { (make) in
            make.leading.equalTo(avatarView.snp.trailing).offset(6)
            make.top.equalTo(avatarView.snp.top).offset(5)
            make.width.equalTo(90)
            make.height.equalTo(14)
        }

        let desView = self.getSkeletonView()
        addSubview(desView)
        desView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleView)
            make.top.equalTo(titleView.snp.bottom).offset(4)
            make.width.equalTo(54)
            make.height.equalTo(12)
        }

        let contentView = self.getSkeletonView()
        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.leading.equalTo(avatarView)
            make.top.equalTo(avatarView.snp.bottom).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(17)
        }

        let desContentView = self.getSkeletonView()
        addSubview(desContentView)
        self._desContentView = desContentView
        desContentView.snp.makeConstraints { (make) in
            make.leading.equalTo(avatarView)
            make.top.equalTo(contentView.snp.bottom).offset(8)
            make.width.equalTo(0)
            make.height.equalTo(17)
        }
    }
}

private final class ReplyThreadIntermedeNavigationBar: UIView {
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
        backButton.setImage(LarkUIKit.Resources.navigation_back_light, for: .normal)
        backButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
           make.centerY.equalToSuperview()
           make.width.height.equalTo(24)
           make.leading.equalTo(16)
        }

        let rightView = self.getSkeletonSmallCircleView()
        addSubview(rightView)
        rightView.snp.makeConstraints { (make) in
            make.trailing.equalTo(-16)
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

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.LarkThread.Lark_IM_Thread_ThreadDetail_Title
        label.textAlignment = .center
        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(88)
            make.right.equalToSuperview().offset(-88)
        }
    }

    @objc
    private func backButtonClicked() {
        backButtonClickedBlock?()
    }
}
