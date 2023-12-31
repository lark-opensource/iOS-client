//
//  ProfileSectionNormalProvider.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/12/30.
//

import UIKit
import Foundation

public protocol ProfileSectionCellItem {
    var title: String { get set }
    var subTitle: String { get set }
    var content: String { get set }
    var pushLink: String { get set }
    var showPushIcon: Bool { get set }
}

public struct ProfileSectionNormalItem: ProfileSectionItem {
    public var cellItems: [ProfileSectionCellItem] = []

    public init(cellItems: [ProfileSectionCellItem] = []) {
        self.cellItems = cellItems
    }
}

public final class ProfileSectionNormalProvider: ProfileSectionProvider {
    private var item: ProfileSectionNormalItem

    public weak var fromVC: UIViewController?

    public required init?(item: ProfileSectionItem) {
        guard let sectionItem = item as? ProfileSectionNormalItem else { return nil }
        self.item = sectionItem
    }

    public func update(item: ProfileSectionItem) {
        guard let sectionItem = item as? ProfileSectionNormalItem else { return }
        self.item = sectionItem
    }

    public func numberOfRows() -> Int {
        return item.cellItems.count
    }

    public func cellTypesForSection() -> [ProfileSectionTabCell.Type] {
        return [ProfileSectionTitleCell.self,
                ProfileSectionNormalCell.self,
                ProfileSectionLinkCell.self]
    }

    public func cellForRowAt(index: Int) -> ProfileSectionTabCell {
        guard item.cellItems.count > index else {
            return ProfileSectionTabCell()
        }

        let cellitem = item.cellItems[index]
        if cellitem as? ProfileSectionTitleCellItem != nil {
            let cell = ProfileSectionTitleCell()
            cell.fromVC = fromVC
            cell.update(item: cellitem)
            return cell
        }

        if cellitem as? ProfileSectionLinkCellItem != nil {
            let cell = ProfileSectionLinkCell()
            cell.update(item: cellitem)
            return cell
        }

        if cellitem as? ProfileSectionNormalCellItem != nil {
            let cell = ProfileSectionNormalCell()
            cell.update(item: cellitem)
            return cell
        }

        return ProfileSectionTabCell()
    }
}
