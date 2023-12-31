//
//  MyAIStopGeneratingView.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/23.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Foundation
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignShadow
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont

/// 展示「停止生成」
final class MyAIStopGeneratingView: UIView {
    private let viewModel: MyAIStopGeneratingViewModel
    private let disposeBag = DisposeBag()
    weak var targetVC: UIViewController?
    /// 停止生成按钮
    private let stopGeneratingButton = UIButton(type: .custom)

    init(viewModel: MyAIStopGeneratingViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        self.isHidden = true
        // 监听数据变化
        self.viewModel.currIsShow.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] currIsShow in
            self?.isHidden = !currIsShow
            // 停止生成按钮隐藏时，恢复状态
            if !currIsShow { self?.changeStopGeneratingButtonToNormal() }
        }).disposed(by: self.disposeBag)

        // 停止生成底部添加阴影，需要把stopGeneratingButton添加到shadowView才有效，有点奇怪
        let shadowView = UIView(frame: .zero)
        shadowView.layer.ud.setShadow(type: .s3Down)
        self.addSubview(shadowView)
        shadowView.snp.makeConstraints { $0.edges.equalToSuperview() }
        // 添加停止生成按钮
        self.stopGeneratingButton.layer.cornerRadius = Cons.buttonCornerRadius
        self.stopGeneratingButton.layer.masksToBounds = true
        // 添加icon
        let iconView = UIImageView()
        iconView.tag = 1001
        iconView.image = UDIcon.stopOutlined
        self.stopGeneratingButton.addSubview(iconView)
        iconView.snp.makeConstraints { maker in
            maker.size.equalTo(Cons.iconSize)
            maker.centerY.equalToSuperview()
            maker.left.equalTo(Cons.hMargin)
        }
        // 添加title
        let titleLabel = UILabel()
        titleLabel.tag = 1002
        titleLabel.text = BundleI18n.LarkAI.MyAI_IM_StopGenerating_Button
        titleLabel.font = UIFont.ud.body2
        titleLabel.textColor = UIColor.ud.textTitle
        self.stopGeneratingButton.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.right.equalTo(-Cons.hMargin)
            maker.left.equalTo(iconView.snp.right).offset(Cons.iconTitleSpacing)
        }
        // 设置按压态背景色
        self.stopGeneratingButton.setBackgroundImage(UIColor.ud.image(with: UIColor.ud.udtokenBtnSeBgNeutralPressed, size: CGSize(width: 1, height: 1), scale: 1), for: .highlighted)
        self.stopGeneratingButton.setBackgroundImage(UIColor.ud.image(with: UIColor.ud.bgBody, size: CGSize(width: 1, height: 1), scale: 1), for: .normal)
        // 设置点击事件
        self.stopGeneratingButton.addTarget(self, action: #selector(self.clickStopGenerating(button:)), for: .touchUpInside)
        shadowView.addSubview(self.stopGeneratingButton)
        self.stopGeneratingButton.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func changeStopGeneratingButtonToLoading() {
        guard let iconView = self.stopGeneratingButton.viewWithTag(1001) as? UIImageView, let titleLabel = self.stopGeneratingButton.viewWithTag(1002) as? UILabel else { return }

        self.stopGeneratingButton.isEnabled = false
        titleLabel.textColor = UIColor.ud.udtokenComponentTextDisabledLoading
        iconView.image = UDIcon.getIconByKey(.loadingOutlined, iconColor: UIColor.ud.primaryContentDefault)
        iconView.lu.addRotateAnimation()
    }

    private func changeStopGeneratingButtonToNormal() {
        guard let iconView = self.stopGeneratingButton.viewWithTag(1001) as? UIImageView, let titleLabel = self.stopGeneratingButton.viewWithTag(1002) as? UILabel else { return }

        self.stopGeneratingButton.isEnabled = true
        titleLabel.textColor = UIColor.ud.textTitle
        iconView.image = UDIcon.stopOutlined
        iconView.lu.removeRotateAnimation()
    }

    @objc
    private func clickStopGenerating(button: UIButton) {
        self.viewModel.clickStopGenerating {} onError: { [weak self] error in
            // 请求出错时，恢复状态
            self?.changeStopGeneratingButtonToNormal()
            guard let view = self?.targetVC?.view else { return }
            if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: apiError)
            } else {
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: error)
            }
        }
        // 开始请求时，进入loading态
        self.changeStopGeneratingButtonToLoading()
    }
}

extension MyAIStopGeneratingView {

    enum Cons {
        static var hMargin: CGFloat { 8 }
        static var iconTitleSpacing: CGFloat { 4 }
        static var iconSize: CGSize { .square(16.auto()) }
        static var buttonCornerRadius: CGFloat { QuickActionListButton.Cons.cornerRadius }
    }
}
