//
//  ViewController.swift
//  LarkFontDev
//
//  Created by 白镜吾 on 2023/3/9.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    lazy var dataSource: [(String, UIViewController)] = [
        ("FontListViewController", FontListViewController()),
        ("MonoViewController", MonoViewController()),
        ("CTFontAndUIFontVC", CTFontAndUIFontVC()),
        ("DemoVC", DemoVC())
    ]

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.width.top.equalTo(self.view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else { return UITableViewCell() }
        cell.textLabel?.text = dataSource[indexPath.row].0
        cell.selectionStyle = .none
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = dataSource[indexPath.row].1
        self.present(vc, animated: true)
    }
}
