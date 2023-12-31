//
//  DocsPermissionView.swift
//  Lark
//
//  Created by qihongye on 2018/2/26.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit
import LarkModel
import RustPB

public protocol DocsPermissionVCProps {
    var permissions: [DocPermissionCellProps] { get set }
    func authDocs(_ docs: [String: DocPermissionCellProps])
}

public final class DocsPermissionViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    public struct State {
        var selectedIdxs: [Int] = []
    }

    private var props: DocsPermissionVCProps
    private var selectedCompletion: (([String: RustPB.Im_V1_CreateChatRequest.DocPermissions]) -> Void)?

    lazy private var titleLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textColor = UIColor.ud.N900
        label.numberOfLines = 1
        label.textAlignment = .center
        label.text = BundleI18n.LarkChat.Lark_Legacy_ChatDocAuthNewGroupTitle

        return label
    }()

    lazy private var summarizeLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.N500
        label.numberOfLines = 0
        label.textAlignment = .left
        label.text = BundleI18n.LarkChat.Lark_Legacy_ChatDocAuthNewGroupMessage

        return label
    }()

    lazy private var permissionTableView: UITableView = {
        let tableview = UITableView()
        tableview.backgroundColor = UIColor.ud.N00
        tableview.separatorColor = UIColor.clear
        tableview.keyboardDismissMode = .onDrag
        tableview.rowHeight = 70
        tableview.estimatedRowHeight = 70
        tableview.lu.register(cellSelf: DocsPermissionTableViewCell.self)
        tableview.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))

        tableview.contentInsetAdjustmentBehavior = .never

        return tableview
    }()

    lazy private var ignoreBtn: UIButton = {
        var button = UIButton(type: .custom)
        button.backgroundColor = UIColor.ud.N00
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(UIColor.ud.N900, for: .normal)
        button.setTitle(BundleI18n.LarkChat.Lark_Legacy_Skip, for: .normal)

        return button
    }()

    lazy private var authBtn: UIButton = {
        var button = UIButton(type: .custom)
        button.backgroundColor = UIColor.ud.N00
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(UIColor.ud.N900, for: .normal)
        button.setTitle(BundleI18n.LarkChat.Lark_Legacy_ChatDocAuthCountBtn(self.state.selectedIdxs.count), for: .normal)
        return button
    }()

    lazy private var buttonView: UIView = {
        var view = UIView()
        return view
    }()

    lazy private var headerLine: UIView = {
        var line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()

    lazy private var buttonSplitLine: UIView = {
        var line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()

    lazy private var shadowView: UIImageView = {
        var view = UIImageView()
        view.image = Resources.tabbar_shadow
        return view
    }()

    public var state: State = State() {
        didSet {
            self.authBtn.setTitle(BundleI18n.LarkChat.Lark_Legacy_ChatDocAuthCountBtn(self.state.selectedIdxs.count), for: .normal)
        }
    }

    public init(props: DocsPermissionVCProps) {

        var newProps = props
        newProps.permissions = newProps.permissions.map { (permission) -> DocPermissionCellProps in
            var newPermission = permission
            newPermission.selectedPermisionStateIndex = 0
            newPermission.selected = true
            return newPermission
        }

        self.props = newProps
        super.init(nibName: nil, bundle: nil)
        self.updateState()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        ignoreBtn.addTarget(self, action: #selector(ignoreAuth), for: .touchUpInside)
        authBtn.addTarget(self, action: #selector(auth), for: .touchUpInside)

        self.view.addSubview(titleLabel)
        self.view.addSubview(summarizeLabel)
        self.view.addSubview(headerLine)
        self.view.addSubview(permissionTableView)
        self.view.addSubview(buttonView)
        self.view.addSubview(shadowView)
        self.buttonView.addSubview(ignoreBtn)
        self.buttonView.addSubview(authBtn)
        self.buttonView.addSubview(buttonSplitLine)

        self.permissionTableView.delegate = self
        self.permissionTableView.dataSource = self

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.right.equalToSuperview()
        }
        summarizeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
        }
        headerLine.snp.makeConstraints { (make) in
            make.top.equalTo(summarizeLabel.snp.bottom).offset(10)
            make.height.equalTo(1.0 / UIScreen.main.scale)
            make.left.right.equalToSuperview()
        }
        buttonView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(49)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        shadowView.snp.makeConstraints { (make) in
            make.bottom.equalTo(buttonView.snp.top)
            make.height.equalTo(10)
            make.left.right.equalToSuperview()
        }
        buttonSplitLine.snp.makeConstraints { (make) in
            make.width.equalTo(1)
            make.height.equalTo(30)
            make.center.equalToSuperview()
        }
        ignoreBtn.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.right.equalTo(buttonSplitLine)
        }
        authBtn.snp.makeConstraints { (make) in
            make.top.right.bottom.equalToSuperview()
            make.left.equalTo(buttonSplitLine)
        }
        permissionTableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerLine.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(buttonView.snp.top)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.permissionTableView.reloadData()
    }

    @objc
    func ignoreAuth() {
        let messageIdTopermissions = [String: RustPB.Im_V1_CreateChatRequest.DocPermissions]()
        self.selectedCompletion?(messageIdTopermissions)
        self.hide()
    }

    @objc
    func auth() {
        var messageIdTopermissions = [String: RustPB.Im_V1_CreateChatRequest.DocPermissions]()
        self.props.permissions.filter({ $0.selected == true }).forEach { (permission) in
            permission.messageIds.forEach({ (messageId) in
                if messageIdTopermissions[messageId] == nil {
                    var perms = [String: CreateChatRequest.DocPermission]()
                    let docPermission: CreateChatRequest.DocPermission = (permission.selectedPermisionStateIndex == 1) ? .edit : .read
                    perms[permission.docUrl] = docPermission
                    var docPermissions: RustPB.Im_V1_CreateChatRequest.DocPermissions = RustPB.Im_V1_CreateChatRequest.DocPermissions()
                    docPermissions.perms = perms
                    messageIdTopermissions[messageId] = docPermissions
                } else {
                    if var perms = messageIdTopermissions[messageId]?.perms {
                        perms[permission.docUrl] = (permission.selectedPermisionStateIndex == 1) ? .edit : .read
                        messageIdTopermissions[messageId]?.perms = perms
                    }
                }
            })
        }
        self.selectedCompletion?(messageIdTopermissions)
        self.hide()
    }

    public func show(rootVC: UIViewController,
              isHeightHalf: Bool = false,
              showCompletion: (() -> Void)? = nil,
              selectedCompletion: (([String: RustPB.Im_V1_CreateChatRequest.DocPermissions]) -> Void)? = nil) {
        self.selectedCompletion = selectedCompletion
        let containerVC = SwipeContainerViewController(subViewController: self)
        containerVC.showMiddleState = isHeightHalf
        rootVC.present(containerVC, animated: true, completion: showCompletion)
    }

    public func hide(completion: (() -> Void)? = nil) {
        self.swipContainerVC?.dismiss(animated: true, completion: completion)
    }

    func updateState() {
        var arr: [Int] = []
        self.props.permissions.enumerated().forEach { (index, permission) in
            if permission.selected {
                arr.append(index)
            }
        }
        self.state.selectedIdxs = arr
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.props.permissions.count
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        let selected = self.props.permissions[indexPath.row].selected
        self.props.permissions[indexPath.row].selected = !selected
        tableView.reloadRows(at: [indexPath], with: .none)
        self.updateState()
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = String(describing: DocsPermissionTableViewCell.self)
        var cell: DocsPermissionTableViewCell
        if let reuseCell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as? DocsPermissionTableViewCell {
            cell = reuseCell
        } else {
            cell = DocsPermissionTableViewCell(style: .default, reuseIdentifier: id)
        }

        cell.props = self.props.permissions[indexPath.row]

        return cell
    }
}
