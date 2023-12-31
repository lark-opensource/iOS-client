//
//  MonitorDebugVC.swift
//  SecurityComplianceDebug
//
//  Created by yifan on 2023/5/15.
//

import SnapKit
import LarkSecurityComplianceInfra
import LarkDebug
import LarkReleaseConfig
import LarkSensitivityControl
import UniverseDesignToast

final class MonitorDebugVC: UIViewController {
    private let cellId = "MonitorDebugCell"

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = nil
        tableView.tableHeaderView = nil
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()

    private let packageStatusArray: [PackageStatus] = {
        var packageStatusArray: [PackageStatus] = []
        packageStatusArray.append(PackageStatus(name: "Debug", status: isDebug()))
        packageStatusArray.append(PackageStatus(name: "LarkDebug", status: isLarkDebug()))
        packageStatusArray.append(PackageStatus(name: "ALPHA", status: isALPHA()))
        packageStatusArray.append(PackageStatus(name: "BETA", status: isBETA()))
        packageStatusArray.append(PackageStatus(name: "KA", status: isKA()))
        packageStatusArray.append(PackageStatus(name: "PrivateKA", status: isPrivateKA()))
        packageStatusArray.append(PackageStatus(name: "SaasKA", status: isSaasKA()))
        packageStatusArray.append(PackageStatus(name: "Feishu", status: isFeishu()))
        return packageStatusArray
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Monitor Debug"
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(85)
            $0.bottom.left.right.equalToSuperview()
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SCDebugViewCell.self, forCellReuseIdentifier: cellId)
        
        let vendorID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 3) {
            DIDManager.shared.updateVendorID(vendorID)
            DIDManager.shared.updateCurrentModel()
            _ = DIDManager.shared.detectMigration()
            DIDManager.shared.updateCache()
            DispatchQueue.runOnMainQueue {
                DIDManager.shared.showDataState { msg in
                    UDToast.showTips(with: msg, on: self.view)
                }
            }
        }
    }
}

// MARK: dataSource & delegate for tableView
extension MonitorDebugVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return packageStatusArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as?
                SCDebugViewCell else {
            return UITableViewCell()
        }
        let packageStatus = packageStatusArray[indexPath.row]
        cell.configModel(model: SCDebugModel(cellTitle: packageStatus.name, cellSubtitle: String(packageStatus.status), cellType: .subtitle))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else {
            Logger.error("Array out of bounds")
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)    // 取消选中
    }
}

// MARK: get app status
extension MonitorDebugVC {

    struct PackageStatus {
        let name: String
        let status: Bool
    }

    private static func isDebug() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// 内侧包，不包括本地debug
    private static func isLarkDebug() -> Bool {
        #if canImport(LarkDebug)
        return appCanDebug()
        #else
        return false
        #endif
    }

    private static func isALPHA() -> Bool {
        #if ALPHA
        return true
        #else
        return false
        #endif
    }

    private static func isBETA() -> Bool {
        #if BETA
        return true
        #else
        return false
        #endif
    }

    private static func isKA() -> Bool {
        return ReleaseConfig.isKA
    }

    private static func isPrivateKA() -> Bool {
        return ReleaseConfig.isPrivateKA
    }

    private static func isSaasKA() -> Bool {
        return isKA() && !isPrivateKA()
    }

    private static func isFeishu() -> Bool {
        return ReleaseConfig.isFeishu
    }
}
