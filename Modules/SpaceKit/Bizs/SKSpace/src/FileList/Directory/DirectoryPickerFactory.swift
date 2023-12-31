//
//  DirectoryPickerFactory.swift
//  SKECM
//
//  Created by wenfeng lin on 2021/6/3.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource
import SKInfra
import SpaceInterface
import LarkContainer

private extension DirectoryUtilContextType {
    var targetFolderType: WorkspacePickerTracker.TargetFolderType {
        switch self {
        case .mySpace:
            return .folder
        case .shareSpace:
            return .sharedFolder
        case let .subFolder(folderType):
            return folderType.isShareFolder ? .sharedFolder : .folder
        }
    }
}

public extension DirectoryUtilLocation {
    var folderPickerLocation: SpaceFolderPickerLocation {
        SpaceFolderPickerLocation(folderToken: folderToken,
                                  folderType: folderType,
                                  isExternal: isExternal,
                                  canCreateSubNode: canCreateSubNode,
                                  targetModule: targetModule,
                                  targetFolderType: contextType.targetFolderType)
    }
}

class DirectoryPickerFactory: TemplateSpaceFolderPickerCreator, SpaceFolderPickerProvider {
    
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    func createPicker(with completion: @escaping (_ folderToken: String, _ folderVersion: Int, _ controller: UIViewController) -> Void) -> UIViewController {
        let tracker = WorkspacePickerTracker(actionType: .createFile, triggerLocation: .topBar)
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.Doc_Facade_AddTo,
                                           action: .createSpaceShortcut,
                                           entrances: .spaceOnly,
                                           tracker: tracker) { location, picker in
            guard case let .folder(folderLocation) = location else {
                spaceAssertionFailure("picker should not return non-space location")
                return
            }
            completion(folderLocation.folderToken, folderLocation.folderType.v2 ? 2 : 1, picker)
        }
        let context = DirectoryEntranceContext(action: .callback(completion: { location, controller in
            let folderVersion = location.folderType.v2 ? 2 : 1
            completion(location.folderToken, folderVersion, controller)
        }),
                                               pickerConfig: config)
                
        return DirectoryEntranceController(userResolver: userResolver, context: context)
    }

    func createMySpacePicker(config: WorkspacePickerConfig) -> UIViewController {
        let callback: DirectoryUtilCallback = { location, picker in
            config.completion(.folder(location: location.folderPickerLocation), picker)
        }
        let context = DirectoryUtilContext(action: .callback(completion: callback),
                                           desFile: nil,
                                           desType: .mySpace,
                                           ownerTypeChecker: config.ownerTypeChecker,
                                           pickerConfig: config,
                                           targetModule: .personal)
        context.actionName = config.actionName
        let controller = DirectoryUtilController(context: context)
        controller.navigationBar.title = UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? BundleI18n.SKResource.LarkCCM_NewCM_MyFolder_Menu : BundleI18n.SKResource.Doc_List_My_Space
        return controller
    }

    func createShareSpacePicker(config: WorkspacePickerConfig) -> UIViewController {
        let callback: DirectoryUtilCallback = { location, picker in
            config.completion(.folder(location: location.folderPickerLocation), picker)
        }
        let context = DirectoryUtilContext(action: .callback(completion: callback),
                                           desFile: nil,
                                           desType: .shareSpace,
                                           ownerTypeChecker: config.ownerTypeChecker,
                                           pickerConfig: config,
                                           targetModule: .shared)
        context.actionName = config.actionName
        let controller = DirectoryUtilController(context: context)
        if SettingConfig.singleContainerEnable && !LKFeatureGating.newShareSpace {
            controller.navigationBar.title = UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? BundleI18n.SKResource.LarkCCM_NewCM_SharedFolder_Menu : BundleI18n.SKResource.CreationMobile_ECM_ShareWithMe_Tab
        } else {
            controller.navigationBar.title = UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? BundleI18n.SKResource.LarkCCM_NewCM_SharedFolder_Menu : BundleI18n.SKResource.Doc_List_Shared_Space
        }
        return controller
    }

    func createFolderPicker(config: WorkspacePickerConfig, recentEntry: WorkspacePickerSpaceEntry) -> UIViewController {
        let completion = config.completion
        let callback: DirectoryUtilCallback = { location, picker in
            completion(.folder(location: location.folderPickerLocation), picker)
        }
        let folderEntry = FolderEntry(type: .folder,
                                      nodeToken: recentEntry.folderToken,
                                      objToken: recentEntry.folderToken)
        // 更新几个必要的字段
        folderEntry.updateName(recentEntry.name)
        folderEntry.updateOwnerType(recentEntry.folderType.ownerType)
        folderEntry.updateExtraValue(recentEntry.extra)
        let context = DirectoryUtilContext(action: .callback(completion: callback),
                                           desFile: folderEntry,
                                           desType: .subFolder(folderType: recentEntry.folderType),
                                           ownerTypeChecker: config.ownerTypeChecker,
                                           pickerConfig: config,
                                           targetModule: .space)
        context.actionName = config.actionName
        let vc = DirectoryUtilController(context: context)
        vc.navigationBar.title = recentEntry.name
        return vc
    }

}
