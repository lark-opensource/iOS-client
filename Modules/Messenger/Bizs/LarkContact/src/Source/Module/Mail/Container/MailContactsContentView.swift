//
//  SelectionExternalContactsContentView.swift
//  LarkContact
//
//  Created by SolaWing on 2020/11/6.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkFeatureSwitch
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkAlertController
import UniverseDesignToast
import LarkAccountInterface
import LarkMessengerInterface
import LarkKeyCommandKit
import LarkFeatureGating
import LarkSearchCore
import LKCommonsLogging
import UniverseDesignEmpty
import Homeric

final class MailContactsContentView: UIViewController, UITableViewDelegate, UITableViewDataSource,
                               HasSelectChannel, TableViewKeyboardHandlerDelegate {

    var selectChannel: SelectChannel {
        return .mail
    }
    static let log = Logger.log(MailContactsContentView.self, category: "LarkContact")

    weak var selectionSource: SelectionDataSource?
    let viewModel: MailContactsContentViewModel

    private let tableView = UITableView(frame: CGRect.zero)
    let disposeBag = DisposeBag()

    private let timeStringFormatter: ((String) -> String?) = { timeZoneId in
        guard let chatterTimeZone = TimeZone(identifier: timeZoneId),
            chatterTimeZone.secondsFromGMT() != TimeZone.current.secondsFromGMT() else {
            return nil
        }
        return Date().lf.formatedOnlyTime(accurateToSecond: false, timeZone: chatterTimeZone)
    }

    private var datasource: [MailContactsItemCellViewModel] = [] {
        didSet {
            if datasource.isEmpty {
                self.tableView.isHidden = true
                self.emptyView.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.emptyView.isHidden = true
            }
        }
    }
    private let emptyView = UDEmptyView(config: UDEmptyConfig(titleText: BundleI18n.LarkContact.Lark_Legacy_ContactEmpty, type: .noContact))
    private let loadingPlaceholderView = LoadingPlaceholderView()

    // Tableview keyboard
    private var keyboardHandler: TableViewKeyboardHandler?

    override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (keyboardHandler?.baseSelectiveKeyBindings ?? [])
    }

    struct Config {
        let pickerTracker: PickerAppReciable?
        let selectedHandler: ((Int) -> Void)?
    }
    private let config: Config

    init(
        viewModel: MailContactsContentViewModel,
        selectionSource: SelectionDataSource,
        config: Config
    ) {
        self.selectionSource = selectionSource
        self.viewModel = viewModel
        self.config = config
        super.init(nibName: nil, bundle: nil)

        self.config.pickerTracker?.initViewEnd()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.naviTitle
        self.view.backgroundColor = UIColor.ud.bgBase
        self.view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        initializeTableView()

        loadingPlaceholderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingPlaceholderView.frame = view.bounds
        view.addSubview(loadingPlaceholderView)

        bindViewModel()
        // keyboard
        keyboardHandler = TableViewKeyboardHandler()
        keyboardHandler?.delegate = self

        self.config.pickerTracker?.firstRenderEnd()
        // Picker 埋点
        SearchTrackUtil.trackPickerSelectEmailMemberView()
    }

    // MARK: - TableViewKeyboardHandlerDelegate
    func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return tableView
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        tableView.deselectRow(at: indexPath, animated: false)

        let item = datasource[indexPath.row]

        if let model = item as? Option,
           let selectionSource = self.selectionSource,
           let mailCell = cell as? MailContactsContentTableViewCell {
            if !mailCell.canSelect {
                if let namecard = model as? NameCardInfo, let window = self.view.window, namecard.email.isEmpty {
                    UDToast.showTips(with: BundleI18n.LarkContact.Lark_Contacts_CantSelectEmptyEmailAddress,
                                     on: window)
                }
                return
            }

            if selectionSource.toggle(option: model,
                                      from: self,
                                      at: tableView.absolutePosition(at: indexPath),
                                      event: Homeric.PUBLIC_PICKER_SELECT_EMAIL_MEMBER_CLICK,
                                      target: Homeric.PUBLIC_PICKER_SELECT_EMAIL_MEMBER_VIEW),
               selectionSource.state(for: model, from: self).selected {
                self.config.selectedHandler?(indexPath.row + 1)
            }
        } else {
            assert(false, "oops, viewmodel cannot transform to namecardInfo, something wrong")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: MailContactsContentTableViewCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MailContactsContentTableViewCell {
            let contact = self.datasource[indexPath.row]
            if let selectionSource = self.selectionSource {
                let state = viewModel.checkItemSelectState(item: contact, selectionSource: selectionSource)
                cell.setCellViewModel(viewModel: contact, canSelect: !state.disable, isSelected: state.selected)
            }
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }

    private func initializeTableView() {
        view.addSubview(tableView)
        view.backgroundColor = UIColor.ud.bgBase
        tableView.backgroundColor = UIColor.clear
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = view.bounds
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        let identifier = String(describing: MailContactsContentTableViewCell.self)
        tableView.register(MailContactsContentTableViewCell.self, forCellReuseIdentifier: identifier)

        tableView.addBottomLoadMoreView { [weak self] in
            guard let `self` = self else {
                return
            }
            self.viewModel.getMailContactsList(isRefresh: false)
        }
    }

    private func bindViewModel() {
        selectionSource?.isMultipleChangeObservable.subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        selectionSource?.selectedChangeObservable.subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        self.loadingPlaceholderView.isHidden = false

        let startLoadTimeStamp = CACurrentMediaTime()

        self.viewModel.state.drive(onNext: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .refresh(let data):
                self.handleRefresh(list: data)
            case .loading:
                self.loadingPlaceholderView.isHidden = false
            case .loadMore(let data):
                self.handleLoadMore(list: data)
            case .dataError(let error):
                self.handleDataError(error)
            }
            self.tableView.endBottomLoadMore()
            self.tableView.enableBottomLoadMore(self.viewModel.hasMore)
        }, onCompleted: {

        }).disposed(by: disposeBag)

        self.viewModel.getMailContactsList(isRefresh: true)
    }
}

// MARK: handler
extension MailContactsContentView {
    private func handleRefresh(list: [MailContactsItemCellViewModel]) {
        self.datasource = list
        self.loadingPlaceholderView.isHidden = true
        self.tableView.reloadData()
    }

    private func handleDataError(_ error: Error) {

    }

    private func handleLoadMore(list: [MailContactsItemCellViewModel]) {
        self.tableView.endBottomLoadMore()
        self.datasource.append(contentsOf: list)
        self.tableView.reloadData()
    }
}

extension MailContactsContentTableViewCell {

}

extension NameCardInfo: PickerSelectionTrackable {
    public var selectType: PickerSearchSelectType { return .emailMember }
}
