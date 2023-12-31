//
//  EventEditAttendeeTimeZoneViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/2/8.
//

import UIKit
import Foundation
import LarkTimeFormatUtils
import CTFoundation
import LarkContainer
import LarkUIKit

final class EventEditAttendeeTimeZoneViewController: UIViewController,
                                                     UITableViewDataSource,
                                                     UITableViewDelegate,
                                                     PopupViewControllerItem {
    private let viewModel: EventEditAttendeeTimeZoneViewModel
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.safeAreaInsets.bottom + 20))
        tableView.separatorStyle = .none
        tableView.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        tableView.register(EventEditAttendeeTimeZoneCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    private lazy var headerView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let cellIdentifier = "Cell"
    init(viewModel: EventEditAttendeeTimeZoneViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloat
        self.popupViewController?.foregroundColor = UIColor.ud.bgFloat
        setupTableView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tableView.reloadData()

        if let gesture = popupViewController?.interactivePopupGestureRecognizer {
            tableView.panGestureRecognizer.require(toFail: gesture)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // 每次 view 变换使需要更新 tableview header view 的布局
        DispatchQueue.main.async {
            self.tableView.tableHeaderView?.layoutIfNeeded()
            self.tableView.tableHeaderView = self.tableView.tableHeaderView
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        if newCollection.horizontalSizeClass == .compact {
            tableView.tableHeaderView = headerView
            headerView.snp.makeConstraints {
                $0.width.top.equalToSuperview()
                $0.height.greaterThanOrEqualTo(44)
            }
            tableView.tableHeaderView?.layoutIfNeeded()
            tableView.tableHeaderView = tableView.tableHeaderView
        } else {
            tableView.tableHeaderView = nil
        }
    }

    private func setupTableView() {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.cd.regularFont(ofSize: 16)
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        
        // 场景: 编辑页-查看不同时区
        // 用指定的时区 format

        label.text = viewModel.timeRangeDescription
        headerView.addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 9, right: 16))
        }

        if self.traitCollection.horizontalSizeClass == .compact {
            tableView.tableHeaderView = headerView
            headerView.snp.makeConstraints {
                $0.width.top.equalToSuperview()
                $0.height.greaterThanOrEqualTo(44)
            }
            tableView.tableHeaderView?.layoutIfNeeded()
            tableView.tableHeaderView = tableView.tableHeaderView
        }
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.attendees.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? EventEditAttendeeTimeZoneCell else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        let attendee = viewModel.attendees[indexPath.row]
        cell.item = (avatar: attendee.avatar, name: attendee.name)
        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        EventEditAttendeeTimeZoneCell.desiredHeight
    }

    // MARK: PopupViewControllerItem

    var naviBarTitle: String {
        self.viewModel.timeRangeDescription
    }

    var preferredPopupOffset: PopupOffset {
        if Display.pad {
            return PopupOffset(rawValue: 0.6)
        } else {
            let preferredHeight = Popup.Const.defaultPresentHeight
            let containerHeight = (popupViewController?.contentHeight ?? UIScreen.main.bounds.height)
            return PopupOffset(rawValue: preferredHeight / containerHeight)
        }
    }

    var hoverPopupOffsets: [PopupOffset] {
        [preferredPopupOffset, .full]
    }

    var naviBarBackgroundColor: UIColor { EventEditUIStyle.Color.viewControllerBackground }

    func shouldBeginPopupInteractingInCompact(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let popupViewController = popupViewController,
            interactivePopupGestureRecognizer == popupViewController.interactivePopupGestureRecognizer,
            let panGesture = interactivePopupGestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        guard abs(popupViewController.currentPopupOffset.rawValue - hoverPopupOffsets.last!.rawValue) < 0.01 else {
            return true
        }

        let velocity = panGesture.velocity(in: panGesture.view)
        // 上滑
        if velocity.y < 0 {
            return false
        }
        // 下滑
        if velocity.y > 0 && tableView.contentOffset.y > 0.1 {
            return false
        }
        return true
    }

    func shouldBeginPopupInteractingInRegular(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let popupViewController = popupViewController,
            interactivePopupGestureRecognizer == popupViewController.interactivePopupGestureRecognizer,
            let panGesture = interactivePopupGestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        let velocity = panGesture.velocity(in: panGesture.view)
        let point = panGesture.location(in: self.view)

        // 手势开始时不在tableview中
        if !tableView.frame.contains(point) {
            return true
        }

        // 左滑 or 右滑
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }

        // 上滑
        if velocity.y < 0 {
            return false
        }
        // 下滑
        if velocity.y > 0 && tableView.contentOffset.y > 0.1 {
            return false
        }
        return true
    }

}
