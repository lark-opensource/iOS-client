//
//  FeedFilterSelectViewController.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/7/5.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import RustPB
import UniverseDesignToast
import FigmaKit
import EENavigator
import LarkMessengerInterface
import UIKit

final class FeedFilterSelectViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private let tableView: UITableView = {
        let tableView = FeedFilterSortTableView(frame: .zero)
        tableView.lu.register(cellSelf: FeedFilterSelectCell.self)
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.separatorStyle = .none
        return tableView
    }()

    private let dataSource: [FilterItemModel]

    var tapHandler: ((_ type: Feed_V1_FeedFilter.TypeEnum) -> Void)?

    init(dataSource: [FilterItemModel]) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        reloadData()
    }

    override func closeBtnTapped() {
        super.closeBtnTapped()
    }

    private func setupViews() {
        self.title = BundleI18n.LarkFeed.Lark_IM_FeedFilter_SelectFrequentlyUsedFilter_Title
        addCancelItem()

        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
    }

    private func reloadData() {
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < dataSource.count else {
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }

        let item = dataSource[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: FeedFilterSelectCell.lu.reuseIdentifier) as? FeedFilterSelectCell {
            cell.item = item
            return cell
        }

        return UITableViewCell(style: .default, reuseIdentifier: "cell")
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? FeedFilterSelectCell,
              indexPath.row < dataSource.count else { return }
        cell.setIconHidden(false)
        let item = dataSource[indexPath.row]
        self.tapHandler?(item.type)
        self.navigationController?.dismiss(animated: true)
    }
}
