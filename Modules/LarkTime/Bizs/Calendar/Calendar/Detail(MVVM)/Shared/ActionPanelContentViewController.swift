//
//  ActionPanelContentViewController.swift
//  Calendar
//
//  Created by tuwenbo on 2022/11/27.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignButton
import UniverseDesignIcon
import LarkUIKit

class ActionPanelContentViewController: UIViewController {

    private lazy var titleView: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.ud.body2(.fixed)
        return label
    }()

    private lazy var contentView: UIView = {
        let uiView = UIView()
        uiView.backgroundColor = UIColor.ud.bgFloat
        uiView.layer.cornerRadius = 10
        uiView.layer.masksToBounds = true
        return uiView
    }()

    private lazy var cancelButton: UIButton = {
        let button = MyButton(type: .custom)
        button.backgroundColor = UIColor.ud.bgFloat
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.setTitle(BundleI18n.Calendar.Calendar_Common_Cancel, for: .normal)
        button.setTitleColor(UIColor.ud.titleColor, for: .normal)
        button.addTarget(self, action: #selector(onCancelClicked), for: .touchUpInside)
        return button
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = UIColor.ud.bgFloatBase
     }

    func addContentView(_ content: UIView, contentHeight: Int, title: String? = nil) {
        var contentTopInset = 16
        if let title = title, !title.isEmpty {
            view.addSubview(titleView)
            titleView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(16)
                make.left.right.equalToSuperview().inset(32)
                make.height.equalTo(20)
            }
            titleView.text = title
            contentTopInset = 40
        }

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(contentTopInset)
            make.bottom.equalToSuperview().inset(100)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(contentHeight)
        }

        contentView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(36)
            make.height.equalTo(48)
        }
    }

    @objc
    private func onCancelClicked() {
        self.parent?.dismiss(animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ActionPanelContentViewController {
    class MyButton: UIButton {
        override public var isHighlighted: Bool {
            didSet {
                backgroundColor = isHighlighted ? UIColor.ud.fillPressed : UIColor.ud.bgFloat
            }
        }
    }
}

// 给 ipad 用的，因为 UDActionPanel 不支持 ipad
class ParsedLinkViewController: UIViewController {

   init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloatBase
        setupBarBackButton()
    }

    func addContentView(_ content: UIView, title: String) {
        self.title = title
        self.view.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupBarBackButton() {
        let backItem = LKBarButtonItem(
            image: UDIcon.getIconByKeyNoLimitSize(.closeOutlined).renderColor(with: .n1).scaleNaviSize().withRenderingMode(.alwaysOriginal)
        )
        backItem.button.addTarget(self, action: #selector(onCancelClicked), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = backItem
    }

    @objc
    private func onCancelClicked() {
        self.parent?.dismiss(animated: true)
    }

}
