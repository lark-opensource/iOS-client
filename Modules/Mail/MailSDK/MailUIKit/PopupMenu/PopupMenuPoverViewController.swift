//
//  PopupMenuPoverViewController.swift
//  MailSDK
//
//  Created by tanghaojin on 2020/6/5.
//

import UIKit
import SnapKit
import FigmaKit


class PopupMenuPoverViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    private var items: [PopupMenuActionItem] = []
    private let container: UIView = UIView()
    private let itemHeight: Int = 50

    var hideIconImage: Bool = false
    var dismissCallback: (() -> Void)?

    // MARK: life Circle
    init(items: [PopupMenuActionItem]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
        self.popoverPresentationController?.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // self.view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        self.view.alpha = 0

        // 容器
        container.layer.cornerRadius = 6
        container.layer.masksToBounds = true
        container.layer.borderColor = UIColor.ud.bgFloat.cgColor
        container.layer.borderWidth = 1
        container.backgroundColor = UIColor.ud.bgBody
        container.frame = self.view.bounds
        self.view.addSubview(container)
        container.snp.makeConstraints({ make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(self.items.count * itemHeight)
            make.width.greaterThanOrEqualTo(137)
        })

        self.setupActionsViews()
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        dismissCallback?()
    }
    
    func resetSourceRect(offsetY: CGFloat) {
        if let originRect = self.popoverPresentationController?.sourceRect {
            let newRect = CGRect(x: originRect.minX,
                                 y: offsetY,
                                 width: originRect.width,
                                 height: originRect.height)
            self.popoverPresentationController?.sourceRect = newRect
            self.popoverPresentationController?.containerView?.setNeedsLayout()
            self.popoverPresentationController?.containerView?.layoutIfNeeded()
        }
    }

    func setupActionsViews() {
        self.items.enumerated().forEach { (index, actionItem) in
            let floatView = PopupMenuItemView(frame: .zero, hideIconImage: self.hideIconImage)
            self.container.addSubview(floatView)
            floatView.setContent(icon: actionItem.icon, title: actionItem.title, accessibilityIdentifier: MailAccessibilityIdentifierKey.PopupCellKey + "\(index)", titleColor: actionItem.titleColor)
            floatView.snp.makeConstraints({ (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(itemHeight)
                make.top.equalToSuperview().offset(itemHeight * index)
            })
            floatView.selectedBlock = { [weak self] in
                self?.didClickActionItem(actionItem)
            }
            floatView.isEnabled = actionItem.isEnabled
            floatView.placeHolderTitle = actionItem.placeHolderTitle
        }
    }

    private func didClickActionItem(_ actionItem: PopupMenuActionItem) {
        self.dismiss(animated: false) {
            actionItem.actionCallBack(self, actionItem)
        }
    }

    override func viewDidLayoutSubviews() {
           super.viewDidLayoutSubviews()
           preferredContentSize = container.bounds.size
    }

    // MARK: config
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        dismissCallback?()
    }
}
