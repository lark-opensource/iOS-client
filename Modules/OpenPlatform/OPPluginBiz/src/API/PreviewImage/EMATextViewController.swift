//
//  EMATextViewController.swift
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/10.
//

import Foundation
import LarkUIKit
import EENavigator

class EMATextViewController: BaseUIViewController {
    private let text: String

    public init(text: String) {
        self.text = text
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let textView = UITextView()
        view.addSubview(textView)
        view.backgroundColor = .white
        textView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        }
        textView.backgroundColor = .white
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isUserInteractionEnabled = true
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.text = text
        textView.isEditable = false
    }
}
