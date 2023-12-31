//
//  PolicyEngineBaseInfoView.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2022/11/2.
//

import UIKit
import SnapKit
import ByteDanceKit

struct PolicyEngineBaseInfo {
    let userID: String
    let tenantID: String
    let engineSwitch: Bool
    let engineLocalValidateSwitch: Bool
    let refreshInterval: Int
    let localValidateLimit: Int
    let pointcutRetryDelay: Int
    let tenantHasDeployPolicy: Bool?
}

final class PolicyEngineBaseInfoView: UIView {

    let Margin = 12
    
    let info: PolicyEngineBaseInfo
    
    init(info: PolicyEngineBaseInfo) {
        self.info = info
        super.init(frame: .zero)
        buildView()
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    private func buildView() {
        self.layer.cornerRadius = 4
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowRadius = 2
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.backgroundColor = .white
        
        let userIDView = createLineText(title: "User ID:", content: info.userID)
        addSubview(userIDView)
        userIDView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(5)
        }
        
        let tenantIDView = createLineText(title: "Tenant ID:", content: info.tenantID)
        addSubview(tenantIDView)
        tenantIDView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.top.equalTo(userIDView.snp.bottom).offset(Margin)
        }
        
        let engineSwitch = createLineText(title: "策略引擎开关", content: "\(info.engineSwitch)")
        addSubview(engineSwitch)
        engineSwitch.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.top.equalTo(tenantIDView.snp.bottom).offset(Margin)
        }
        
        let localValidateSwitchView = createLineText(title: "禁用本地计算", content: "\(info.engineLocalValidateSwitch)")
        addSubview(localValidateSwitchView)
        localValidateSwitchView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.top.equalTo(engineSwitch.snp.bottom).offset(Margin)
        }
        
        let fetchIntervalView = createLineText(title: "策略刷新间隔（秒）", content: "\(info.refreshInterval)")
        addSubview(fetchIntervalView)
        fetchIntervalView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.top.equalTo(localValidateSwitchView.snp.bottom).offset(Margin)
        }
        
        let pointcutRetryDelayView = createLineText(title: "切点重试延迟（秒）", content: "\(info.pointcutRetryDelay)")
        addSubview(pointcutRetryDelayView)
        pointcutRetryDelayView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.top.equalTo(fetchIntervalView.snp.bottom).offset(Margin)
        }
        
        let localValidateLimit = createLineText(title: "本地决策数量限制", content: "\(info.localValidateLimit)")
        addSubview(localValidateLimit)
        localValidateLimit.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.top.equalTo(pointcutRetryDelayView.snp.bottom).offset(Margin)
        }
        
        var tenantHasDeployPolicyValueStr : String = ""
        if let tenantHasDeployPolicyValue = info.tenantHasDeployPolicy{
            tenantHasDeployPolicyValueStr = tenantHasDeployPolicyValue.stringValue
        }
        let tenantHasDeployPolicy = createLineText(title: "是否需要拉取策略信息", content: tenantHasDeployPolicyValueStr)
        addSubview(tenantHasDeployPolicy)
        tenantHasDeployPolicy.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview().inset(5)
            make.top.equalTo(localValidateLimit.snp.bottom).offset(Margin)
        }
    }

    private func createLineText(title: String, content: String) -> UIView {
        let container = UIView()
        
        //title
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textAlignment = .left
        titleLabel.font = .systemFont(ofSize: 18)
        titleLabel.textColor = .black
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        container.addSubview(titleLabel)
        
        let contentLabel = UILabel()
        contentLabel.text = content
        contentLabel.textAlignment = .right
        contentLabel.font = .systemFont(ofSize: 16)
        contentLabel.textColor = .gray
        contentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        container.addSubview(contentLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
            make.right.equalTo(contentLabel.snp.left)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(titleLabel.snp.right)
        }
        
        return container
    }
}
