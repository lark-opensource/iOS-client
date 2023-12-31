//
//  PolicyEngineDesicionLogInfoViewController.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/8/24.
//

import UIKit
import LarkSnCService
import LarkPolicyEngine
import LarkContainer
import SnapKit
import LarkSecurityCompliance

let policyEngineDesicionLogInfoCacheKey = "DecisionLogCacheKey"

final class PolicyEngineDesicionLogInfoViewController: UIViewController {
    
    private lazy var contentView: UITextView = {
        let view = UITextView(frame: .zero)
        view.isEditable = false
        return view
    }()
    
    @Provider
    private var serviceImpl: PolicyEngineSnCService
    
    init() {
        super.init(nibName: nil, bundle: nil)
        refreshAllPointCutAction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "真实决策日志信息"
        self.view.backgroundColor = .gray
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshAllPointCutAction)),
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAllPointCutAction))
        ]
        
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - Private

extension PolicyEngineDesicionLogInfoViewController {

    @objc
    private func refreshAllPointCutAction() {
        do {
            let userStorage = serviceImpl.storage
            let evaluateInfoList: [EvaluateInfo]? = try userStorage?.get(key: policyEngineDesicionLogInfoCacheKey, space: .user)
            guard let evaluateInfoList = evaluateInfoList else {
                contentView.text = ""
                contentView.contentOffset = .zero
                return
            }
            let data = try JSONEncoder().encode(evaluateInfoList)
            let jsonObj = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObj, options: JSONSerialization.WritingOptions.prettyPrinted)
            let content = String(data: jsonData, encoding: .utf8)

            contentView.text = content
            contentView.contentOffset = .zero
        } catch {
            print("Error: \(error)")
            contentView.text = "读取错误：\(error)"
        }
    }

    @objc
    private func deleteAllPointCutAction() {
        do {
            let userStorage = serviceImpl.storage
            let _: [EvaluateInfo]? = try userStorage?.remove(key: policyEngineDesicionLogInfoCacheKey, space: .user)
            contentView.text = nil
        } catch {
            print("Remove Error: \(error)")
        }
    }
}

