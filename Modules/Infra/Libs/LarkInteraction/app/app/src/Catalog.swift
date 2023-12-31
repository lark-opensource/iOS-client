//
//  Catalog.swift
//  LarkInteractionDev
//
//  Created by Saafo on 2021/10/8.
//

import Foundation
import UIKit
import SnapKit

class Catalog: UIViewController {
    let table = UITableView()

    let demoVC: [UIViewController.Type] = [
        ViewController.self,
        PointerDemo.self,
        ContextMenuDemo.self
    ]

    private let cellReuseIdentifier = "UITableViewCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.title = "LarkInteraction Demos"

        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        view.addSubview(table)
        table.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // Debug
        table.delegate?.tableView?(table, didSelectRowAt: IndexPath(row: 1, section: 0))
    }
}

extension Catalog: UITableViewDataSource, UITableViewDelegate {
    // UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        demoVC.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        let type = demoVC[indexPath.row]
        cell.textLabel?.text = type.description()
        return cell
    }

    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = demoVC[indexPath.row].init()
        navigationController?.pushViewController(vc, animated: true)
    }
}
