//
//  MailProfileDetailInfoView.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/30.
//

import Foundation
import UIKit
import SnapKit
import FigmaKit
import UniverseDesignEmpty
import LarkContainer

final class MailProfileDetailInfoView: UIView, MailProfileTableViewInnerAble {
    private let userResolver: UserResolver
    init(frame: CGRect, resolver: UserResolver) {
        self.userResolver = resolver
        super.init(frame: frame)
        configUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var targetViewController: UIViewController?

    // MARK: property
    lazy var tableView: UITableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 54
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        self.addSubview(tableView)

        tableView.contentInsetAdjustmentBehavior = .never
        tableView.lu.register(cellSelf: MailProfileNormalCell.self)
        tableView.lu.register(cellSelf: MailProfileLinkCell.self)
        tableView.lu.register(cellSelf: MailProfilePhoneCell.self)
        return tableView
    }()

    private var infoItems: [MailProfileCellItem] = []

    // UI
    func configUI() {
        backgroundColor = UIColor.ud.bgBase
        self.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
                .inset(UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4))
        }
    }

    // MARK: MailProfileTableViewInnerAble
    var scrollableView: UIScrollView {
        return tableView
    }
    var contentViewDidScroll: ((UIScrollView) -> Void)?

    // MARK: data interface
    func setData(data: [MailProfileCellItem]) {
        self.infoItems = data
        tableView.reloadData()
    }
}

extension MailProfileDetailInfoView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoItems.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = infoItems[indexPath.row]
        if var cell = tableView.dequeueReusableCell(withIdentifier: item.type.cellIdentifier) as? MailProfileBaseCell {
            cell.item = item
            cell.targetViewController = targetViewController
            if indexPath.row < infoItems.count - 1 {
                cell.addDividingLine()
            } else {
                cell.removeDividingLine()
            }
            return (cell as? UITableViewCell) ?? .init()
        } else {
            assert(false, "未找到对应的Item or cell")
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath) as? MailProfileBaseCell
        cell?.item?.handleClick(fromVC: targetViewController, resolver: userResolver)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        contentViewDidScroll?(scrollView)
    }
}
