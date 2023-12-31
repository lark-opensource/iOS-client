//
//  NetworkInfoDebugViewController.swift
//  PassportDebug
//
//  Created by ZhaoKejie on 2023/3/30.
//

import Foundation
import LarkUIKit
import LarkAccountInterface
import UniverseDesignToast

class NetworkInfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var defaultData: [NetworkInfoItem]

    var errorData: [NetworkInfoItem]

    var searchData: [NetworkInfoItem]

    var headerView: UIView = UIView()

    var searchView: SearchUITextField = SearchUITextField()

    var tableView: UITableView = UITableView()

    var isSearch: Bool = false

    var enableViewSuccList: Bool = false

    init(data: [NetworkInfoItem]) {
        self.defaultData = data
        self.errorData = []
        self.searchData = []
        for datum in defaultData {
            if !datum.isSuccess {
                errorData.append(datum)
            }
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBody

        self.view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            let navigationBarHeight = self.navigationController?.navigationBar.frame.height ?? 0
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(16)
            make.left.right.equalToSuperview()
            make.height.equalTo(20)
        }

        let titleView = UILabel()
        titleView.text = "网络请求信息列表"
        titleView.font = UIFont.systemFont(ofSize: 20)
        headerView.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let closeView = UIImageView(image: Resources.navigation_close_outlined)
        headerView.addSubview(closeView)
        closeView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(titleView.snp.centerY)
            make.height.width.equalTo(24)
        }
        closeView.lu.addTapGestureRecognizer(action: #selector(dismissVC), target: self, touchNumber: 1)

        let enableSuccButton = LKCheckbox(boxType: .single)
        enableSuccButton.delegate = self
        self.view.addSubview(enableSuccButton)
        enableSuccButton.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
        }
        let checkboxTip = UILabel()
        checkboxTip.text = "显示成功的请求"
        checkboxTip.font = UIFont.systemFont(ofSize: 12)
        self.view.addSubview(checkboxTip)
        checkboxTip.snp.makeConstraints { make in
            make.centerY.equalTo(enableSuccButton)
            make.left.equalTo(enableSuccButton.snp.right).offset(6)
        }

        self.view.addSubview(searchView)
        searchView.snp.makeConstraints { make in
            make.top.equalTo(enableSuccButton.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
        searchView.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)

        self.view.addSubview(self.tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchView.snp.bottom).offset(6)
            make.left.right.bottom.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NetworkInfoCell.self, forCellReuseIdentifier: NetworkInfoCell.description())

        let tapView: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(endEdit))
        self.view.addGestureRecognizer(tapView)
        tapView.cancelsTouchesInView = false
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        DispatchQueue.main.async {
            self.view.endEditing(true)
        }
        return super.touchesEnded(touches, with: event)
    }

    @objc
    func endEdit() {
        DispatchQueue.main.async {
            self.view.endEditing(true)
        }
    }

    @objc
    private func dismissVC() {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - search update

    @objc
    private func textFieldEditingChanged(_ textField: UITextField) {
        updateSearchData(text: textField.text)
        self.tableView.reloadData()
    }

    private func updateSearchData(text: String?) {
        if let text = self.searchView.text, !text.isEmpty {
            self.isSearch = true
            let dataList = enableViewSuccList ? defaultData : errorData
            searchData = []
            for datum in dataList {

                if datum.getPath().lowercased().contains(text.lowercased()) {
                    searchData.append(datum)
                }
            }
        } else {
            self.isSearch = false
            searchData = []
        }
    }

    // MARK: - tableView delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearch {
            return searchData.count
        }
        if enableViewSuccList {
            return defaultData.count
        } else {
            return errorData.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearch {
            let dataItem = self.searchData[indexPath.row]
            let cell = NetworkInfoCell()
            cell.setCell(isSucc: dataItem.isSuccess, host: dataItem.getHost(), path: dataItem.getPath(), time: dataItem.getTime())
            return cell
        }

        let dataList = enableViewSuccList ? defaultData : errorData
        let dataItem = dataList[indexPath.row]
        let cell = NetworkInfoCell()
        cell.setCell(isSucc: dataItem.isSuccess, host: dataItem.getHost(), path: dataItem.getPath(), time: dataItem.getTime())
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataList = enableViewSuccList ? defaultData : errorData
        tableView.deselectRow(at: indexPath, animated: true)
        UIPasteboard.general.string = dataList[indexPath.row].desc
        UDToast.showTips(with: "复制网络请求信息成功", on: self.view)
        endEdit()

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

}

//MARK: - checkbox
extension NetworkInfoViewController: LKCheckboxDelegate {
    func didTapLKCheckbox(_ checkbox: LarkUIKit.LKCheckbox) {
        checkbox.isSelected = !checkbox.isSelected
        self.enableViewSuccList = checkbox.isSelected
        updateSearchData(text: self.searchView.text)
        tableView.reloadData()
    }
}
