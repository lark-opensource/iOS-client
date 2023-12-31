//
//  FavoriteControllerRequestHandler.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import LarkContainer
import LarkModel
import RustPB
import LKCommonsLogging
import RxSwift
import Swinject
import EENavigator
import LarkMessengerInterface
import LarkMessageCore
import LarkAccountInterface
import LarkNavigator
import LarkSDKInterface

final class FavoriteListHandler: UserTypedRouterHandler {

    @ScopedInjectedLazy private var messageAPI: MessageAPI?

    private let disposeBag = DisposeBag()

    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    func handle(_ body: FavoriteListBody, req: EENavigator.Request, res: Response) throws {
        ChatTracker.trackShowFavoriteList()
        let listController = try self.createListController()
        let navigator = self.navigator
        let resolver = self.resolver
        let userResolver = self.userResolver
        listController.pushDetailController = { (cellViewModel, targetVC) in
            FavoriteDetailHander.pushDetailController(with: cellViewModel,
                                             targetVC: targetVC,
                                             navigator: navigator,
                                             resolver: resolver,
                                             userResolver: userResolver)
        }
        res.end(resource: listController)
    }

    private func createListController() throws -> FavoriteListController {
        let listFactory = FavoriteListViewModelFactory()
        let dataProvider = try FavoriteVMDataProvider(resolver: userResolver)
        let costInfo = EnterFavoriteCostInfo()
        let listVM = FavoriteViewModel(userResolver: userResolver, viewModelFactory: listFactory, dataProvider: dataProvider, enterCostInfo: costInfo)
        let listController = FavoriteListController(viewModel: listVM, enterCostInfo: costInfo)

        let dispatcher = RequestDispatcher(userResolver: userResolver, label: "FavoriteListCellFactory")
        FavoriteActionFactory(
            resolver: resolver,
            dispatcher: dispatcher,
            controller: listController,
            assetsProvider: listVM
        ).registerActions()
        FavoriteListControllerActionFactory(
            dispatcher: dispatcher,
            controller: listController
        ).registerActions()
        listController.cellFactory = FavoriteListCellFactory(
            dispatcher: dispatcher,
            tableView: listController.table
        )
        costInfo.initViewStamp = CACurrentMediaTime()
        return listController
    }
}
