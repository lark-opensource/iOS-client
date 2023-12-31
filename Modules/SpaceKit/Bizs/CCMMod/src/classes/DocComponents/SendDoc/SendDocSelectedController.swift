//
//  SendDocSelectController.swift
//  Lark
//
//  Created by lichen on 2018/7/20.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import LarkUIKit
import LKCommonsLogging
import RxSwift
import UniverseDesignColor

class SendDocSelectController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {

    static let logger = Logger.log(SendDocSelectController.self, category: "Module.SendDocSelectController")

    let viewModel: SendDocSelectedViewModel
    let tableView: UITableView = UITableView()

    init(viewModel: SendDocSelectedViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UDColor.bgBody
        self.view.addSubview(tableView)
        tableView.backgroundColor = UDColor.bgBody
        tableView.lu.register(cellSelf: SendDocSelectedCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.setupNavigationBar()
        self.updateTitle()
    }

    func setupNavigationBar() {
        let item = LKBarButtonItem(title: BundleI18n.CCMMod.Lark_Legacy_Save)
        item.setProperty(alignment: .right)
        item.setBtnColor(color: UDColor.primaryContentDefault)
        item.button.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = item
    }

    @objc
    fileprivate func navigationBarRightItemTapped() {
        self.viewModel.save()
        self.navigationController?.popViewController(animated: true)
    }

    private func updateTitle() {
        self.title = BundleI18n.CCMMod.Lark_Legacy_SelectedCountHint(self.viewModel.showItems.count)
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.showItems.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: SendDocSelectedCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? SendDocSelectedCell {
            let doc = self.viewModel.showItems[indexPath.row]
            cell.setDoc(doc)
            cell.clickDeleteBlock = { [weak self] doc in
                guard let `self` = self else { return }
                self.viewModel.delete(item: doc)
                self.updateTitle()
                self.tableView.reloadData()
            }
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}
