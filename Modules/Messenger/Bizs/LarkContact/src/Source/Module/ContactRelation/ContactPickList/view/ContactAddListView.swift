//
//  ContactAddListView.swift
//  LarkContact
//
//  Created by zhenning on 2020/07/10.
//
import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LKCommonsLogging
import SkeletonView

protocol ContactAddListViewDelegate: AnyObject {
    // 点击确定
    func onPickConfirm(selectedContacts: [ContactItem])
    // 点击申请添加联系人
    func onContactApplyTapped(selectContact: ContactItem)

}

final class ContactAddListView: UIView {
    static let logger: Log = Logger.log(ContactAddListView.self, category: "LarkContact.ContactAddListView")

    let viewModel: ContactAddListViewModel
    weak var delegate: ContactAddListViewDelegate?
    private let disposeBag: DisposeBag = DisposeBag()

    private lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.backgroundColor = UIColor.ud.N100
        return contentView
    }()
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = Layout.contactCellHeight
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.ud.N300
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0),
                                                         size: CGSize(width: 0.1, height: CGFloat.leastNormalMagnitude)))
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0),
                                                         size: CGSize(width: 0.1, height: CGFloat.leastNormalMagnitude)))
        tableView.register(ContactAddListCell.self, forCellReuseIdentifier: ContactAddListCell.lu.reuseIdentifier)
        return tableView
    }()
    // loading view
    private lazy var loadingView: ContactPickSkeletonTableView = {
        let view = ContactPickSkeletonTableView()
        return view
    }()

    init(viewModel: ContactAddListViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
    }

    private func setupUI() {
        self.backgroundColor = UIColor.ud.N100

        /// content
        self.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.contentView.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func reloadContactList() {
        self.tableView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
}

extension ContactAddListView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let contactCell = tableView
            .dequeueReusableCell(withIdentifier: ContactAddListCell.lu.reuseIdentifier,
                                 for: indexPath) as? ContactAddListCell, indexPath.row < viewModel.contacts.count {
            let contact: ContactItem = viewModel.contacts[indexPath.row]
            contactCell.contact = contact
            contactCell.addContactHandler = { [weak self] contact in
                self?.delegate?.onContactApplyTapped(selectContact: contact)
            }
            return contactCell
        }
        return UITableViewCell()
    }
}

extension ContactAddListView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Layout.contactCellHeight
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ContactAddListView {
    enum Layout {
        static var contactCellHeight: CGFloat = 68
    }
}
