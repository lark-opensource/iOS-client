//
//  NameCardEditDependency.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/4/13.
//

import Foundation
import LarkSDKInterface
import RxSwift
import RustPB

protocol NameCardEditDependency {
    /// 添加联系人个人信息
    /// @params namecardInfo: 描述联系人的结构体
    /// @params accountID: 联系人所属邮箱账号id
    func setSingleNamecard(namecardInfo: RustPB.Email_Client_V1_NamecardMetaInfo, accountID: String) -> Observable<RustPB.Email_Client_V1_SetSingleNamecardResponse>

    /// 更新联系人信息
    /// @params namecard: 描述联系人的结构体
    /// @params accountID: 联系人所属邮箱账号id
    func updateSingleNamecard(namecard: RustPB.Email_Client_V1_NamecardMetaInfo, accountID: String) -> Observable<RustPB.Email_Client_V1_UpdateSingleNamecardResponse>

    /// 获取联系人信息
    /// @params id: 联系人id
    /// @params accountID: 联系人所属邮箱账号id
    func getNamecardsByID(_ id: String, accountID: String) -> Observable<RustPB.Email_Client_V1_NamecardMetaInfo?>

    /// 获取当前账号的所有邮箱账号及邮箱账号下的联系人和群组数量
    func getAllMailAccountDetail(latest: Bool) -> Observable<[MailAccountBriefInfo]>
}

final class NameCardEditDependencyImpl: NameCardEditDependency {

    let namecardAPIProvider: () -> NamecardAPI
    lazy var namecardAPI: NamecardAPI = {
        namecardAPIProvider()
    }()

    init(namecardAPIProvider: @escaping () -> NamecardAPI) {
        self.namecardAPIProvider = namecardAPIProvider
    }

    /// 添加联系人个人信息
    /// @params namecardInfo: 描述联系人的结构体
    /// @params accountID: 联系人所属邮箱账号id
    func setSingleNamecard(namecardInfo: RustPB.Email_Client_V1_NamecardMetaInfo, accountID: String) -> Observable<RustPB.Email_Client_V1_SetSingleNamecardResponse> {
        return namecardAPI.setSingleNamecard(namecardInfo: namecardInfo, accountID: accountID)
    }

    /// 更新联系人信息
    /// @params namecard: 描述联系人的结构体
    /// @params accountID: 联系人所属邮箱账号id
    func updateSingleNamecard(namecard: RustPB.Email_Client_V1_NamecardMetaInfo, accountID: String) -> Observable<RustPB.Email_Client_V1_UpdateSingleNamecardResponse> {
        return namecardAPI.updateSingleNamecard(namecard: namecard, accountID: accountID)
    }

    /// 获取联系人信息
    /// @params id: 联系人id
    /// @params accountID: 联系人所属邮箱账号id
    func getNamecardsByID(_ id: String, accountID: String) -> Observable<RustPB.Email_Client_V1_NamecardMetaInfo?> {
        return namecardAPI.getNamecardsByID(id, accountID: accountID)
    }

    /// 获取当前账号的所有邮箱账号及邮箱账号下的联系人和群组数量
    func getAllMailAccountDetail(latest: Bool) -> Observable<[MailAccountBriefInfo]> {
        return namecardAPI.getAllMailAccountDetail(latest: latest)
    }
}
