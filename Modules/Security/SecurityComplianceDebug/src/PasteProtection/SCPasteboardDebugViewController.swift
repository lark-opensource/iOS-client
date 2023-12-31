//
//  SCPasteboardDebugViewController.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/12/24.
//

import Foundation
import UIKit
import WebKit
import LarkEMM
import LarkContainer
import LarkSensitivityControl

enum PasteboardDebugType: String {
    case textField
    case textView
    case webview
    case system
}

final class SCPasteboardDebugViewController: UITableViewController {
    
    @Provider var debug: EMMDebugService
    
    let userResolver: UserResolver
    let dataSource: [PasteboardDebugType] = [.textView, .textField, .webview, .system]
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = UIColor.ud.bgBody

    }

    @objc
    func clickButton() {
        let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier), scene: nil, pointId: nil, shouldImmunity: true)
        SCPasteboard.general(config).string = "系统剪贴板豁免能力"
    }

    @objc
    func clickButton1() {
        let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier), scene: nil, pointId: nil, shouldImmunity: false)
        SCPasteboard.general(config).string = "系统剪贴板粘贴保护能力"
    }
    
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let title = dataSource[indexPath.row]
        cell.textLabel?.text = title.rawValue
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = PasteboardCategoryViewController(type: dataSource[indexPath.row])
        guard let currentVC = userResolver.navigator.mainSceneTopMost else { return }
        userResolver.navigator.push(vc, from: currentVC)
        
        
    }
}


class PasteboardCategoryViewController: UIViewController {
    
    let type: PasteboardDebugType
    let label = UILabel()
    
    init(type: PasteboardDebugType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        switch self.type {
        case .textView:
            addTextView()
        case .textField:
            addTextField()
        case .webview:
            addWebview()
        case .system:
            addSystemButton()
        }
    }

}

extension PasteboardCategoryViewController {
    func addTextView() {
        let textView = UITextView(frame: view.bounds)
        view.addSubview(textView)
    }
    
    func addTextField() {
        let testField = UITextField(frame: view.bounds)
        testField.placeholder = "UITextField"
        view?.addSubview(testField)
    }
}

extension PasteboardCategoryViewController {
    func addWebview() {
        let webView = WKWebView(frame: view.bounds)
        if let url = URL(string: "https://www.baidu.com") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        view.addSubview(webView)
        
    }
}

extension PasteboardCategoryViewController {
    
    func addSystemButton() {
        let button: UIButton = UIButton(type: .custom)
        button.frame = CGRect(x: 10, y: 320, width: 220, height: 50)
        button.backgroundColor = UIColor.ud.colorfulBlue
        button.titleLabel?.textColor = UIColor.ud.staticBlack
        button.setTitle("系统单点豁免能力", for: .normal)
        button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
        view.addSubview(button)

        let button1: UIButton = UIButton(type: .custom)
        button1.frame = CGRect(x: 240, y: 320, width: 220, height: 50)
        button1.backgroundColor = UIColor.ud.colorfulRed
        button1.titleLabel?.textColor = UIColor.ud.staticBlack
        button1.setTitle("系统粘贴保护", for: .normal)
        button1.addTarget(self, action: #selector(clickButton1), for: .touchUpInside)
        view.addSubview(button1)
        
        let button2: UIButton = UIButton(type: .custom)
        button2.frame = CGRect(x: 10, y: 380, width: 220, height: 50)
        button2.backgroundColor = UIColor.ud.colorfulRed
        button2.titleLabel?.textColor = UIColor.ud.staticBlack
        button2.setTitle("单一文档保护复制", for: .normal)
        button2.addTarget(self, action: #selector(clickButton2), for: .touchUpInside)
        view.addSubview(button2)
        
        let button3: UIButton = UIButton(type: .custom)
        button3.frame = CGRect(x: 240, y: 380, width: 220, height: 50)
        button3.backgroundColor = UIColor.ud.colorfulRed
        button3.titleLabel?.textColor = UIColor.ud.staticBlack
        button3.setTitle("单一文档保护粘贴", for: .normal)
        button3.addTarget(self, action: #selector(clickButton3), for: .touchUpInside)
        view.addSubview(button3)
        
        label.frame = CGRect(x: 10, y: 450, width: 220, height: 50)
        view.addSubview(label)
        label.backgroundColor = UIColor.red
    }
    
    @objc
    func clickButton() {
        let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier), scene: nil, pointId: nil, shouldImmunity: true)
        SCPasteboard.general(config).string = "系统剪贴板豁免能力"
    }

    @objc
    func clickButton1() {
        let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier), scene: nil, pointId: nil, shouldImmunity: false)
        SCPasteboard.general(config).string = "系统剪贴板粘贴保护能力"
    }
    @objc
    func clickButton2() {
        let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier), scene: nil, pointId: "aaaaa", shouldImmunity: false)
        SCPasteboard.general(config).string = "单一文档保护"
    }
    
    @objc
    func clickButton3() {
        let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier), scene: nil, pointId: "aaaaa", shouldImmunity: false)
        label.text = SCPasteboard.general(config).string
    }
}
