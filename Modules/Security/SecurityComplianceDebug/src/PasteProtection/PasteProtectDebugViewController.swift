//
//  PasteProtectDebugViewController.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/8/26.
//

import Foundation
import UIKit
import WebKit
import LarkEMM
import LarkAccountInterface
import LarkContainer
import LarkSensitivityControl
import UniverseDesignColor

final class PasteProtectDebugViewController: UIViewController {
    
    @Provider var debug: EMMDebugService
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody

        let testField = UITextField(frame: CGRect(x: 10, y: 100, width: 150, height: 30))
        testField.placeholder = "UITextField"
        view?.addSubview(testField)

        let testField1 = UITextField(frame: CGRect(x: 170, y: 100, width: 200, height: 30))
        testField1.placeholder = "UITextField 单点豁免能力"
        testField1.shouldImmunity = true
        view?.addSubview(testField1)

        let testView = UITextView(frame: CGRect(x: 10, y: 150, width: 300, height: 30))
        testView.text = "TextView"
        view.addSubview(testView)

        let webView = WKWebView(frame: CGRect(x: 10, y: 200, width: 300, height: 100))
        if let url = URL(string: "https://google.com") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        view.addSubview(webView)

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

        let webView2 = WKWebView(frame: CGRect(x: 10, y: 400, width: 300, height: 100))
        webView2.pointId = "123456765sfgggafesdefr"
        if let url = URL(string: "https://www.baidu.com") {
            let request = URLRequest(url: url)
            webView2.load(request)
        }
        view.addSubview(webView2)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        label.backgroundColor = UIColor.ud.green
        label.text = "单一文档粘贴保护"
        label.textColor = UIColor.ud.staticBlack
        webView2.addSubview(label)
        
        let thirdEMMIntegrateState = debug.intergrateThirdEMMStateOnDisk
        let emmDiskStateLabel: UILabel = UILabel(frame: CGRect(x: 10, y: 530, width: UIWindow.ud.windowBounds.size.width - 20, height: 30))
        emmDiskStateLabel.text = "磁盘中集成三方EMM能力状态：\(thirdEMMIntegrateState)"
        emmDiskStateLabel.textColor = UIColor.ud.staticBlack
        view.addSubview(emmDiskStateLabel)
        
        let isThirdEMMIntegrated = debug.isIntegrateThirdEMMInMemory
        let emmMemoryStateLabel: UILabel = UILabel(frame: CGRect(x: 10, y: 570, width: UIWindow.ud.windowBounds.size.width - 20, height: 30))
        emmMemoryStateLabel.text = "内存中集成三方EMM能力值：\(isThirdEMMIntegrated ?? false)"
        emmMemoryStateLabel.textColor = UIColor.ud.staticBlack
        view.addSubview(emmMemoryStateLabel)
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
}
