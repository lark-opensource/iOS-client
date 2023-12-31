//
//  MineMainRouter.swift
//  Lark
//
//  Created by 姚启灏 on 2018/6/26.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel

protocol MineModuleRouter: AnyObject {
    var hostProvider: () -> UIViewController? { get set }
}

protocol MineMainRouter: MineModuleRouter {
    func openFocusListController(_ controller: MineMainViewController, sourceView: UIView)
    func openAwardActivityEntry(_ activityURL: String, controller: MineMainViewController)
    func openWalletController(_ controller: MineMainViewController, walletUrl: String?)
    func openFavoriteController(_ controller: MineMainViewController)
    func openDataController(_ controller: MineMainViewController)
    func openSettingController(_ controller: MineMainViewController)
    func openWorkDescription(_ controller: MineMainViewController, completion: @escaping (String) -> Void)
    func openCustomServiceChat(_ controller: MineMainViewController)
    func openCustomServiceChatById(_ controller: MineMainViewController, id: String, reportLocation: Bool)
    func openPersonalInformationController(_ controller: MineMainViewController, chatter: Chatter, completion: @escaping (String) -> Void)
    func openProfileDetailController(_ controller: MineMainViewController, chatter: Chatter)
    func openSetUserName(_ controller: MineMainViewController, oldName: String)
    func openSetAnotherName(_ controller: MineMainViewController, oldName: String)
    func presentAssetBrowser(_ controller: MineMainViewController, avatarKey: String, entityId: String)
    func openLink(_  mineMaincontroller: MineMainViewController, linkURL: URL?, isShowDetail: Bool)
    func openTeamConversionController(_ controller: MineMainViewController)
}
