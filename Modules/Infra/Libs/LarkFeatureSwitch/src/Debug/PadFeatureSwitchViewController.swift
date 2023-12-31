//
//  PadFeatureSwitchViewController.swift
//  LarkApp
//
//  Created by Chang Rong on 2019/9/3.
//

import Foundation
import UIKit

enum FeatureValue: String, CaseIterable {
    case `default`
    case on
    case off
    case downgraded
}

public final class PadFeatureSwitchViewController: UIViewController, UITableViewDelegate,
    UITableViewDataSource, UISearchBarDelegate {
    private static let reuseKey = "PadFeatureSwitchTableViewCell"

    private let tableView = UITableView()
    private let searchTextField = UISearchBar()
    private var filter: String = ""
    private var featureSetCache: [Feature] = []

    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "iPadFeatureSwitch - 仅在iPad生效"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(clickCancelBtn)
        )
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(clearLocalPadFeatureSwitch)
        )

        self.navigationController?.navigationBar.isTranslucent = false

        searchTextField.placeholder = "过滤内容..."
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        self.view.addSubview(searchTextField)

        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.tableHeaderView = searchTextField
        self.tableView.tableFooterView = nil
        self.tableView.estimatedRowHeight = 40
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(PadFeatureSwitchTableViewCell.self, forCellReuseIdentifier: Self.reuseKey)

        self.view.addSubview(self.tableView)
        self.reloadTableView(filter: self.filter)

        self.updateViewSize()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            self?.updateViewSize()
        }
    }

    func updateViewSize() {
        var frame = self.view.bounds
        frame.size.height = 44
        searchTextField.frame = frame

        tableView.frame = view.bounds
    }

    @objc
    func clickCancelBtn() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    private func clearLocalPadFeatureSwitch() {
        FeatureSwitchDebug.clear()
    }

    private func reloadTableView(filter: String) {
        self.featureSetCache = []
        for value in 0 ..< Feature.allCases.count {
            let feature = Feature(rawValue: value)!
            if !filter.isEmpty && !"\(feature)".lowercased().contains(filter.lowercased()) {
                continue
            }
            self.featureSetCache.append(feature)
        }
        self.tableView.reloadData()
    }

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filter = searchText
        self.reloadTableView(filter: self.filter)
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        self.filter = searchBar.text ?? ""
        self.reloadTableView(filter: self.filter)
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        let feature = self.featureSetCache[indexPath.row]

        let actionSheet = UIAlertController(
            title: "设置完成，需要手动重启后生效",
            message: "",
            preferredStyle: .actionSheet
        )

        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = cell
            popoverController.sourceRect = cell.bounds
        }

        func makeAction(_ value: FeatureValue) -> UIAlertAction {
            UIAlertAction(title: value.rawValue, style: .default) { [weak self] _ in
                FeatureSwitchDebug.write(feature: feature, value: value.rawValue)
                self?.reloadTableView(filter: self?.filter ?? "")
            }
        }

        // add value case
        FeatureValue.allCases.forEach { actionSheet.addAction(makeAction($0)) }

        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))

        self.present(actionSheet, animated: true, completion: nil)
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.featureSetCache.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.reuseKey,
            for: indexPath
        ) as? PadFeatureSwitchTableViewCell else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let feature = self.featureSetCache[indexPath.row]
        cell.textLabel?.text = "\(feature)"
        cell.detailTextLabel?.text = "\(getFeatureSwitchValue(feature: feature)?.rawValue ?? "")"

        return cell
    }

    func getFeatureSwitchValue(feature: Feature) -> FeatureValue? {
        var value: FeatureValue?
        Feature.on(feature).apply(on: {
            value = .on
        }, off: {
            value = .off
        }, downgraded: {
            value = .downgraded
        })
        return value
    }
}
