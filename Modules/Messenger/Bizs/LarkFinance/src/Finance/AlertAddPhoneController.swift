//
//  AlertAddPhoneController.swift
//  LarkFinance
//
//  Created by 李晨 on 2020/1/15.
//

import UIKit
import Foundation
import SnapKit
import LarkContainer
import LarkAccountInterface
import EENavigator

final class AlertAddPhoneController: UIViewController, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    private var currView: UIView = UIView()
    private var addButton: UIButton = UIButton()
    private var content: String?

    public init(userResolver: UserResolver,
                content: String? = nil) {
        self.userResolver = userResolver
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: Resources.hongbao_close,
            style: .plain,
            target: self,
            action: #selector(closeVC))
        self.title = BundleI18n.LarkFinance.Lark_Hongbao_TitleNeedAddPhoneNumber

        self.addLimitView()
        self.addPhoneButton()
    }

    @objc
    func closeVC() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    func clickAddPhone() {
        userResolver.navigator.push(body: AccountManagementBody(), from: self)
    }

    private func addLimitView() {
        currView.backgroundColor = UIColor.ud.N50
        currView.layer.cornerRadius = 4
        currView.clipsToBounds = true
        self.view.addSubview(currView)
        currView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalToSuperview().offset(20.5)
        }
        /// 提示title
        let titleFont: UIFont = UIFont.boldSystemFont(ofSize: 16)
        let titleLabel: UILabel = UILabel()
        titleLabel.text = BundleI18n.LarkFinance.Lark_Wallet_AccountMissingPhone()
        titleLabel.font = titleFont
        titleLabel.textColor = UIColor.ud.N700
        titleLabel.numberOfLines = 0
        currView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(38)
            make.top.equalTo(19)
            make.right.lessThanOrEqualTo(-16)
        }
        /// 图标 和title顶部对齐
        let iconTopOffset = (titleFont.lineHeight - titleFont.pointSize) / 2
        let iconImageView: UIImageView = UIImageView()
        iconImageView.image = Resources.warning
        currView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(titleLabel.snp.top).offset(iconTopOffset)
        }
        let detailLabel: UILabel = UILabel()
        detailLabel.textColor = UIColor.ud.N700
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        if let content = self.content {
            detailLabel.text = content
        } else {
            detailLabel.text = BundleI18n.LarkFinance.Lark_Hongbao_FinancialAccountMissPhoneText()
        }
        detailLabel.numberOfLines = 0
        currView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(13)
            make.bottom.equalTo(-20)
        }
    }

    private func addPhoneButton() {
        addButton.clipsToBounds = true
        addButton.layer.cornerRadius = 4
        addButton.backgroundColor = UIColor.ud.colorfulBlue
        self.view.addSubview(addButton)
        addButton.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(48)
            make.top.equalTo(self.currView.snp.bottom).offset(40)
        }
        addButton.setTitle(
            BundleI18n.LarkFinance.Lark_Hongbao_ButtonAddPhoneNumber,
            for: .normal)
        addButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        addButton.addTarget(self, action: #selector(clickAddPhone), for: .touchUpInside)
    }

}
