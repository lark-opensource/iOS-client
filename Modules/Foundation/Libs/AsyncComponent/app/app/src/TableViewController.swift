//
//  TableViewController.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/1/17.
//

import Foundation
import UIKit
import CommonCrypto
import AsyncComponent

class TableViewController: UIViewController {
    var style = ASComponentStyle()

    var datasource: [CellViewModel] = []

    var tableView: UITableView!
    var total = 0
    var lock = NSLock()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white

        setupTableView()

        var datasource: [CellViewModel] = []
        let start = CACurrentMediaTime()
        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            var arr: [CellViewModel] = []
            for i in 0..<2 {
                let m = Model(name: "\(i)", avatar: UIColor.random(), content: NSAttributedString(string: String.randomString(length: 300 + 300 * .random(in: 0...1))))
                let cvm = CellViewModel(model: m)
                cvm.tableView = self.tableView
                arr.append(cvm)
            }
            lock.lock()
            datasource.append(contentsOf: arr)
            total += 2
            lock.unlock()
            if total == 20 {
                print(CACurrentMediaTime() - start)
                DispatchQueue.main.async {
                    self.datasource = datasource
                    self.tableView.reloadData()
                }
            }
        }

        reload()
    }

    func setupTableView() {
        tableView = UITableView()
        view.addSubview(tableView)
        tableView.frame = self.view.bounds

        tableView.delegate = self
        tableView.dataSource = self
    }

    func reload() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            self.reload()
        }
    }
}

class TableViewCell: UITableViewCell {
    var view: UIView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.view = UIView(frame: .zero)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(view)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return datasource[indexPath.row].height()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

extension TableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let vm = self.datasource[indexPath.row]
        let node = vm.renderer
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TableViewCell.self)) as? TableViewCell ?? TableViewCell(style: .default, reuseIdentifier: String(describing: TableViewCell.self))
        node.bind(to: cell.view)
        node.render(cell.view)
        return cell
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}

extension String {
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...length - 1).map { _ in letters.randomElement()! })
    }
}
