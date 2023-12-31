//
//  MentionDebugSettingViewController.swift
//  LarkMention
//
//  Created by Yuri on 2022/6/12.
//

import Foundation
#if !LARK_NO_DEBUG
import UIKit
import SnapKit

final class MentionDebugSettingViewController: UIViewController {
    
    var didCompleteHandler: ((MentionUIParameters, MentionSearchParameters) -> Void)?
    
    typealias Item = MentionDebugItemCell.Item
    
    var tableView = UITableView(frame: .zero, style: .grouped)
    var sections = [MentionDebugItemCell.Section]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onSure))
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = UIColor.clear
        tableView.rowHeight = 44
        tableView.register(MentionDebugItemCell.self, forCellReuseIdentifier: "MentionDebugItemCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalToSuperview().offset(44)
        }
        tableView.contentInsetAdjustmentBehavior = .never
    }

    @objc private func onCancel() {
        navigationController?.dismiss(animated: true)
    }

    @objc private func onSure() {
        navigationController?.dismiss(animated: true)
    }
    
    @objc func injected() {
        view.subviews.forEach { $0.removeFromSuperview() }
        viewDidLoad()
    }
}

extension MentionDebugSettingViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MentionDebugItemCell", for: indexPath)
        if let c = cell as? MentionDebugItemCell {
            c.item = sections[indexPath.section].items[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
}
#endif
