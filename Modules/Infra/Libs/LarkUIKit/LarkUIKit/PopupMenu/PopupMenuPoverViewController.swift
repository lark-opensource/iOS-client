//
//  PopupMenuPoverViewController.swift
//  MailSDK
//
//  Created by tanghaojin on 2020/6/5.
//

import Foundation
import UIKit
import SnapKit

public final class PopupMenuPoverViewController: UIViewController {
    private var items: [PopupMenuActionItem] = []
    private let container: UIView = UIView()
    private let itemHeight: Int = 50

    // MARK: life Circle
    public init(items: [PopupMenuActionItem]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.2)

        self.view.alpha = 0

        // 容器
        container.layer.cornerRadius = 6
        container.layer.masksToBounds = true
        container.backgroundColor = UIColor.ud.N00
        container.frame = self.view.bounds
        self.view.addSubview(container)
        container.snp.makeConstraints({ make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(self.items.count * itemHeight).constraint
            make.width.greaterThanOrEqualTo(137).constraint
        })

        self.setupActionsViews()
    }

    func setupActionsViews() {
        self.items.enumerated().forEach { (index, actionItem) in
            let floatView = PopupMenuItemView(frame: .zero)
            self.container.addSubview(floatView)
            floatView.setContent(icon: actionItem.icon, title: actionItem.title, accessibilityIdentifier: "PopupCellKey\(index)")
            floatView.snp.makeConstraints({ (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(itemHeight)
                make.top.equalToSuperview().offset(itemHeight * index)
            })
            floatView.selectedBlock = { [weak self] in
                self?.didClickActionItem(actionItem)
            }
            if index != items.count - 1 {
                floatView.addItemBorder()
            }
            floatView.isEnabled = actionItem.isEnabled
        }
    }

    private func didClickActionItem(_ actionItem: PopupMenuActionItem) {
        self.dismiss(animated: false) {
            actionItem.actionCallBack(self, actionItem)
        }
    }

    public override func viewDidLayoutSubviews() {
           super.viewDidLayoutSubviews()
           preferredContentSize = container.bounds.size
       }

    // MARK: confpublic ig
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

}
