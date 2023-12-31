//
//  UrgentConfirmViewController+dataProcess.swift
//  LarkUrgent
//
//  Created by JackZhao on 2022/1/11.
//

import UIKit
import Foundation
import RustPB
import LarkModel
import CoreGraphics

enum UrgentConfirmDisplayMode {
    case single(_ chatterWappers: [ChatterWrapper])
    case group(_ groups: [UrgentConfrimChatterGroup], _ disableList: [String], _ additionalList: [String])
}

struct UrgentConfrimChatterSectionModel {
    var chatters: [Chatter]
    var title: String?
    var description: String?
    var isShowTopLine: Bool = false
    let allCount: Int
    // 不显示的人数
    var otherCount: Int?
    // 是否显示“...等x人”
    var hasOther: Bool {
        otherCount != nil
    }
    let type: UnSupportChatterType
    var descriptionMaxWidth: CGFloat = 320
    lazy var suggestHeight: CGFloat = {
        var height: CGFloat = 0
        if isShowTopLine {
            height += UrgentChatterCollectionHeader.lineTopPadding
        }
        if title != nil {
            height += UrgentChatterCollectionHeader.labelHeight + UrgentChatterCollectionHeader.labelTopPadding
        }
        if let description = description {
            height += UrgentChatterCollectionHeader.alertLabelTopPadding + heightForString(description, onWidth: descriptionMaxWidth, font: UrgentChatterCollectionHeader.alertLabelFont)
        }
        return height
    }()

    init(chatters: [Chatter],
         title: String? = nil,
         allCount: Int,
         otherCount: Int? = nil,
         isShowTopLine: Bool = false,
         description: String? = nil,
         type: UnSupportChatterType = .none) {
        self.chatters = chatters
        self.type = type
        self.title = title
        self.allCount = allCount
        self.otherCount = otherCount
        self.description = description
        self.isShowTopLine = isShowTopLine
    }

    func heightForString(_ string: String, onWidth: CGFloat, font: UIFont) -> CGFloat {
        let rect = (string as NSString).boundingRect(
            with: CGSize(width: onWidth, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.height)
    }
}

struct UrgentConfrimChatterGroup {
    var displayChatters: [Chatter]
    var allCount: Int
    let type: UnSupportChatterType
}

struct ChatterWrapper {
    var chatter: Chatter
    var unSupportChatterType: UnSupportChatterType

    init(chatter: Chatter, unSupportChatterType: UnSupportChatterType = .none) {
        self.chatter = chatter
        self.unSupportChatterType = unSupportChatterType
    }
}

enum UnSupportChatterType: Int {
    case none = 0
    case emptyName
    case emptyPhone
    case crossGroup
    case externalNotFriend

    func getDesription(urgentType: RustPB.Basic_V1_Urgent.TypeEnum) -> String {
        switch self {
        case .none:
            return ""
        case .crossGroup:
            switch urgentType {
            case .sms:
                return BundleI18n.LarkUrgent.Lark_Buzz_UnableToBuzzText_NoCrossPlatformUser
            case .phone:
                return BundleI18n.LarkUrgent.Lark_Buzz_UnableToBuzzCall_NoCrossPlatformUser
            default:
                return ""
            }
        case .emptyPhone:
            switch urgentType {
            case .sms:
                return BundleI18n.LarkUrgent.Lark_Buzz_TextBuzzFailedEmptyPhone
            case .phone:
                return BundleI18n.LarkUrgent.Lark_Buzz_CantBuzzEmptyPhoneNumber
            default:
                return ""
            }
        case .externalNotFriend:
            switch urgentType {
            case .sms:
                return BundleI18n.LarkUrgent.Lark_Buzz_UnableToBuzzText_ExternalNotFriend
            case .phone:
                return BundleI18n.LarkUrgent.Lark_Buzz_UnableToBuzzCall_ExternalNotFriend
            default:
                return ""
            }
        case .emptyName:
            switch urgentType {
            case .sms:
                return BundleI18n.LarkUrgent.Lark_Buzz_TextBuzzFailedEmptyName
            case .phone:
                return BundleI18n.LarkUrgent.Lark_Buzz_CantBuzzEmptyName
            default:
                return ""
            }
        }
    }

