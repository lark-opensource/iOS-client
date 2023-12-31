//
//  ChatLinkedPagesDetailViewController.swift
//  LarkChatSetting
//
//  Created by zhaojiachen on 2023/10/18.
//

import Foundation
import RxSwift
import RxCocoa
import FigmaKit
import LarkUIKit

final class ChatLinkedPagesDetailViewController: BaseSettingController, UITableViewDataSource, UITableViewDelegate {

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private lazy var tableView: UITableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.lu.register(cellSelf: ChatInfoLinkedPagesDetailCell.self)
        tableView.lu.register(cellSelf: ChatInfoLinkedPagesFooterCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    private let viewModel: ChatLinkedPagesDetailViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: ChatLinkedPagesDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkChatSetting.Lark_GroupLinkPage_LinkedPages_Title
        self.view.addSubview(tableView)
        self.view.backgroundColor = UIColor.ud.bgFloatBase
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.viewModel.setup(targetVC: self)
        self.viewModel.reloadDriver
            .drive(onNext: { [weak self] in
                self?.tableView.reloadData()
            }).disposed(by: disposeBag)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.cellItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellItem = self.viewModel.cellItems[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: cellItem.cellIdentifier, for: indexPath) as? CommonCellProtocol {
            cell.item = cellItem
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
}
