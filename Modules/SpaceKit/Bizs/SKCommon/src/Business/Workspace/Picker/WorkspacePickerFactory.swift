//
//  WorkspacePickerFactory.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/9/6.
//

import Foundation
import UIKit
import LarkUIKit
import SKFoundation
import SKInfra
import SpaceInterface
import LarkContainer

public enum WorkspacePickerFactory {
    // 创建 workspace picker
    public static func createWorkspacePicker(config: WorkspacePickerConfig) -> UIViewController {
        let rootController: UIViewController
        if config.entrances == .wikiOnly,
           !((UserScopeNoChangeFG.WWJ.cloudDriveEnabled || UserScopeNoChangeFG.WWJ.newSpaceTabEnable) && MyLibrarySpaceIdCache.get() != nil) {
            rootController = createWikiPicker(config: config)
        } else {
            rootController = WorkspacePickerController(config: config)
        }
        let nav = LkNavigationController(rootViewController: rootController)
        nav.modalPresentationStyle = .pageSheet
        return nav
    }

    // 创建 wiki picker
    public static func createWikiPicker(config: WorkspacePickerConfig) -> UIViewController {
        guard let provider = try? Container.shared.resolve(assert: WikiPickerProvider.self) else {
            DocsLogger.error("can not get provider")
            return BaseViewController()
        }
        let controller = provider.createNodePicker(config: config)
        return controller
    }

    // 创建我的空间 picker
    public static func createMySpacePicker(config: WorkspacePickerConfig) -> UIViewController {
        guard let provider = try? Container.shared.resolve(assert: SpaceFolderPickerProvider.self) else {
            DocsLogger.error("can not get provider")
            return BaseViewController()
        }

        let controller = provider.createMySpacePicker(config: config)
        return controller
    }

    // 创建共享空间 picker
    public static func createShareSpacePicker(config: WorkspacePickerConfig) -> UIViewController {
        guard let provider = try? Container.shared.resolve(assert: SpaceFolderPickerProvider.self) else {
            DocsLogger.error("can not get provider")
            return BaseViewController()
        }
        
        let controller = provider.createShareSpacePicker(config: config)
        return controller
    }
    
    // 创建我的文档库 picker
    public static func createMyLibraryPicker(spaceID: String, spaceName: String, config: WorkspacePickerConfig) -> UIViewController {
        guard let provider = try? Container.shared.resolve(assert: WikiPickerProvider.self) else {
            DocsLogger.error("can not get provider")
            return BaseViewController()
        }

        let controller = provider.createMyLibraryPicker(spaceID: spaceID, spaceName: spaceName, config: config)
        return controller
    }
    
    // 创建未整理 picker
    public static func createUnorganizedPicker(config: WorkspacePickerConfig) -> UIViewController {
        let controller = UnorganizedPickerController(config: config)
        return controller
    }

    static func createNodePicker(config: WorkspacePickerConfig, recentEntry: WorkspacePickerRecentEntry) -> UIViewController {
        switch recentEntry {
        case let .wiki(entry):
            guard let provider = try? Container.shared.resolve(assert: WikiPickerProvider.self) else {
                DocsLogger.error("can not get provider")
                return BaseViewController()
            }

            let controller = provider.createNodePicker(config: config, recentEntry: entry)
            return controller
        case let .folder(entry):
            guard let provider = try? Container.shared.resolve(assert: SpaceFolderPickerProvider.self) else {
                DocsLogger.error("can not get provider")
                return BaseViewController()
            }
            
            let controller = provider.createFolderPicker(config: config, recentEntry: entry)
            return controller
        }
    }
}
