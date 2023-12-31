//
//  UDListViewController.swift
//  UDDebug
//
//  Created by 白镜吾 on 2023/7/24.
//

#if !LARK_NO_DEBUG

import UIKit
import FigmaKit
import UniverseDesignColor
import UniverseDesignIcon

typealias ListItem = (String, UIImage, () -> UIViewController)

class UDListViewController: UIViewController {
    var dataSource: [ListItem] = [
        ListItem("UDIcon \(UDIcon.resourceVersion), iconFont: \(UDIcon.iconFontEnable ? "enabled": "disabled")", UDIcon.imageSquareColorful, { UniverseDesignIconVC() }),
        ListItem("UDNotice", UDIcon.imageSquareColorful, { UniverseDesignNoticeVC() })
    ]

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(UDListTableViewCell.self, forCellReuseIdentifier: UDListTableViewCell.id)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(80)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
}

extension UDListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UDListTableViewCell.id, for: indexPath) as? UDListTableViewCell else {
            return UITableViewCell()
        }

        cell.textLabel?.text = dataSource[indexPath.item].0
        cell.imageView?.image = dataSource[indexPath.item].1
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = dataSource[indexPath.row].2
        self.navigationController?.pushViewController(vc(), animated: true)
    }
}

private final class UDListTableViewCell: UITableViewCell {

    static var id: String { "cell" }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
