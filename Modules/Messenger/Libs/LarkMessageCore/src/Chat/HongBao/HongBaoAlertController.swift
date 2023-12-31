//
//  HongBaoAlertController.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2020/3/2.
//

import UIKit
import Foundation
import LarkUIKit

/// 红包弹窗内容
public struct HongBaoAlertContent {
    /// 标题
    let title: String
    /// 描述
    let desc: String
    /// 红包金额
    let amount: String

    public init(title: String, desc: String, amount: String) {
        self.title = title
        self.desc = desc
        self.amount = amount
    }
}

/// 红包弹窗
public final class HongBaoAlertController: BaseUIViewController {
    /// 红包弹窗内容
    private let content: HongBaoAlertContent
    /// 中间的内容视图
    private let imageView = UIImageView(image: BundleResources.alert_background_icon)

    public init(content: HongBaoAlertContent) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear

        // 背景黑色按钮，点击退出
        let button = UIButton()
        button.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
        self.view.addSubview(button)
        button.snp.makeConstraints { $0.edges.equalToSuperview() }
        button.addTarget(self, action: #selector(exit), for: .touchUpInside)
        // 红包背景，大小固定，居中
        imageView.isUserInteractionEnabled = true
        imageView.alpha = 0
        button.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.equalTo(300)
            make.height.equalTo(339)
            make.center.equalToSuperview()
        }
        // 右上角的x
        let exitButton = UIButton()
        exitButton.setImage(Resources.close_alert_icon, for: .normal)
        exitButton.hitTestEdgeInsets = UIEdgeInsets(top: -15, left: -15, bottom: -15, right: -15)
        exitButton.addTarget(self, action: #selector(exit), for: .touchUpInside)
        imageView.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(14.5)
            make.right.equalTo(-23)
            make.top.equalTo(12.5)
        }
        // 上面的title
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.text = self.content.title
        titleLabel.textColor = UIColor.ud.N600
        imageView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(30.5)
            make.top.equalTo(41)
        }
        // 中间的金额
        let centerView = UIView()
        imageView.addSubview(centerView)
        centerView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(82)
        }
        let amount = UILabel()
        amount.font = UIFont.systemFont(ofSize: 43, weight: .semibold)
        amount.text = self.content.amount
        amount.textColor = UIColor.ud.colorfulRed
        centerView.addSubview(amount)
        amount.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.height.equalTo(60)
        }
        let unit = UILabel()
        unit.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        unit.text = BundleI18n.LarkMessageCore.Lark_Retained_Activity_Award_Admin_Second_Task_Amount("")
        unit.textColor = UIColor.ud.colorfulRed
        centerView.addSubview(unit)
        unit.snp.makeConstraints { (make) in
            make.left.equalTo(amount.snp.right)
            make.right.equalToSuperview()
            make.bottom.equalTo(-13.5)
            make.height.equalTo(16.5)
        }
        // 下面的detail
        let detailLabel = UILabel()
        detailLabel.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.alignment = .left
        let detail = NSMutableAttributedString(string: self.content.desc)
        detail.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: detail.length))
        detail.addAttribute(.font, value: UIFont.systemFont(ofSize: 12, weight: .regular), range: NSRange(location: 0, length: detail.length))
        detail.addAttribute(.foregroundColor, value: UIColor.ud.N600, range: NSRange(location: 0, length: detail.length))
        detailLabel.attributedText = detail
        imageView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.equalTo(30.5)
            make.top.equalTo(166)
        }
        // 下面的button
        let bottomButton = UIButton()
        bottomButton.setImage(BundleResources.confirm_alert_icon, for: .normal)
        bottomButton.setImage(BundleResources.confirm_alert_select_icon, for: .highlighted)
        bottomButton.addTarget(self, action: #selector(exit), for: .touchUpInside)
        imageView.addSubview(bottomButton)
        bottomButton.snp.makeConstraints { (make) in
            make.width.equalTo(185)
            make.height.equalTo(61)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-10.5)
        }
        let bottomTitle = UILabel()
        bottomTitle.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        bottomTitle.textColor = UIColor.ud.Y900
        bottomTitle.text = BundleI18n.LarkMessageCore.Lark_Retained_Open_Hongbao_Confirm
        bottomButton.addSubview(bottomTitle)
        bottomTitle.snp.makeConstraints({ $0.center.equalToSuperview() })
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// 因为当前vc在present时是没有动画的，所以需要等待一会儿才可以做自己的动画，不然动画会被吞掉
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) { self.imageView.alpha = 1 }
        }
    }

    @objc
    private func exit() {
        UIView.animate(withDuration: 0.2, animations: {
            self.imageView.alpha = 0
        }) { (_) in
            self.dismiss(animated: false, completion: nil)
        }
    }
}
