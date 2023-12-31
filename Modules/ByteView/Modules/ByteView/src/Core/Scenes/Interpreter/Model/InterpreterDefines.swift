//
//  InterpreterDefination.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/10/26.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxDataSources
import RxSwift
import RxCocoa
import ByteViewCommon
import ByteViewNetwork

struct InterpretationChannelInfo: Equatable {
    /// 会前预设（仅视频会议设置页）
    var preUser: User?
    /// 会中管理
    var user: ByteviewUser?
    var avatarInfo: AvatarInfo?
    var displayName: String?
    var interpreterSetting: InterpreterSetting
    // 用于列表的UI展示
    var isFirstCell: Bool = false
    var interpreterIndex: Int = 0
    // 用于标记即将被移除的interpreter
    var willBeRemoved: Bool = false
    /// 入会状态，默认已入会
    var joined: Bool = true
}

extension InterpretationChannelInfo {
    var localIdentifier: String {
        return String(interpreterSetting.interpreterSetTime)
    }

    var isEmpty: Bool {
        return user == nil && interpreterSetting.isEmpty
    }

    var isFull: Bool {
        return user != nil && interpreterSetting.isFull
    }

    func convertToSetInterpreter() -> SetInterpreter? {
        guard let user = user else { return nil }
        return .init(user: user, interpreterSetting: willBeRemoved ? nil : interpreterSetting, isDeleteInterpreter: willBeRemoved)
    }

    var isPreSetFull: Bool {
        return preUser != nil && interpreterSetting.isFull
    }

    func convertToPreSetInterpreter() -> SetInterpreter? {
        guard let preUser = preUser, interpreterSetting.isFull else { return nil }
        let bvUser = ByteviewUser(id: preUser.id, type: .larkUser, deviceId: "0")
        return .init(user: bvUser, interpreterSetting: interpreterSetting, isDeleteInterpreter: false)
    }

    func convertToPreSetWebinarInterpreter() -> SetInterpreter? {
        if let preUser = preUser {
            let bvUser = ByteviewUser(id: preUser.id, type: .larkUser, deviceId: "0")
            return .init(user: bvUser, interpreterSetting: interpreterSetting, isDeleteInterpreter: false)
        } else if !interpreterSetting.isEmpty {
            let bvUser = ByteviewUser(id: "", type: .unknown, deviceId: "")//当没填写议员时用于占位
            return .init(user: bvUser, interpreterSetting: interpreterSetting, isDeleteInterpreter: false)
        }
        return nil
    }

    mutating func updateUser(_ u: ByteviewUser, avatarInfo: AvatarInfo, displayName: String) {
        self.user = u
        self.avatarInfo = avatarInfo
        self.displayName = displayName
    }

    mutating func updatePreUser(_ u: User, avatarInfo: AvatarInfo, displayName: String) {
        self.preUser = u
        self.avatarInfo = avatarInfo
        self.displayName = displayName
    }

    mutating func updateLanguageType(language: LanguageType, isFirstLang: Bool) {
        if isFirstLang {
            self.interpreterSetting.firstLanguage = language
        } else {
            self.interpreterSetting.secondLanguage = language
        }
    }
}

struct InterpreterSectionModel {
    var items: [InterpretationChannelInfo]
}

extension InterpreterSectionModel: SectionModelType {
    init(original: InterpreterSectionModel, items: [InterpretationChannelInfo]) {
        self = original
        self.items = items
    }
}

struct InterpreterInformation {
    var languageType: LanguageType?
    var avatarInfo: AvatarInfo?
    var description: String?
    var descriptionColor: UIColor?
    var joinState: String?
    var icon: UIImage?
}

extension LanguageType {
    var isEmpty: Bool {
        return languageType.isEmpty
    }

    func sameAs(lang: LanguageType) -> Bool {
        return self.languageType == lang.languageType
    }
}

extension InterpreterSetting {
    var isEmpty: Bool {
        return firstLanguage.isEmpty && secondLanguage.isEmpty
    }

    var isFull: Bool {
        return !firstLanguage.isEmpty && !secondLanguage.isEmpty
    }

    var identifier: String {
        return "\(firstLanguage.languageType)_\(secondLanguage.languageType)"
    }

    func sameAs(setting: InterpreterSetting) -> Bool {
        return self.firstLanguage.sameAs(lang: setting.firstLanguage)
            && self.secondLanguage.sameAs(lang: setting.secondLanguage)
    }
}

extension InterpreterSetting {
    var isUserConfirm: Bool {
        confirmStatus == .confirmed
    }

    var userIsOnTheCall: Bool {
        confirmStatus == .reserve || confirmStatus == .waitConfirm || confirmStatus == .confirmed
    }
}
