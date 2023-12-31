//
//  AtNoResultCellAndItem.swift
//  Action
//
//  Created by kkk on 2019/5/8.
//

import UIKit
import Foundation
import LarkCore
import LarkModel
import LarkTag
import SnapKit
import LarkUIKit
import LarkListItem
import LarkBizTag
import LarkContainer

/// 搜索结果没有可被@的人；
/// 当且仅当群内成员为空，且有群外的人时才添加“AtNoResultItem”
struct AtNoResultItem: ChatChatterItem {
    var itemId: String = ""
    var itemAvatarKey: String = ""
    var itemMedalKey: String = ""
    var itemName: String = ""
    var itemPinyinOfName: String?
    var itemDescription: Chatter.Description?
    var descInlineProvider: DescriptionInlineProvider?
    var descUIConfig: StatusLabel.UIConfig?
    var itemDepartment: String?
    var itemTags: [TagDataItem]?
    var itemCellClass: AnyClass = AtNoResultCell.self
    var isBottomLineHidden: Bool = false
    var isSelectedable: Bool = false
    var itemUserInfo: Any?
    var itemTimeZoneId: String?
    var needDisplayDepartment: Bool?
    var supportShowDepartment: Bool?
}

final class AtNoResultCell: UITableViewCell, ChatChatterCellProtocol {
    var isCheckboxHidden: Bool = true
    var isCheckboxSelected: Bool = false
    var item: ChatChatterItem?
    var titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.text = BundleI18n.LarkChat.Lark_Chat_AtChatMemberNoResults
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.N900
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(16)
            maker.top.bottom.equalToSuperview().inset(23)
            maker.height.equalTo(22.5)
        }

        self.contentView.backgroundColor = UIColor.ud.bgBody
        selectedBackgroundView = BaseCellSelectView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(_ item: ChatChatterItem, filterKey: String?, userResolver: UserResolver) {
        guard let item = item as? AtNoResultItem else { return }
        self.item = item
    }
}
