//
//  EventVisibilityViewController.swift
//  Calendar
//
//  Created by Miao Cai on 2020/3/23.
//

import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import CTFoundation
import UniverseDesignIcon

/// 日程 - Visibility 编辑页

protocol EventVisibilityViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventVisibilityViewController)
    func didFinishEdit(from viewController: EventVisibilityViewController)
}

final class EventVisibilityViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    weak var delegate: EventVisibilityViewControllerDelegate?
    internal private(set) var selectedVisibility: EventVisibility

    private let disposeBag = DisposeBag()
    private let visibilityItems: [EventVisibility] = [.default, .public, .private]
    private var tableView: UITableView = UITableView(frame: .zero, style: .plain)
    private let cellReuseId = "Cell"

    init(visibility: EventVisibility) {
        selectedVisibility = visibility
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Calendar.Calendar_Bot_ChooseVisibility
        setupView()
        bindViewAction()
        tableView.reloadData()
    }

    private func setupView() {
        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground

        tableView.frame = self.view.bounds
        tableView.tableFooterView = UIView()
        tableView.register(VisibilityCell.self, forCellReuseIdentifier: cellReuseId)
        tableView.separatorStyle = .none
        tableView.sectionHeaderHeight = EventEditUIStyle.Layout.horizontalSeperatorHeight
        tableView.sectionFooterHeight = EventEditUIStyle.Layout.horizontalSeperatorHeight
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(14)
            $0.left.right.bottom.equalToSuperview()
        }
        let backItem = LKBarButtonItem(
            image: UDIcon.getIconByKeyNoLimitSize(.leftOutlined)
                .scaleNaviSize()
                .renderColor(with: .n1)
                .withRenderingMode(.alwaysOriginal)
        )
        navigationItem.leftBarButtonItem = backItem
    }

    private func bindViewAction() {
        let closeItem = navigationItem.leftBarButtonItem as? LKBarButtonItem
        closeItem?.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didCancelEdit(from: self)
            }
            .disposed(by: disposeBag)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibilityItems.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let separator = UIView()
        separator.backgroundColor = .clear
        return separator
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let separator = UIView()
        separator.backgroundColor = .clear
        return separator
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        guard let visibilityCell = cell as? VisibilityCell else {
            return cell
        }
        let visibility = visibilityItems[indexPath.row]
        visibilityCell.title = visibility.description
        visibilityCell.isChecked = visibility == selectedVisibility
        return visibilityCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return EventEditUIStyle.Layout.secondaryPageCellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        selectedVisibility = visibilityItems[indexPath.row]
        tableView.reloadData()
        self.delegate?.didFinishEdit(from: self)
    }
}

extension EventVisibilityViewController {

    final class VisibilityCell: UITableViewCell {
        var innerView = EventEditCellLikeView()
        var title: String = "" {
            didSet {
                let titleContent = EventBasicCellLikeView.ContentTitle(text: title)
                innerView.content = .title(titleContent)
            }
        }

        var isChecked: Bool = false {
            didSet {
                innerView.accessory = isChecked ? .type(.checkmark) : .none
                let titleContent = EventBasicCellLikeView.ContentTitle(text: title, color: isChecked ? UIColor.ud.functionInfoContentDefault: UIColor.ud.textTitle)
                innerView.content = .title(titleContent)
            }
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none
            isChecked = false
            innerView.icon = .none
            innerView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
            contentView.addSubview(innerView)
            innerView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

}
