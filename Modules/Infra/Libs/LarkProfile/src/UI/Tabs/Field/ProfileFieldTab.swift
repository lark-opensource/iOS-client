//
//  ProfileFieldTab.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/8/3.
//

import UIKit
import Foundation
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface
import LarkUIKit

public class ProfileFieldTab: UIViewController, ProfileTab, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver

    public static var tabId: String = "ProfileFieldTab"

    public var itemId: String = "ProfileFieldTab"

    public var contentViewDidScroll: ((UIScrollView) -> Void)?

    public weak var profileVC: UIViewController?

    private var tabTitle: String

    var fields: [ProfileFieldItem] = []

    private var context: ProfileFieldContext?

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }()

    public init(resolver: UserResolver, title: String) {
        self.userResolver = resolver
        self.tabTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundColor = Display.pad ? UIColor.ud.bgFloatBase : UIColor.ud.bgBase
        self.view.backgroundColor = backgroundColor

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.right.equalToSuperview().inset(Cons.hMargin).priority(.high)
        }
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.dataSource = self
        tableView.delegate = self

        for (id, cell) in ProfileFieldFactory.getFieldCellTypes() {
            tableView.register(cell, forCellReuseIdentifier: id)
        }

        context = ProfileFieldContext(tableView: self.tableView,
                                      fromVC: profileVC)
    }

    private lazy var headerView: UIView = {
        let topMargin: CGFloat = Cons.topMargin
        let cornerRadius: CGFloat = Cons.cornerRadius
        let view = UIView()
        let content = UIView()
        view.addSubview(content)
        view.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: topMargin + cornerRadius)
        view.layer.masksToBounds = true
        content.frame = CGRect(x: 0, y: topMargin, width: view.frame.width, height: cornerRadius * 2)
        content.backgroundColor = UIColor.ud.bgBody
        content.layer.cornerRadius = cornerRadius
        return view
    }()

    private lazy var footerView: UIView = {
        let bottomMargin: CGFloat = Cons.bottomMargin
        let cornerRadius: CGFloat = Cons.cornerRadius
        let view = UIView()
        let content = UIView()
        view.addSubview(content)
        view.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: bottomMargin + cornerRadius)
        view.layer.masksToBounds = true
        content.frame = CGRect(x: 0, y: -cornerRadius, width: view.frame.width, height: cornerRadius * 2)
        content.backgroundColor = UIColor.ud.bgBody
        content.layer.cornerRadius = cornerRadius
        return view
    }()

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
    }

    public func updateField(fields: [ProfileFieldItem]) {
        self.fields = fields
        self.tableView.reloadData()
    }
}

extension ProfileFieldTab: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fields.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.fields.count,
              let context = context,
              let cell = ProfileFieldFactory.createWithItem(self.fields[indexPath.row],
                                                            context: context)
        else { return UITableViewCell() }
        
        if let phoneCell = cell as? ProfileFieldPhoneCell  {
            phoneCell.chatterAPI = try? self.userResolver.resolve(assert: ChatterAPI.self)
            phoneCell.callRequestService = try? self.userResolver.resolve(assert: CallRequestService.self)
            phoneCell.saveToContactsFG = userResolver.fg.staticFeatureGatingValue(with: "lark.core.save_to_contacts")
            phoneCell.userResolver = userResolver
        }
        cell.navigator = self.userResolver.navigator
        // 设置第一个和最后一个 Cell 的圆角
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        if fields.count == 1 {
            cell.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        } else if indexPath.row == 0 {
            cell.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner
            ]
        } else if indexPath.row == fields.count - 1 {
            cell.layer.maskedCorners = [
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
        } else {
            cell.layer.maskedCorners = []
        }
        // 移除最后一个 Cell 的分割线
        if indexPath.row == self.fields.count - 1 {
            cell.removeDividingLine()
        } else {
            cell.addDividingLine()
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath) as? ProfileFieldCell
        cell?.didTap()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.contentViewDidScroll?(self.tableView)
    }
}

extension ProfileFieldTab {

    public func listView() -> UIView {
        return view
    }

    public var segmentTitle: String {
        return tabTitle
    }

    public var scrollableView: UIScrollView {
        return self.tableView
    }
}

extension ProfileFieldTab {

    enum Cons {
        static var hMargin: CGFloat = 16
        static var topMargin: CGFloat = 12
        static var bottomMargin: CGFloat = 68
        static var cornerRadius: CGFloat = 0
    }
}
