//
//  MinePersonalInformationRouter.swift
//  LarkMine
//
//  Created by 姚启灏 on 2018/12/26.
//

import Foundation

protocol MinePersonalInformationRouter: AnyObject {
    func presentAssetBrowser(_ controller: MinePersonalInformationViewController, avatarKey: String, entityId: String, supportReset: Bool)
    func pushSetUserName(_ controller: MinePersonalInformationViewController, oldName: String)
    func pushSetAnotherName(_ controller: MinePersonalInformationViewController, oldName: String)
    func openMyQrcodeController(_ controller: MinePersonalInformationViewController)
    func openMedalController(_ controller: MinePersonalInformationViewController, userID: String)
    func openWorkDescription(_ controller: MinePersonalInformationViewController, completion: @escaping (String) -> Void)
    func openLink(_  mineMaincontroller: MinePersonalInformationViewController, linkURL: URL?, isShowDetail: Bool)
    func pushSetTextViewController(_ controller: MinePersonalInformationViewController, key: String, pageTitle: String, text: String, successCallBack: @escaping (String) -> Void)
    func pushSetLinkViewController(_ controller: MinePersonalInformationViewController,
                                   key: String,
                                   pageTitle: String,
                                   text: String,
                                   link: String,
                                   successCallBack: @escaping (String, String) -> Void)
}
