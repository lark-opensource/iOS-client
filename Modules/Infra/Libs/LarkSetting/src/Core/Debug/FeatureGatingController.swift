//
//  FeatureGatingController.swift
//  LarkSetting
//
//  Created by Supeng on 2021/7/21.
//

#if ALPHA

import UIKit
import Foundation
import SnapKit
import LarkCombine
import LarkFoundation

// swiftlint:disable no_space_in_method_call
private typealias DataSourceType = [(String, Bool)]

final class FeatureGatingController: UIViewController {
    private let tableView = UITableView()

    private let userID: String
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    private let keyBoardEmitSubject = PassthroughSubject<Void, Never>()

    private var disposeBag = Set<AnyCancellable>()
    private var featureGatingDataSource = DataSourceType()
    private var currentDataSource = DataSourceType()
    private var filter: String = ""
    private lazy var searchBar = UISearchBar()

    init(chatterID: String) {
        userID = chatterID
        super.init(nibName: nil, bundle: nil)

        keyBoardEmitSubject
            .sink(receiveValue: { [weak self] _ in self?.reloadTableView() })
            .store(in: &disposeBag)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "close",
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(closeVC))
        title = "FeatureGating"

        searchBar.placeholder = "filter contents..."
        searchBar.delegate = self
        searchBar.returnKeyType = .search
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.snp_topMargin)
            $0.right.left.equalToSuperview()
            $0.height.equalTo(44)
        }

        updateFGDataSource()

        tableView.keyboardDismissMode = .onDrag
        tableView.tableHeaderView = nil
        tableView.tableFooterView = nil
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FeatureGatingCell.self, forCellReuseIdentifier: "FeatureGatingCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.right.left.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        reloadTableView()
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(popAlert))
        ]

        if #available(iOS 13.0, *) {
            searchBar.searchTextField.customize()
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
    }

    private func updateFGDataSource() {
        featureGatingDataSource = FeatureGatingStorage.debugFeatureDict(of: userID).sorted { $0.key < $1.key }
    }

    private func addTempFeatureGating(fg: String, isEnable: Bool) {
        FeatureGatingStorage.updateDebugFeatureGating(fg: fg, isEnable: isEnable, id: userID)
    }

    @objc
    private func popAlert() {
        let actionSheet = UIAlertController(title: "Add FG", message: "please enter FG key", preferredStyle: .alert)
        actionSheet.addTextField { [weak self] textField in textField.customize(with: self?.searchBar.text) }
        actionSheet.addAction(.init(title: "cancel", style: .destructive))
        actionSheet.addAction(.init(title: "confirm", style: .default, handler: { [weak self, weak actionSheet] _ in
            self?.addFG(with: actionSheet?.textFields?.first?.text ?? "")
        }))

        present(actionSheet, animated: true)
    }

    private func addFG(with text: String) {
        guard !text.isEmpty else { return }

        searchBar.text = text
        filter = text
        addTempFeatureGating(fg: text, isEnable: true)
        updateFGDataSource()
        reloadTableView()
    }

    @objc
    private func closeVC() { navigationController?.dismiss(animated: true) }

    private func reloadTableView() {
        let key = filter.lowercased()
        currentDataSource = filter.isEmpty ?
        featureGatingDataSource :
        featureGatingDataSource.compactMap { $0.0.lowercased().fuzzyMatch(key) ? $0 : nil }
        tableView.reloadData()
    }
}

extension FeatureGatingController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        filter = searchBar.text ?? ""
        reloadTableView()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filter = searchText
        keyBoardEmitSubject.send()
    }
}

extension FeatureGatingController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { currentDataSource.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let featureGatingCell = tableView.dequeueReusableCell(
            withIdentifier: "FeatureGatingCell",
            for: indexPath) as? FeatureGatingCell else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let currKey = currentDataSource[indexPath.row]
        featureGatingCell.titleLabel.text = currKey.0
        featureGatingCell.valueLabel.text = "\(currKey.1)"
        return featureGatingCell
    }
}

extension FeatureGatingController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        let currKey = currentDataSource[indexPath.row].0
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(.init(title: "true", style: .default, handler: { [weak self] _ in
            self?.addTempFeatureGating(fg: currKey, isEnable: true)
            self?.updateFGDataSource()
            self?.reloadTableView()
        }))
        actionSheet.addAction(.init(title: "false", style: .default, handler: { [weak self] _ in
            self?.addTempFeatureGating(fg: currKey, isEnable: false)
            self?.updateFGDataSource()
            self?.reloadTableView()
        }))
        actionSheet.addAction(.init(title: "cancel", style: .destructive))
        let cell = tableView.cellForRow(at: indexPath)
        actionSheet.popoverPresentationController?.sourceView = cell
        actionSheet.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero
        present(actionSheet, animated: true)
    }
}

private final class FeatureGatingCell: UITableViewCell {
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

#endif
