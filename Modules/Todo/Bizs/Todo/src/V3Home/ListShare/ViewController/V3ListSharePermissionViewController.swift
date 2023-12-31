//
//  V3ListSharePermissionViewController.swift
//  Todo
//
//  Created by GCW on 2022/12/8.
//

import UIKit
import LarkUIKit
import Foundation
import EENavigator
import LarkBizAvatar

enum AlertActionStyle: Int {
    case option
    case destructive
}

protocol AlertActionDelegate: AnyObject {
    func alertDismiss()
    func getAlertAction() -> [AlertAction]
    func getItemHeightFor(_ action: AlertAction) -> CGFloat
}

public final class AlertAction {
    var title: String?
    var style: (selectStyle: AlertActionStyle, selectPermission: Rust.MemberRole)
    var isSelected: Bool?
    var canBeSelected: Bool?
    var needSeparateLine: Bool = false
    var handler: (() -> Void)?

    init(title: String,
         style: (selectStyle: AlertActionStyle, selectPermission: Rust.MemberRole),
         isSelected: Bool,
         canBeselected: Bool,
         needSeparateLine: Bool = false,
         handler: (() -> Void)?) {
        self.title = title
        self.style = style
        self.isSelected = isSelected
        self.canBeSelected = canBeselected
        self.needSeparateLine = needSeparateLine
        self.handler = handler
    }
}

final class V3ListSharePermissionViewController: BaseViewController {

    private var itemHeight = CGFloat(50)
    private var actions: [AlertAction] = []

    // 判断是否转过屏标志
    private var didAppear: Bool = false

    lazy internal var alertView: AlertView = {
        let alertView = AlertView(frame: .zero, delegate: self)
        alertView.layer.cornerRadius = 12
        alertView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return alertView
    }()

    public init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupView()
        alertView.setUpHeaderView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didAppear = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if didAppear {
            dismiss(animated: true)
        }
    }

    func heightForAlertView() -> CGFloat {
        var alertViewHeight: CGFloat = 67
        self.actions.forEach { (action) in
            alertViewHeight += getItemHeightFor(action)
        }
        return alertViewHeight
    }

    private func setupView() {
        view.backgroundColor = UIColor.clear
        view.addSubview(alertView)
        alertView.setAlertView(view.frame.width)
        alertView.backgroundColor = UIColor.ud.bgBody
        if Display.pad {
            alertView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
        } else {
            alertView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(heightForAlertView())
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
        }
    }

    func setMember(avatar: TaskMemberCellData.IconType, name: String) {
        alertView.setMember(avatar: avatar, name: name)
    }
}

extension  V3ListSharePermissionViewController {
    public func add(_ item: AlertAction) {
        actions.append(item)
    }
    public func removeAllAction() {
        actions.removeAll()
    }
}

extension  V3ListSharePermissionViewController: AlertActionDelegate {
    public func alertDismiss() {
        dismiss(animated: true)
    }
    public func getAlertAction() -> [AlertAction] {
        return self.actions
    }
    public func getItemHeightFor(_ action: AlertAction) -> CGFloat {
        return self.itemHeight
    }
}
