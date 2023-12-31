//
//  UniversalRecommendViewController.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/12.
//

import UIKit
import Foundation
import SnapKit
import LarkSceneManager
import LarkKeyboardKit
import LarkKeyCommandKit
import LarkSearchCore
import RxSwift
import LarkUIKit
import LKCommonsLogging
import LarkSDKInterface
import LarkSearchFilter
import LarkAccountInterface
import LarkContainer
import LarkMessengerInterface

final class UniversalRecommendViewController: NiblessViewController, TableViewKeyBoardFocusHandler {
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.separatorStyle = .none
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.isHidden = true
        view.tag = SearchScrollView.scrollGestureSimultaneousTag
        return view
    }()

    let viewModel: UniversalRecommendPresentable

    private let bag = DisposeBag()

    private var shouldShowFooterView: Bool {
        return viewModel.numberOfSections > 1
    }

    static let logger = Logger.log(UniversalRecommendViewController.self, category: "Module.IM.Search")

    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: UniversalRecommendPresentable) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        super.init()
    }

    deinit {
        Self.logger.info("[UniversalRecommendViewController] deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupViewModel()
        viewModel.requestIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: 推荐频率策略
//        viewModel.requestIfNeeded()
        if Display.pad {
                viewModel.reloadData()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self), searchOuterService.enableUseNewSearchEntranceOnPad() {
            viewModel.reloadData()
            if searchOuterService.isCompactStatus() {
                tableView.snp.updateConstraints { make in
                    make.left.right.equalToSuperview().inset(UIConfig.tableViewHorizontalPadding)
                }
            } else {
                tableView.snp.updateConstraints { make in
                    make.left.right.equalToSuperview().inset(0)
                }
            }
        }
    }

    private func setupViews() {
        view.addSubview(tableView)
        view.backgroundColor = .ud.bgBase
        tableView.backgroundColor = .ud.bgBase
        tableView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(UIConfig.tableViewHorizontalPadding)
        }

        registerHeaders(headerTypes: viewModel.headerTypes)
        registerFooters(footerTypes: viewModel.footerTypes)
    }

    private(set) var status: UniversalRecommendViewModel.Status = .initial

    private func registerHeaders(headerTypes: [UniversalRecommendHeaderProtocol.Type]) {
        for headerType in headerTypes {
            tableView.register(headerType, forHeaderFooterViewReuseIdentifier: headerType.identifier)
        }
    }

    private func registerFooters(footerTypes: [UniversalRecommendFooterProtocol.Type]) {
        for footerType in footerTypes {
            tableView.register(footerType, forHeaderFooterViewReuseIdentifier: footerType.identifier)
        }
    }

    private func setupViewModel() {
        viewModel.shouldReloadData
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.tableView.isHidden = false
                if self.shouldShowFooterView {
                    let footerView = UniversalRecommendFooter()
                    footerView.frame.size.height = UniversalRecommendFooter.height
                    self.tableView.tableFooterView = footerView
                }
                self.tableView.reloadData()
            })
            .disposed(by: bag)

        viewModel.currentWidth = { [weak self] in
            guard let `self` = self else { return nil }
            return self.view.bounds.width - 2 * UIConfig.tableViewHorizontalPadding
        }

        viewModel.status
            .drive(onNext: { [weak self] status in
                guard let `self` = self else { return }
                self.status = status
                switch status {
                case .initial, .empty:
                    self.view.isHidden = true
                case .result:
                    self.view.isHidden = false
                }
            })
            .disposed(by: bag)

        viewModel.currentVC = { [weak self] in return self }
        viewModel.shouldInsertRows
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _, rows in
                guard let self = self else { return }
                self.tableView.insertRows(at: rows, with: .automatic)
            })
            .disposed(by: bag)

        viewModel.shouldDeleteRows
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _, rows in
                guard let self = self else { return }
                self.tableView.deleteRows(at: rows, with: .automatic)
            })
            .disposed(by: bag)

        observeKeyboardType().disposed(by: bag)
    }

    // MARK: - ScrollDelegate
    /// if user scroll after page load
    var onScreenType = OnScreenItemManager.Action.refresh
    var lastestOffsetY: CGFloat = 0
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        if scrollView == self.tableView {
            if offset <= CGFloat(0.0) {
                viewModel.changeFilterStyle(.dark)
            } else {
                viewModel.changeFilterStyle(.light)
            }
            onScreenType = .scroll
        }
    }

    // MARK: - KeyBinding
    override func keyBindings() -> [KeyBindingWraper] {
        if self.view.isHidden { return super.keyBindings() }
        return super.keyBindings() + focusChangeKeyBinding()
    }

    func canHandleKeyBoard(in responder: UIResponder) -> Bool {
        var enableCapsuleHandleKeyBoardFG = !SearchFeatureGatingKey.disableCapsuleSupportKeyboard.isUserEnabled(userResolver: self.userResolver)
        for next in Search.UIResponderIterator(start: responder) where next == self || next is SearchRootViewController || (enableCapsuleHandleKeyBoardFG && (next is SearchMainRootViewController)) {
            return true
        }
        return false
    }

    func firstFocusPosition() -> FocusInfo? {
        assert(Thread.isMainThread, "should occur on main thread!")
        return viewModel.firstFocusPosition()
    }

    func canFocus(info: IndexPath) -> Bool {
        return viewModel.canFocus(info: info)
    }

    func trackShow() {
        viewModel.trackShow()
    }

    // MARK: KeyBoard Focus Handle
    var kbTableView: UITableView { tableView }
    typealias FocusInfo = IndexPath
    var _currentKBFocus: FocusInfo?

    // Eiditing
    private func endEditing() {
        self.navigationController?.view.endEditing(false)
    }
}

extension UniversalRecommendViewController: UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(forSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellType = viewModel.cellType(forIndexPath: indexPath) else { return UITableViewCell() }
        if viewModel.registeredCellTypes.insert(cellType.identifier).inserted {
            tableView.register(cellType, forCellReuseIdentifier: cellType.identifier)
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellType.identifier) as? SearchCellProtocol else {
            assertionFailure("Search recommend cell type error")
            return UITableViewCell()
        }
        guard let cellViewModel = viewModel.cellViewModel(forIndexPath: indexPath) else { return UITableViewCell() }
        guard let currentAccount = (try? userResolver.resolve(assert: PassportUserService.self))?.user else { return UITableViewCell() }
        cell.setup(withViewModel: cellViewModel, currentAccount: currentAccount)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        endEditing()
        if Display.phone {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        viewModel.selectItem(atIndexPath: indexPath, from: self)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerType = viewModel.headerType(forSection: section) else { return nil }
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerType.identifier) as? UniversalRecommendHeaderProtocol else {
            assertionFailure("Search recommend header type error")
            return nil
        }

        guard let headerViewModel = viewModel.headerViewModel(forSection: section) else { return nil }
        header.setup(withViewModel: headerViewModel)
        return header
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(atIndexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerType = viewModel.footerType(forSection: section) else { return nil }
        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: footerType.identifier) as? UniversalRecommendFooterProtocol else {
            return nil
        }
        return footer
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.headerHeight(forSection: section)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.heightForCell(forIndexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return viewModel.footerHeight(forSection: section)
    }

}

extension UniversalRecommendViewController {
    fileprivate struct UIConfig {
        static var tableViewHorizontalPadding: CGFloat { return 8 }
    }
}
