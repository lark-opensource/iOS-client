//
//  DetailTaskListPickerViewController.swift
//  Todo
//
//  Created by wangwanxin on 2022/12/27.
//

import Foundation
import UniverseDesignIcon
import RxSwift
import RxCocoa
import RichLabel
import LarkUIKit
import UniverseDesignFont

final class DetailTaskListPickerViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    let viewModel: DetailTaskListPickerViewModel

    var didSelectedHandler: ((DetailTaskListPicker) -> Void)?
    var addTaskListHandler: ((DetailTaskListCreate) -> Void)?

    private let disposeBag = DisposeBag()

    private lazy var headerView = DetailPickerHeaderView()

    private lazy var searchBar: DetailPickerSearchBar = {
        let search = DetailPickerSearchBar(with: viewModel.placeholder)
        search.searchBar.delegate = self
        return search
    }()

    private lazy var tableContainer = UIView()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.ctf.register(cellType: DetailTaskListPickerViewCell.self)
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()

    private lazy var stateView: ListStateView = {
        return ListStateView(
            with: tableContainer,
            targetView: tableView,
            bottomInset: Display.pad ? 0 : 350,
            backgroundColor: UIColor.ud.bgBody
        )
    }()
    // 描述是否已经退出
    private var isExiting = false

    init(with viewModel: DetailTaskListPickerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyBoardObserver()
        setupSubviews()
        bindViewState()
        viewModel.setup()
        viewModel.onUpdate = { [weak self] in
            self?.tableView.reloadData()
        }
        bindViewAction()

    }

    private func setupKeyBoardObserver() {
        // ipad 上不需要
        guard !Display.pad else { return }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard let userinfo = notification.userInfo else { return }
            guard let toFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self?.stateView.bottomInset = toFrame.height
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 侧滑或者下拉返回的时候,并且没有进行点选操作
        if (isMovingFromParent || navigationController?.isBeingDismissed == true) && !isExiting {
            viewModel.handleDefaultSelect(completion: didSelectedHandler)
        }
    }

    private func setupSubviews() {
        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(headerView)
        headerView.updateTitle(viewModel.headerText, viewModel.subTitle, nil)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
        }

        view.addSubview(searchBar)
        view.addSubview(tableContainer)
        tableContainer.addSubview(tableView)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
        }
        tableContainer.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bindViewState() {
        guard viewModel.isTaskListScene else { return }
        viewModel.rxViewState.distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] state in
                    guard let self = self else { return }
                    self.stateView.updateViewState(
                        state: state,
                        emptyType: .searchFailed,
                        emptyDescription: I18N.Lark_Legacy_SearchNoAnyResult
                    )
                })
            .disposed(by: disposeBag)
    }

    private func bindViewAction() {
        headerView.onCloseHandler = { [weak self] in
            self?.dismiss(animated: true)
        }
        searchBar.becomeFirstResponder()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.ctf.dequeueReusableCell(DetailTaskListPickerViewCell.self, for: indexPath),
              let cellData = viewModel.cellData(indexPath: indexPath) else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        cell.selectionStyle = .none
        cell.viewData = cellData
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard let cellData = viewModel.cellData(indexPath: indexPath), let id = cellData.identifier else { return }
        if cellData.identifier == searchBar.searchBar.text {
            viewModel.didCreateNew(with: cellData.identifier, completion: addTaskListHandler)
        } else {
            viewModel.didSelectItem(with: id, completion: didSelectedHandler)
        }
        isExiting = true
        dismiss(animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.queryData(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

}

struct DetailTaskListPickerViewCellData {
    var attributedText: AttrText?
    var identifier: String?
    var isChecked: Bool = false
    var isAdd: Bool = false
}

final class DetailTaskListPickerViewCell: UITableViewCell {

    var viewData: DetailTaskListPickerViewCellData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            label.attributedText = viewData.attributedText
            addIcon.isHidden = !viewData.isAdd
            checkIcon.isHidden = !viewData.isChecked
            updateLayout()
        }
    }

    private lazy var checkIcon: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.listCheckBoldOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault)
        view.isHidden = true
        return view
    }()

    private lazy var addIcon: UIImageView = {
        let view = UIImageView()
        let image = UDIcon.addMiddleOutlined
            .ud.resized(to: CGSize(width: 20, height: 20))
            .ud.withTintColor(UIColor.ud.iconN2)
        view.image = image
        view.isHidden = true
        return view
    }()

    private lazy var label: LKLabel = {
        let label = LKLabel()
        let textColor = UIColor.ud.textTitle
        label.backgroundColor = .clear
        label.linkAttributes = [.foregroundColor: textColor]
        label.outOfRangeText = AttrText(string: "...", attributes: [.foregroundColor: textColor])
        label.activeLinkAttributes = [:]
        label.autoDetectLinks = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(addIcon)
        contentView.addSubview(label)
        contentView.addSubview(checkIcon)
    }

    private func updateLayout() {

        addIcon.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        checkIcon.snp.remakeConstraints { make in
            make.width.height.equalTo(16)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        label.snp.remakeConstraints { make in
            if addIcon.isHidden {
                make.left.equalToSuperview().offset(16)
            } else {
                make.left.equalTo(addIcon.snp.right).offset(8)
            }
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
            if checkIcon.isHidden {
                make.right.equalToSuperview().offset(-16)
            } else {
                make.right.equalTo(checkIcon.snp.left).offset(-8)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
