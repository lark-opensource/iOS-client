//
//  SelectedMeetingRoomViewController.swift
//  Calendar
//
//  Created by Rico on 2021/5/14.
//

import UIKit
import UniverseDesignIcon
import Foundation
import SnapKit
import RxSwift
import RxRelay
import LarkContainer
import LarkUIKit
import EENavigator

/// 聚合编辑态和详情态的已选会议室列表
final class SelectedMeetingRoomViewController: CalendarController, UserResolverWrapper {

    typealias ViewModel = SelectedMeetingRoomViewModel

    private let viewModel: ViewModel
    private let bag = DisposeBag()

    let userResolver: UserResolver

    init(viewModel: ViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNaviBar()
        layoutUI()
        bindViewModel()
    }

    // MARK: - Lazy View
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(SelectedMeetingRoomDetailCell.self,
                           forCellReuseIdentifier: String(describing: SelectedMeetingRoomDetailCell.self))
        tableView.register(SelectedMeetingRoomEditCell.self,
                           forCellReuseIdentifier: String(describing: SelectedMeetingRoomEditCell.self))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.safeAreaInsets.bottom))
        return tableView
    }()
}

extension SelectedMeetingRoomViewController {

    private func setupNaviBar() {
        title = BundleI18n.Calendar.Calendar_Edit_SelectedMeetingRooms
        let closeItem = LKBarButtonItem(
            image: UDIcon.getIconByKeyNoLimitSize(.leftOutlined).scaleNaviSize().renderColor(with: .n1)
        )
        closeItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.navigationController?.popViewController(animated: true)
            }
            .disposed(by: bag)
        navigationItem.leftBarButtonItem = closeItem
    }

    private func layoutUI() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func bindViewModel() {
        viewModel.route.subscribeForUI(onNext: { [weak self] route in
            guard let self = self else { return }
            switch route {
            case let .url(url):
                self.userResolver.navigator.push(url, context: ["from": "calendar"], from: self)
            case let .roomInfo(calendarID):
                self.jumpToMeetingRoomInfo(with: calendarID)
            }
        }).disposed(by: bag)

        viewModel.reloadTrigger.subscribeForUI(onNext: {[weak self] _ in
            guard let self = self else { return }
            self.tableView.reloadData()
        }).disposed(by: bag)
    }
}

extension SelectedMeetingRoomViewController {

    private func jumpToMeetingRoomInfo(with calendarID: String) {
        CalendarTracer.shared.calClickMeetingRoomInfoFromDetail()
        var context = DetailOnlyContext()
        context.calendarID = calendarID
        let viewModel = MeetingRoomDetailViewModel(input: .detailOnly(context), userResolver: self.userResolver)
        let toVC = MeetingRoomDetailViewController(viewModel: viewModel, userResolver: self.userResolver)
        if Display.pad {
            let navigation = LkNavigationController(rootViewController: toVC)
            navigation.modalPresentationStyle = .formSheet
            navigationController?.present(navigation, animated: true, completion: nil)
        } else {
            navigationController?.pushViewController(toVC, animated: true)
        }
    }
}

extension SelectedMeetingRoomViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if viewModel.sourceType == .detail {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SelectedMeetingRoomDetailCell.self), for: indexPath) as? SelectedMeetingRoomDetailCell,
                  let item = viewModel.detailItem(at: indexPath.row) else {
                return UITableViewCell()
            }

            cell.updateContent(item) { [weak self] in
                guard let self = self else { return }
                self.viewModel.clickDetail(on: .trailingIcon, at: indexPath.row)
            }

            return cell
        }

        if viewModel.sourceType == .edit {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SelectedMeetingRoomEditCell.self), for: indexPath) as? SelectedMeetingRoomEditCell,
                  let item = viewModel.editItem(at: indexPath.row) else {
                return UITableViewCell()
            }

            cell.updateContent(item) { [weak self] (_) in
                guard let self = self else { return }
                self.viewModel.clickEdit(on: .trailingIcon, at: indexPath.row)
            } itemFormClickHandler: { [weak self] (_) in
                guard let self = self else { return }
                self.viewModel.clickEdit(on: .form, at: indexPath.row)
            } itemClickHandler: { [weak self] (_) in
                guard let self = self else { return }
                self.viewModel.clickEdit(on: .wholeCell, at: indexPath.row)
            }

            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard viewModel.sourceType == .detail else {
            return
        }

        self.viewModel.clickDetail(on: .wholeCell, at: indexPath.row)
    }
}
