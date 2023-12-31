//
//  ViewController.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/7.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import SwiftUI

class ViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    override var navigationBarStyle: NavigationBarStyle {
        return .default
    }

    struct DatasourceItem {
        var title: String
        var targetVC: () -> UIViewController
    }

    var tableView: UITableView!

    var datasource: [DatasourceItem] = []

    var pageTitle: String {
        return "LarkUIKit Demos"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white

        self.title = self.pageTitle

        setupTableView()
        setupDatasource()
    }

    func setupTableView() {
        tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 68
        tableView.register(TableViewCell.self, forCellReuseIdentifier: String(describing: TableViewCell.self))
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // 以后所有的demo都加在这里了
    func setupDatasource() {
        let imagePicker = DatasourceItem(title: "图片选择(ImagePicker)") {
            ImagePickerViewControllerDemo()
        }

        let singleItem = DatasourceItem(title: "单个viewdemo集合") { () -> UIViewController in
            SingleViewController()
        }

        let naviItem = DatasourceItem(title: "NaviBar") { () -> UIViewController in
            NavibarViewController()
        }

        let videoPalceHolderItem = DatasourceItem(title: "LoadPlaceHolderView") {
            LoadPlaceHolderViewController()
        }

        let segmentItem = DatasourceItem(title: "Segment") { () -> UIViewController in
            SegmentViewController()
        }

        let segmentItem2 = DatasourceItem(title: "Segment2") { () -> UIViewController in
            SegmentTableViewController()
        }

        let checkBox = DatasourceItem(title: "CheckBox") { () -> UIViewController in
            if #available(iOS 14.0.0, *) {
                return UIHostingController(rootView: CheckBoxView())
            } else {
                // Fallback on earlier versions
                return CheckBoxViewController()
            }
        }

        let presentIniPad = DatasourceItem(title: "Present VC") {
            return iPadPresentViewController()
        }

        let naviAnimation = DatasourceItem(title: "Edge Navi Animation") { () -> UIViewController in
            return NaviAnimationMasterViewController()
        }

        datasource = [
            imagePicker,
            singleItem,
            naviItem,
            videoPalceHolderItem,
            segmentItem,
            segmentItem2,
            checkBox,
            presentIniPad,
            naviAnimation
        ]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = datasource[indexPath.row].targetVC()
        if vc is UINavigationController {
            self.present(vc, animated: true, completion: nil)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TableViewCell.self),
                                                 for: indexPath)
        if let cell = cell as? TableViewCell {
            cell.title = datasource[indexPath.row].title
        }
        return cell
    }
}

class TableViewCell: UITableViewCell {
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    var titleLabel: UILabel = UILabel()

    var leftView: UIView = {
        let view = UIImageView(image: UIImage(named: "swipeCell_dealed"))
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.right.equalTo(-15)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
