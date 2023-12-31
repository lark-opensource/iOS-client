//
//  ListItemNode.swift
//  CryptoSwift
//
//  Created by Yuri on 2023/5/26.
//

import Foundation
import RustPB

public class ListItemContext {
    public var userId: String?
    public var statusService: ItemStatusServiceType?

    weak var delegate: ItemTableViewCellDelegate?
    public init(userId: String? = nil) {
        self.userId = userId
    }
}

public struct ListItemNode {

    public var indexPath: IndexPath

    public var checkBoxState: CheckBoxState = .init()

    public var icon = Icon.local(nil)

    public var title: NSAttributedString?

    public var subtitle: NSAttributedString?

    public var status: [RustPB.Basic_V1_Chatter.ChatterCustomStatus]?

    public var tags: [TagType] = []

    public var content: NSAttributedString?

    public var descIcon: UIImage?
    public var desc: NSAttributedString?

    public var accessories: [AccessoryType]?
}

extension ListItemNode {

    public struct CheckBoxState {
        public init(isShow: Bool = false, isSelected: Bool = false, isEnable: Bool = true) {
            self.isShow = isShow
            self.isSelected = isSelected
            self.isEnable = isEnable
        }

        public var isShow = false
        public var isSelected = false
        public var isEnable = true
    }

    public struct DocIcon {
        enum Style {
            case circle
            case square
            case outline
        }
        var iconInfo: String
        var style: Style = .square
    }

    public enum Icon {
        case local(UIImage?)
        case remote(String, String?)
        case avatarImageURL(URL?)  // imageURL webImage
        case avatar(String, String) // id, key
        case docIcon(DocIcon)
    }

    public enum TagType {
        case crypto
        case `private`
        case `public`
        case external
        case officialOncall // 官方服务台
        case oncallOffline // helpdesk offline
        case bot
        case doNotDisturb
        case onLeave
        case unregistered
        case oncall
        case connect // 互通
        case team
        case allStaff // 全员
        case custom(String)
        case relationTag(Search_V2_TagData)
    }

    public enum AccessoryType {
        case targetPreview
        case delete
    }
}
