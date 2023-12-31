//
//  InsetTableViewController.swift
//  FigmaKitDev
//
//  Created by Hayden Wang on 2021/9/1.
//

import Foundation
import UIKit
import FigmaKit

class InsetTableViewController: UIViewController {

    private lazy var tableView: InsetTableView = {
        return InsetTableView()
    }()

    private lazy var textField: UITextField = {
        let field = UITextField()
        field.backgroundColor = .groupTableViewBackground
        field.layer.cornerRadius = 10
        field.layer.masksToBounds = true
        field.placeholder = "  Search keyword"
        return field
    }()

    private lazy var topView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "InsetTableView"
        view.backgroundColor = .groupTableViewBackground
        if #available(iOS 13.0, *) {
            topView.backgroundColor = .systemBackground
        } else {
            topView.backgroundColor = .white
        }

        view.addSubview(tableView)
        view.addSubview(topView)
        topView.addSubview(textField)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        topView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topView.topAnchor.constraint(equalTo: view.topAnchor),
            topView.bottomAnchor.constraint(equalTo: textField.bottomAnchor, constant: 10),
            topView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            textField.leadingAnchor.constraint(equalTo: tableView.insetLayoutGuide.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: tableView.insetLayoutGuide.trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 36)
        ])
        NSLayoutConstraint.activate([
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: topView.bottomAnchor)
        ])

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "footer")
        tableView.contentInsetAdjustmentBehavior = .never
    }
}

extension InsetTableViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:     return 6
        case 1:     return 1
        case 2:     return 3
        default:    return 10
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = "TableViewCell \(indexPath.row)"
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Section \(section)"
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 46
    }
}
