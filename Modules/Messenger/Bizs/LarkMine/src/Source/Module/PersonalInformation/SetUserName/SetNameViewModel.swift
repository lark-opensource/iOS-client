//
//  SetNameViewModel.swift
//  LarkMine
//
//  Created by 李勇 on 2019/9/23.
//

import Foundation
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface

final class SetNameViewModel {
    private let chatterAPI: ChatterAPI
    let oldName: String
    let nameType: SetNameType

    init(chatterAPI: ChatterAPI, oldName: String, nameType: SetNameType = .name) {
        self.chatterAPI = chatterAPI
        self.oldName = oldName
        self.nameType = nameType
    }

    func setUserName(name: String) -> Observable<Void> {
        switch self.nameType {
        case .name:
            return self.chatterAPI.setUserName(name: name)
        case .anotherName:
            return self.chatterAPI.setAnotherName(anotherName: name)
        }
    }

    var nameEmptyEnable: Bool {
        switch self.nameType {
        case .name:
            return false
        case .anotherName:
            return true
        }
    }

    var title: String {
        switch self.nameType {
        case .name:
            return BundleI18n.LarkMine.Lark_Setting_NameEdit
        case .anotherName:
            return BundleI18n.LarkMine.Lark_ProfileMyAlias_EditAlias_PageTitle
        }
    }

    var placeholderTitle: String {
        switch self.nameType {
        case .name:
            return ""
        case .anotherName:
            return BundleI18n.LarkMine.Lark_ProfileMyAlias_EnterAlias_Placeholder
        }
    }

    func trackView() {
        if self.nameType == .name {
            /// 仅别名时候加埋点
            return
        }
        MineTracker.trackEditAnotherNameView()
    }

    func trackSaveBtnClick(name: String?, success: Bool) {
        if self.nameType == .name {
            /// 仅别名时候加埋点
            return
        }
        var trackName = name ?? ""
        let target = success ? "setting_personal_information_view" : "none"
        MineTracker.trackEditAnotherNameClick(click: "save",
                                             target: target,
                                             nickNameLength: trackName.count,
                                             nickNameChanged: self.oldName != trackName)
    }

    func trackCancleBtnClick(name: String?) {
        if self.nameType == .name {
            /// 仅别名时候加埋点
            return
        }
        var trackName = name ?? ""
        MineTracker.trackEditAnotherNameClick(click: "cancel",
                                              target: "setting_personal_information_view",
                                              nickNameLength: trackName.count,
                                              nickNameChanged: self.oldName != trackName)
    }
}
