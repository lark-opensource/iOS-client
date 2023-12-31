//
//  PointCutListViewController.swift
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

let kPointCutInfoCacheKey = "PointCutInfoCacheKey"

final class PointCutListViewController: UIViewController {
    
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
        self.title = "切点列表"
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

extension PointCutListViewController {

    @objc
    private func refreshAllPointCutAction() {
        do {
            let userStorage = serviceImpl.storage
            let policyInfo: [String: PointCutModel]? = try userStorage?.get(key: kPointCutInfoCacheKey, space: .global)
            guard let policyInfo = policyInfo else {
                contentView.text = ""
                contentView.contentOffset = .zero
                return
            }
            let data = try JSONEncoder().encode(policyInfo)
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
            let _: [String: PointCutModel]? = try userStorage?.remove(key: kPointCutInfoCacheKey, space: .global)
            contentView.text = nil
        } catch {
            print("Remove Error: \(error)")
        }
    }
}
