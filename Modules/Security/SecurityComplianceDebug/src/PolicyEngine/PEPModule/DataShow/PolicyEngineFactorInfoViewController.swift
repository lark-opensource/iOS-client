//
//  PolicyEngineFactorInfoViewController.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/10/9.
//

import UIKit
import LarkSnCService
import LarkPolicyEngine
import LarkContainer
import SnapKit
import LarkSecurityCompliance

private let subjectFactorInfoCacheKey = "SubjectFactorInfoCacheKey"
private let ipFactorInfoCacheKey = "IPFactorInfoCacheKey"

final class PolicyEngineFactorInfoViewController: UIViewController {

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
        self.title = "特征信息"
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
extension PolicyEngineFactorInfoViewController {

    @objc
    private func refreshAllPolicyAction() {
        do {
            var content = ""
            let userStorage = serviceImpl?.storage
            
            let subjectFactorModel: SubjectFactorModel? = try userStorage?.get(key: subjectFactorInfoCacheKey)
            if let subjectFactorModel = subjectFactorModel {
                let data = try JSONEncoder().encode(subjectFactorModel)
                content += try dataToString(data: data) + "\n"
            }
            let ipFactorModel: IPFactorModel? = try userStorage?.get(key: ipFactorInfoCacheKey)
            if let ipFactorModel = ipFactorModel {
                let data = try JSONEncoder().encode(ipFactorModel)
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
            let _: SubjectFactorModel? = try userStorage?.remove(key: subjectFactorInfoCacheKey)
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
