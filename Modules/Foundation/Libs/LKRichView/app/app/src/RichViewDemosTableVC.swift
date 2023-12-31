//
//  RichViewDemosTableVC.swift
//  LKRichViewDev
//
//  Created by qihongye on 2019/9/29.
//

import Foundation
import UIKit

class RichViewDemosTableVC: UIViewController {
    struct DatasourceItem {
        var title: String
        var targetVC: () -> UIViewController
    }

    var tableView: UITableView!
    var datasource: [DatasourceItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupDatasource()
    }

    func setupTableView() {
        tableView = UITableView()
        tableView.tableFooterView = UIView()
        self.view.addSubview(tableView)

        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        tableView.delegate = self
        tableView.dataSource = self
        //        tableView.allowsMultipleSelection = false
        //        tableView.isMultipleTouchEnabled = false

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
    }

    func setupDatasource() {
        let normalResize = DatasourceItem(title: "Normal Resize") { () -> UIViewController in
            NormalResizeDemoVC()
        }
        let borderDemo = DatasourceItem(title: "Border") { () -> UIViewController in
            BorderDemoVC()
        }
        let styleSheetDemo = DatasourceItem(title: "StyleSheet") { () -> UIViewController in
            StyleSheetVC()
        }
        let marginPaddingDemo = DatasourceItem(title: "Margin Padding") { () -> UIViewController in
            MarginPaddingDemoVC()
        }
        let largeStringDemo = DatasourceItem(title: "Large String") { () -> UIViewController in
            LargeStringDemoVC()
        }
        let emotionDemo = DatasourceItem(title: "Emotion") { () -> UIViewController in
            EmotionDemoVC()
        }
        let magnifierDemo = DatasourceItem(title: "Magnifier") {
            MagnifierViewController()
        }
        let selectionDemo = DatasourceItem(title: "Selection") { () -> UIViewController in
            SelectionDemoVC()
        }
        let textOverflowDemo = DatasourceItem(title: "TextOverflowDemo") { () -> UIViewController in
            TextOverflowDemoVC()
        }
        let lineCampDemo = DatasourceItem(title: "LineCampDemo") {
            LineCampViewController()
        }
        let testCaseTest1Demo = DatasourceItem(title: "TestCaseTest1") { () -> UIViewController in
            TestCaseTest1VC()
        }
        let textWorldWrapDemo = DatasourceItem(title: "TextWorldWrapDemoVC") { () -> UIViewController in
            TextWorldWrapDemoVC()
        }
        let blodWordDemo = DatasourceItem(title: "BlodWordDemoVC") { () -> UIViewController in
            BoldWordDemoVC()
        }
        let attachmentBugDemo = DatasourceItem(title: "AttachmentBugDemoVC") { () -> UIViewController in
            AttachmentBugDemoVC()
        }

        self.datasource = [
            normalResize,
            borderDemo,
            styleSheetDemo,
            marginPaddingDemo,
            largeStringDemo,
            emotionDemo,
            magnifierDemo,
            selectionDemo,
            textOverflowDemo,
            lineCampDemo,
            testCaseTest1Demo,
            textWorldWrapDemo,
            blodWordDemo,
            attachmentBugDemo
        ]
    }
}

extension RichViewDemosTableVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
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
}

extension RichViewDemosTableVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.textLabel?.text = datasource[indexPath.row].title
        return cell
    }
}
