//
//  ProfileFieldFactory.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/6/25.
//

import Foundation
import UIKit
import LarkLocalizations

public enum ProfileFieldType {
    case normal
    case push
    case link
    case textList
    case linkList
    case none
}

public protocol ProfileFieldItem: AnyObject {
    var type: ProfileFieldType { get }

    var fieldKey: String { get }

    var title: String { get }

    var enableLongPress: Bool { get }
}

public struct ProfileFieldContext {
    weak var tableView: UITableView?
    weak var fromVC: UIViewController?

    public init(tableView: UITableView?, fromVC: UIViewController?) {
        self.tableView = tableView
        self.fromVC = fromVC
    }
}

public final class ProfileFieldFactory {

    private static var useVerticalLayout: Bool = {
        return false
        /*
        #if DEBUG
        return false
        #else
        // 中文使用横向布局，其他语言使用纵向布局
        let horiLangs = [Lang.zh_CN, Lang.zh_TW, Lang.zh_HK]
        return !horiLangs.contains(LanguageManager.currentLanguage)
        #endif
         */
    }()

    /// 存储PersonCardFieldItem 类型
    private static var profileFieldCellType: [ProfileFieldCell.Type] = [
        ProfileFieldLinkCell.self,
        ProfileFieldNormalCell.self,
        ProfileFieldPushCell.self,
        ProfileFieldTextListCell.self,
        ProfileFieldLinkListCell.self
    ]

    public static func register(type: ProfileFieldCell.Type) {
        guard !ProfileFieldFactory.profileFieldCellType.contains(where: { $0 == type }) else {
            return
        }
        profileFieldCellType.append(type)
    }

    public static func getFieldCellTypes() -> [(String, ProfileFieldCell.Type)] {
        return self.profileFieldCellType.map {
            if $0 == ProfileFieldLinkCell.self {
                return ("ProfileFieldLinkCell", $0)
            } else if $0 == ProfileFieldPhoneCell.self {
                return ("ProfileFieldPhoneCell", $0)
            } else if $0 == ProfileFieldNormalCell.self {
                return ("ProfileFieldNormalCell", $0)
            } else if $0 == ProfileFieldPushCell.self {
                return ("ProfileFieldPushCell", $0)
            } else if $0 == ProfileFieldTextListCell.self {
                return ("ProfileFieldTextListCell", $0)
            } else if $0 == ProfileFieldLinkListCell.self {
                return ("ProfileFieldLinkListCell", $0)
            } else {
                fatalError("cell type don't have id")
            }
        }
    }

    private init() {}

    /// 构建PersonCardFieldItem，根据item构建cell
    public static func createWithItem(_ item: ProfileFieldItem,
                                      context: ProfileFieldContext) -> ProfileFieldCell? {
        guard let cellType = ProfileFieldFactory
            .profileFieldCellType
            .first(where: { (type) -> Bool in
                type.canHandle(item: item)
            }) else { return nil }

        return cellType.init(
            item: item,
            context: context,
            isVertical: useVerticalLayout
        )
    }
}
