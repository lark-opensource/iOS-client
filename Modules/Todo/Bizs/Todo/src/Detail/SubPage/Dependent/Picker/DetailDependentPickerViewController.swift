//
//  DetailDependentPickerViewController.swift
//  Todo
//
//  Created by wangwanxin on 2023/7/18.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa

final class DetailDependentPickerViewController:
    BaseViewController,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UISearchBarDelegate {

    let viewModel: DetailDependentPickerViewModel

    private let disposeBag = DisposeBag()
    private let onConfirm: ([Rust.Todo]) -> Void

    private lazy var headerView = DetailPickerHeaderView()

    private lazy var searchBar: DetailPickerSearchBar = {
        let search = DetailPickerSearchBar(with: I18N.Todo_Task_SearchTask)
        search.searchBar.delegate = self
        return search
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor.ud.bgFloatBase
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.alwaysBounceVertical = true
        cv.allowsMultipleSelection = true
        cv.ctf.register(cellType: DetailDependentListCell.self)
        cv.dataSource = self
        cv.delegate = self
        cv.keyboardDismissMode = .onDrag
        return cv
    }()
    
    private lazy var listContainer = UIView()

    private lazy var stateView: ListStateView = {
        return ListStateView(
            with: listContainer,
            targetView: collectionView,
            bottomInset: Display.pad ? 0 : 350,
            backgroundColor: UIColor.ud.bgFloatBase
        )
    }()
    private var keyboardShowObserver: NSObjectProtocol?

    init(
        viewModel: DetailDependentPickerViewModel,
        confirm: @escaping ([Rust.Todo]) -> Void)
    {
        self.viewModel = viewModel
        self.onConfirm = confirm
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
        viewModel.onUpdate = { [weak self] in
            if let selectedItems = self?.viewModel.selectedTodos {
                self?.updateHeader(by: selectedItems.count)
            }
            self?.collectionView.reloadData()
        }
        bindViewAction()
    }

    deinit {
        if let keyboardShowObserver = keyboardShowObserver {
            NotificationCenter.default.removeObserver(keyboardShowObserver)
        }
    }

    private func setupKeyBoardObserver() {
        // ipad 上不需要
        guard !Display.pad else { return }
        keyboardShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard let userinfo = notification.userInfo else { return }
            guard let toFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self?.stateView.bottomInset = toFrame.height
        }
    }

    private func setupSubviews() {
        view.backgroundColor = UIColor.ud.bgFloatBase

        view.addSubview(headerView)
        updateHeader(by: 0)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
        }

        view.addSubview(searchBar)
        searchBar.backgroundColor = UIColor.ud.bgBody
        view.addSubview(listContainer)
        listContainer.addSubview(collectionView)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
        }
        listContainer.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bindViewState() {
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
        headerView.onConfirmHandler = { [weak self] in
            guard let self = self else { return }
            let selectedItem = self.viewModel.selectedTodos
            self.onConfirm(selectedItem)
            self.dismiss(animated: true)
        }
        searchBar.searchBar.becomeFirstResponder()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.cellDatas.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.ctf.dequeueReusableCell(DetailDependentListCell.self, for: indexPath),
              let row = viewModel.safeCheckRows(indexPath)
        else {
            return UICollectionViewCell()
        }
        cell.viewData = viewModel.cellDatas[row]
        cell.actionDelegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let row = viewModel.safeCheckRows(indexPath) else {
            return .zero
        }
        let item = viewModel.cellDatas[row]
        let maxWidth = collectionView.frame.width - Config.hPadding * 2
        if let height = item.cellHeight {
            return CGSize(width: collectionView.frame.width, height: height)
        }
        let height = item.preferredHeight(maxWidth: maxWidth)
        viewModel.cellDatas[row].cellHeight = height
        return CGSize(width: collectionView.frame.width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: Config.vSpace, left: 0, bottom: 0, right: 0)
    }


    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.queryTodo(by: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    private func updateHeader(by count: Int) {
        headerView.updateTitle(viewModel.title, nil, count)
    }
}

extension DetailDependentPickerViewController: DetailDependentListCellDelegate {

    func didClickRemove(from sender: DetailDependentListCell) { }

    func didClickContent(from sender: DetailDependentListCell) {
        guard let indexPath = collectionView.indexPath(for: sender) else {
            return
        }
        viewModel.didSelectItem(at: indexPath)
    }

}

extension DetailDependentPickerViewController {

    struct Config {
        static let topSpace = 16.0
        static let hPadding = 16.0
        static let vSpace = 8.0
    }

}
