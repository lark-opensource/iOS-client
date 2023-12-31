//
//  FoldMessagesDetailInfoViewController.swift
//  LarkChat
//
//  Created by liluobin on 2022/9/19.
//

import UIKit
import Foundation
import LarkUIKit
import LarkMessageCore
import LarkMessengerInterface
import EENavigator

protocol FoldMessagesTableViewDelegate: AnyObject {
    func loadMore(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
    func refresh(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
}
final class FoldMessagesTableView: CommonTable {
    init() {
        super.init(frame: .zero, style: .plain)
        self.enableTopPreload = false
        self.enableBottomPreload = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    weak var tableLoadDelegate: FoldMessagesTableViewDelegate?

    override func loadMoreBottomContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        tableLoadDelegate?.loadMore(finish: finish)
    }

    override func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        tableLoadDelegate?.refresh(finish: finish)
    }
}
final class FoldMessagesDetailInfoViewController: BaseUIViewController,
                                            UITableViewDelegate,
                                            UITableViewDataSource,
                                            FoldMessagesTableViewDelegate {

    override var navigationBarStyle: LarkUIKit.NavigationBarStyle {
        return .custom(UIColor.ud.bgBody)
    }

    lazy var tableView: FoldMessagesTableView = {
        let table = FoldMessagesTableView()
        table.delegate = self
        table.dataSource = self
        table.tableLoadDelegate = self
        table.hasHeader = true
        table.separatorStyle = .none
        table.register(FoldMessageDetailTableViewCell.self, forCellReuseIdentifier: "FoldMessageDetailTableViewCell")
        return table
    }()

    let viewModel: FoldMessagesDetailInfoViewModel

    init(viewModel: FoldMessagesDetailInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkChat.Lark_IM_StackMessage_Details_Title
        self.view.backgroundColor = UIColor.ud.bgBody
        self.tableView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        viewModel.loadFristScreenreData { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("\(error)")
            } else {
                self.refreshData()
            }
        }
    }

    private func refreshData() {
        self.tableView.reloadData()
        self.tableView.hasFooter = self.viewModel.hasMore
        self.tableView.hasHeader = true
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "FoldMessageDetailTableViewCell") as? FoldMessageDetailTableViewCell {
            cell.viewModel = viewModel.cellViewModels[indexPath.row]
            cell.tapAvatarBlock = { [weak self] (userId)in
                self?.jumpToProfileVC(userId)
            }
            return cell
        }
        assertionFailure("error dequeueReusableCell")
        return UITableViewCell()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.cellViewModels.count
    }

    /// 上拉和下拉加载更多
    func loadMore(finish: @escaping (LarkMessageCore.ScrollViewLoadMoreResult) -> Void) {
        self.viewModel.loadData { [weak self] error in
            if error == nil {
                finish(.success(valid: true))
                self?.refreshData()
            } else {
                finish(.error)
            }
        }
    }

    func refresh(finish: @escaping (LarkMessageCore.ScrollViewLoadMoreResult) -> Void) {
        self.viewModel.refreshData { [weak self] error in
            if error == nil {
                finish(.success(valid: true))
                self?.refreshData()
            } else {
                finish(.error)
            }
        }
    }

    private func jumpToProfileVC(_ userId: String) {
        let body = PersonCardBody(chatterId: userId,
                                  source: .chat)
        viewModel.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: self,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }
}
