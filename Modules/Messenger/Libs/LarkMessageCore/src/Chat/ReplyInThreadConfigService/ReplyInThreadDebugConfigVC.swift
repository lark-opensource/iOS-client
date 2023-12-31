//
//  ReplyInThreadDebugConfigVC.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/6/6.
//

import Foundation
import LarkUIKit
import SnapKit
import UIKit
import LarkStorage

final class ReplyInThreadDebugCell: UITableViewCell {
    private lazy var globalStore = KVStores.Messenger.global()
    var key = ""
    let switchBtn = UISwitch()
    let label = UILabel()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        self.contentView.addSubview(label)
        self.contentView.addSubview(switchBtn)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview()
            make.right.equalTo(switchBtn.snp.left).offset(8)
        }
        switchBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
        }
        switchBtn.addTarget(self, action: #selector(onSwitch), for: .valueChanged)
    }

    @objc
    func onSwitch() {
        globalStore[self.key] = switchBtn.isOn
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            exit(0)
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
final class ReplyInThreadDebugConfigVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private lazy var globalStore = KVStores.Messenger.global()
    let data: [String] = ["切换feed头像"]
    let keys: [String] = ["replyInThreadFeedIcon"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        setupUI()
    }

    func setupUI() {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(ReplyInThreadDebugCell.self, forCellReuseIdentifier: "ReplyInThreadDebugCell")
        let tipsLabel = UILabel()
        tipsLabel.text = "开关会导致重启app"
        tipsLabel.font = UIFont.systemFont(ofSize: 14)
        tipsLabel.textAlignment = .center
        tipsLabel.textColor = UIColor.ud.textPlaceholder
        tipsLabel.frame = CGRect(x: 0, y: 0, width: 0.1, height: 60)
        tableView.tableFooterView = tipsLabel
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ReplyInThreadDebugCell") as? ReplyInThreadDebugCell {
            cell.label.text = data[indexPath.row]
            cell.key = keys[indexPath.row]
            cell.switchBtn.isOn = globalStore.bool(forKey: cell.key)
            return cell
        }
        return UITableViewCell()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
