//
//  EventFreeBusyViewController.swift
//  Calendar
//
//  Created by Miao Cai on 2020/3/20.
//

import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import CTFoundation
import UniverseDesignIcon

/// 日程 - FreeBusy 编辑页

protocol EventFreeBusyViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventFreeBusyViewController)
    func didFinishEdit(from viewController: EventFreeBusyViewController)
}

final class EventFreeBusyViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    weak var delegate: EventFreeBusyViewControllerDelegate?
    internal private(set) var selectedFreeBusy: EventFreeBusy

    private let disposeBag = DisposeBag()
    private let freeBusyItems: [EventFreeBusy] = [.busy, .free]
    private var tableView: UITableView = UITableView(frame: .zero, style: .plain)
    private let cellReuseId = "Cell"

    init(freeBusy: EventFreeBusy) {
        selectedFreeBusy = freeBusy
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Calendar.Calendar_Edit_ChooseAvailability
        setupView()
        bindViewAction()
        tableView.reloadData()
    }

    private func setupView() {
        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground

        tableView.frame = view.bounds
        tableView.register(FreeBusyCell.self, forCellReuseIdentifier: cellReuseId)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(14)
            $0.left.right.bottom.equalToSuperview()
        }

        let backItem = LKBarButtonItem(
            image: UDIcon.getIconByKeyNoLimitSize(.leftOutlined)
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
        return freeBusyItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        guard let freeBusyCell = cell as? FreeBusyCell else {
            return cell
        }
        let freeBusy = freeBusyItems[indexPath.row]
        freeBusyCell.title = freeBusy.description
        freeBusyCell.isChecked = freeBusy == selectedFreeBusy
        return freeBusyCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return EventEditUIStyle.Layout.singleLineCellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        selectedFreeBusy = freeBusyItems[indexPath.row]
        tableView.reloadData()
        self.delegate?.didFinishEdit(from: self)
    }
}

extension EventFreeBusyViewController {

    final class FreeBusyCell: UITableViewCell {
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
                let titleContent = EventBasicCellLikeView.ContentTitle(text: title,
                                                                       color: isChecked ? UIColor.ud.functionInfoContentDefault: UIColor.ud.textTitle)
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
