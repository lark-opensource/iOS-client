//
//  TranslateEffectController.swift
//  LarkChat
//
//  Created by 李勇 on 2019/5/31.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift

/// 翻译效果界面
final class TranslateEffectController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    private let disposeBag = DisposeBag()
    private let viewModel: TranslateEffectViewModel
    private lazy var tableView = self.createTableView()

    init(viewModel: TranslateEffectViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkChat.Lark_Chat_TranslationComparison
        self.view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        /// header视图
        let headerView = UIView()
        do {
            headerView.backgroundColor = UIColor.ud.N50
            /// header视图添加内容
            do {
                /// label
                let label = UILabel()
                label.textColor = UIColor.ud.N500
                label.font = UIFont.systemFont(ofSize: 14)
                label.numberOfLines = 0
                label.text = BundleI18n.LarkChat.Lark_Chat_TranslationComparisonDescription
                headerView.addSubview(label)
                label.snp.makeConstraints { (make) in
                    make.left.equalTo(16)
                    make.right.equalTo(-16)
                    make.top.equalTo(12)
                    make.bottom.equalTo(-4)
                }
            }
            self.view.addSubview(headerView)
            headerView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            }
        }
        /// 添加表格视图
        do {
            self.view.addSubview(self.tableView)
            self.tableView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(headerView.snp.bottom)
            }
        }
        /// 监听信号
        self.viewModel.refreshDriver.drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }

    /// 创建表格视图
    private func createTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        tableView.lu.register(cellSelf: TextContentEffectCell.self)
        tableView.lu.register(cellSelf: PostContentEffectCell.self)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }
    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tableViewCell = UITableViewCell()
        guard indexPath.row < self.viewModel.dataSource.count else {
            return tableViewCell
        }

        let currData = self.viewModel.dataSource[indexPath.row]
        let translateInfo = currData.0
        switch translateInfo.type {
        /// 普通文本消息
        case .text:
            if let cell = tableView.dequeueReusableCell(withIdentifier: TextContentEffectCell.lu.reuseIdentifier, for: indexPath) as? TextContentEffectCell {
                cell.setTranslateInfo(userResolver: viewModel.userResolver, translateInfo: translateInfo, parseRichTextResult: currData.1)
                tableViewCell = cell
            }
        /// 富文本消息
        case .post:
            if let cell = tableView.dequeueReusableCell(withIdentifier: PostContentEffectCell.lu.reuseIdentifier, for: indexPath) as? PostContentEffectCell {
                cell.setTranslateInfo(userResolver: self.viewModel.userResolver, translateInfo: translateInfo, parseRichTextResult: currData.1)
                tableViewCell = cell
            }
        @unknown default:
            break
        }

        return tableViewCell
    }
}
