//
//  SearchSelectTabView.swift
//  LarkSearch
//
//  Created by wangjingcan on 2023/6/26.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignIcon
import LKCommonsLogging
import LarkUIKit

final class SearchSelectTabView: UIView {
    static let logger = Logger.log(SearchSelectTabView.self, category: "SearchSelectTabView")
    private static let SearchHeaderHeight = 48.0
    private static let SearchItemHeight = 48.0
    private static let SearchTopMargin = 16.0
    private static let SearchFooterHeight = 48.0
    private static let SearchFooterTopMargin = 16.0
    private static let SearchFooterBottomMargin = Display.pad ? 20.0 : 8.0
    private var items = [SearchTab]()
    private var filterCount = 0
    private let itemSelectSubject = PublishSubject<SearchTab?>()
    private var selectedTab: SearchTab = .main
    private var showAdvancedSearch: Bool = true
    private let disposeBag = DisposeBag()

    let closeTapEvent = UITapGestureRecognizer()
    let editTapEvent = UITapGestureRecognizer()
    let advancedSearchTapEvent = UITapGestureRecognizer()
    var itemSelect: Driver<SearchTab?> {
        return itemSelectSubject.asDriver(onErrorJustReturn: nil)
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Self.SearchItemHeight
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = nil
        tableView.tableFooterView = UIView()
        tableView.register(TabItemCell.self, forCellReuseIdentifier: TabItemCell.identifier)
        return tableView
    }()

    lazy var editButton: UIButton = {
        let editButton = UIButton()
        editButton.setTitle(BundleI18n.LarkSearch.Lark_NewSearch_SecondarySearch_AdvancedSearchFilters_EditButton, for: .normal)
        editButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        editButton.sizeToFit()
        return editButton
    }()

    lazy var advancedSearchButton: UIButton = {
        let advancedSearchButton = UIButton()
        let countStr = self.filterCount > 0 ? " \(self.filterCount)" : ""
        advancedSearchButton.setTitle(BundleI18n.LarkSearch.Lark_NewSearch_SecondarySearch_AdvancedSearchFilters_Title + countStr, for: .normal)
        advancedSearchButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        advancedSearchButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        advancedSearchButton.titleLabel?.textAlignment = .center
        advancedSearchButton.layer.cornerRadius = 10
        advancedSearchButton.clipsToBounds = true
        advancedSearchButton.backgroundColor = UIColor.ud.bgFloat
        return advancedSearchButton
    }()

    init(frame: CGRect, dataSource: [SearchTab], filterCount: Int, selectedTab: SearchTab, showAdvancedSearch: Bool) {
        super.init(frame: frame)
        self.selectedTab = selectedTab
        self.showAdvancedSearch = showAdvancedSearch
        self.items += dataSource
        self.filterCount = filterCount
        self.initSubViews()
        Self.logger.info("SearchSelectTabView set tabTypes: \(self.items.map { $0.shortDescription }.joined(separator: ", "))")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has falset been implemented")
    }

    private func initSubViews() {
        clipsToBounds = true
        self.layer.cornerRadius = 12
        self.backgroundColor = UIColor.ud.bgFloatBase
        let headerView = UIView()

        let closeIcon = UIButton()
        closeIcon.setImage(UDIcon.closeSmallOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        closeIcon.tintColor = UIColor.ud.iconN1

        headerView.addSubview(closeIcon)
        closeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.height.width.equalTo(24)
            make.centerY.equalToSuperview()
        }

        closeIcon.addGestureRecognizer(self.closeTapEvent)

        headerView.addSubview(editButton)
        editButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        let titleLable = UILabel()
        titleLable.text = BundleI18n.LarkSearch.Lark_Legacy_Search
        titleLable.textColor = UIColor.ud.textTitle
        titleLable.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        headerView.addSubview(titleLable)
        titleLable.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let divider = UIView()
        headerView.addSubview(divider)
        divider.backgroundColor = UIColor.ud.lineDividerDefault
        divider.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.leading.trailing.bottom.equalToSuperview()
        }

