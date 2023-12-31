//
//  MobileCodeSelectViewController.swift
//  LarkLogin
//
//  Created by 姚启灏 on 2019/1/8.
//

import Foundation
import UIKit
import LarkLocalizations

public final class MobileCodeSelectViewController: UIViewController {
    fileprivate var tableView: UITableView = UITableView(frame: CGRect.zero, style: .grouped)

    typealias MobileCodeSection = (String, [MobileCode])

    private let mobileCodeLocale: Lang
    private let mobileCodeProvider: MobileCodeProvider
    private var confirmBlock: ((MobileCode) -> Void)?

    private var searchView: SearchUITextField = SearchUITextField()
    private var headerView: UIView = UIView()

    private var isSearch: Bool = false
    private var defaultSections: [MobileCodeSection] = []
    private var searchMobileCodes: [MobileCode] = []

    public init(
        mobileCodeLocale: Lang,
        topCountryList: [String],
        blackCountryList: [String],
        confirmBlock: ((MobileCode) -> Void)?
    ) {
        self.mobileCodeLocale = mobileCodeLocale
        self.mobileCodeProvider = MobileCodeProvider(
            mobileCodeLocale: mobileCodeLocale,
            topCountryList: topCountryList,
            blackCountryList: blackCountryList
        )
        self.confirmBlock = confirmBlock
        super.init(nibName: nil, bundle: nil)
    }

    // 当 allowCountryList 不为空时，仅展示 allowCountryList 内的国家代码
    public init(
        mobileCodeLocale: Lang,
        topCountryList: [String],
        allowCountryList: [String],
        blockCountryList: [String],
        confirmBlock: ((MobileCode) -> Void)?
    ) {
        self.mobileCodeLocale = mobileCodeLocale
        self.mobileCodeProvider = MobileCodeProvider(
            mobileCodeLocale: mobileCodeLocale,
            topCountryList: topCountryList,
            allowCountryList: allowCountryList,
            blockCountryList: blockCountryList
        )
        self.confirmBlock = confirmBlock
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.loadData()

        self.view.backgroundColor = UIColor.ud.bgBody

        self.view.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }

        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.text = BundleI18n.LarkUIKit.Lark_Login_TitleOfCountryCode
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
        closeImageView.lu.addTapGestureRecognizer(action: #selector(dismissVC), target: self, touchNumber: 1)

        self.view.addSubview(searchView)
        searchView.placeholder = BundleI18n.LarkUIKit.Lark_Login_PlaceholderOfSearchInput
        searchView.clearButtonMode = .always
        searchView.isUserInteractionEnabled = true
        searchView.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        searchView.lu.addTapGestureRecognizer(action: #selector(tapSearchView), target: self, touchNumber: 1)
        searchView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            make.height.equalTo(36)
            make.left.equalToSuperview().offset(11)
            make.right.equalToSuperview().offset(-13)
        }

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(searchView.snp.bottom).offset(6)
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
        let identifier = String(describing: MobileCodeSelectCell.self)
        tableView.register(MobileCodeSelectCell.self, forCellReuseIdentifier: identifier)
    }

    private func loadData() {
        let mobileCodes = mobileCodeProvider.getMobileCodes()
        var topMobileCode: [MobileCode] = []
        mobileCodeProvider.getTopList().forEach { (key) in
            topMobileCode.append(contentsOf: mobileCodes.filter({ $0.key == key }))
        }
        self.defaultSections.append(("", topMobileCode))

        mobileCodeProvider.getIndexList().forEach { [weak self] (index) in
            let indexMobileCode: [MobileCode] = mobileCodes.filter({ $0.index == index })
            self?.defaultSections.append((index, indexMobileCode))
        }
    }

    @objc
    private func tapSearchView() {
        if self.searchView.isFirstResponder {
            self.searchView.endEditing(false)
        } else {
            self.searchView.becomeFirstResponder()
        }
    }

    @objc
    private func textFieldEditingChanged(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            self.isSearch = true
            self.searchMobileCodes = mobileCodeProvider.searcMobileCode(searchText: text)
        } else {
            self.isSearch = false
        }
        self.tableView.reloadData()
    }

    @objc
    private func dismissVC() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension MobileCodeSelectViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        var mobileCode: MobileCode
        if !isSearch {
            mobileCode = self.defaultSections[indexPath.section].1[indexPath.row]
        } else {
            mobileCode = self.searchMobileCodes[indexPath.row]
        }

        self.confirmBlock?(mobileCode)
        self.dismissVC()
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        if !isSearch {
            return self.defaultSections.count
        } else {
            return 1
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isSearch {
            return self.defaultSections[section].1.count
        } else {
            return self.searchMobileCodes.count
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MobileCodeSelectCell()
        if !isSearch {
            let data = self.defaultSections[indexPath.section].1[indexPath.row]
            cell.setCell(name: data.name, code: data.code)
            if indexPath.row == self.defaultSections[indexPath.section].1.count - 1 {
                cell.bottomSeperator.isHidden = true
            }
        } else {
            let data = searchMobileCodes[indexPath.row]
            cell.setCell(name: data.name, code: data.code)
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !isSearch {
            let text = self.defaultSections[section].0
            if text.isEmpty {
                return nil
            }

            let headerView = UIView()
            let nameLabel = UILabel()

            headerView.addSubview(nameLabel)
            headerView.backgroundColor = UIColor.ud.bgBodyOverlay// N50
            nameLabel.font = UIFont.systemFont(ofSize: 14)
            nameLabel.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
            }

            nameLabel.text = text
            nameLabel.textColor = UIColor.ud.N500

            return headerView
        } else {
            return UIView()
        }
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if !isSearch, !self.defaultSections[section].0.isEmpty {
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
        if !isSearch, !mobileCodeProvider.getIndexList().isEmpty {
            return mobileCodeProvider.getIndexList()
        } else {
            return nil
        }
    }

    public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index + 1
    }
}
