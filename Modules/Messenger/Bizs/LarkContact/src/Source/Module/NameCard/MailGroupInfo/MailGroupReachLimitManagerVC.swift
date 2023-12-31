//
//  MailGroupReachLimitManagerVC.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/11/23.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkCore
import EENavigator
import LarkModel
import LKCommonsLogging
import LarkMessengerInterface
import LarkActionSheet
import LarkFeatureGating
import RxRelay
import UniverseDesignToast
import UniverseDesignActionPanel
import RustPB
import UniverseDesignIcon

final class MailGroupReachLimitManagerVC: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = 68
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = 0
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.lu.register(cellSelf: MailGroupMemberManagedCell.self)
        tableView.register(MailGroupMemberTableHeader.self,
                           forHeaderFooterViewReuseIdentifier: String(describing: MailGroupMemberTableHeader.self))
        return tableView
    }()

    var datas: [GroupInfoMemberItem]

    init(datas: [GroupInfoMemberItem]) {
        self.datas = datas
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = BundleI18n.LarkContact.Mail_MailingList_MailingListAdmin

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.top.equalToSuperview()
        }
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = MailGroupMemberTableHeader()
        header.headerText.text = BundleI18n.LarkContact.Mail_MailingList_MailingListLimitFailed
        return header
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.row < datas.count {
            let item = datas[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MailGroupMemberManagedCell.lu.reuseIdentifier),
                                                 for: indexPath)

            if var itemCell = cell as? MailGroupMemberManagedCellProtocol {
                itemCell.set(item)
                // 重置cell状态
                itemCell.setCellSelect(canSelect: true, isSelected: false, isCheckboxHidden: true)
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.lu.reuseIdentifier, for: indexPath)
        }
        return cell
    }
}
