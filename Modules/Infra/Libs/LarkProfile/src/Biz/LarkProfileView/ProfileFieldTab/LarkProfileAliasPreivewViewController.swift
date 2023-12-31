//
//  LarkProfileAliasPreivewViewController.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/10/25.
//

import Foundation
import LarkAssetsBrowser
import LarkUIKit
import UIKit

final class LarkProfileAliasPreivewViewController: LKAssetBrowserViewController {
    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.backgroundColor = .clear
        stack.axis = .vertical
        stack.alignment = .fill
        return stack
    }()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .light
        }

        let wrapper = UIView()
        self.view.addSubview(wrapper)
        wrapper.addSubview(stackView)
        wrapper.backgroundColor = UIColor.ud.staticBlack
        wrapper.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
        }
        stackView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    public func addAction(title: String,
                          titleColor: UIColor = UIColor.ud.primaryOnPrimaryFill,
                          action: @escaping (UIButton) -> Void) {
        let item = AliasProcessItem(labelText: title, titleColor: titleColor, action: action)
        stackView.addArrangedSubview(item)
    }
}

final class AliasProcessItem: UIButton {
    lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()

    var action: (UIButton) -> Void

    public init(labelText: String,
                titleColor: UIColor,
         action: @escaping (UIButton) -> Void
         ) {
        self.action = action
        super.init(frame: .zero)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        let wrapper = UIView()
        wrapper.isUserInteractionEnabled = false
        self.addSubview(wrapper)
        wrapper.snp.makeConstraints { (make) in
            make.top.bottom.centerX.equalToSuperview()
            make.height.equalTo(58)
        }

        label.text = labelText
        label.textColor = titleColor
        wrapper.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
        }
        self.lu.addTopBorder(color: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.25))
        self.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func buttonTapped(_ sender: UIButton) {
        self.action(sender)
    }
}
