//
//  PolicyEnginePolicyListViewController.swift
//  SecurityComplianceDebug
//
//  Created by WangHao on 2022/11/3.
//

import UIKit
import LarkSnCService
import LarkPolicyEngine
import LarkContainer
import SnapKit
import LarkSecurityCompliance

private let kPolicyInfoCacheKey = "PolicyEntityCacheKey"
private let policyEntityInfoCacheKey = "PolicyEntityCacheKey"
private let lastRequestDateCacheKey = "LastRequestDateCacheKey"

final class PolicyEnginePolicyListViewController: UIViewController {

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
        self.title = "策略列表"
        self.view.backgroundColor = .gray
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshAllPolicyAction)),
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteDateInfo)),
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAllPolicyAction))
        ]
        
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalTo(0)
        }
    }
}

// MARK: - Private

extension PolicyEnginePolicyListViewController {
    
    @objc
    private func refreshAllPolicyAction() {
        do {
            var content = ""
            let userStorage = serviceImpl?.storage
            let policyEntityInfo: PolicyEntityModel? = try userStorage?.get(key: policyEntityInfoCacheKey)
            if let policyEntityInfo = policyEntityInfo {
                let data = try JSONEncoder().encode(policyEntityInfo)
                content += try dataToString(data: data) + "\n"
            }
            content += "-------------------\n"
            let lastRequestDate: Date? = try userStorage?.get(key: lastRequestDateCacheKey)
            if let lastRequestDate = lastRequestDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: lastRequestDate)
                content += dateString
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
            let _: PolicyEntityModel? = try userStorage?.remove(key: policyEntityInfoCacheKey)
            refreshAllPolicyAction()
        } catch {
            print("Remove Error: \(error)")
        }
    }
    
    @objc
    private func deleteDateInfo() {
        do {
            let userStorage = serviceImpl?.storage
            let _: Date? = try userStorage?.remove(key: lastRequestDateCacheKey)
            refreshAllPolicyAction()
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