    // 目前端上控制, 后续可抽到setting
    func getLimit() -> Int {
        switch self {
        case .none:
            return 99
        case .crossGroup, .emptyPhone, .externalNotFriend, .emptyName:
            return 9
        }
    }
}

extension UrgentConfirmViewController {
    func updateUrgentChatters() {
        var supportChatterSectionModel: UrgentConfrimChatterSectionModel?
        var unSupportChatterSectionModels: [UrgentConfrimChatterSectionModel] = []

        var onlySupportAppUrgent = true
        let urgentType = self.urgentType
        var unsupportChattersMap: [Int: [Chatter]] = [:]
        // 根据外界不同的数据模型初始化当前页面的数据模型
        switch mode {
        // 一般来说是手用选择的人
        case .single(let chatters):
            Self.logger.info("updateUrgentChatters single, chattersCount = \(chatters.count)")
            var supportChatters: [Chatter] = []
            let allChatters = chatters
            allChatters.forEach { (wrapper) in
                let chatter = wrapper.chatter
                if wrapper.unSupportChatterType == .none {
                    // 如果有支持的人则能支持sms/phone加急
                    onlySupportAppUrgent = false
                    supportChatters.append(chatter)
                } else {
                    if self.urgentType == .app {
                        supportChatters.append(chatter)
                    } else {
                        // 组装不支持chatter的数据源
                        var unsupportChatters: [Chatter] = unsupportChattersMap[wrapper.unSupportChatterType.rawValue] ?? []
                        unsupportChatters.append(chatter)
                        unsupportChattersMap[wrapper.unSupportChatterType.rawValue] = unsupportChatters
                    }
                }
            }
            // 初始化支持的列表数据
            let title = supportSectionHeaderTitle(supportChatters.count)
            Self.logger.info("updateUrgentChatters single, supportChattersCount = \(supportChatters.count)")
            supportChatterSectionModel = UrgentConfrimChatterSectionModel(chatters: supportChatters, title: title, allCount: supportChatters.count)

            // 初始化不支持的列表数据
            unSupportChatterSectionModels = unsupportChatterTypes.compactMap { type -> UrgentConfrimChatterSectionModel? in
                guard let chatters = unsupportChattersMap[type.rawValue] else { return nil }
                return UrgentConfrimChatterSectionModel(chatters: chatters, allCount: chatters.count, type: type)
            }
            Self.logger.info("updateUrgentChatters single, unsupportChattersCount = \(unsupportChattersMap.count)")
        // 通过全选接口返回的group数组
        case .group(let groups, _, _):
            // 如果支持的列表有数据则能支持sms/phone加急
            if let group = groups.first(where: { $0.type == .none }), group.displayChatters.isEmpty == false {
                onlySupportAppUrgent = false
            }
            if self.urgentType == .app {
                let allChatters = groups.flatMap({ $0.displayChatters })
                let allCount = groups.reduce(0) { partialResult, group in
                    return group.allCount + partialResult
                }
                let title = supportSectionHeaderTitle(allCount)
                // 应用内加急初始化支持的列表数据(上游数据全部支持)
                supportChatterSectionModel = UrgentConfrimChatterSectionModel(chatters: allChatters, title: title, allCount: allCount)
            } else {
                // sms/phone加急初始化支持的列表数据
                if let group = groups.first(where: { $0.type == .none }), group.displayChatters.isEmpty == false {
                    let title = supportSectionHeaderTitle(group.allCount)
                    Self.logger.info("updateUrgentChatters group, supportChattersCount = \(group.allCount)")
                    supportChatterSectionModel = UrgentConfrimChatterSectionModel(chatters: group.displayChatters, title: title, allCount: group.allCount)
                }
                // sms/phone加急初始化不支持的列表数据
                unSupportChatterSectionModels = unsupportChatterTypes.compactMap { type -> UrgentConfrimChatterSectionModel? in
                    guard let group = groups.first(where: { $0.type == type }) else { return nil }
                    if group.allCount == 0 { return nil }
                    return UrgentConfrimChatterSectionModel(chatters: group.displayChatters,
                                                            allCount: group.allCount,
                                                            type: type)
                }
            }
        }

        self.onlySupportAppUrgent = onlySupportAppUrgent
        self.collectionHeader.supportAllType = !onlySupportAppUrgent
        // UI上对支持的chatter进行数据处理
        if let model = supportChatterSectionModel, model.chatters.isEmpty == false {
            self.supportChatterSectionModel = formateSupportChatterSectionModel(model, isShowTopLine: !unSupportChatterSectionModels.isEmpty)
        }
        // UI上对不支持的chatter进行数据处理
        self.unSupportChatterSectionModels = formateUnSupportChatterSectionModels(unSupportChatterSectionModels)

        // 刷新总的数据源, 不支持的数据排在前面
        self.allSectionModels = self.unSupportChatterSectionModels
        if let model = self.supportChatterSectionModel {
            self.allSectionModels.append(model)
        }

        self.reloadData()
    }

