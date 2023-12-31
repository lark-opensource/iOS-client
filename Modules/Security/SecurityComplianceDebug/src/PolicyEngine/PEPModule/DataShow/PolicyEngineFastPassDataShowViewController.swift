//
//  PolicyEngineFastPassDataShowViewController.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2023/2/16.
//

import UIKit
import LarkSnCService
import LarkPolicyEngine
import LarkContainer
import SnapKit
import LarkSecurityCompliance

fileprivate typealias FastPassConfig = [String: [String]]

private let fastPassConfigCacheKey = "FastPassConfigCacheKey"

final class PolicyEngineFastPassDataShowViewController: UIViewController {
    
    private lazy var contentView: UITextView = {
        let view = UITextView(frame: .zero)
        view.isEditable = false
        return view
    }()
    
    @Provider
    private var serviceImpl: PolicyEngineSnCService
    
    init() {
        super.init(nibName: nil, bundle: nil)
        refreshAllInfo()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "快速剪枝信息列表"
        self.view.backgroundColor = .gray
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshAllInfo)),
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAllInfo))
        ]
        
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalTo(0)
        }
    }
}

// MARK: - Private

extension PolicyEngineFastPassDataShowViewController {
    
    @objc
    private func refreshAllInfo() {
        do {
            let userStorage = serviceImpl.storage
            let info: FastPassConfig? = try userStorage?.get(key: fastPassConfigCacheKey, space: .global)
            guard let info = info else {
                contentView.text = ""
                contentView.contentOffset = .zero
                return
            }
            let data = try JSONEncoder().encode(info)
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
    private func deleteAllInfo() {
        do {
            let userStorage = serviceImpl.storage
            let _: FastPassConfig? = try userStorage?.remove(key: fastPassConfigCacheKey, space: .global)
            contentView.text = nil
        } catch {
            print("Remove Error: \(error)")
        }
    }
}
