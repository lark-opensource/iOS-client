//
//  CBLangSelectViewController.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/9/21.
//
// https://bytedance.feishu.cn/docs/doccnQGwOHqVQIqrzgpYlBxvkCg#

import SKFoundation
import SKCommon
import SKBrowser
import SKResource
import LarkUIKit
import LarkExtensions
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon

protocol CBLangSelectViewControllerDelegate: AnyObject {
    func didSelectedNewLanguague(_ language: String)
    func willDismissLangSelectVC()
    
}

class CBLangSelectViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    private lazy var searchView: SearchUITextField = {
        let searchView = SearchUITextField()
        searchView.placeholder = BundleI18n.SKResource.Doc_Facade_Search
        searchView.clearButtonMode = .always
        searchView.isUserInteractionEnabled = true
        return searchView
    }()

    private lazy var languagesTableView: UITableView = {
        return createTableView()
    }()

    private lazy var headerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 0.5))
        view.backgroundColor = UDColor.lineBorderCard
        return view
    }()

    var context: CBLangSelectVCContext
    weak var delegate: CBLangSelectViewControllerDelegate?

    public required init(context: CBLangSelectVCContext, delegate: CBLangSelectViewControllerDelegate?) {
        self.context = context
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.SKResource.Doc_Block_ChangeCodeLanguage
        setupSubViews()
        layoutSubViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 滚动至指定的位置
        if let selectIndex = context.obtainSelectIndex() {
            let indexPath = IndexPath(row: selectIndex, section: 0)
            self.languagesTableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.willDismissLangSelectVC()
    }

    override func refreshLeftBarButtons() {
        super.refreshLeftBarButtons()
        let itemComponents: [SKBarButtonItem] = navigationBar.leadingBarButtonItems
        if !itemComponents.contains(closeButtonItem) {
            self.navigationBar.leadingBarButtonItems.removeAll()
            closeButtonItem.image = UDIcon.closeSmallOutlined
            self.navigationBar.leadingBarButtonItems.insert(closeButtonItem, at: 0)
        }
    }

    private func setupSubViews() {
        view.backgroundColor = UDColor.bgBody

        view.addSubview(searchView)
        searchView.addTarget(self, action: #selector(searchTextFieldEditingChanged(_:)), for: .editingChanged)
        searchView.lu.addTapGestureRecognizer(action: #selector(didTapSearchView), target: self, touchNumber: 1)

        view.addSubview(languagesTableView)
        
    }

    private func layoutSubViews() {
        searchView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(CBLangSelectVCContext.Const.searchViewOffset)
            make.right.equalToSuperview().offset(-CBLangSelectVCContext.Const.searchViewOffset)
            make.top.equalTo(navigationBar.snp.bottom)
            make.height.equalTo(CBLangSelectVCContext.Const.searchViewHeight)
        }

        languagesTableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(searchView.snp.bottom).offset(CBLangSelectVCContext.Const.searchViewOffset)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func createTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 54
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = UDColor.bgBody
        tableView.separatorColor = UDColor.lineBorderCard
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.layer.masksToBounds = true
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView()
        tableView.register(SelectLanguageTableViewCell.self, forCellReuseIdentifier: String(describing: SelectLanguageTableViewCell.self))
        return tableView
    }
// MARK: UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return context.obtainLanguages().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SelectLanguageTableViewCell.self)) as? SelectLanguageTableViewCell else {
            return UITableViewCell()
        }

        guard let languageInfo = context.ontainLanguageInfoWithIndex(indexPath.row) else {
            return UITableViewCell()
        }

        cell.set(title: languageInfo.name, isSelected: languageInfo.isSelect)
        cell.setTitleLabelColor(languageInfo.isEmpty ? UDColor.textCaption : UDColor.textTitle)
        cell.separatorInset.left = languageInfo.isLast ? 0.0 : 16.0 // cell统一设置separatorInset
        cell.backgroundColor = UDColor.bgBody
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let languageInfo = context.ontainLanguageInfoWithIndex(indexPath.row), !languageInfo.isSelect, !languageInfo.isEmpty else {
            return
        }
        delegate?.didSelectedNewLanguague(languageInfo.name)
        self.dismiss(animated: true, completion: nil)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.searchView.isFirstResponder {
            self.searchView.endEditing(false)
        }
    }

    @objc
    private func searchTextFieldEditingChanged(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            context.filterRelatedLanguagesWithKeyword(text) {
                self.languagesTableView.reloadData()
            }
        } else {
            context.resetFilterLanguages {
                self.languagesTableView.reloadData()
            }
        }
    }

    @objc
    private func didTapSearchView() {
        if self.searchView.isFirstResponder {
            self.searchView.endEditing(false)
        } else {
            self.searchView.becomeFirstResponder()
        }
    }
}
