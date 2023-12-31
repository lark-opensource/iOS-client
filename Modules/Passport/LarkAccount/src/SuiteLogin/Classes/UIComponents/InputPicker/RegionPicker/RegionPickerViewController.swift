//
//  RegionPickerViewController.swift
//  LarkAccount
//
//  Created by au on 2022/8/2.
//

import LarkLocalizations
import LarkUIKit

// 国家/地区选择，参考 LarkUIKit MobileCodeSelect 国家码选择组件改造
class RegionPickerViewController: UIViewController {
    
    typealias RegionSection = (String, [Region])
    
    private var tableView: UITableView = UITableView(frame: .zero, style: .grouped)
    private var searchView: SearchUITextField = SearchUITextField()
    private var headerView: UIView = UIView()
    
    private var isSearch: Bool = false
    
    private var regionProvider: RegionProvider
    private var defaultSections = [RegionSection]()
    private var searchResultList = [Region]()
    
    private var didSelectBlock: ((Region) -> Void)?
    
    init(
        regionList: [Region],
        topRegionList: [Region],
        didSelectBlock: ((Region) -> Void)?
    ) {
        self.regionProvider = RegionProvider(regionList: regionList, topRegionList: topRegionList)
        self.didSelectBlock = didSelectBlock
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        
        view.backgroundColor = UIColor.ud.bgBody
        
        view.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.text = I18N.Lark_Shared_LarkNewWebSignUp_OrganizationInfo_Title
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(16)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }
        
        let closeImageView = UIImageView(image: Resources.navigation_close_outlined)
        headerView.addSubview(closeImageView)
        closeImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.height.width.equalTo(24)
        }
        closeImageView.lu.addTapGestureRecognizer(action: #selector(close), target: self, touchNumber: 1)
        
        view.addSubview(searchView)
        searchView.placeholder = I18N.Lark_Login_PlaceholderOfSearchInput
        searchView.clearButtonMode = .always
        searchView.isUserInteractionEnabled = true
        searchView.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        searchView.lu.addTapGestureRecognizer(action: #selector(tapSearchView), target: self, touchNumber: 1)
        searchView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            make.height.equalTo(38)
            make.left.right.equalToSuperview().inset(16)
        }
        
        let messageLabel = UILabel()
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.text = BundleI18n.suiteLogin.Lark_Login_TitleOfCountryCode
        messageLabel.backgroundColor = UIColor.clear
        messageLabel.textColor = UIColor.ud.N500
        view.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(38)
            make.top.equalTo(searchView.snp.bottom).offset(8)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(messageLabel.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.ud.N500
        tableView.separatorStyle = .none
        tableView.rowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        tableView.register(RegionPickerTableViewCell.self, forCellReuseIdentifier: RegionPickerTableViewCell.lu.reuseIdentifier)
        tableView.register(RegionPickerHeaderView.self, forHeaderFooterViewReuseIdentifier: String(describing: RegionPickerHeaderView.self))
    }
    
    private func loadData() {
        if !regionProvider.topRegionList.isEmpty {
            defaultSections.append(("", regionProvider.topRegionList))
        }
        
        let regionList = regionProvider.regionList
        regionProvider.indexList.forEach { index in
            let indexedRegions = regionList.filter { $0.index == index }
            defaultSections.append((index, indexedRegions))
        }
    }
    
    @objc
    private func tapSearchView() {
        if searchView.isFirstResponder {
            searchView.endEditing(false)
        } else {
            searchView.becomeFirstResponder()
        }
    }
    
    @objc
    private func textFieldEditingChanged(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            isSearch = true
            searchResultList = regionProvider.search(text)
        } else {
            isSearch = false
        }
        tableView.reloadData()
    }
    
    @objc
    private func close() {
        dismiss(animated: true, completion: nil)
    }
}

extension RegionPickerViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        
        let result: Region
        if !isSearch {
            result = defaultSections[indexPath.section].1[indexPath.row]
        } else {
            result = searchResultList[indexPath.row]
        }
        
        didSelectBlock?(result)
        close()
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        if !isSearch {
            return defaultSections.count
        } else {
            return 1
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isSearch {
            return defaultSections[section].1.count
        } else {
            return searchResultList.count
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RegionPickerTableViewCell.lu.reuseIdentifier, for: indexPath) as? RegionPickerTableViewCell else {
            return UITableViewCell()
        }
        if !isSearch {
            let region = defaultSections[indexPath.section].1[indexPath.row]
            cell.setCell(name: region.name)
            cell.bottomSeparator.isHidden = (indexPath.row == defaultSections[indexPath.section].1.count - 1)
        } else {
            let data = searchResultList[indexPath.row]
            cell.setCell(name: data.name)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !isSearch {
            let text = defaultSections[section].0
            if text.isEmpty {
                return nil
            }
            guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: RegionPickerHeaderView.self)) as? RegionPickerHeaderView else { return nil }
            header.name = text
            return header
        } else {
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if !isSearch, !defaultSections[section].0.isEmpty {
            return 36
        } else {
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if !isSearch, !regionProvider.indexList.isEmpty {
            return regionProvider.indexList
        } else {
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index + 1
    }
}
