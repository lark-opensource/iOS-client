//
//  FeedSwipeActionSettingViewController.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/10/31.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkModel
import EENavigator
import FigmaKit
import LarkSwipeCellKit
import LarkContainer

/// 滑动手势设置界面
final class FeedSwipeActionSettingViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver {
        return viewModel.userResolver
    }

    let bag = DisposeBag()
    // MARK: - DATA
    private var viewModel: FeedSwipeActionSettingViewModel

    // MARK: - UI
    lazy var tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.rowHeight = UITableView.automaticDimension
        tableView.lu.register(cellSelf: FeedSwipeActionsPreviewCell.self)
        return tableView
    }()

    // MARK: - LIFE CYCLE
    init(viewModel: FeedSwipeActionSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupViews()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: FeedSwipeActionsPreviewCell.lu.reuseIdentifier) as? FeedSwipeActionsPreviewCell {
            let item = viewModel.item(at: indexPath.section)
            cell.configCell(item)
            cell.didClick = {[weak self] item in
                guard let self = self else { return }
                self.jumpToSwipeActionConfigPage(orientation: item.orientation)
            }
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return UIView() }
        let view = UITableViewHeaderFooterView()
        let detailLabel = UILabel()
        detailLabel.text = BundleI18n.LarkFeed.Lark_ChatSwipeActions_Mobile_Desc
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.ud.textCaption
        detailLabel.numberOfLines = 0
        view.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.equalTo(18)
            make.right.equalTo(-16)
        }
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    // MAKR: - Helper
    private func setupViews() {
        view.backgroundColor = UIColor.ud.bgFloatBase
        title = viewModel.title
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(0)
        }
    }

    private func setupViewModel() {
        viewModel.reloadData.drive(onNext: {[weak self] in
            self?.tableView.reloadData()
        }).disposed(by: bag)
    }

    private func jumpToSwipeActionConfigPage(orientation: SwipeActionsOrientation) {
        let vm = FeedSwipeActionConfigViewModel(settingStore: viewModel.settingStore, orientation: orientation)
        let vc = FeedSwipeActionConfigViewController(viewModel: vm)
        self.userResolver.navigator.push(vc, from: self)
    }
}
