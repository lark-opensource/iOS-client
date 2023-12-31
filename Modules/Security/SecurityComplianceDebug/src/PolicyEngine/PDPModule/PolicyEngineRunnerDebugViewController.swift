//
//  PolicyEngineRunnerDebugViewController.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2022/11/28.
//

import Foundation
import SnapKit
import LarkPolicyEngine
import EENavigator
import LarkUIKit
import LarkContainer
import LarkSecurityCompliance
import LarkEMM
import LarkSensitivityControl

final class PolicyEngineRunnerDebugViewController: UIViewController {
    
    let policyTextView = UITextView()
    let contextTextView = UITextView()
    let combineTextView = UITextView()
    let outputTextView = UITextView()
    var combine: CombineAlgorithm = .denyOverride
    private let pasteboardConfig = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier))
    
    @Provider
    private var serviceImpl: PolicyEngineSnCService
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildView()
    }
    
    func buildView() {
        view.backgroundColor = .gray
        
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(didClickClearBtn)),
            UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(didClickValidate)),
        ]
        
        let emptyButton = UIButton()
        emptyButton.addTarget(self, action: #selector(didClickEmpty), for: .touchUpInside)
        view.addSubview(emptyButton)
        emptyButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let policyLabel = UILabel()
        policyLabel.text = "策略信息"
        policyLabel.font = .systemFont(ofSize: 18)
        policyLabel.textColor = .black
        view.addSubview(policyLabel)
        policyLabel.snp.makeConstraints { make in
            make.leftMargin.rightMargin.equalToSuperview()
            make.top.equalTo(view.snp.topMargin)
        }
        
        let copyPolicyBtn = UIButton()
        copyPolicyBtn.setTitle("复制", for: .normal)
        copyPolicyBtn.layer.borderColor = UIColor.gray.cgColor
        copyPolicyBtn.layer.borderWidth = 2
        copyPolicyBtn.layer.cornerRadius = 4
        copyPolicyBtn.backgroundColor = .greenSea
        copyPolicyBtn.addTarget(self, action: #selector(didClickCopyPolicy), for: .touchUpInside)
        view.addSubview(copyPolicyBtn)
        copyPolicyBtn.snp.makeConstraints { make in
            make.rightMargin.equalToSuperview()
            make.top.bottom.equalTo(policyLabel)
            make.width.equalTo(60)
        }
        
        let pastePolicyBtn = UIButton()
        pastePolicyBtn.setTitle("粘贴", for: .normal)
        pastePolicyBtn.layer.borderColor = UIColor.gray.cgColor
        pastePolicyBtn.layer.borderWidth = 2
        pastePolicyBtn.layer.cornerRadius = 4
        pastePolicyBtn.backgroundColor = .greenSea
        pastePolicyBtn.addTarget(self, action: #selector(didClickPastePolicy), for: .touchUpInside)
        view.addSubview(pastePolicyBtn)
        pastePolicyBtn.snp.makeConstraints { make in
            make.right.equalTo(copyPolicyBtn.snp.left).offset(-5)
            make.top.bottom.equalTo(policyLabel)
            make.width.equalTo(60)
        }
        
        policyTextView.isEditable = true
        policyTextView.layer.cornerRadius = 4
        policyTextView.layer.shadowColor = UIColor.gray.cgColor
        policyTextView.layer.shadowRadius = 2
        policyTextView.layer.shadowOpacity = 1
        policyTextView.layer.shadowOffset = CGSize(width: 1, height: 1)
        policyTextView.backgroundColor = .white
        policyTextView.layer.borderWidth = 1
        policyTextView.layer.borderColor = UIColor.black.cgColor
        view.addSubview(policyTextView)
        policyTextView.snp.makeConstraints { make in
            make.top.equalTo(policyLabel.snp.bottom).offset(12)
            make.leftMargin.rightMargin.equalToSuperview()
            make.height.equalTo(120)
        }
        
        let contextLabel = UILabel()
        contextLabel.text = "参数信息"
        contextLabel.font = .systemFont(ofSize: 18)
        contextLabel.textColor = .black
        view.addSubview(contextLabel)
        contextLabel.snp.makeConstraints { make in
            make.leftMargin.rightMargin.equalToSuperview()
            make.top.equalTo(policyTextView.snp.bottom).offset(12)
        }
        
        let copyContextBtn = UIButton()
        copyContextBtn.setTitle("复制", for: .normal)
        copyContextBtn.layer.borderColor = UIColor.gray.cgColor
        copyContextBtn.layer.borderWidth = 2
        copyContextBtn.layer.cornerRadius = 4
        copyContextBtn.backgroundColor = .greenSea
        copyContextBtn.addTarget(self, action: #selector(didClickCopyContext), for: .touchUpInside)
        view.addSubview(copyContextBtn)
        copyContextBtn.snp.makeConstraints { make in
            make.rightMargin.equalToSuperview()
            make.top.bottom.equalTo(contextLabel)
            make.width.equalTo(60)
        }
        
        let pasteContextBtn = UIButton()
        pasteContextBtn.setTitle("粘贴", for: .normal)
        pasteContextBtn.layer.borderColor = UIColor.gray.cgColor
        pasteContextBtn.layer.borderWidth = 2
        pasteContextBtn.layer.cornerRadius = 4
        pasteContextBtn.backgroundColor = .greenSea
        pasteContextBtn.addTarget(self, action: #selector(didClickPasteContext), for: .touchUpInside)
        view.addSubview(pasteContextBtn)
        pasteContextBtn.snp.makeConstraints { make in
            make.right.equalTo(copyContextBtn.snp.left).offset(-5)
            make.top.bottom.equalTo(contextLabel)
            make.width.equalTo(60)
        }
        
        contextTextView.isEditable = true
        contextTextView.layer.cornerRadius = 4
        contextTextView.layer.shadowColor = UIColor.gray.cgColor
        contextTextView.layer.shadowRadius = 2
        contextTextView.layer.shadowOpacity = 1
        contextTextView.layer.shadowOffset = CGSize(width: 1, height: 1)
        contextTextView.backgroundColor = .white
        contextTextView.layer.borderWidth = 1
        contextTextView.layer.borderColor = UIColor.black.cgColor
        view.addSubview(contextTextView)
        contextTextView.snp.makeConstraints { make in
            make.top.equalTo(contextLabel.snp.bottom).offset(12)
            make.leftMargin.rightMargin.equalToSuperview()
            make.height.equalTo(120)
        }
        
        let combineLabel = UILabel()
        combineLabel.text = "策略组合算法"
        combineLabel.font = .systemFont(ofSize: 18)
        combineLabel.textColor = .black
        view.addSubview(combineLabel)
        combineLabel.snp.makeConstraints { make in
            make.leftMargin.rightMargin.equalToSuperview()
            make.top.equalTo(contextTextView.snp.bottom).offset(12)
        }
        
        let selectCombineBtn = UIButton()
        selectCombineBtn.setTitle("选择", for: .normal)
        selectCombineBtn.layer.borderColor = UIColor.gray.cgColor
        selectCombineBtn.layer.borderWidth = 2
        selectCombineBtn.layer.cornerRadius = 4
        selectCombineBtn.backgroundColor = .greenSea
        selectCombineBtn.addTarget(self, action: #selector(didClickChoiseCombine), for: .touchUpInside)
        view.addSubview(selectCombineBtn)
        selectCombineBtn.snp.makeConstraints { make in
            make.rightMargin.equalToSuperview()
            make.top.bottom.equalTo(combineLabel)
            make.width.equalTo(60)
        }
        
        combineTextView.isEditable = false
        combineTextView.layer.cornerRadius = 4
        combineTextView.layer.shadowColor = UIColor.gray.cgColor
        combineTextView.layer.shadowRadius = 2
        combineTextView.layer.shadowOpacity = 1
        combineTextView.layer.shadowOffset = CGSize(width: 1, height: 1)
        combineTextView.backgroundColor = .white
        combineTextView.layer.borderWidth = 1
        combineTextView.layer.borderColor = UIColor.black.cgColor
        combineTextView.text = combine.rawValue
        view.addSubview(combineTextView)
        combineTextView.snp.makeConstraints { make in
            make.top.equalTo(combineLabel.snp.bottom).offset(12)
            make.leftMargin.rightMargin.equalToSuperview()
            make.height.equalTo(40)
        }
        
        let outputLabel = UILabel()
        outputLabel.text = "输出"
        outputLabel.font = .systemFont(ofSize: 18)
        outputLabel.textColor = .black
        view.addSubview(outputLabel)
        outputLabel.snp.makeConstraints { make in
            make.leftMargin.rightMargin.equalToSuperview()
            make.top.equalTo(combineTextView.snp.bottom).offset(12)
        }
        
        let copyOutputBtn = UIButton()
        copyOutputBtn.setTitle("复制", for: .normal)
        copyOutputBtn.layer.borderColor = UIColor.gray.cgColor
        copyOutputBtn.layer.borderWidth = 2
        copyOutputBtn.layer.cornerRadius = 4
        copyOutputBtn.backgroundColor = .greenSea
        copyOutputBtn.addTarget(self, action: #selector(didClickCopyOutput), for: .touchUpInside)
        view.addSubview(copyOutputBtn)
        copyOutputBtn.snp.makeConstraints { make in
            make.rightMargin.equalToSuperview()
            make.top.bottom.equalTo(outputLabel)
            make.width.equalTo(60)
        }
        
        outputTextView.isEditable = false
        outputTextView.layer.cornerRadius = 4
        outputTextView.layer.shadowColor = UIColor.gray.cgColor
        outputTextView.layer.shadowRadius = 2
        outputTextView.layer.shadowOpacity = 1
        outputTextView.layer.shadowOffset = CGSize(width: 1, height: 1)
        outputTextView.backgroundColor = .white
        outputTextView.layer.borderWidth = 1
        outputTextView.layer.borderColor = UIColor.black.cgColor
        view.addSubview(outputTextView)
        outputTextView.snp.makeConstraints { make in
            make.top.equalTo(outputLabel.snp.bottom).offset(12)
            make.leftMargin.rightMargin.equalToSuperview()
            make.bottom.equalTo(view.snp.bottomMargin)
        }
    }
    
    @objc
    private func didClickEmpty() {
        policyTextView.resignFirstResponder()
        contextTextView.resignFirstResponder()
    }
    
    @objc
    private func didClickCopyPolicy() {
        SCPasteboard.general(pasteboardConfig).string = policyTextView.text
    }
    
    @objc
    private func didClickPastePolicy() {
        policyTextView.text = SCPasteboard.general(pasteboardConfig).string
    }
    
    @objc
    private func didClickCopyContext() {
        SCPasteboard.general(pasteboardConfig).string = contextTextView.text
    }
    
    @objc
    private func didClickPasteContext() {
        contextTextView.text = SCPasteboard.general(pasteboardConfig).string
    }
    
    @objc
    private func didClickCopyOutput() {
        SCPasteboard.general(pasteboardConfig).string = outputTextView.attributedText.string
    }
    
    @objc
    private func didClickChoiseCombine() {
        guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
        let dialog = UIAlertController(title: "列表", message: nil, preferredStyle: .actionSheet)
        
        for choise in CombineAlgorithm.allCases.map{ $0.rawValue } {
            dialog.addAction(UIAlertAction(title: choise, style: .default, handler: { [weak self] action in
                guard let combine = CombineAlgorithm(rawValue: action.title ?? "") else { return }
                self?.combine = combine
                self?.combineTextView.text = combine.rawValue
            }))
        }
        
        dialog.addAction(UIAlertAction(title: "取消", style: .cancel))
        Navigator.shared.present(dialog, from: fromVC)
    }
    
    @objc
    private func didClickClearBtn() {
        policyTextView.text = ""
        policyTextView.contentOffset = .zero
        contextTextView.text = ""
        contextTextView.contentOffset = .zero
        outputTextView.text = ""
        outputTextView.attributedText = nil
        outputTextView.contentOffset = .zero
    }
    
    @objc
    private func didClickValidate() {
        guard let policyText = policyTextView.text else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
            let dialog = UIAlertController(title: "Error", message: "策略不能为空", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            return
        }
        guard let policyData = policyText.data(using: .utf8) else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
            let dialog = UIAlertController(title: "Error", message: "策略内容解析失败\n请检查格式是否正确", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            return
        }
        var policies: [Policy]?
        do {
            policies = try JSONDecoder().decode([Policy].self, from: policyData)
        } catch {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
            let dialog = UIAlertController(title: "Error", message: "策略内容解析失败\n\(error)", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            return
        }
        guard let policies = policies else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
            let dialog = UIAlertController(title: "Error", message: "策略内容解析失败\n请检查格式是否正确", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            return
        }
        
        var params = [AnyHashable: Any]()
        if let context = contextTextView.text {
            guard let tempParams = (context as NSString).btd_jsonDictionary() else {
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let dialog = UIAlertController(title: "Error", message: "参数解析失败\n请检查格式是否正确", preferredStyle: .alert)
                Navigator.shared.present(dialog, from: fromVC)
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    dialog.dismiss(animated: true)
                }
                return
            }
            params = tempParams
        }
        let logger = PolicyEngineDebugLogger()
        let serviceWrapper = PolicyEngineServiceDebugWrapper(service: serviceImpl)
        serviceWrapper.logger = logger
        
        let paramsString = params.mapValues{ $0 }
        var bizParams: [String: Any] = [:]
        for (key, value) in paramsString {
            if let stringKey = key as? String {
                bizParams[stringKey] = value
            }
        }
        var policyMap: [String: Policy] = [:]
        for policy in policies {
            policyMap[policy.id] = policy
        }
        let runnerContext = RunnerContext(uuid: UUID().uuidString, contextParams: bizParams, policies: policyMap, combineAlgorithm: combine, service: serviceWrapper)
        let runner = PolicyRunner(context: runnerContext)
        
        do {
            let ret = try runner.runPolicy()
            logger.logList.append((.info, "Result: \(ret.combinedEffect.rawValue)"))
            logger.logList.append((.info, """
            <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            Result:\(ret.combinedEffect.rawValue)
            Hit:
            \(ret.hits.reduce("", { partialResult, checkResult in
            return "\(partialResult)PolicyName: \(checkResult.policy.name)，Effect: \(checkResult.effect.rawValue), Action:\(checkResult.actions), isExcuted:\(checkResult.isExecuted) \n"
            }))
            Combine Action: \(ret.combinedActions)
            >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            """))
        } catch {
            logger.logList.append((.error, "Exception: \(error)"))
        }
        outputTextView.contentOffset = .zero
        outputTextView.attributedText = logger.logList.reversed().reduce(into: NSMutableAttributedString(), { partialResult, msg in
            partialResult.append(NSAttributedString(string: "\(msg.1)\n\n\n---------------\n", attributes: [
                .foregroundColor: msg.0 == .error ? UIColor.red : UIColor.black
            ]))
        })
    }
}
