//
//  CustomFieldsTagsPanelViewController.swift
//  Todo
//
//  Created by baiyantao on 2023/4/23.
//

import Foundation
import UniverseDesignIcon
import RxSwift
import UniverseDesignEmpty
import UniverseDesignFont

final class CustomFieldsTagsPanelViewController: UIViewController {

    // MARK: dependencies
    private let viewModel: CustomFieldsTagsPanelViewModel
    private let disposeBag = DisposeBag()

    // MARK: views
    private lazy var naviContainerView = UIView()
    private lazy var exitButton = initExitButton()
    private lazy var titleLabel = initTitleLabel()
    private lazy var tableView = initTableView()
    private lazy var emptyVIew = initEmptyView()

    init(viewModel: CustomFieldsTagsPanelViewModel, title: String) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewData()
    }

    private func setupView() {
        view.addSubview(naviContainerView)
        naviContainerView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(48)
        }

        naviContainerView.addSubview(exitButton)
        exitButton.snp.makeConstraints {
            $0.width.height.equalTo(28)
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(14)
        }

        naviContainerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.left.lessThanOrEqualToSuperview().offset(56)
            $0.right.lessThanOrEqualToSuperview().offset(-56)
        }

        if viewModel.numberOfItems() == 0 {
            view.addSubview(emptyVIew)
            emptyVIew.snp.makeConstraints {
                $0.top.equalTo(naviContainerView.snp.bottom).offset(60)
                $0.centerX.equalToSuperview()
            }
        } else {
            view.addSubview(tableView)
            tableView.snp.makeConstraints {
                $0.top.equalTo(naviContainerView.snp.bottom)
                $0.left.right.bottom.equalToSuperview()
            }
        }
    }

    private func bindViewData() {
        viewModel.reloadNoti
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        viewModel.dismissHandler = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    private func initExitButton() -> UIButton {
        let button = UIButton()
        let image = UDIcon.closeSmallOutlined.ud.withTintColor(UIColor.ud.iconN1)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .selected)
        button.addTarget(self, action: #selector(onExitBtnClick), for: .touchUpInside)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -6, left: -6, bottom: -6, right: -6)
        return button
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.boldSystemFont(ofSize: 17)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
        return label
    }

    private func initTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.ctf.register(cellType: CustomFieldsTagsPanelContentCell.self)
        return tableView
    }

    private func initEmptyView() -> UDEmptyView {
        let config = UDEmptyConfig(
            description: UDEmptyConfig.Description(descriptionText: I18N.Todo_CustomField_NoOptions_Text),
            type: .noContent
        )
        return UDEmptyView(config: config)
    }

    @objc
    private func onExitBtnClick() {
        dismiss(animated: true)
    }

}

extension CustomFieldsTagsPanelViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.ctf.dequeueReusableCell(CustomFieldsTagsPanelContentCell.self, for: indexPath),
              let info = viewModel.cellInfo(indexPath: indexPath) else {
            assertionFailure()
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        cell.viewData = info
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.doToggle(at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        DetailCustomFields.tagsPanelCellHeight
    }
}
