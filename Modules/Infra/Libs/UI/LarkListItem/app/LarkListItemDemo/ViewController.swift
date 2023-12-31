//
//  ViewController.swift
//  LarkListItemDemo
//
//  Created by Yuri on 2023/5/26.
//

import UIKit
import SnapKit
import LarkModel
@testable import LarkListItem

class ViewController: UIViewController {

    let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(ItemTableViewCell.self, forCellReuseIdentifier: "1")
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }


}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "1", for: indexPath)
        if let cell = cell as? ItemTableViewCell {
            var item = PickerItemMocker.mockDoc()
            item.renderData?.titleHighlighted = NSAttributedString(string: "🧑‍💻 别的工程师都用 chatgpt 写代码了，你还在 github 上面拷")
            cell.delegate = self
            var node = PickerItemTransformer.transform(indexPath: indexPath, item: item)
            node.accessories = [.targetPreview]
            cell.node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                     checkBoxState: .init(isShow: false),
                                     icon: .local(nil),
                                     title: NSAttributedString(string: "Title"),
                                     subtitle: NSAttributedString(string: "SubtitleSubtitleSubtitleSubtitleSubtitleSubtitleSubtitle"),
                                     desc: NSAttributedString(string: "DescDescDescDescDescDescDescDescDescDescDescDescDescDescDesc")
                                     )
        }
        return cell
    }
}

extension ViewController: ItemTableViewCellDelegate {
    func listItemDidClickAccessory(type: ListItemNode.AccessoryType, at indexPath: IndexPath) {
        print("click access", type, indexPath)
    }
}
