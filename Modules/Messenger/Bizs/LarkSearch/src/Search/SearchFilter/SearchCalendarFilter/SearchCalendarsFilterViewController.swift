//
//  SearchCalendarsFilterViewController.swift
//  LarkSearchFilter
//
//  Created by ByteDance on 2023/8/31.
//

import UIKit
import Foundation
import LarkUIKit
import LarkContainer
import RxSwift
import RxCocoa
import RustPB
import EENavigator
import LarkRustClient
import LarkSearchFilter
import LarkNavigator

final class SearchCalendarsFilterViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {

    let tableView = UITableView(frame: .zero)
    let userResolver: UserResolver
    var calendarItems: [MainSearchCalendarItem]
    let completion: ([MainSearchCalendarItem]) -> Void
    let bag = DisposeBag()
    @ScopedInjectedLazy var searchDependency: SearchDependency?
    init(userResolver: UserResolver,
         title: String,
         selectedCalendarItems: [MainSearchCalendarItem],
         completion: @escaping ([MainSearchCalendarItem]) -> Void) {
        self.userResolver = userResolver
        self.calendarItems = selectedCalendarItems
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var saveButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 30))
        button.addTarget(self, action: #selector(save), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.contentHorizontalAlignment = .right
        return button
    }()

    func updateSaveButtonTitle() {
        let count = calendarItems.filter { item in
            item.isSelected
        }.count
        let countStr: String = count >= 1 ? " (\(count))" : ""
        self.saveButton.setTitle(BundleI18n.LarkSearch.Lark_Legacy_Sure + countStr, for: .normal)
        self.saveButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.addCancelItem()
        updateSaveButtonTitle()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.saveButton)

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        tableView.register(MainSearchCalendarCell.self, forCellReuseIdentifier: "MainSearchCalendarCell")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()

        searchDependency?.getAllCalendarsForSearchBiz(isNeedSelectedState: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] subscribeCalendarsItems in
                guard let self = self else { return }
                guard !subscribeCalendarsItems.isEmpty else { return }
                let subscribeCalendarsItems = subscribeCalendarsItems.filter { item in
                    !self.calendarItems.contains { _item in
                        item.id.elementsEqual(_item.id)
                    }
                }
                self.calendarItems = MainSearchCalendarItem.sortCalendarItems(items: self.calendarItems + subscribeCalendarsItems)
                self.tableView.reloadData()
            }).disposed(by: bag)
    }

    @objc
    func save() {
        let selectedItems = calendarItems.filter({ $0.isSelected })
        completion(selectedItems)
        closeBtnTapped()
    }

    // MARK: TableView Delegate & DataSource
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) as? MainSearchCalendarCell != nil, calendarItems.count > indexPath.row else {
            return
        }
        calendarItems[indexPath.row].isSelected = !calendarItems[indexPath.row].isSelected
        self.tableView.reloadRows(at: [indexPath], with: .none)
        updateSaveButtonTitle()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MainSearchCalendarCell.cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainSearchCalendarCell", for: indexPath)
        if let cell = cell as? MainSearchCalendarCell, calendarItems.count > indexPath.row {
            let item = calendarItems[indexPath.row]
            cell.updateCellContent(cellContent: item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return calendarItems.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
