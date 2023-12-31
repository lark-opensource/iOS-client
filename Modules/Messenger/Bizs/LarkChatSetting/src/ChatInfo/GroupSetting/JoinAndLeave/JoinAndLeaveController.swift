//
//  JoinAndLeaveController.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/10/12.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import LarkMessengerInterface
import UniverseDesignEmpty
import FigmaKit

final class JoinAndLeaveController: BaseSettingController, UITableViewDelegate, UITableViewDataSource {
    private let disposeBag = DisposeBag()

    private var datas: [JoinAndLeaveItem] = []

    private let viewModel: JoinAndLeaveViewModel

    private lazy var emptyView = UDEmptyView(config: UDEmptyConfig(type: .defaultPage))
    private let table = InsetTableView(frame: .zero)
    private var _errorView: LoadFailPlaceholderView?
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }
    private lazy var errorView: LoadFailPlaceholderView = {
        let view = LoadFailPlaceholderView()
        self.view.addSubview(view)
        view.snp.makeConstraints { $0.edges.equalToSuperview() }
        view.isHidden = true
        view.text = BundleI18n.LarkChatSetting.Lark_Legacy_LoadingFailed
        _errorView = view
        return view
    }()

    init(viewModel: JoinAndLeaveViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkChatSetting.Lark_Group_MemberJoinAndLeaveHistory

        self.view.addSubview(self.table)
        self.table.snp.makeConstraints { $0.edges.equalToSuperview() }
        self.table.separatorStyle = .none
        self.table.delegate = self
        self.table.dataSource = self
        self.table.showsVerticalScrollIndicator = false
        self.table.rowHeight = UITableView.automaticDimension
        self.table.estimatedRowHeight = 100
        self.table.sectionHeaderHeight = 0
        self.table.sectionFooterHeight = 0
        self.table.lu.register(cellSelf: JoinAndLeaveCell.self)
        self.table.register(
            UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView")
        self.table.backgroundColor = UIColor.ud.bgFloatBase

        self.loadingPlaceholderView.isHidden = false

        self.viewModel.dataSource.drive(onNext: { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let datas):
                self.datas = datas
                self.setDispalyView()
                self.reloadTableStatus()
            case .failure:
                if self.datas.isEmpty {
                    self.errorView.isHidden = false
                }
            }
        }).disposed(by: disposeBag)

        self.viewModel.onTap = { [weak self] type in
            self?.onTap(type)
        }

        self.viewModel.loadData()
    }

    private func setDispalyView() {
        self.loadingPlaceholderView.isHidden = true
        self._errorView?.isHidden = true

        if self.datas.isEmpty {
            self.view.addSubview(emptyView)
            emptyView.backgroundColor = UIColor.ud.bgFloatBase
            emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
    }

    private func reloadTableStatus() {
        self.table.reloadData()
        self.table.removeBottomLoadMore()
        if self.viewModel.hasMore {
            self.table.addBottomLoadMoreView { [weak self] in
                self?.viewModel.loadData()
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.table.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    private func onTap(_ type: JoinAndLeaveViewModel.TapType) {
        switch type {
        case .user(let id):

            // There is no need to pass `chatID`, because the user may not be in the
            // group when the click event occurs.
            // 点击事件发生时，用户可能已经不是群成员。所以无需传`chatID`
            self.viewModel.navigator.push(body: PersonCardBody(chatterId: id), from: self)

        case .chat(let id):
            self.viewModel.navigator.push(body: GroupCardSystemMessageJoinBody(chatId: id), from: self)

        case .doc(let url):
            self.viewModel.navigator.push(url, from: self)
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: JoinAndLeaveCell.self),
            for: indexPath)

        if let cell = cell as? JoinAndLeaveCell {
            cell.maxAvailableWidth = tableView.bounds.width
            var item = datas[indexPath.row]
            item.isShowBoaderLine = indexPath.row != datas.count - 1
            cell.item = item
            cell.onTapChatter = { [weak self] chatterID in
                self?.onTap(.user(id: chatterID))
            }
        }

        return cell
    }
}
