//
//  RustMetricUploadDebugViewController.swift
//  LarkApp
//
//  Created by lixiaorui on 2019/12/19.
//

import Foundation
import UIKit
import SnapKit
import LarkSDKInterface
import LarkUIKit
import RoundedHUD
import LarkActionSheet
import LarkAlertController
import UniverseDesignColor
import LarkDebug
import EENavigator
import RxSwift

var cmUploadConfig: [RustMetricUploadConfigType] = [.limit(nil), .size(nil), .packets(nil)]

enum RustMetricUploadConfigType {
    case limit(Bool?)
    case size(Int32?)
    case packets(UInt32?)

    var name: String {
        switch self {
        case .limit:
            return "限制上传"
        case .size:
            return "每个package最小日志量"
        case .packets:
            return "每次上传最大package数"
        }
    }

    var desc: String {
        switch self {
        case .limit:
            return "Rust Cache里的日志小于最小上传日志大小且日志文件没有新日志时，不上传Cache里的日志"
        case .size:
            return "从日志文件读取日志到Rust Cache，Cache里日志字节数需大于该值，才会打包进行上传（输入非 Int32 将设置为 nil）"
        case .packets:
            return "每次上传，最多传的包数（输入非 UInt32 将设置为 nil）"
        }
    }

    var value: String {
        switch self {
        case let .limit(lm):
            if lm != nil {
                return String(lm!)
            }
            return ""
        case let .size(sz):
            if sz != nil {
                return String(sz!)
            }
            return ""
        case let .packets(pk):
            if pk != nil {
                return String(pk!)
            }
            return ""
        }
    }
}

class RustMetricUploadDebugViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {

    private let logAPI: RustLogAPI
    private let disposeBag = DisposeBag()
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.keyboardDismissMode = .onDrag
        table.tableHeaderView = nil
        table.tableFooterView = nil
        table.estimatedRowHeight = 40
        table.rowHeight = UITableView.automaticDimension
        table.delegate = self
        table.dataSource = self
        table.register(ConfigTableViewCell.self, forCellReuseIdentifier: "ConfigTableViewCell")
        return table
    }()

    init(logAPI: RustLogAPI) {
        self.logAPI = logAPI
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Client Metrics 上传配置"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.viewTopConstraint)
            make.right.left.equalToSuperview()
            make.bottom.equalTo(self.viewBottomConstraint)
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cmUploadConfig.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigTableViewCell", for: indexPath) as? ConfigTableViewCell else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        let config = cmUploadConfig[indexPath.item]
        cell.titleLabel.text = config.name
        cell.valueLabel.text = config.value
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil,
            indexPath.item < cmUploadConfig.count else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        switch cmUploadConfig[indexPath.item] {
        case .limit:
            showActoinSheet(index: indexPath.item)
        default:
            showInputAlert(index: indexPath.item)
        }
    }

    private func showActoinSheet(index: Int) {
        let actionSheet = ActionSheet(title: cmUploadConfig[index].desc)
        actionSheet.addItem(title: "True", textColor: UIColor.ud.N500) { [weak self] in
            cmUploadConfig[index] = .limit(true)
            self?.setConfig(index: index)
        }
        actionSheet.addItem(title: "False", textColor: UIColor.ud.colorfulBlue) { [weak self] in
            cmUploadConfig[index] = .limit(false)
            self?.setConfig(index: index)
        }
        actionSheet.addItem(title: "None", textColor: UIColor.ud.colorfulBlue) { [weak self] in
            cmUploadConfig[index] = .limit(nil)
            self?.setConfig(index: index)
        }
        actionSheet.addCancelItem(title: "取消", textColor: UIColor.ud.colorfulBlue)
        self.present(actionSheet, animated: true, completion: nil)
    }

    private func showInputAlert(index: Int) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: "修改\(cmUploadConfig[index].name)")
        let customView = ContentWithTextFieldView(text: cmUploadConfig[index].desc)
        customView.textField.text = cmUploadConfig[index].value
        alertController.setContent(view: customView, padding: UIEdgeInsets(top: 10, left: 20, bottom: 18, right: 20))
        alertController.addSecondaryButton(text: "取消")
        alertController.addPrimaryButton(text: "确定") { [weak self] in
            let text = customView.textField.text ?? ""
            switch cmUploadConfig[index] {
            case .size:
                cmUploadConfig[index] = .size(Int32(text))
            case .packets:
                cmUploadConfig[index] = .packets(UInt32(text))
            default:
                break
            }
            self?.setConfig(index: index)
        }
        DispatchQueue.main.async {
            Navigator.shared.present(alertController, from: self)
        }
    }

    private func setConfig(index: Int) {
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        var limit: Bool?
        var size: Int32?
        var packets: UInt32?
        if case let .limit(lm) = cmUploadConfig[0] {
            limit = lm
        }
        if case let .size(sz) = cmUploadConfig[1] {
            size = sz
        }
        if case let .packets(pk) = cmUploadConfig[2] {
            packets = pk
        }
        logAPI.setClientMetricUploadConfig(limit: limit,
                                           minLogSize: size,
                                           maxPacketsPerUpload: packets)
            .subscribe(onNext: { (_) in
                DispatchQueue.main.async {
                    RoundedHUD().showSuccess(with: "设置成功")
                }
            }, onError: { (_) in
                DispatchQueue.main.async {
                    RoundedHUD().showFailure(with: "设置失败")
                }
            }).disposed(by: self.disposeBag)
    }
}

private class ConfigTableViewCell: UITableViewCell {

    let titleLabel = UILabel()
    let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .disclosureIndicator

        self.valueLabel.font = UIFont.systemFont(ofSize: 15)
        self.contentView.addSubview(self.valueLabel)
        self.valueLabel.snp.makeConstraints { (make) in
            make.right.centerY.equalToSuperview()
        }

        self.titleLabel.font = UIFont.systemFont(ofSize: 17)
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.numberOfLines = 0
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(5)
            make.right.lessThanOrEqualTo(self.valueLabel.snp.left)
            make.centerY.equalToSuperview()
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
