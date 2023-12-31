//
//  IMMentionDebugViewController.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/20.
//
import UIKit
#if !LARK_NO_DEBUG
import Foundation

final class IMMentionDebugViewController: UIViewController, IMMentionPanelDelegate {
    func panelDidCancel() {
        print("@@@@ panelDidCancel")
    }
    struct ChatModel: IMMentionChatConfigType {
        var showChatUserCount: Bool = true
        var id: String
        var userCount: Int32
        var isEnableAtAll: Bool
    }
    var textField = UITextField()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        textField.borderStyle = .roundedRect
        textField.text = "7120126817863843868"
        view.addSubview(textField)
        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-80)
            $0.top.equalToSuperview().offset(80)
            $0.height.equalTo(48)
        }
        
        let btn = UIButton()
        btn.setTitle("test", for: .normal)
        btn.backgroundColor = UIColor.ud.blue
        view.addSubview(btn)
        btn.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(48)
        }
        btn.addTarget(self, action: #selector(onSetting), for: .touchUpInside)
        
    }
    
    func panel(didFinishWith items: [IMMentionOptionType]) {
        print("@@@ \(items.count)")
    }
    
    @objc func onSetting() {
//        var text = textField.text ?? ""
//        text = text.replacingOccurrences(of: "\n", with: "")
//        var chat: ChatModel = ChatModel(id: textField.text ?? "", userCount: 50, isEnableAtAll: false)
//        let debugVc = IMMentionPanel(mentionChatModel: chat)
//        debugVc.show(from: self)
    }
}
#endif
