//
//  ZoomAlternativeHostViewController.swift
//  Calendar
//
//  Created by pluto on 2022/11/1.
//

import UIKit
import Foundation
import LarkContainer
import UniverseDesignToast
import LarkAlertController
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignEmpty
import RxCocoa
import RxSwift
import FigmaKit
import LarkUIKit

// 默认 有值显示ResultView，无值显示兜底页。 符合匹配规则才显示searchingView，
// 视图层级 placeholder - 0（最底层） resultView - 1  SearchingView - 2 （最上层）
// Navigation titleView 在每次选人或删除人时更新
final class ZoomAlternativeHostViewController: BaseUIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    let disposeBag = DisposeBag()
    let doneItem = LKBarButtonItem(title: I18n.Calendar_Common_Confirm, fontStyle: .medium)

    var onSaveCallBack: (([String]) -> Void)?

    private lazy var naviTitleView: ZoomHostNavigationTitleView = {
        let view = ZoomHostNavigationTitleView(title: I18n.Calendar_Zoom_AddAlternativeHosts)
        view.configNum(number: 0)
        return view
    }()

    private lazy var searchView: ZoomCommonUITextField = {
        let searchView = ZoomCommonUITextField()
        searchView.layer.cornerRadius = 6
        searchView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        searchView.attributedPlaceholder = NSAttributedString(string: I18n.Calendar_Ex_EnterYourMail, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.ud.textCaption])
        searchView.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        return searchView
    }()

    private let placeholderView: UDEmptyView = {
        let view = UDEmptyView(config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: I18n.Calendar_Zoom_NoAlterHostYet), type: .noContact))
        view.useCenterConstraints = true
        return view
    }()

    private lazy var searchingView: ZoomHostSearchingView = {
        let view = ZoomHostSearchingView()
        view.isHidden = true
        return view
    }()

    private lazy var searchResultView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ZoomHostSearchResultCell.self, forCellReuseIdentifier: "ZoomHostSearchResultCell")
        tableView.register(ZoomHostHeaderView.self, forHeaderFooterViewReuseIdentifier: String(describing: "ZoomHostHeaderView".self))
        return tableView
    }()

    private lazy var sepratorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBase
        return view
    }()

    private let viewModel: ZoomAlternativeHostViewModel

    init (viewModel: ZoomAlternativeHostViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        self.view.backgroundColor = UIColor.ud.bgFloat
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNaviItem()
        addBackItem()
        setupPlaceHolder()
        setupInputItem()
        addSeparator(with: 8)
        setupSearchResultView()
        setupSearchingView()
        refreshUI()
    }

    private func setupNaviItem() {
        self.navigationItem.titleView = naviTitleView
        doneItem.button.tintColor = UIColor.ud.primaryContentDefault
        navigationItem.rightBarButtonItem = doneItem
        doneItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.onSaveCallBack?(self.viewModel.selectedData)
                self.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)

    }

    private func setupInputItem() {
        view.addSubview(searchView)
        searchView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.height.equalTo(38)
            make.width.equalToSuperview().offset(-32)
            make.centerX.equalToSuperview()
        }
    }

    private func addSeparator(with height: CGFloat) {
        view.addSubview(sepratorLine)

        sepratorLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(height)
            make.top.equalTo(searchView.snp.bottom).offset(8)
        }
    }

    private func setupPlaceHolder() {
        let viewt = UIView()
        view.addSubview(viewt)
        viewt.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.top.equalToSuperview()
        }

        viewt.addSubview(placeholderView)
        placeholderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupSearchingView() {
        view.addSubview(searchingView)
        searchingView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(sepratorLine.snp.bottom)
        }

        // 选中邮箱联系人 刷新
        searchingView.selectCallback = { [weak self] addr in
            self?.viewModel.selectedData.append(addr)
            self?.searchView.text = nil
            self?.searchView.endEditing(true)
            self?.searchingView.isHidden = true
            self?.refreshUI()
        }
    }

    private func setupSearchResultView() {
        view.addSubview(searchResultView)
        searchResultView.addSubview(tableView)

        searchResultView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(sepratorLine.snp.bottom)
        }

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // 刷新 Navi + resultView
    private func refreshUI() {
        self.searchResultView.isHidden = self.viewModel.selectedData.isEmpty
        self.naviTitleView.configNum(number: self.viewModel.selectedData.count ?? 0)
        self.tableView.reloadData()
    }

    @objc
    private func textFieldEditingChanged(_ textField: UITextField) {
        searchingView.isHidden = !(textField.text?.isEmailAddress() ?? false)
        if textField.text?.isEmailAddress() ?? false {
            searchingView.updateEmailAddress(addr: textField.text ?? "")
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: ZoomHostHeaderView.self)) as? ZoomHostHeaderView else {
            return nil
        }
        header.setup(titleText: I18n.Calendar_Zoom_AlternativeHosts)
        return header
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.selectedData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let date = self.viewModel.selectedData[safeIndex: indexPath.row] {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ZoomHostSearchResultCell", for: indexPath) as? ZoomHostSearchResultCell else {
                return UITableViewCell()
            }
            cell.showTopLine = !(indexPath.row == 0)
            cell.configCellInfo(title: date)
            cell.deleteCallBack = { [weak self] in
                self?.viewModel.removeAddr(pos: indexPath.row)
            }
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 26
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension ZoomAlternativeHostViewController: ZoomAlternativeHostViewModelDelegate {
    func refreshData() {
            self.refreshUI()
    }
}

final class ZoomHostHeaderView: UITableViewHeaderFooterView {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(20)
            make.bottom.equalToSuperview()
        }
    }

    func setup(titleText: String) {
        titleLabel.text = titleText
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
