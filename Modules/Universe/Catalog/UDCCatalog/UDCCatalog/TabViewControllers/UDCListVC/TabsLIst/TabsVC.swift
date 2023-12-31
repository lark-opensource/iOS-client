//
//  TabsVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/12/8.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import SnapKit
import UIKit
import UniverseDesignTabs
import UniverseDesignFont

public class TabsVC: UIViewController, UDTabsListContainerViewDelegate {

    private var textView = UITextField()
    public var callback: ((String, Int) -> Void)?
    private let index: Int
    private lazy var confirmBtn: UIButton = {
        let button = UIButton()
        button.setTitle("confirm", for: .normal)
        button.titleLabel?.font = UDFont.body2
        button.setTitleColor(UIColor.ud.N00, for: .normal)
        button.backgroundColor = UIColor.ud.primaryContentLoading
        button.addTarget(self, action: #selector(onBtnClicked), for: .touchUpInside)
        return button
    }()

    init(index: Int) {
        self.index = index
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(textView)
        self.view.addSubview(confirmBtn)
        textView.returnKeyType = .done;
        textView.placeholder = "please enter text"
        textView.delegate = self
        textView.returnKeyType = UIReturnKeyType.done
        self.view.backgroundColor = .white

        textView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        confirmBtn.snp.makeConstraints { (make) in
            make.top.equalTo(textView.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
        }
        textView.backgroundColor = UIColor.ud.R50
    }

    func setBackgroundColor(_ color: UIColor?) {
        self.view.backgroundColor = color
    }

    public func listWillAppear() {
        print(222)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        print(111)
    }

    public func listDidAppear() {
        print(3333)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(4444)
    }

    func setTitle(_ title: String) {
    }

    public func listView() -> UIView {
        return view
    }
    /// 确认按钮点击事件
    @objc private func onBtnClicked() {
        self.callback?(textView.text ?? "", index)
    }
}

extension TabsVC: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(false)
        return true
    }
}