        self.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Self.SearchHeaderHeight)
        }
        self.addSubview(self.tableView)
        let bottomSafeHeight = safeBottomHeight()
        if showAdvancedSearch {
            self.addSubview(self.advancedSearchButton)
            if Display.pad {
                self.tableView.snp.makeConstraints { make in
                    make.top.equalTo(headerView.snp.bottom)
                    make.leading.equalToSuperview()
                    make.trailing.equalToSuperview()
                    make.height.equalTo(100)
                }
                self.advancedSearchButton.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(16)
                    make.trailing.equalToSuperview().offset(-16)
                    make.top.equalTo(self.tableView.snp.bottom).offset(Self.SearchFooterTopMargin)
                    make.bottom.lessThanOrEqualToSuperview().offset(-1 * bottomSafeHeight - Self.SearchFooterBottomMargin)
                    make.height.equalTo(Self.SearchFooterHeight)
                }
            } else {
                self.tableView.snp.makeConstraints { make in
                    make.top.equalTo(headerView.snp.bottom)
                    make.bottom.equalTo(self.advancedSearchButton.snp.top).offset(-1 * Self.SearchFooterTopMargin)
                    make.leading.equalToSuperview()
                    make.trailing.equalToSuperview()
                    make.height.equalTo(100)
                }
                self.advancedSearchButton.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(16)
                    make.trailing.equalToSuperview().offset(-16)
                    make.bottom.equalToSuperview().offset(-1 * bottomSafeHeight - Self.SearchFooterBottomMargin)
                    make.height.equalTo(Self.SearchFooterHeight)
                }
            }
        } else {
            self.tableView.snp.makeConstraints { make in
                make.top.equalTo(headerView.snp.bottom)
                make.bottom.equalToSuperview()
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
                make.height.equalTo(100)
            }
        }

        self.tableView.rx.observe(CGSize.self, "contentSize")
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let maxHeight = self.tableViewMaxHeight()
                if maxHeight > 0 {
                    let height = min(self.tableView.contentSize.height, maxHeight)
                    self.tableView.snp.updateConstraints { make in
                        make.height.equalTo(height)
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    private func tableViewMaxHeight() -> CGFloat {
        guard let superview = superview else { return 0 }
        let topSafeHeight = self.safeTopHeight()
        let bottomSafeHeight = showAdvancedSearch ? self.safeBottomHeight() : 0
        let extraHeight = (Self.SearchHeaderHeight
                           + (showAdvancedSearch ? Self.SearchFooterHeight : 0)
                           + (showAdvancedSearch ? Self.SearchFooterTopMargin : 0)
                           + (showAdvancedSearch ? Self.SearchFooterBottomMargin : 0)
                           + topSafeHeight
                           + bottomSafeHeight)
        return superview.frame.size.height - extraHeight
    }

    private func safeBottomHeight() -> CGFloat {
        if Display.pad {
            return 0
        } else {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0.0
        }
    }

    private func safeTopHeight() -> CGFloat {
        if Display.pad {
            return 0
        } else {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0.0
        }
    }
}

extension SearchSelectTabView: ISearchPopupContentView {
    func updateContainerSize(size: CGSize) {

    }
}

extension SearchSelectTabView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else {
            return
        }
        self.itemSelectSubject.onNext(self.items[safe: indexPath.row])
    }
}

extension SearchSelectTabView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TabItemCell.identifier, for: indexPath)
        if let itemCell = cell as? TabItemCell, let newItem = self.items[safe: indexPath.row] {
            itemCell.update(withItem: newItem, isSelectedTab: newItem == selectedTab)
            itemCell.bgView.layer.cornerRadius = 10
            if indexPath.row == 0 {
                itemCell.bgView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            } else if indexPath.row == self.items.count - 1 {
                itemCell.bgView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                cell.separatorInset = UIEdgeInsets(top: 0, left: self.bounds.size.width, bottom: 0, right: 16)
            } else {
                itemCell.bgView.layer.cornerRadius = 0
                cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            }
            itemCell.bgView.clipsToBounds = true
        }

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Self.SearchTopMargin
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if !self.showAdvancedSearch {
            return Display.pad ? Self.SearchFooterBottomMargin : self.safeBottomHeight()
        } else {
            return 0
        }
    }
}

private final class TabItemCell: UITableViewCell {

    public lazy var bgView: UIView = {
        let bgView = UIView()
        bgView.backgroundColor = UIColor.ud.bgFloat
        return bgView
    }()

    private lazy var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 2
        return imageView
    }()

    private lazy var title: UILabel = {
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        title.textColor = UIColor.ud.textTitle
        return title
    }()

    private lazy var selectedIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.listCheckBoldOutlined, iconColor: UIColor.ud.primaryPri500, size: CGSize(width: 16, height: 16))
        return imageView
    }()

    var item: SearchTab?

    func update(withItem item: SearchTab?, isSelectedTab: Bool) {
        self.item = item
        guard let newItem = self.item else {
            self.icon.image = nil
            self.title.text = nil
            self.selectedIcon.isHidden = true
            return
        }
        self.title.text = newItem.title
        // icon
        if case .open(let openSearch) = newItem, let iconURLStr = openSearch.icon, !iconURLStr.isEmpty, let iconURL = URL(string: iconURLStr) {
            icon.bt.setImage(with: iconURL, completionHandler: { [weak self] imageResult in
                guard let self = self else { return }
                switch imageResult {
                case .success(let data):
                    self.icon.image = data.image
                case .failure:
                    self.iconImageViewSetDefault()
                }
            })
        } else if let image = newItem.icon {
            icon.backgroundColor = nil
            icon.contentMode = .scaleAspectFit
            icon.image = image
        } else {
            iconImageViewSetDefault()
        }
        self.selectedIcon.isHidden = !isSelectedTab
    }

    private func iconImageViewSetDefault() {
        let image = UDIcon.getIconByKey(.appDefaultOutlined, iconColor: UIColor.ud.staticWhite, size: CGSize(width: 12, height: 12))
        icon.backgroundColor = UIColor.ud.N350
        icon.image = image
        icon.contentMode = .center
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear

        self.contentView.addSubview(self.bgView)
        self.bgView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalToSuperview()
        }

        self.bgView.addSubview(self.icon)
        self.bgView.addSubview(self.title)
        self.bgView.addSubview(self.selectedIcon)
        self.icon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.height.width.equalTo(20)
        }
        self.title.snp.makeConstraints { make in
            make.leading.equalTo(self.icon.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-14)
        }
        self.selectedIcon.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has falset been implemented")
    }

}
