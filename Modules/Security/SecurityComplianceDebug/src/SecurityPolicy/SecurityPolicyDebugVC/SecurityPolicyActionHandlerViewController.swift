//
//  SecurityPolicyActionHandlerViewController.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/4/17.
//

import Foundation
import SnapKit
import LarkSecurityComplianceInterface
import LarkContainer
import LarkEMM

class SecurityPolicyActionHandlerViewController: UIViewController {
    private var inputActionView: UITextView = {
        let view = UITextView(frame: UIWindow.ud.windowBounds)
        view.backgroundColor = .lightGray
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.black.cgColor
        return view
    }()
    
    private var pasteButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .lightGray
        button.setTitle("粘贴", for: .normal)
        button.layer.cornerRadius = 4
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1
        
        return button
    }()
    
    private var executeButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .lightGray
        button.setTitle("处理", for: .normal)
        button.layer.cornerRadius = 4
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    private var bgButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(bgButton)
        bgButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        bgButton.addTarget(self, action: #selector(resignTextViewFirstResponder), for: .touchUpInside)
        view.addSubview(inputActionView)
        inputActionView.snp.makeConstraints {
            $0.topMargin.equalToSuperview().offset(10)
            $0.bottom.equalToSuperview().offset(-150)
            $0.left.equalToSuperview().offset(15)
            $0.right.equalToSuperview().offset(-15)
        }
        view.addSubview(pasteButton)
        pasteButton.snp.makeConstraints {
            $0.top.equalTo(inputActionView.snp.bottom).offset(5)
            $0.height.equalTo(40)
            $0.left.equalToSuperview().offset(15)
            $0.width.equalTo(60)
        }
        pasteButton.addTarget(self, action: #selector(didClickPasteButton), for: .touchUpInside)
        view.addSubview(executeButton)
        executeButton.snp.makeConstraints {
            $0.top.equalTo(pasteButton.snp.top)
            $0.height.width.equalTo(pasteButton)
            $0.right.equalToSuperview().offset(-15)
        }
        executeButton.addTarget(self, action: #selector(didClickExecuteButton), for: .touchUpInside)
    }
    
    @objc
    private func didClickPasteButton() {
        inputActionView.text = SCPasteboard.general(SCPasteboard.defaultConfig()).string
    }
    
    @objc
    private func didClickExecuteButton() {
        @Provider var service: SecurityPolicyService
        let action = DebugSecurityAction(rawActions: inputActionView.text)
        service.handleSecurityAction(securityAction: action)
    }
    
    @objc
    private func resignTextViewFirstResponder() {
        inputActionView.resignFirstResponder()
    }
}

struct DebugSecurityAction: SecurityActionProtocol {
    var rawActions: String
}
