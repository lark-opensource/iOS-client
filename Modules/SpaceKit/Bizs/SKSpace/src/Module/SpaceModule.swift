//
//  SpaceModule.swift
//  SKECM
//
//  Created by guoqp on 2020/6/30.
//

import Foundation
import SKFoundation
import SKCommon
import RxRelay
import EENavigator
import SKResource
import SpaceInterface
import SKInfra
import LarkDocsIcon
import LarkBizAvatar
import LarkContainer
import LarkNavigator

public final class SpaceModule: ModuleService {
    
    private var userResolver: UserResolver {
        Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
    }

    public init() { }

    public func setup() {
        
        DocsLogger.info("SpaceModule setup")
        let userContainer = Container.shared.inObjectScope(CCMUserScope.userScope)
        
        DocsContainer.shared.register(SpaceModule.self, factory: { _ in
            return self
        }).inObjectScope(.container)

        DocsContainer.shared.register(SpaceAutoRefresherFactory.self) { (r) -> SpaceAutoRefresherFactory in
            return SpaceAutoRefresherFactory(resolver: r)
        }.inObjectScope(.container)

        DocsContainer.shared.register(PopViewManagerProtocol.self, factory: { _ in
            return PopViewManager()
        }).inObjectScope(.container) //


        DocsContainer.shared.register(FileManualOfflineManagerAPI.self, factory: { _ in
            return FileListManualOfflineManager()
        }).inObjectScope(.container) //

        DocsContainer.shared.register(ManuOfflineRNWatcherAPI.self, factory: { _ in
            return ManuOfflineRNWatcher()
        }).inObjectScope(.container) //

        DocsContainer.shared.register(SubFolderVCProtocol.self, factory: { _ in
            return SubFolderVCChecker()
        }).inObjectScope(.container) //

        DocsContainer.shared.register(SpaceBadgeConfig.self) { _ in
            return SpaceEmptyBadgeConfig()
        }.inObjectScope(.user)
        
        userContainer.register(TemplateSpaceFolderPickerCreator.self) { userResolver in
            return DirectoryPickerFactory(userResolver: userResolver)
        }

        DocsContainer.shared.register(DataCenterAPI.self) { _ in
            let shared = SKDataManager.shared
            shared.dataModelsContainer = DataModelsContainer.shared
            return shared
        }.inObjectScope(.container)

        
        // 给 More 面板使用
        DocsContainer.shared.register(SpaceManagementAPI.self) { _ in
            return SpaceInteractionHelper.default
        }

        userContainer.register(SpaceFolderPickerProvider.self) { userResolver in
            return DirectoryPickerFactory(userResolver: userResolver)
        }

        DocsContainer.shared.register(SpaceUploadFileListService.self) { _ in
            let dataManager = SKDataManager.shared
            let uploadService = DocsContainer.shared.resolve(DriveUploadCallbackServiceBase.self)!
            return SpaceUploadFileListService(dataManager: dataManager, uploadService: uploadService)
        }.inObjectScope(.container)
        
        userContainer.register(SpaceVCFactory.self) { userResolver in
            return SpaceVCFactory(userResolver: userResolver)
        }
        
        userContainer.register(FolderRouterService.self) { userResolver in
            return FolderRouterManager(userResolver: userResolver)
        }
        
        userContainer.register(SpacePerformanceTracker.self) { _ in
            return SpacePerformanceTracker()
        }

        
        //后续考虑看下放其他地方是否更合理
        DocsIconCustomBinder.shared.register(model: SpaceList.ThumbnailInfo.self, binder: ThumbnailInfoBinder())
        
    }

    public func registerURLRouter() {
        // 打开我的空间：lark://ccm/space/me
        Navigator.shared.registerRoute.plain("//ccm/space/me").priority(.high).factory(SpaceMeRouterHandler.init(resolver:))
        
        // 打开收藏列表：lark://ccm/favorite/list
        Navigator.shared.registerRoute.plain("//ccm/favorite/list").priority(.high).factory(SpaceFavoriteListRouterHandler.init(resolver:))
        
        // 打开云盘我的文件夹： lark://ccm/cloudDrive/myFolder
        Navigator.shared.registerRoute.plain("//ccm/cloudDrive/myFolder").priority(.high).factory(CloudDriveMyFolderRouterHandler.init(resolver:))
    }

    public func userDidLogin() {
        // 触发监听
        _ = DocsContainer.shared.resolve(SpaceUploadFileListService.self)
    }
    
    public func userDidLogout() {
    }

}

final class SpaceMeRouterHandler: UserRouterHandler {
    static func compatibleMode() -> Bool { CCMUserScope.compatibleMode }
    
    func handle(req: EENavigator.Request, res: EENavigator.Response) throws {
        let spaceVCFactory =  try userResolver.resolve(assert: SpaceVCFactory.self)
        let containerVC = SpaceListContainerController(contentViewController: spaceVCFactory.makeNewMySpaceViewController(), title: BundleI18n.SKResource.Doc_List_My_Space)

        res.end(resource: containerVC)
    }
    
}

final class SpaceFavoriteListRouterHandler: UserRouterHandler {
    static func compatibleMode() -> Bool { CCMUserScope.compatibleMode }
    
    func handle(req: EENavigator.Request, res: EENavigator.Response) throws {
        let spaceVCFactory =  try userResolver.resolve(assert: SpaceVCFactory.self)
        let containerVC = SpaceListContainerController(contentViewController: spaceVCFactory.makeNewFavoriteViewController(), title: BundleI18n.SKResource.Doc_List_MainTabHomeFavorite)
        
        res.end(resource: containerVC)
    }
    
}

final class CloudDriveMyFolderRouterHandler: UserRouterHandler {
    static func compatibleMode() -> Bool { CCMUserScope.compatibleMode }
    
    func handle(req: EENavigator.Request, res: EENavigator.Response) throws {
        let spaceVCFactory =  try userResolver.resolve(assert: SpaceVCFactory.self)
        let containerVC = spaceVCFactory.makeCloudDriveViewControllerV2()
        
        res.end(resource: containerVC)
    }
}

