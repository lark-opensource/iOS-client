//
//  NetDiagnoseNavBar.swift
//  LarkMine
//
//  Created by huanglx on 2021/12/29.
//

import Foundation
import UIKit

/// 代理
protocol NetDiagnoseNavBarDelegate: AnyObject {
    //点击返回
    func backButtonClicked()
}

final class NetDiagnoseNavBar: UIView {
    private let backButton = UIButton(type: .custom)
    private let headerLabel: UILabel = UILabel()
    weak var delegate: NetDiagnoseNavBarDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        /// 返回
        backButton.setImage(LarkMine.Resources.netDiagnose_back, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        self.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.top.equalTo(54)
            make.left.equalToSuperview().offset(12)
        }
        /// header
        self.headerLabel.text = BundleI18n.LarkMine.Lark_NetworkDiagnosis
        self.headerLabel.font = UIFont.systemFont(ofSize: 17)
        self.headerLabel.textAlignment = .center
        self.headerLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        self.addSubview(self.headerLabel)
        self.headerLabel.snp.makeConstraints { (make) in
            make.top.equalTo(54)
            make.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func backButtonClicked() {
        self.delegate?.backButtonClicked()
    }
}
