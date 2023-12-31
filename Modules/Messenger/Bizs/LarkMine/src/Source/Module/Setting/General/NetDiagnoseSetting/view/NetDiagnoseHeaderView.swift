//
//  NetDiagnoseHeaderView.swift
//  LarkMine
//
//  Created by huanglx on 2021/12/16.
//

import Foundation
import UIKit

final class NetDiagnoseHeaderView: UIView {
    private let titleLabel: UILabel = UILabel()
    private let descLabel: UILabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        /// 标题
        self.titleLabel.font = UIFont.ud.title1
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        self.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(34)
            make.left.equalTo(16)
            make.width.equalToSuperview().offset(-32)
        }
        /// 描述
        self.descLabel.font = UIFont.systemFont(ofSize: 14)
        self.descLabel.textAlignment = .left
        self.descLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        self.descLabel.numberOfLines = 2
        self.addSubview(self.descLabel)
        self.descLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.equalTo(16)
            make.width.equalToSuperview().offset(-32)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func set(status: NetDiagnoseStatus) {
        switch status {
        case .unStart:
            self.titleLabel.text = BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetworkError_DiagnosisVairable
            self.descLabel.text = BundleI18n.LarkMine.Lark_NetworkDiagnosis_Diagnosing_PlesWait
        case .running:
            self.titleLabel.text = BundleI18n.LarkMine.Lark_NetworkDiagnosis_Diagnosing
            self.descLabel.text = BundleI18n.LarkMine.Lark_NetworkDiagnosis_Diagnosing_PlesWait
        case .normal:
            self.titleLabel.text = BundleI18n.LarkMine.Lark_NetworkDiagnosis_Diagnosis_Normal
            self.descLabel.text = BundleI18n.LarkMine.Lark_NetworkDiagnosis_Diagnosis_NormalDesc
        case .error:
            self.titleLabel.text = BundleI18n.LarkMine.Lark_NetworkDiagnosis_Abnormal
            self.descLabel.text = BundleI18n.LarkMine.Lark_NetworkDiagnosis__AbnormalDesc
        }
    }
}
