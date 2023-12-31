//
//  DemoViewController.swift
//  FigmaKitDev
//
//  Created by Hayden Wang on 2021/9/1.
//

import Foundation
import UIKit
import FigmaKit

class DemoViewController: UIViewController {

    typealias DataSource = (title: String, vc: () -> UIViewController)

    var dataSource: [DataSource] = [
        ("Squircle", { SquircleViewController() }),
        ("Blur", { BlurViewController() }),
        ("Shadows", { ShadowViewController() }),
        ("Gradients", { GradientDemoViewController() }),
        ("InsetTable", { InsetTableViewController() }),
        ("Aurora", { AuroraDemoViewController() })
    ]

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.backgroundColor = .groupTableViewBackground
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FigmaKit"
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension DemoViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = dataSource[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension DemoViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = dataSource[indexPath.row].vc()
        navigationController?.pushViewController(vc, animated: true)
    }
}
