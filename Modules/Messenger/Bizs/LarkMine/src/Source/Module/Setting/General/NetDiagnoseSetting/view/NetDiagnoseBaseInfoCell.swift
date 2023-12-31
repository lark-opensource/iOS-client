//
//  NetDiagnoseBaseInfoCell.swift
//  LarkMine
//
//  Created by huanglx on 2021/12/24.
//

import Foundation
import LarkUIKit
import UIKit

/// 网络检测基础信息cell
final class NetDiagnoseBaseInfoCell: BaseTableViewCell {
    private let bgColorView = GradientView()
    /// 标题
    private let titleLabel = UILabel()
    /// 应用版本
    private let appVersionLabel = UILabel()
    /// 系统版本
    private let osVersionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.primaryOnPrimaryFill

        //渐变背景
        bgColorView.locations = [0.0, 1.0]
        bgColorView.direction = .vertical
        bgColorView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        self.contentView.addSubview(self.bgColorView)
        self.bgColorView.snp.makeConstraints { (make) in
            make.top.bottom.left.right.equalToSuperview()
        }
        self.bgColorView.addSubview(self.baseInfoContentView)
        self.baseInfoContentView.snp.makeConstraints { (make) in
            make.top.bottom.left.right.equalToSuperview()
        }
        /// 标题
        self.titleLabel.font = UIFont.ud.title4
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.baseInfoContentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(28)
            make.left.equalTo(16)
            make.width.equalToSuperview().offset(-32)
        }
        /// 应用版本
        self.appVersionLabel.font = UIFont.systemFont(ofSize: 14)
        self.appVersionLabel.textAlignment = .left
        self.appVersionLabel.numberOfLines = 0
        self.appVersionLabel.textColor = UIColor.ud.textPlaceholder
        self.baseInfoContentView.addSubview(self.appVersionLabel)
        self.appVersionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalTo(16)
            make.width.equalToSuperview().offset(-32)
        }
        /// 系统版本
        self.osVersionLabel.font = UIFont.systemFont(ofSize: 14)
        self.osVersionLabel.textAlignment = .left
        self.osVersionLabel.numberOfLines = 0
        self.osVersionLabel.textColor = UIColor.ud.textPlaceholder
        self.baseInfoContentView.addSubview(self.osVersionLabel)
        self.osVersionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(appVersionLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-30)
            make.left.equalTo(16)
            make.width.equalToSuperview().offset(-32)
        }
    }

    private lazy var baseInfoContentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = 10
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, appVersion: String, osVersion: String, status: NetDiagnoseStatus) {
        self.titleLabel.text = title
        self.appVersionLabel.text = appVersion
        self.osVersionLabel.text = osVersion
        switch status {
        case .unStart:
            self.bgColorView.colors = [UIColor.ud.primaryContentDefault.withAlphaComponent(0.8)]
        case .running:
            self.bgColorView.colors = [UIColor.ud.primaryContentDefault.withAlphaComponent(0.8)]
        case .normal:
            self.bgColorView.colors = [UIColor.ud.functionSuccessContentDefault.withAlphaComponent(0.8)]
        case .error:
            self.bgColorView.colors = [UIColor.ud.functionWarningContentDefault.withAlphaComponent(0.8)]
        }
    }
}
