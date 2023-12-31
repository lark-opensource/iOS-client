//
//  DataModelSContainer.swift
//  SKSpace
//
//  Created by guoqp on 2021/7/1.
//

import Foundation
import SKFoundation
import SKCommon
import SwiftyJSON
import RxCocoa
import RxRelay
import RxSwift
import SKInfra

public protocol DataModelsContainerProtocol: AnyObject {
    func getMyFolder() -> SpaceEntry?
}

public final class DataModelsContainer: NSObject, DataModelsContainerProtocol {
    private let disposeBag = DisposeBag()
    private let resolver: DocsResolver = DocsContainer.shared

    /// 手动离线
    private lazy var manualOfflineNotifySection: ManuOffLineNotifySection = {
        let section = ManuOffLineNotifySection()
        return section
    }()

    public static let shared = DataModelsContainer()

    override init() {
        super.init()
        
        SKDataManager.shared.dbLoadingState.subscribe(onNext: { ret in
            if ret {
                self.doSomethingWhenDbLoad()
            } else {
                self.clear()
            }
        }).disposed(by: disposeBag)
    }

    private func doSomethingWhenDbLoad() {
        self.resolver.resolve(DocsBulletinManager.self)?.reloadData()
        self.resolver.resolve(ListConfigAPI.self)?.excuteAllDelayedBlocks()
        /// 准备好数据，延迟加载之后，这两个列表数据依旧需要，考虑到从不进入云空间，从lark首页搜索进入文件夹列表页没有数据情况
        MyFolderDataModel.fetchRootToken().disposed(by: disposeBag)
        self.manualOfflineNotifySection.notify()
//        if UserScopeNoChangeFG.WWJ.userDefaultLocationEnabled {
//            WorkspaceCreateDirector.updateDefaultCreateLocation().subscribe().disposed(by: disposeBag)
//        }
    }
    

    public func clear() {
        self.manualOfflineNotifySection.clear()

        DocsContainer.shared.resolve(DocsBulletinManager.self)?.clear()
        /// 清除首页pin和star相关的FG配置，为了tab大空间的UI路由功能更加安全
        clearFileManualOfflineMgr()
    }

    private func clearFileManualOfflineMgr() {
        /// 清除手动离线相关的FG配置，为了tab大空间的UI路由功能更加安全
        ManualOfflineConfig.clear()
        guard
            let fmoMgr = resolver.resolve(FileManualOfflineManagerAPI.self)
        else {
            return
        }
        fmoMgr.clear()
        guard
            let popMgr = resolver.resolve(PopViewManagerProtocol.self)
        else {
            return
        }
        popMgr.clear()
    }

    public func getMyFolder() -> SpaceEntry? {
        let token = MyFolderDataModel.rootToken
        if !token.isEmpty {
            return SKDataManager.shared.spaceEntry(nodeToken: token)
        }
        MyFolderDataModel.fetchRootToken().disposed(by: disposeBag)
        return nil
    }
}
