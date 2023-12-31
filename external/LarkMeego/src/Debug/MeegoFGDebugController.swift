//
//  MeegoFGDebugController.swift
//  LarkMeego
//
//  Created by zhenning on 2022/10/03.
//  Copyright © 2022 shizhengyu All rights reserved.
//

import Foundation
import SnapKit
import LarkContainer
import LarkMeegoNetClient
import LarkFlutterContainer
import LarkUIKit
import RoundedHUD
import LarkMeegoLogger

class MeegoFGDebugController: UIViewController {
    static let FGAppName: String = "Meego"

    @Provider private var dependency: MeegoFlutterDependency
    private var featureGatingDataSource = [(String, Bool)]()
    private var featureGatingDataKeys: [String] {
        featureGatingDataSource.map {$0.0}
    }
    private var currentDataSource = [(String, Bool)]()
    private var filter: String = ""

    private let tableView = UITableView()
    private lazy var searchTextField = UISearchBar()

    public override func viewDidLoad() {
        super.viewDidLoad()

        title = "Meego FeatureGating Debug"
        view.addSubview(tableView)

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(popAlert))
        ]

        searchTextField.placeholder = "filter contents..."
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        view.addSubview(searchTextField)
        searchTextField.snp.makeConstraints {
            $0.top.equalTo(view.snp_topMargin)
            $0.right.left.equalToSuperview()
            $0.height.equalTo(44)
        }

        tableView.keyboardDismissMode = .onDrag
        tableView.tableHeaderView = nil
        tableView.tableFooterView = nil
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MGFeatureGatingCell.self, forCellReuseIdentifier: String(describing: MGFeatureGatingCell.self))
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom)
            $0.right.left.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        if #available(iOS 13.0, *) {
           view.backgroundColor = .systemBackground
        } else {
           view.backgroundColor = .white
        }

        // fetch
        fetchFeatureGating()
    }

    private func reloadTableView() {
        var newDataSource: [(String, Bool)] = []

        if filter.isEmpty {
            newDataSource = featureGatingDataSource
        } else {
            var array = Array(filter) as [Character]
            for index in array.indices.reversed() {
                array.insert(Character("*"), at: index)
            }
            array.append(Character("*"))

            let preicate = NSPredicate(format: "SELF LIKE[c] %@", String(array))
            newDataSource = featureGatingDataSource.filter { preicate.evaluate(with: $0.0.lowercased()) }
        }

        currentDataSource = newDataSource

        if Thread.current.isMainThread {
            self.tableView.reloadData()
        } else {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    func fetchFeatureGating() {
        func innerFunc(result: Result<Response<MGFeatureGatingResponse>, Error>) {
            switch result {
            case .success(let response):
                featureGatingDataSource = response.data?.fgJsonInfos
                    .reduce(into: [(String, Bool)]()) { (result, item) in
                        result.append((item.key, item.isHit))
                    } ?? []
                self.reloadTableView()
                MeegoLogger.debug("[MeegoFGDebugController] : fgKeys: \(fgKeys) response: \(response)")
                break
            case .failure(let error):
                RoundedHUD.showFailure(
                    with: "fetchFeatureGating Failed! error: \(error)",
                    on: self.view
                )
                MeegoLogger.debug("[MeegoFGDebugController] : fgKeys: \(fgKeys) error: \(error)")
                break
            }
        }

        let fgKeys = MeegoFeatureGatingManager.shared.registedFGKeys
        // TODO: 后续支持 project 维度查询
        let fgParams = FetchFeatureGatingRequestParams(keys: fgKeys,
                                                       appName: MeegoFGDebugController.FGAppName,
                                                       meegoProjectKey: "",
                                                       meegoUserKey: dependency.currentUserId,
                                                       meegoTenantKey: "")
        MeegoFeatureGatingManager.shared.fetchFeatureGating(with: fgParams, completionHandler: { [weak self] result in
            DispatchQueue.main.async {
                innerFunc(result: result)
            }
        })
    }

    private func addTempFeatureGating(fg: String, isEnable: Bool) {
        let tempFeatureGating: (String, Bool) = (fg, isEnable)
        if !featureGatingDataKeys.contains(fg) {
            featureGatingDataSource.append(tempFeatureGating)
        }
    }

    @objc
    private func popAlert() {
        let actionSheet = UIAlertController(title: "Add FG", message: "please enter FG key", preferredStyle: .alert)
        actionSheet.addTextField { [weak self] textField in textField.text = self?.searchTextField.text }
        actionSheet.addAction(.init(title: "cancel", style: .destructive))
        actionSheet.addAction(.init(title: "confirm", style: .default, handler: { [weak self, weak actionSheet] _ in
            self?.addFG(with: actionSheet?.textFields?.first?.text ?? "")
        }))

        present(actionSheet, animated: true)
    }

    private func addFG(with text: String) {
        guard !text.isEmpty else { return }

        searchTextField.text = text
        filter = text
        addTempFeatureGating(fg: text, isEnable: true)
        reloadTableView()
    }
}

// MARK: - UITableViewDataSource UITableViewDelegate

extension MeegoFGDebugController: UITableViewDataSource {
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { currentDataSource.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let featureGatingCell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: MGFeatureGatingCell.self),
            for: indexPath) as? MGFeatureGatingCell else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let currKey = currentDataSource[indexPath.row]
        featureGatingCell.titleLabel.text = currKey.0
        featureGatingCell.valueLabel.text = "\(currKey.1)"
        return featureGatingCell
    }
}

extension MeegoFGDebugController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        let currKey = currentDataSource[indexPath.row].0
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(.init(title: "true", style: .default, handler: { [weak self] _ in
            self?.addTempFeatureGating(fg: currKey, isEnable: true)
            self?.reloadTableView()
        }))
        actionSheet.addAction(.init(title: "false", style: .default, handler: { [weak self] _ in
            self?.addTempFeatureGating(fg: currKey, isEnable: false)
            self?.reloadTableView()
        }))
        actionSheet.addAction(.init(title: "cancel", style: .destructive))
        let cell = tableView.cellForRow(at: indexPath)
        actionSheet.popoverPresentationController?.sourceView = cell
        actionSheet.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero
        present(actionSheet, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension MeegoFGDebugController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        filter = searchBar.text ?? ""
        reloadTableView()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filter = searchText
        reloadTableView()
    }
}

// MARK: - MGFeatureGatingCell

private class MGFeatureGatingCell: UITableViewCell {
    fileprivate let titleLabel = UILabel()
    fileprivate let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator

        valueLabel.font = .systemFont(ofSize: 15)
        contentView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { $0.right.centerY.equalToSuperview() }
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(16)
            $0.top.equalTo(5)
            $0.right.lessThanOrEqualTo(valueLabel.snp.left).offset(5)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
