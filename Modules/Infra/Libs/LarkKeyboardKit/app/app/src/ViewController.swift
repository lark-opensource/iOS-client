//
//  ViewController.swift
//  KeyboardKitDev
//
//  Created by 李晨 on 2019/10/17.
//

import Foundation
import UIKit
import LarkKeyboardKit
import RxSwift
import SnapKit

class ViewController: UIViewController {

    struct DatasourceItem {
        var title: String
        var block: () -> Void
    }

    var tableView: UITableView!

    var datasource: [DatasourceItem] = []

    var pageTitle: String {
        return "KeyboardKit Demos"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white

        self.title = self.pageTitle

        KeyboardKit.shared.start()

        setupTableView()
        setupDatasource()
    }

    func setupTableView() {
        tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 68
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        self.view.addSubview(tableView)
        tableView.frame = self.view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleLeftMargin, .flexibleTopMargin]
    }

    // 以后所有的demo都加在这里了
    func setupDatasource() {
        let vc1 = DatasourceItem(title: "push") {
            let vc = ViewController1()
            self.navigationController?.pushViewController(vc, animated: true)
        }

        let vc2 = DatasourceItem(title: "present") {
            let vc = ViewController1()
            vc.modalPresentationStyle = .formSheet
            self.present(vc, animated: true, completion: nil)
        }

        datasource = [
            vc1,
            vc2
        ]
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        datasource[indexPath.row].block()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self),
                                                 for: indexPath)
        cell.textLabel?.text = datasource[indexPath.row].title
        return cell
    }
}

class ViewController1: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white

        _ = KeyboardKit.shared.keyboardEventChange.subscribe(onNext: { (event) in
            print("type: \(event.type), keyboard frame \(event.keyboard.frame) \n")
        })

        let textfield = UITextField()
        self.view.addSubview(textfield)
        textfield.backgroundColor = UIColor.red
        textfield.frame = CGRect(x: 0, y: 100, width: UIScreen.main.bounds.width, height: 44)

        let textfield2 = UITextField()
        self.view.addSubview(textfield2)
        textfield2.backgroundColor = UIColor.red
        textfield2.frame = CGRect(x: 0, y: 180, width: UIScreen.main.bounds.width, height: 44)

        let btn = UIButton()
        btn.addTarget(self, action: #selector(clickBtn1(sender:)), for: .touchUpInside)
        self.view.addSubview(btn)
        btn.setTitle("Btn 1", for: .normal)
        btn.backgroundColor = UIColor.blue

        btn.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.height.equalTo(44)
            maker.bottom.equalTo(
                self.view.lkKeyboardLayoutGuide
                    .update(respectSafeArea: true)
                    .snp.top
            )
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.view.endEditing(true)
    }

    @objc
    func clickBtn1(sender: UIButton) {
        self.view.endEditing(true)

//        let alert = UIAlertController(title: "123", message: "123", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "123", style: .cancel, handler: nil))
//        self.present(alert, animated: true, completion: nil)

//        _ = sender.becomeFirstResponder()
    }
}
