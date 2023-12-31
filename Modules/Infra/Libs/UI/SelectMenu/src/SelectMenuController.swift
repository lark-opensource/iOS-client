//
//  SelectMenuController.swift
//  LarkDynamic
//
//  Created by Songwen Ding on 2019/7/18.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignEmpty

public final class SelectMenuController: BaseUIViewController, UITableViewDelegate {
    
    public var selectConfirm: (([SelectMenuViewModel.Item]) -> Void)?

    private let viewModel: SelectMenuViewModel
    
    private lazy var navBar: UIView = {
        let container = UIView()
        container.backgroundColor = UIColor.ud.bgBody
        return container
    }()

    private lazy var textFieldWrap: SearchUITextFieldWrapperView = {
        let textFieldWrap = SearchUITextFieldWrapperView()
        textFieldWrap.searchUITextField.placeholder = BundleI18n.SelectMenu.Lark_Legacy_MsgCardSearch
        textFieldWrap.searchUITextField.returnKeyType = .search
        textFieldWrap.searchUITextField.enablesReturnKeyAutomatically = true
        textFieldWrap.searchUITextField.addTarget(
            self, action: #selector(searchTextFieldEditChanged),
            for: .editingChanged)
        return textFieldWrap
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self.viewModel
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.rowHeight = 52
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(SelectMenuTableViewCell.self, forCellReuseIdentifier: "Cell")
        return tableView
    }()

    private lazy var emptyDetailLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    private lazy var emptyView: UIView = {
        let view = UIView()
        let imageView = UIImageView(image: UDEmptyType.noSearchResult.defaultImage())
        view.addSubview(imageView)
        view.addSubview(self.emptyDetailLabel)
        imageView.snp.makeConstraints({ (make) in
            make.width.height.equalTo(125)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(123)
        })
        self.emptyDetailLabel.snp.makeConstraints({ (make) in
            make.centerX.equalToSuperview()
            make.left.equalTo(imageView)
            make.top.equalTo(imageView.snp.bottom).offset(10)
        })
        return view
    }()

    public init(items: [SelectMenuViewModel.Item], selectedValues: [String]? = nil, isMulti: Bool = false) {
        self.viewModel = SelectMenuViewModel(items: items, selectedValues: selectedValues, isMulti: isMulti)
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        var topConstraintItem = view.snp.top
        if viewModel.isMulti {
            setupNaviBar()
            topConstraintItem = navBar.snp.bottom
        }
        view.addSubview(textFieldWrap)
        textFieldWrap.snp.makeConstraints { (make) in
            make.top.equalTo(topConstraintItem)
            make.height.equalTo(50)
            make.leading.trailing.equalToSuperview()
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(textFieldWrap.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let indexPath = viewModel.firstSelectIndexPath {
            tableView.scrollToRow(at: indexPath,
                                  at: .middle,
                                  animated: true)
        }
    }

    @objc
    private func searchTextFieldEditChanged() {
        let text = self.textFieldWrap.searchUITextField.text ?? ""
        self.viewModel.filter(keyWord: text) { [weak self] (isEmpty) in
            if isEmpty {
                let wholeText = BundleI18n.SelectMenu.Lark_Legacy_SearchNoResult(text)
                let template = BundleI18n.SelectMenu.__Lark_Legacy_SearchNoResult as NSString

                let attributedString = NSMutableAttributedString(string: wholeText)
                attributedString.addAttribute(.foregroundColor,
                                              value: UIColor.ud.N500,
                                              range: NSRange(location: 0, length: attributedString.length))

                let start = template.range(of: "{{").location
                if start != NSNotFound {
                    attributedString.addAttribute(.foregroundColor,
                                                  value: UIColor.ud.colorfulBlue,
                                                  range: NSRange(location: start, length: (text as NSString).length))
                }
                self?.emptyDetailLabel.attributedText = attributedString
                self?.tableView.tableFooterView = self?.emptyView
            } else {
                self?.tableView.tableFooterView = UIView()
            }
            self?.tableView.reloadData()
        }
    }
    
    private func setupNaviBar() {
        view.addSubview(navBar)
        navBar.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(56)
        }
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = BundleI18n.SelectMenu.Lark_Legacy_MsgCardSelect
        navBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let closeBtn = UIButton()
        closeBtn.setImage(BundleResources.SelectMenu.navigation_close_outlined, for: .normal)
        closeBtn.addTarget(self, action: #selector(dismissBtnTapped), for: .touchUpInside)
        navBar.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        let confirmBtn = UIButton()
        confirmBtn.setTitle(BundleI18n.SelectMenu.Lark_Legacy_Confirm, for: .normal)
        confirmBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        confirmBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        confirmBtn.addTarget(self, action: #selector(confirmBtnTapped), for: .touchUpInside)
        navBar.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    @objc
    private func dismissBtnTapped() {
        dismiss(animated: true)
    }
    
    @objc
    private func confirmBtnTapped() {
        selectConfirm?(self.viewModel.selectedItems)
        dismiss(animated: true)
    }

    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let selectCell = tableView.cellForRow(at: indexPath) as? SelectMenuTableViewCell,
              let selectItem = viewModel.item(index: indexPath.row) else {
            return
        }
        
        if viewModel.isMulti {
            selectCell.isChosen = !selectCell.isChosen
            viewModel.selectItem(select: selectCell.isChosen, item: selectItem)
        } else {
            if let selectedIndex = viewModel.singlePreSelectIndex, 
               selectedIndex != indexPath,
               let lastSelectCell = tableView.cellForRow(at: selectedIndex) as? SelectMenuTableViewCell {
                lastSelectCell.isChosen = false
            }
            selectCell.isChosen = true
            selectConfirm?([selectItem])
            dismiss(animated: true)
        }
    }
}
