//
//  SearchShareDocumentsViewController.swift
//  ByteView
//
//  Created by lvdaqian on 2019/10/16.
//
import UIKit
import RxSwift
import RxCocoa

final class SearchShareDocumentsViewController: BaseViewController {

    lazy var searchBar: SearchBarView = {
        let searchView = SearchBarView(frame: CGRect.zero, isNeedCancel: true)
        searchView.clipsToBounds = true
        return searchView
    }()

    lazy var searchView: SearchContainerView = {
        let searchResult = SearchContainerView(frame: CGRect.zero)
        searchResult.tableView.backgroundColor = UIColor.ud.bgBody
        searchResult.tableView.tableFooterView = UIView(frame: CGRect.zero)
        searchResult.tableView.separatorStyle = .none
        searchResult.tableView.rowHeight = UITableView.automaticDimension
        searchResult.tableView.estimatedRowHeight = 72
        searchResult.tableView.accessibilityLabel = "SearchShareDocumentsViewController.searchView.accessibilityLabel"
        searchResult.tableView.accessibilityIdentifier = "SearchShareDocumentsViewController.searchView.accessibilityIdentifier"
        return searchResult
    }()

    lazy var maskSearchViewTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer()
        return tap
    }()

    lazy var searchResultMaskView: UIView = {
        let backView = UIView(frame: .zero)
        backView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.5)
        backView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backView.addGestureRecognizer(maskSearchViewTap)
        backView.isHidden = true
        return backView
    }()

    lazy var loadingAnimationView = LoadingView(frame: CGRect(x: 0, y: 0, width: 32, height: 28), style: .grey)
    lazy var loadingView: UIView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center

        stackView.addArrangedSubview(loadingAnimationView)

        let label = UILabel()
        label.text = I18n.View_VM_Loading
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        stackView.addArrangedSubview(label)

        let view = UIView()
        view.isHidden = true
        view.backgroundColor = UIColor.ud.N00
        view.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        return view
    }()

    let viewModel: SearchShareDocumentsVMProtocol
    init(_ viewModel: SearchShareDocumentsVMProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        setupViews()
        bindMaskViewHidden()
        bindModel(viewModel)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewSafeAreaInsetsDidChange() {
        let leftOffset = max(view.safeAreaInsets.left, 16)
        let rightOffset = max(view.safeAreaInsets.right, 16)
        searchBar.snp.updateConstraints { (maker) in
            maker.left.equalToSuperview().offset(leftOffset)
            maker.right.equalToSuperview().offset(-rightOffset)
        }
    }

    private func setupViews() {
        view.addSubview(searchBar)
        view.addSubview(searchView)
        view.addSubview(searchResultMaskView)
        view.addSubview(loadingView)

        let leftOffset = max(view.safeAreaInsets.left, 16)
        let rightOffset = max(view.safeAreaInsets.right, 16)
        searchBar.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(8)
            maker.left.equalToSuperview().offset(leftOffset)
            maker.right.equalToSuperview().offset(-rightOffset)
            maker.height.equalTo(36)
        }

        searchView.tableView.register(SearchDocumentResultCell.self, forCellReuseIdentifier: "Cell")
        searchView.tableView.isAccessibilityElement = true
        searchView.tableView.accessibilityIdentifier = "SearchShareDocumentsViewController.searchView.accessibilityIdentifier"
        searchView.snp.makeConstraints { maker in
            maker.top.equalTo(searchBar.snp.bottom).offset(8)
            maker.left.right.equalToSuperview()
            maker.bottom.equalToSuperview().priority(.high)
            maker.bottom.lessThanOrEqualTo(view.vc.debounceKeyboardLayoutGuide.snp.top)
        }

        searchResultMaskView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(searchBar.snp.bottom)
            make.bottom.equalTo(view.vc.debounceKeyboardLayoutGuide.snp.top)
        }

        loadingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    private func configureNavigation() {
        self.title = I18n.View_VM_ShareDocsButton
    }

    private func bindModel(_ model: SearchShareDocumentsVMProtocol) {
        model.bindToViewController(self)
        bindMaskViewTap()
        viewModel.showLoadingObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.loadingView.isHidden = !isLoading
                if isLoading {
                    self?.loadingAnimationView.play()
                } else {
                    self?.loadingAnimationView.stop()
                }
            })
            .disposed(by: rx.disposeBag)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

extension SearchShareDocumentsViewController: SearchShareDocumentsViewControllerProtocol {
    var searchViewCellIdentifier: String { "Cell" }
    var disposeBag: DisposeBag { rx.disposeBag }
    var scenario: ShareContentScenario { self.viewModel.scenario }
}
