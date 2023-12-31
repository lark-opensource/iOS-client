//
//  PostCategoriesListViewContrller.swift
//  Moment
//
//  Created by liluobin on 2021/4/22.
//

import UIKit
import Foundation
import LarkUIKit
import LarkMessageCore
import LarkFeatureGating
import RxSwift
import RxCocoa
import LarkTraitCollection

final class PostCategoriesListViewContrller: MomentsBaseRefreshViewController, PostNavigationBarDelegate {
    private let disposeBag = DisposeBag()
    var categoryItems: [PostCategoryDataItem] = []
    var categoryListRefreshNotice: Driver<[RawData.PostCategory]>
    let selectCallBack: ((RawData.PostCategory?) -> Void)?
    lazy var navBar = MomentsPostNavigationBar(backImage: Resources.momentsNavBarClose.ud.withTintColor(UIColor.ud.iconN1), delegate: self)
    init(categoryItems: [PostCategoryDataItem],
         categoryListRefreshNotice: Driver<[RawData.PostCategory]>,
         selectCallBack: ((RawData.PostCategory?) -> Void)?) {
        self.categoryItems = categoryItems
        self.categoryListRefreshNotice = categoryListRefreshNotice
        self.selectCallBack = selectCallBack
        super.init(nibName: nil, bundle: nil)
        self.categoryListRefreshNotice.drive(onNext: {[weak self] data in
            guard let self = self else { return }
            var selectedItem: String?
            for oldItem in self.categoryItems where oldItem.userSelected {
                selectedItem = oldItem.data.category.categoryID
                break
            }
            self.categoryItems = data.map({ item in
                PostCategoryDataItem(item, userSelected: item.category.categoryID == selectedItem)
            })
            self.reloadData()

        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.Moment.Lark_Community_PostInTitle
        self.reloadData()
        tableView.hasHeader = false
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 80))
        setupSubview()
        self.view.backgroundColor = .ud.bgBody
        self.navBar.leftBtn.isHidden = presentingViewController?.view.window?.traitCollection.horizontalSizeClass == .regular
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Display.pad {
            self.navBar.leftBtn.isHidden = view.window?.traitCollection.horizontalSizeClass == .regular
            RootTraitCollection.observer
                .observeRootTraitCollectionDidChange(for: self.view)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] traitChange in
                    self?.navBar.leftBtn.isHidden = traitChange.new.horizontalSizeClass == .regular
                }).disposed(by: self.disposeBag)
        }
    }

    func setupSubview() {
        self.view.addSubview(navBar)
        navBar.backgroundColor = .ud.bgBody
        navBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(view.safeAreaInsets.top)
            make.height.equalTo(56)
        }
        tableView.snp.remakeConstraints { make in
            make.top.equalTo(navBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    override func viewSafeAreaInsetsDidChange() {
        if navBar.superview == nil {
            return
        }
        navBar.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(view.safeAreaInsets.top)
        }
    }

    func MomentsNavigationViewOnRightButtonTapped(_ view: MomentsPostNavigationBar) {
        //do nothing
    }
    func MomentsNavigationViewOnClose(_ view: MomentsPostNavigationBar) {
        dismiss(animated: true, completion: nil)
    }

    func titleViewForNavigation() -> UIView? {
        let label = UILabel()
        label.text = BundleI18n.Moment.Lark_Community_PostInTitle
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categoryItems.count
    }
    override func registerCellForTableView(_ tableView: UITableView) {
        tableView.register(PostCategoriesListCell.self, forCellReuseIdentifier: PostCategoriesListCell.reuseId)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCategoriesListCell.reuseId, for: indexPath)
        if let categoryCell = cell as? PostCategoriesListCell,
           indexPath.row < self.categoryItems.count {
            let item = self.categoryItems[indexPath.row]
            categoryCell.item = item
        }
        return cell
    }

    override func showEmptyView() -> Bool {
        return self.categoryItems.isEmpty
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }
//     swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let categoryCell = tableView.cellForRow(at: indexPath) as? PostCategoriesListCell,
           indexPath.row < self.categoryItems.count {
            if let row = categoryItems.firstIndex(where: { $0.userSelected }) {
                if !(row == indexPath.row) {
                    categoryItems[row].userSelected = false
                    tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
                }
            }
            categoryItems[indexPath.row].userSelected = true
            categoryCell.item = categoryItems[indexPath.row]
            self.selectCallBack?(categoryCell.item?.data)
        }
        if Display.pad {
            self.dismiss(animated: true, completion: nil)
        } else {
            /// 延时一下 展示一下选中态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    // swiftlint:enable did_select_row_protection
}

final class PostCategoryDataItem {
    let data: RawData.PostCategory
    var userSelected: Bool
    init(_ data: RawData.PostCategory, userSelected: Bool = false) {
        self.data = data
        self.userSelected = userSelected
    }
}
