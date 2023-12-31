//
//  SecurityPolicyDebugRegister.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2022/10/17.
//

import Foundation
import EENavigator
import LarkSecurityComplianceInterface
import LarkSecurityCompliance
import LarkContainer
import UniverseDesignDialog
import LarkAppLog
import UniverseDesignToast
import LarkAccountInterface
import UniverseDesignLoading
import LarkSecurityComplianceInfra

final class SecurityPolicyDebugRegister: SCDebugModelRegister {

    let userResolver: UserResolver

    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }

    func registModels() {
        let hintURL =  "Api detail: https://bytedance.feishu.cn/wiki/wikcnGjJk2NlX0dSimEr05EoIRf"

        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }

        debugEntrance.regist(section: .securityPolicy) {
            let version = SecurityPolicyAssembly.enableSecurityPolicyV2 ? "V2" : "V1"
            return SCDebugModel(cellTitle: "当前初始化版本", cellSubtitle: version, cellType: .subtitle)
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "校验", cellType: .normal, normalHandler: { [weak self] in
                guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                let generator = SecurityPolicyDebugFormHandler(resolver: self.userResolver)
                let vc = generator.generateVC()
                Navigator.shared.push(vc, from: currentVC)
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "导入动态缓存",
                                         cellType: .normal,
                                         normalHandler: { [weak self] in
                self?.inputMockCache()
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "清缓存", cellType: .normal, normalHandler: { [weak self] in
                let service = try? self?.userResolver.resolve(assert: SecurityPolicyDebugService.self)
                service?.clearStrategyAuthCache()
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "展示日志", cellType: .normal, normalHandler: {
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let debugVC = SCDebugTextViewController()
                debugVC.getText = {
                    let service = try? self.userResolver.resolve(assert: SecurityPolicyDebugService.self)
                    return service?.text ?? ""
                }
                Navigator.shared.push(debugVC, from: fromVC)
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "是否开启日志记录", cellType: .switchButton, isSwitchButtonOn: UserDefaults.standard.bool(forKey: "file_operate_log_open"), switchHandler: { isOn in
                UserDefaults.standard.setValue(isOn, forKey: "file_operate_log_open")
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "展示动态缓存内容", cellType: .normal, normalHandler: {
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let debugVC = SCDebugTextViewController()
                debugVC.getText = {
                    let service = try? implicitResolver?.resolve(assert: SecurityPolicyDebugService.self)
                    return service?.getSceneCache() ?? ""
                }
                Navigator.shared.push(debugVC, from: fromVC)
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "展示静态缓存内容", cellType: .normal, normalHandler: {
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let list: [SecurityPolicyDebugDataRetrievalProtocol.Type] = [SecurityPolicyV2.SecurityPolicyV1DataRetriever.self,
                                                                             SecurityPolicyV2.SecurityPolicyV2DataRetriever.self,
                                                                             SecurityPolicyV2.SecurityPolicyV3DebugDataRetriever.self]
                let alertController = UIAlertController.generateChoiceDialog(choiceList: list, getChoiceName: { $0.identifier },
                                                                             complete: { retrieverType in
                    let debugVC = SCDebugTextViewController()
                    debugVC.getText = { [weak self] in
                        guard let self else { return "" }
                        let service = try? implicitResolver?.resolve(assert: SecurityPolicyDebugService.self)
                        return service?.getStaticCache(with: retrieverType.init(userResolver: self.userResolver)) ?? ""
                    }
                    Navigator.shared.push(debugVC, from: fromVC)
                })
                Navigator.shared.present(alertController, from: fromVC)
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "延迟展示弹窗", cellType: .normal, normalHandler: { [weak self] in
                let dialog = UIAlertController(title: "延迟展示弹窗", message: "", preferredStyle: .alert)
                dialog.addTextField { $0.placeholder = "延迟时间 默认为20s" }
                let action = UIAlertAction(title: "确认", style: .default) { _ in
                    let timeInterval = Double(dialog.textFields?[0].text ?? "")
                    Timer.scheduledTimer(withTimeInterval: timeInterval ?? 20, repeats: false) { [weak self] _ in
                        DispatchQueue.main.async {
                            guard let self, let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                            UDToast().showTips(with: "倒计时结束", on: fromVC.view)
                            let service = try? self.userResolver.resolve(assert: SecurityPolicyService.self)
                            let policyModel = PolicyModel(.ccmFileDownload, CCMEntity(entityType: .file,
                                                                                      entityDomain: .ccm,
                                                                                      entityOperate: .ccmFileDownload,
                                                                                      operatorTenantId: 1,
                                                                                      operatorUid: 7130510970970980371,
                                                                                      fileBizDomain: .ccm))
                            service?.showInterceptDialog(policyModel: policyModel)
                        }
                    }
                }
                dialog.addAction(action)

                DispatchQueue.main.async {
                    guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                    Navigator.shared.present(dialog, from: fromVC)
                }
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "当前动态缓存数量", cellType: .normal, normalHandler: { [weak self] in
                DispatchQueue.main.async {
                    guard let self, let window = Navigator.shared.mainSceneWindow else { return }
                    let service = try? self.userResolver.resolve(assert: SecurityPolicyDebugService.self)
                    let size = service?.getSceneCacheSize() ?? 0
                    UDToast().showTips(with: "scene size is \(size)", on: window)
                }
            })
        }
        
        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "展示待更新点位表", cellType: .normal, normalHandler: { [weak self] in
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let debugVC = SCDebugTextViewController()
                debugVC.getText = {
                    let service = try? self?.userResolver.resolve(assert: SecurityPolicyDebugService.self)
                    return service?.getRetryList() ?? ""
                }
                Navigator.shared.push(debugVC, from: fromVC)
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "展示IP信息表", cellType: .normal, normalHandler: { [weak self] in
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let debugVC = SCDebugTextViewController()
                debugVC.getText = {
                    let service = try? self?.userResolver.resolve(assert: SecurityPolicyDebugService.self)
                    return service?.getIPList() ?? ""
                }
                Navigator.shared.push(debugVC, from: fromVC)
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "处理 action", cellType: .normal, normalHandler: {
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let debugVC = SecurityPolicyActionHandlerViewController()
                Navigator.shared.push(debugVC, from: fromVC)
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "「动态缓存」Tests", cellType: .normal, normalHandler: {
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let debugVC = SecurityPolicyCacheTestsVC()
                Navigator.shared.push(debugVC, from: fromVC)
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "场景事件", cellType: .normal, normalHandler: {
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let debugVC = SecurityPolicySceneEventTestVC(resolver: self.userResolver)
                Navigator.shared.push(debugVC, from: fromVC)
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "缓存内容查看", cellType: .normal, normalHandler: {
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let debugVC = SecurityPolicyCacheViewController(userResolver: self.userResolver)
                Navigator.shared.push(debugVC, from: fromVC)
            })
        }

        debugEntrance.regist(section: .securityPolicy) {
            SCDebugModel(cellTitle: "安全 SDK 快捷入口", cellType: .switchButton, switchHandler: { isOn in
                guard let window = Navigator.shared.mainSceneWindow,
                      let debugEntrance = try? self.resolver.resolve(assert: SCDebugEntrance.self) else { return }
                let viewTag = 1000_002
                if isOn {
                    let models = debugEntrance.generateSectionViewModels(section: .securityPolicy)
                    let floatView = SecurityComplianeDebugFloatView(viewTag: viewTag, isZoomable: true)
                    let contentView = SCDebugSectionView(model: models)
                    window.addSubview(floatView)
                    floatView.addSubview(contentView)
                    floatView.snp.makeConstraints {
                        $0.width.height.equalTo(200)
                        $0.center.equalToSuperview()
                    }
                } else {
                    if let floatView = window.viewWithTag(viewTag) {
                        floatView.removeFromSuperview()
                    }
                }
            })
        }
    }
    
    private var operateTypeMap: [EntityOperate: PermissionType] = [
        .ccmExport: .fileExport,
        .ccmAttachmentDownload: .fileDownload,
        .ccmCopy: .fileCopy,
        .ccmFileDownload: .fileDownload,
        .imFileDownload: .fileDownload,
        .imFilePreview: .localFilePreview
    ]
   
    func inputMockCache() {
        let passportService = try? userResolver.resolve(assert: PassportService.self)
        guard let window = Navigator.shared.mainSceneWindow,
              let fromVC = window.fromViewController,
              let uid = passportService?.foregroundUser?.userID,
              let tid = passportService?.foregroundUser?.tenant.tenantID else { return }
        
        var loading: UDToast?
        
        let alert = UIAlertController(title: "导入动态缓存", message: nil, preferredStyle: .alert)
        alert.addTextField()
        let action = UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
            let str = alert?.textFields?[0].text
            let count = Int(str ?? "10") ?? 10
            let groupSize = 50
            var groups = count / groupSize
            if count % groupSize > 0 {
                groups += 1
            }
            let allGroups = Array((0..<groups).map { Array($0 * groupSize ..< min(($0 + 1) * groupSize, count)) })
            var index = 0
            
            func insertCache(_ msgIDs: [Int]) {
                guard !msgIDs.isEmpty else {
                    loading?.remove()
                    DispatchQueue.runOnMainQueue {
                        UDToast().showTips(with: "导入动态缓存完成", on: UIWindow.ud.keyWindow!)
                    }
                    return
                }
                let service = try? self.userResolver.resolve(assert: SecurityPolicyService.self)
                let config = ValidateConfig(ignoreSecurityOperate: true)
                DispatchQueue.main.async {
                    if loading == nil {
                        loading = UDToast.showLoading(with: "缓存创建中，进度\(index)/\(groups)", on: UIWindow.ud.keyWindow!)
                    } else {
                        loading?.updateToast(with: "缓存创建中，进度\(index)/\(groups)", superView: UIWindow.ud.keyWindow!)
                    }

                }
                var testPolicyModels = [PolicyModel]()
                msgIDs.forEach {
                    let entity = IMFileEntity(entityType: .imMsg,
                                              entityDomain: .im,
                                              entityOperate: .imFileRead,
                                              operatorTenantId: Int64(tid) ?? 0,
                                              operatorUid: Int64(uid) ?? 0,
                                              fileBizDomain: .im,
                                              senderUserId: 7171410947632791572,
                                              senderTenantId: 1)
                    entity.msgId = String($0)
                    let model = PolicyModel(.imFileRead, entity)
                    testPolicyModels.append(model)
                }
                service?.asyncValidate(policyModels: testPolicyModels, config: config) { _ in
                    index += 1
                    if allGroups.count <= index {
                        insertCache([])
                    } else {
                        insertCache(allGroups[index])
                    }
                }
            }
            insertCache(allGroups[index])
        }
        alert.addAction(action)
        let cancel = UIAlertAction(title: "cancel", style: .cancel)
        alert.addAction(cancel)
        DispatchQueue.runOnMainQueue {
            Navigator.shared.present(alert, from: fromVC)
        }
    }
}
