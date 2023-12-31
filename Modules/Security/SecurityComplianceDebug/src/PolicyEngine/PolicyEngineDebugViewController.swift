//
//  PolicyEngineDebugViewController.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2022/11/2.
//

import Foundation
import UIKit
import SnapKit
import LarkSecurityComplianceInfra
import LarkAccountInterface
import EENavigator
import LarkContainer
import LarkPolicyEngine

struct PolicyDebugItem {
    let title: String
    let action: () -> Void
    
    init(title: String, action:@escaping () -> Void = {}) {
        self.title = title
        self.action = action
    }
}

final class PolicyEngineDebugViewController: UIViewController {    
    
    var items = [(String, [PolicyDebugItem])]()
    
    let userResolver: UserResolver
    
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        return nil
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareData()
        buildView()
    }
    
    private func prepareData() {
        items = [
            (
                "PEP测试工具",
                [
                    PolicyDebugItem(title: "策略信息", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let vc = PolicyEnginePolicyListViewController(userResolver: self.userResolver)
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "切点信息", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let vc = PointCutListViewController()
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "快速剪枝信息", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let vc = PolicyEngineFastPassDataShowViewController()
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "特征信息", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let vc = PolicyEngineFactorInfoViewController(userResolver: self.userResolver)
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "策略优先级信息", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let vc = PolicyEnginePriorityInfoViewController(userResolver: self.userResolver)
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "事件监控", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let vc = PolicyEngineEventDebugViewController(resolver: self.userResolver)
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "模拟决策", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let model = PolicyEngineValidateDebugHandler(resolver: self.userResolver).generateModel()
                        let vc = SCDebugFormViewController(model: model)
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "因子管控查询", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let model = FactorControlDebugHandler(resolver: self.userResolver).generateModel()
                        let vc = SCDebugFormViewController(model: model)
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "快速剪枝测试", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let model = PolicyEngineFastPassDebugHandler(resolver: self.userResolver).generateModel()
                        let vc = SCDebugFormViewController(model: model)
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "降级决策测试", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let model = PolicyEngineDowngradeDebugHandler(resolver: self.userResolver).generateModel()
                        let vc = SCDebugFormViewController(model: model)
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "策略拉取测试", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let model = PolicyEngineCheckDeployPolicyDebugHandler(resolver: self.userResolver).generateModel()
                        let vc = SCDebugFormViewController(model: model)
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "真实日志上报测试", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let model = PolicyEngineDesicionLogReportDebugHandler(resolver: self.userResolver).generateModel()
                        let vc = SCDebugFormViewController(model: model)
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "真实日志缓存信息", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let vc = PolicyEngineDesicionLogInfoViewController()
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "日志删除测试", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let model = PolicyEngineDesicionLogDeleteDebugHandler(resolver: self.userResolver).generateModel()
                        let vc = SCDebugFormViewController(model: model)
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                ]
            ),
            (
                "PDP测试工具",
                [
                    PolicyDebugItem(title: "策略计算", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }                        
                        let vc = PolicyEngineRunnerDebugViewController()
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                    PolicyDebugItem(title: "表达式计算", action: { [weak self] in
                        guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                        let vc = PolicyEngineExpressionDebugViewController()
                        Navigator.shared.push(vc, from: currentVC)
                    }),
                ]
            )
        ]
    }
    
    private func buildView() {
        view.backgroundColor = .gray
        
        let setting = try? userResolver.resolve(assert: Settings.self)
        let userService = try? userResolver.resolve(assert: PassportUserService.self)
        let engine = try? userResolver.resolve(assert: PolicyEngineService.self)
        let baseInfo = PolicyEngineBaseInfo(userID: userService?.user.userID ?? "", tenantID: userService?.userTenant.tenantID ?? "", engineSwitch: setting?.enablePolicyEngine ?? true, engineLocalValidateSwitch: setting?.policyEngineDisableLocalValidate ?? false, refreshInterval: setting?.policyEngineFetchPolicyInterval ?? 60*5, localValidateLimit: setting?.policyEngineLocalValidateCountLimit ?? 100, pointcutRetryDelay: setting?.policyEnginePointcutRetryDelay ?? 5,tenantHasDeployPolicy:engine?.enableFetchPolicy(tenantId:userService?.userTenant.tenantID))
        
        let baseInfoView = PolicyEngineBaseInfoView(info: baseInfo)
        view.addSubview(baseInfoView)
        baseInfoView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.top.equalTo(view.snp.topMargin)
        }
        
        let tableView = UITableView()
        tableView.layer.cornerRadius = 4
        tableView.layer.shadowColor = UIColor.gray.cgColor
        tableView.layer.shadowRadius = 2
        tableView.layer.shadowOpacity = 1
        tableView.layer.shadowOffset = CGSize(width: 1, height: 1)
        tableView.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        tableView.bouncesZoom = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.contentInset = .init(top: 10, left: 0, bottom: 0, right: 0)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.top.equalTo(baseInfoView.snp.bottom).offset(10)
            make.bottom.equalTo(view.snp.bottomMargin)
        }
    }
}

extension PolicyEngineDebugViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = items[section].1
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section].1[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = item.title
        return cell
    }    
}

extension PolicyEngineDebugViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let item = items[indexPath.section].1[indexPath.row]
        item.action()
    }
}