    // 获取要显示的等x人的数量
    private func getOtherCount(chattersCount: Int, allCount: Int, type: UnSupportChatterType) -> Int? {
        let otherCount: Int?
        if chattersCount == allCount {
            if chattersCount <= type.getLimit() {
                otherCount = nil
            } else {
                otherCount = chattersCount - type.getLimit()
            }
        } else if chattersCount < allCount {
            if chattersCount <= type.getLimit() {
                otherCount = allCount - chattersCount
            } else {
                otherCount = allCount - type.getLimit()
            }
        } else {
            otherCount = nil
            assertionFailure("error result")
        }
        return otherCount
    }

    // 格式化支持的列表
    private func formateSupportChatterSectionModel(_ model: UrgentConfrimChatterSectionModel, isShowTopLine: Bool) -> UrgentConfrimChatterSectionModel {
        let limit = UnSupportChatterType.none.getLimit()
        // 获取是否显示等x人的数据 => otherCount
        let otherCount = getOtherCount(chattersCount: model.chatters.count, allCount: model.allCount, type: .none)
        let displayChatters: [Chatter] = model.chatters.prefix(limit).map { $0 }
        var newModel = UrgentConfrimChatterSectionModel(chatters: displayChatters, title: model.title, allCount: model.allCount, otherCount: otherCount, isShowTopLine: isShowTopLine)
        newModel.descriptionMaxWidth = CGFloat(self.view.frame.width - 56)
        return newModel
    }

    // 格式化不支持的列表
    private func formateUnSupportChatterSectionModels(_ models: [UrgentConfrimChatterSectionModel]) -> [UrgentConfrimChatterSectionModel] {
        let allCount = models.reduce(0) { partialResult, model in
            return partialResult + model.allCount
        }
        Self.logger.info("updateUrgentChatters group, unSupportChattersCount = \(allCount)")
        let urgentType = self.urgentType
        let newModels = models.map { model -> UrgentConfrimChatterSectionModel in
            var newModel = model
            let limit = model.type.getLimit()
            newModel.chatters = model.chatters.prefix(limit).map { $0 }
            if model.type == models.first?.type {
                newModel.title = BundleI18n.LarkUrgent.Lark_buzz_AppReceiver(allCount)
            } else {
                newModel.title = nil
            }
            // 获取是否显示等x人的数据 => otherCount
            let otherCount = self.getOtherCount(chattersCount: model.chatters.count, allCount: model.allCount, type: model.type)
            newModel.otherCount = otherCount
            newModel.description = model.type.getDesription(urgentType: urgentType)
            newModel.descriptionMaxWidth = CGFloat(self.view.frame.width - 56)
            return newModel
        }
        return newModels
    }

    fileprivate func supportSectionHeaderTitle(_ count: Int) -> String {
        switch self.urgentType {
        case .app:
            return BundleI18n.LarkUrgent.Lark_buzz_AppReceiver(count)
        case .phone:
            return BundleI18n.LarkUrgent.Lark_buzz_AppPhoneReceiver(count)
        case .sms:
            return BundleI18n.LarkUrgent.Lark_buzz_AppMessageReceiver(count)
        @unknown default:
            fatalError("new value")
        }
    }
}
