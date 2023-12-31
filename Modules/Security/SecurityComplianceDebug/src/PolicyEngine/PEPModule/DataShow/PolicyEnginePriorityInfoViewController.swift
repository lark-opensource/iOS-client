//
//  PolicyEnginePriorityInfoViewController.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/10/10.
//

import UIKit
import LarkSnCService
import LarkPolicyEngine
import LarkContainer
import SnapKit
import LarkSecurityCompliance

private let policyPriorityCacheKey = "PolicyPriorityCacheKey"

final class PolicyEnginePriorityInfoViewController: UIViewController {

    private lazy var contentView: UITextView = {
        let view = UITextView(frame: .zero)
        view.isEditable = false
        return view
    }()

    private var serviceImpl: PolicyEngineSnCService?

    init(userResolver: UserResolver) {
        super.init(nibName: nil, bundle: nil)
        serviceImpl = try? userResolver.resolve(assert: PolicyEngineSnCService.self)
        refreshAllPolicyAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "策略优先级信息"
        self.view.backgroundColor = .gray
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshAllPolicyAction)),
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAllPolicyAction))
        ]

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalTo(0)
        }
    }
}

// MARK: - Private
extension PolicyEnginePriorityInfoViewController {

    @objc
    private func refreshAllPolicyAction() {
        do {
            var content = ""
            let userStorage = serviceImpl?.storage
            
            let policyPriorityData: PolicyPriorityData? = try userStorage?.get(key: policyPriorityCacheKey)
            if let policyPriorityData = policyPriorityData {
                let data = try JSONEncoder().encode(policyPriorityData)
                content += try dataToString(data: data) + "\n"
            }
            
            contentView.text = content
            contentView.contentOffset = .zero
        } catch {
            print("Error: \(error)")
            contentView.text = "读取错误：\(error)"
        }
    }

    @objc
    private func deleteAllPolicyAction() {
        do {
            let userStorage = serviceImpl?.storage
            let _: PolicyPriorityData? = try userStorage?.remove(key: policyPriorityCacheKey)
            contentView.text = nil
        } catch {
            print("Remove Error: \(error)")
        }
    }

    private func dataToString(data: Data) throws -> String {
        let jsonObj = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed)
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObj, options: JSONSerialization.WritingOptions.prettyPrinted)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
}

