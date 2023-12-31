//
//  ProfileSectionSkeletonProvider.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2022/1/6.
//

import UIKit
import Foundation

public struct ProfileSectionSkeletonItem: ProfileSectionItem {
    public var styles: [ProfileSectionSkeletonCellStyle] = []

    public init(styles: [ProfileSectionSkeletonCellStyle] = []) {
        self.styles = styles
    }
}

public final class ProfileSectionSkeletonProvider: ProfileSectionProvider {

    public weak var fromVC: UIViewController?

    private var item: ProfileSectionSkeletonItem = ProfileSectionSkeletonItem()

    public required init?(item: ProfileSectionItem) {
        guard let item = item as? ProfileSectionSkeletonItem else {
            return nil
        }
        self.item = item
    }

    public func update(item: ProfileSectionItem) {
        guard let item = item as? ProfileSectionSkeletonItem else {
            return
        }
        self.item = item
    }

    public func numberOfRows() -> Int {
        item.styles.count
    }

    public func cellTypesForSection() -> [ProfileSectionTabCell.Type] {
        [ProfileSectionSkeletonCell.self]
    }

    public func cellForRowAt(index: Int) -> ProfileSectionTabCell {
        let style = item.styles[index]
        let cell = ProfileSectionSkeletonCell()
        cell.update(style: style)
        return cell
    }
}
