//
//  NetDiagnoseBottomView.swift
//  LarkMine
//
//  Created by huanglx on 2021/12/16.
//

import Foundation
import UIKit

/// 代理
protocol NetDiagnoseBottomViewDelegate: AnyObject {
    //开始诊断
    func startDiagnose()
    //停止诊断
    func stopDiagnose()
    //重新诊断
    func againDiagnose()
    //查看日志
    func viewLog()
}

final class NetDiagnoseBottomView: UIView {
    private let startDiagnoseButton = UIButton()
    private let againDiagnoseButton = UIButton()
    private let viewLogButton = UIButton()
    private var netDiagnoseStatus: NetDiagnoseStatus = .unStart

    weak var delegate: NetDiagnoseBottomViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        /// 开始/暂停button
        self.startDiagnoseButton.addTarget(self, action: #selector(startOrCancelDiagnose), for: .touchUpInside)
        self.startDiagnoseButton.titleLabel?.font = UIFont.ud.title4
        self.startDiagnoseButton.setTitle(BundleI18n.LarkMine.Lark_NetworkDiagnosis_StartDiagnosis, for: .normal)
        self.startDiagnoseButton.layer.borderWidth = 1
        self.startDiagnoseButton.layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        self.startDiagnoseButton.layer.cornerRadius = 8
        self.startDiagnoseButton.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMinXMaxYCorner,
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner
        ]
        self.startDiagnoseButton.clipsToBounds = true
        self.addSubview(self.startDiagnoseButton)
        self.startDiagnoseButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.left.equalTo(16)
            make.height.equalTo(48)
            make.width.equalToSuperview().offset(-32)
        }
        /// 重试button
        self.againDiagnoseButton.addTarget(self, action: #selector(againDiagnose), for: .touchUpInside)
        self.againDiagnoseButton.setTitle(BundleI18n.LarkMine.Lark_NetworkDiagnosis_Re, for: .normal)
        self.againDiagnoseButton.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        self.againDiagnoseButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        self.againDiagnoseButton.titleLabel?.font = UIFont.ud.title4
        self.againDiagnoseButton.layer.borderWidth = 1
        self.againDiagnoseButton.layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        self.againDiagnoseButton.layer.cornerRadius = 8
        self.againDiagnoseButton.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMinXMaxYCorner,
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner
        ]
        self.againDiagnoseButton.clipsToBounds = true
        self.addSubview(self.againDiagnoseButton)
        self.againDiagnoseButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.left.equalTo(16)
            make.height.equalTo(48)
            make.right.equalTo(self.snp.centerX).offset(-8)
        }

        /// 查看日志button
        self.viewLogButton.addTarget(self, action: #selector(viewLog), for: .touchUpInside)
        self.viewLogButton.setTitle(BundleI18n.LarkMine.Lark_NetworkDiagnosis_DownloadLog, for: .normal)
        self.viewLogButton.backgroundColor = UIColor.ud.primaryContentDefault
        self.viewLogButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        self.viewLogButton.titleLabel?.font = UIFont.ud.title4
        self.viewLogButton.layer.cornerRadius = 8
        self.viewLogButton.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMinXMaxYCorner,
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner
        ]
        self.viewLogButton.clipsToBounds = true
        self.addSubview(self.viewLogButton)
        self.viewLogButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.height.equalTo(48)
            make.right.equalToSuperview().offset(-16)
            make.left.equalTo(self.snp.centerX).offset(8)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func set(status: NetDiagnoseStatus) {
        self.netDiagnoseStatus = status
        switch status {
        case .unStart:
            self.againDiagnoseButton.isHidden = true
            self.viewLogButton.isHidden = true
            self.startDiagnoseButton.isHidden = false
            self.startDiagnoseButton.setTitle(BundleI18n.LarkMine.Lark_NetworkDiagnosis_Start, for: .normal)
            self.startDiagnoseButton.backgroundColor = UIColor.ud.primaryContentDefault
            self.startDiagnoseButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
            self.startDiagnoseButton.layer.borderWidth = 0
        case .running:
            self.againDiagnoseButton.isHidden = true
            self.viewLogButton.isHidden = true
            self.startDiagnoseButton.isHidden = false
            self.startDiagnoseButton.setTitle(BundleI18n.LarkMine.Lark_NetworkDiagnosis_Cancel, for: .normal)
            self.startDiagnoseButton.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
            self.startDiagnoseButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
            self.startDiagnoseButton.layer.borderWidth = 1
        case .normal:
            self.startDiagnoseButton.isHidden = true
            self.againDiagnoseButton.isHidden = false
            self.viewLogButton.isHidden = false
            self.startDiagnoseButton.isHidden = true
        case .error:
            self.startDiagnoseButton.isHidden = true
            self.againDiagnoseButton.isHidden = false
            self.viewLogButton.isHidden = false
            self.startDiagnoseButton.isHidden = true
        }
    }

    //开始/取消诊断
    @objc
    private func startOrCancelDiagnose() {
        let netDiagnoseStatus = self.netDiagnoseStatus
        switch netDiagnoseStatus {
        case .unStart:
            self.delegate?.startDiagnose()
        case .running:
            self.delegate?.stopDiagnose()
        case .normal: break
        case .error: break
        }
    }

    //重新诊断
    @objc
    private func againDiagnose() {
        self.delegate?.againDiagnose()
    }

    //查看日志
    @objc
    private func viewLog() {
        self.delegate?.viewLog()
    }
}
