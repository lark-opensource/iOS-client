//
//  SecurityAuditDebugItem.swift
//  LarkSecurityAudit
//
//  Created by ByteDance on 2022/9/4.
//

import Foundation
import LarkDebugExtensionPoint
import EENavigator
import UIKit
import UniverseDesignToast
import LKCommonsLogging
import LarkSecurityAudit
import RustPB
import CryptoSwift

struct SecurityAuditSCDebugModel {
    let titlle: String
    let action: () -> Void

    init(_ title: String, _ action: @escaping () -> Void) {
        self.titlle = title
        self.action = action
    }
}

final class SecurityAuditDebugViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    static let logger = Logger.log(SecurityAuditDebugViewController.self, category: "SecurityAudit.Debug")
    var models: [SecurityAuditSCDebugModel] = []
    var tableView: UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        constructModels()

        tableView.estimatedRowHeight = 40
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SevurityAuditCell")
        self.view.addSubview(tableView)
        tableView.frame = self.view.bounds

    }

    func constructModels() {
        let clearModel = SecurityAuditSCDebugModel("清理权限SDK数据") {
            Self.logger.info("触发清理权限SDK数据")
            SecurityAuditManager.shared.clearPermissionData()
        }
        let fetchModel = SecurityAuditSCDebugModel("拉取权限") {
            Self.logger.info("触发拉取权限SDK数据")
            SecurityAuditManager.shared.fetchPermission()
        }
        let retryModel = SecurityAuditSCDebugModel("拉取重试") {
            SecurityAuditManager.shared.retryPullPermission()
        }
        let checkModel = SecurityAuditSCDebugModel("权限校验") {
            Self.logger.info("权限校验")
            let vc = PermissionCheckViewController()
            Navigator.shared.push(vc, from: self)
        }
        let strictModel = SecurityAuditSCDebugModel("是否从严") {
            UDToast.showTips(with: "strictMode: \(SecurityAuditManager.shared.isStrictMode())", on: self.view)
        }
        let cacheDataModel = SecurityAuditSCDebugModel("展示缓存") {
            let vc = PermissionCacheViewController()
            Navigator.shared.push(vc, from: self)
        }
        let mockDataAndStoreModel0 = SecurityAuditSCDebugModel("构造16的整数倍resp:zeroPadding") {
            SecurityAuditManager.shared.mockAndStoreData(padding: .zeroPadding)
        }
        let mockDataAndStoreModel7 = SecurityAuditSCDebugModel("构造16的整数倍resp:pkcs7Padding") {
            SecurityAuditManager.shared.mockAndStoreData(padding: .pkcs7)
        }
        models.append(contentsOf: [clearModel, fetchModel, retryModel, checkModel, strictModel, cacheDataModel, mockDataAndStoreModel0, mockDataAndStoreModel7])
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let securityAuditCell = tableView.dequeueReusableCell(withIdentifier: "SevurityAuditCell", for: indexPath)
        let model: SecurityAuditSCDebugModel = self.models[indexPath.row]
        securityAuditCell.textLabel?.text = model.titlle
        return securityAuditCell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < self.models.count else {
            return
        }
        self.models[indexPath.row].action()
    }
}

final class PermissionCheckViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var models: [(title: String, PermissionType)] = []
    var tableView: UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        models = [("上传文件", .fileUpload),
                  ("导入为在线文档", .fileImport),
                  ("文件下载", .fileDownload),
                  ("文件导出", .fileExport),
                  ("文件打印", .filePrint),
                  ("用其他应用打开", .fileAppOpen),
                  ("查看文件夹", .fileAccessFolder),
                  ("查看云文档/文件", .fileRead),
                  (" 编辑云文档/文件", .fileEdit),
                  ("评论云文档/文件", .fileComment),
                  ("复制内容/创建副本", .fileCopy),
                  ("文件删除", .fileDelete),
                  ("文件分享", .fileShare),
                  ("本地文件对外分享", .localFileShare),
                  ("本地文件预览", .localFilePreview),
                  ("云文档打开和预览", .docPreviewAndOpen),
                  ("移动端粘贴保护", .mobilePasteProtection),
                  ("百科词库查看", .baikeRepoView)
        ]

        tableView.estimatedRowHeight = 40
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PermissionCheckCell")
        self.view.addSubview(tableView)
        tableView.frame = self.view.bounds
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let securityAuditCell = tableView.dequeueReusableCell(withIdentifier: "PermissionCheckCell", for: indexPath)
        securityAuditCell.textLabel?.text = self.models[indexPath.row].0
        return securityAuditCell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < self.models.count else {
            return
        }
        let dialog = SecurityAuditAlertController(title: "构造实体", message: nil, preferredStyle: .alert)
        dialog.complete = { entity in
            let result = SecurityAudit().checkAuthWithErrorType(permType: self.models[indexPath.row].1, object: entity)
            var toastText = (SecurityAuditManager.shared.getPermissionMap()?[self.models[indexPath.row].1] != nil ? "有缓存" : "无缓存")
            toastText += "，权限结果：\(result.0)"
            guard let errorType = result.1?.rawValue else {
                UDToast.showTips(with: toastText, on: self.view)
                return
            }
            toastText += "，错误类型：\(errorType)"
            UDToast.showTips(with: toastText, on: self.view)
        }
        Navigator.shared.present(dialog, from: self)
    }
}

final class PermissionCacheViewController: UIViewController {
    let textView: SCDebugTextView = {
        let view = SCDebugTextView()
        view.isSelectable = true
        view.isEditable = false
        view.backgroundColor = .white
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        SecurityAuditManager.shared.getPermissionMap()?.forEach { element in
            textView.text += "permType:\(element.key)\n"
            for (index, permission) in element.value.enumerated() {
                textView.text +=
                """
                \(index):
                id: \(permission.object.id)
                entityType: \(permission.object.entityType)
                result: \(permission.result)

                """
            }
            textView.text += "\n"
        }
        textView.frame = view.bounds
        view.addSubview(textView)
    }
}
