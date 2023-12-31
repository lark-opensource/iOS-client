//
//  ViewController.swift
//  PresentViewControllerDev
//
//  Created by 李晨 on 2019/3/17.
//

import Foundation
import UIKit
import SnapKit
import PresentContainerController

class ViewController: UIViewController {

    var tableView: UITableView!

    struct DatasourceItem {
        var title: String
        var action: () -> Void
    }

    var datasource: [DatasourceItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
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
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func setupDatasource() {
        let present1 = DatasourceItem(title: "Present from top") {
            let subView = SubViewController()
            let wrapper = PresentWrapperController(
                subView: subView,
                subViewSize: CGSize(width: UIScreen.main.bounds.width, height: 200))
            let container = PresentContainerController(subViewController: wrapper, animate: PresentFromTop())
            self.present(container, animated: false, completion: nil)

            container.clickDismissEnable = false
            container.maskViewColor = UIColor.red.withAlphaComponent(0.1)
        }

        let present2 = DatasourceItem(title: "Present from bottom") {
            let subView = SubViewController()
            let wrapper = PresentWrapperController(
                subView: subView,
                subViewSize: CGSize(width: UIScreen.main.bounds.width, height: 200))
            let container = PresentContainerController(subViewController: wrapper, animate: PresentFromBottom())
            self.present(container, animated: false, completion: nil)
        }

        let present3 = DatasourceItem(title: "Present from left") {
            let subView = SubViewController()
            let wrapper = PresentWrapperController(
                subView: subView,
                subViewSize: CGSize(width: 200, height: UIScreen.main.bounds.height))
            let container = PresentContainerController(subViewController: wrapper, animate: PresentFromLeft())
            self.present(container, animated: false, completion: nil)
        }

        let present4 = DatasourceItem(title: "Present from right") {
            let subView = SubViewController()
            let wrapper = PresentWrapperController(
                subView: subView,
                subViewSize: CGSize(width: 200, height: UIScreen.main.bounds.height))
            let container = PresentContainerController(subViewController: wrapper, animate: PresentFromRight())
            self.present(container, animated: false, completion: nil)
        }

        let present5 = DatasourceItem(title: "Present from center") {
            let subView = SubViewController()
            let wrapper = PresentWrapperController(
                subView: subView,
                subViewSize: CGSize(width: 200, height: 200))
            let container = PresentContainerController(subViewController: wrapper, animate: PresentFromCenter())
            self.present(container, animated: false, completion: nil)
        }

        let add1 = DatasourceItem(title: "Add subview from top") {
            let subView = Sub2ViewController()
            let container = PresentContainerController(subViewController: subView, animate: PresentFromTop())
            container.show(in: self)
        }

        let add2 = DatasourceItem(title: "Add subview from bottom") {
            let subView = Sub2ViewController()
            let container = PresentContainerController(subViewController: subView, animate: PresentFromBottom())
            container.show(in: self)
        }

        let add3 = DatasourceItem(title: "Add subview from left") {
            let subView = Sub2ViewController()
            let container = PresentContainerController(subViewController: subView, animate: PresentFromLeft())
            container.show(in: self)
        }

        let add4 = DatasourceItem(title: "Add subview from right") {
            let subView = Sub2ViewController()
            let container = PresentContainerController(subViewController: subView, animate: PresentFromRight())
            container.show(in: self)
        }

        let add5 = DatasourceItem(title: "Add subview from center") {
            let subView = Sub2ViewController()
            let container = PresentContainerController(subViewController: subView, animate: PresentFromCenter())
            container.show(in: self)
        }

        datasource = [
            present1,
            present2,
            present3,
            present4,
            present5,
            add1,
            add2,
            add3,
            add4,
            add5
        ]
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        datasource[indexPath.row].action()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self))!
        cell.textLabel?.text = datasource[indexPath.row].title
        return cell
    }
}

class SubViewController: UIViewController {
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.red

        let btn = UIButton()
        btn.backgroundColor = UIColor.yellow
        btn.addTarget(self, action: #selector(clickBtn), for: .touchUpInside)

        self.view.addSubview(btn)
        btn.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(44)
        }
    }

    @objc
    func clickBtn() {
        PresentContainerController.presentContainer(for: self)?.dismiss(animated: true, completion: {
            print("completion in subview")
        })
    }
}

class Sub2ViewController: UIViewController {
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.red

        let btn = UIButton()
        btn.backgroundColor = UIColor.yellow
        btn.addTarget(self, action: #selector(clickBtn), for: .touchUpInside)

        self.view.addSubview(btn)
        btn.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(44)
            maker.left.top.greaterThanOrEqualTo(40)
            maker.right.bottom.lessThanOrEqualTo(-40)
        }
    }

    @objc
    func clickBtn() {
        PresentContainerController.presentContainer(for: self)?.dismiss(animated: true, completion: {
            print("completion in subview2")
        })
    }
}
