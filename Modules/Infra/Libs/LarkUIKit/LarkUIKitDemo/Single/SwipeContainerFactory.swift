//
//  SwipeContainerFactory.swift
//  LarkUIKitDemo
//
//  Created by liuwanlin on 2018/3/22.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

class SwipeContainerFactory {
    class func build() -> UIViewController {
        let vc = SwipeDemoController()
        vc.view.backgroundColor = UIColor.red

        let swipeContainerController = SwipeContainerViewController(subViewController: vc)
        swipeContainerController.showMiddleState = true
        swipeContainerController.delegate = vc
        return swipeContainerController
    }
}

class SwipeDemoController: UIViewController, SwipeContainerViewControllerDelegate {
    func startDrag() {
    }

    func dismissByDrag() {
    }

    func disablePanGestureViews() -> [UIView] {
        return [self.disableView]
    }

    func configSubviewOn(containerView: UIView) {
    }

    let disableView: UIView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = MyTableView()
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints({ (make) in
            make.top.equalTo(50)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(100)
        })

        self.view.addSubview(self.disableView)
        self.disableView.backgroundColor = UIColor.green
        disableView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.height.equalTo(100)
        }
    }
}

class MyTableView: UIView {
    private let tableView: UITableView
    override init(frame: CGRect) {
        tableView = UITableView()
        super.init(frame: frame)
        addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
}

extension MyTableView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "hahaha")
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
}
