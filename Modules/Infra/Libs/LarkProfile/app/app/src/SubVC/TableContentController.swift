//
//  TableContentController.swift
//  SegmentedTableView
//
//  Created by Hayden on 2021/6/24.
//

import Foundation
import UIKit
import LarkProfile
import UniverseDesignColor

class TableContentController: UIViewController {

    private var numberOfCell: Int

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
//        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -10)
        return tableView
    }()

    private lazy var headerView: UIView = {
        let topMargin: CGFloat = 10
        let cornerRadius: CGFloat = 20
        let view = UIView()
        let content = UIView()
        view.addSubview(content)
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 20, height: topMargin + cornerRadius)
        view.layer.masksToBounds = true
        content.frame = CGRect(x: 0, y: topMargin, width: view.frame.width, height: cornerRadius * 2)
        content.backgroundColor = UIColor.systemGreen
        content.layer.cornerRadius = cornerRadius
        return view
    }()

    private lazy var footerView: UIView = {
        let topMargin: CGFloat = 10
        let cornerRadius: CGFloat = 20
        let view = UIView()
        let content = UIView()
        view.addSubview(content)
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 20, height: topMargin + cornerRadius)
        view.layer.masksToBounds = true
        content.frame = CGRect(x: 0, y: -cornerRadius, width: view.frame.width, height: cornerRadius * 2)
        content.backgroundColor = UIColor.systemGreen
        content.layer.cornerRadius = cornerRadius
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Table\(numberOfCell) VC did load")
        view.backgroundColor = UIColor.ud.bgBase
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().inset(10).priority(.high)
            make.top.bottom.equalToSuperview()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Table\(numberOfCell) VC did appear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("Table\(numberOfCell) VC did disappear")
    }

    init(num: Int) {
        self.numberOfCell = num
        super.init(nibName: nil, bundle: nil)
        print("Table\(numberOfCell) VC init")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("Table\(numberOfCell) VC deinit")
    }

    var contentViewDidScroll: ((UIScrollView) -> Void)?
}

extension TableContentController: SegmentedTableViewContentable {

    public func listView() -> UIView {
        return view
    }

    var segmentTitle: String {
        "TableView\(numberOfCell)"
    }

    var scrollableView: UIScrollView {
        tableView
    }
}

extension TableContentController: UITableViewDelegate, UITableViewDataSource {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        contentViewDidScroll?(scrollView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfCell
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
        cell.backgroundColor = .systemRed
        cell.textLabel?.text = "第 \(indexPath.row + 1) 行"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
