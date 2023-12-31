//
//  InvitationViewModel.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/9/10.
//

import Foundation
import LarkModel
import RxSwift
import LarkSDKInterface
import LarkAppConfig
import RustPB

final class InvitationViewModel {
    private let chatApplicationAPI: ChatApplicationAPI
    private let disposeBag = DisposeBag()
    private let appConfiguration: AppConfiguration
    /// 能否邀请国外用户，只对飞书用户有用
    let inviteAbroadphone: Bool
    /// 是否是海外用户
    let isOversea: Bool
    var content: String

    var hotDatasource: [MobileCode] = []
    var allDatasource: [MobileCode] = []

    init(chatApplicationAPI: ChatApplicationAPI,
         content: String,
         appConfiguration: AppConfiguration,
         inviteAbroadphone: Bool,
         isOversea: Bool
        ) {
        self.chatApplicationAPI = chatApplicationAPI
        self.content = content
        self.appConfiguration = appConfiguration
        self.inviteAbroadphone = inviteAbroadphone
        self.isOversea = isOversea
    }

    func loadData() {
        self.chatApplicationAPI.fetchMobileCode()
            .subscribe(onNext: { [weak self] (mobileData) in
                let mobileDataDictionary = mobileData.mobileCodes.lf_toDictionary({ $0.key })
                mobileData.hotKeys.forEach({ (key) in
                    if let data = mobileDataDictionary[key] {
                        self?.hotDatasource.append(data)
                    }
                })
                mobileData.mobileCodes.forEach({ (mobileCode) in
                    self?.allDatasource.append(mobileCode)
                })
            }).disposed(by: self.disposeBag)
    }

    func invite(type: RustPB.Contact_V1_SendUserInvitationRequest.TypeEnum, content: String) -> Observable<InvitationResult> {
        self.content = content
        switch type {
        case .email:
            Tracer.trackInviteByEmail()
        case .mobile:
            Tracer.trackInviteByPhone()
        case .unknown:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
        return chatApplicationAPI.invitationUser(invitationType: type, contactContent: content)
    }
}
