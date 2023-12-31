//
//  MineTranslateLanguageDetailController.swift
//  LarkMine
//
//  Created by zhenning on 2020/02/11.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import FigmaKit

/// 翻译语言列表
final class MineTranslateLanguageDetailController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private let viewModel: MineTranslateLanguageDetailViewModel
    private let disposeBag = DisposeBag()
    private lazy var tableView = self.createTableView()

    init(viewModel: MineTranslateLanguageDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.viewModel.srcLanguageModel.subTitle

        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        self.tableView.contentInsetAdjustmentBehavior = .never

        /// 监听信号
        self.viewModel.refreshDriver.drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }

    private func createTableView() -> UITableView {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 74
        tableView.estimatedSectionHeaderHeight = 42
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.lu.register(cellSelf: MineTranslateRadioCell.self)
        tableView.lu.register(cellSelf: MineTranslateSwitchCell.self)
        return tableView
    }

   func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.viewModel.headerViews[section]()
   }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.viewModel.items[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? MineTranslateBaseCell {
            cell.item = item
            if cell.isMember(of: MineTranslateSwitchCell.self) {
                cell.selectionStyle = .none
            }
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
