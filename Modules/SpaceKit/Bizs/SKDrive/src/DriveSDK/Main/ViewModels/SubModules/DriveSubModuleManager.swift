//
//  DriveSubModuleManager.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/18.
//

import Foundation
import SKCommon
import SKFoundation

protocol DKSubModuleType: AnyObject {
    var hostModule: DKHostModuleType? { get }
    func bindHostModule() -> DKSubModuleType 
    func unBind()
}

// 预览场景，目前附件类型和云盘文件同一个预览流程，通过scene区分两种场景需要挂载的子模块
// IM附件有单独的预览流程
enum DKPreviewScene {
    case space
    case attach
    case im
}
class DriveSubModuleManager {
    private var subModules: [DKSubModuleType] = []
    deinit {
        DocsLogger.driveInfo("DriveSubModuleManager -- deinit")
    }
    func registerSubModules(secne: DKPreviewScene, hostModule: DKHostModuleType) {
        switch secne {
        case .space:
            registerSpaceModules(hostModule: hostModule)
        case .attach:
            registerAttachModule(hostModule: hostModule)
        default:
            break
        }
    }
    
    func unRegist() {
        for module in subModules {
            module.unBind()
        }
        subModules.removeAll()
    }
    
    func count() -> Int {
        return subModules.count
    }
    
    private func registerSpaceModules(hostModule: DKHostModuleType) {
        subModules.append(DKMoreVCModule(hostModule: hostModule, windowSizeDependency: hostModule.windowSizeDependency).bindHostModule())
        subModules.append(DKOpenInOtherAppModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKShareVCModule(hostModule: hostModule, uiDependency: hostModule.windowSizeDependency).bindHostModule())
        subModules.append(DKMyAIServiceModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKInlineAIServiceModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKUserPermissionModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKPublicPermissionSettingModule(hostModule: hostModule,
                                                          windowSizeDependency: hostModule.windowSizeDependency).bindHostModule())
        subModules.append(DKRenameModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKReadingDataModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKHistoryRecordModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKSpaceNaviBarModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKDocsInfoUpdator(hostModule: hostModule).bindHostModule())
        subModules.append(DKMultiVersionModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKFeedModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKCommentModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKDeleteMonitorModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKSecretMonitorModule(hostModule: hostModule).bindHostModule())
        subModules.append(DKSecretSettingVCModule(hostModule: hostModule, windowSizeDependency: hostModule.windowSizeDependency).bindHostModule())
        subModules.append(DKContainerInfoModule(hostModule: hostModule).bindHostModule())
    }
    
    private func registerAttachModule(hostModule: DKHostModuleType) {
        subModules.append(DKNaviBarModule(hostModule: hostModule).bindHostModule())
    }
}
