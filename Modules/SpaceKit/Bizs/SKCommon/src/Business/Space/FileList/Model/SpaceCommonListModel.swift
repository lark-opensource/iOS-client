//
//  SpaceCommonListModel.swift
//  SKCommon
//
//  Created by majie.7 on 2023/9/14.
//

import Foundation
import RxSwift


public struct SpaceCommonListItemModel {
    
    var leftIconItem: IconConfig?
    var rightIconItem: IconConfig?
    var titleItem: TitleConfig?
    
    public struct IconConfig {
        let image: UIImage
        let color: UIColor?
        let size: CGSize?
        
        public init(image: UIImage, color: UIColor? = nil, size: CGSize? = nil) {
            self.image = image
            self.color = color
            self.size = size
        }
    }

    public struct TitleConfig {
        let title: String
        let color: UIColor?
        let font: UIFont?
        
        public init(title: String, color: UIColor? = nil, font: UIFont? = nil) {
            self.title = title
            self.color = color
            self.font = font
        }
    }
    
    public init(leftIconItem: IconConfig? = nil,
                rightIconItem: IconConfig? = nil,
                titleItem: TitleConfig? = nil) {
        self.leftIconItem = leftIconItem
        self.rightIconItem = rightIconItem
        self.titleItem = titleItem
    }
}


// 通用面板样式： leftIcon-title-rightIcon ----------- leftIcon-title-rightIcon
public struct SpaceCommonListItem {
    let leadingItem: SpaceCommonListItemModel?
    // 左边每个view之间的间距，不设置默认为4
    let leadingItemSpacing: CGFloat?
    let trailingItem: SpaceCommonListItemModel?
    let trailingItemSpacing: CGFloat?
    let enableObservable: Observable<Bool>
    let clickHandler: (() -> Void)?
    
    public init(leadingLeftIcon: SpaceCommonListItemModel.IconConfig? = nil,
                leadingRightIcon: SpaceCommonListItemModel.IconConfig? = nil,
                leadingTitle: SpaceCommonListItemModel.TitleConfig? = nil,
                leadingItemSpacing: CGFloat? = nil,
                trailingLeftIcon: SpaceCommonListItemModel.IconConfig? = nil,
                trailingRightIcon: SpaceCommonListItemModel.IconConfig? = nil,
                trailingTitle: SpaceCommonListItemModel.TitleConfig? = nil,
                trailingItemSpacing: CGFloat? = nil,
                enableObservable: Observable<Bool> = .just(true),
                clickHandler: (() -> Void)? = nil) {
        self.leadingItem = SpaceCommonListItemModel(leftIconItem: leadingLeftIcon,
                                                    rightIconItem: leadingRightIcon,
                                                    titleItem: leadingTitle)
        self.trailingItem = SpaceCommonListItemModel(leftIconItem: trailingLeftIcon,
                                                     rightIconItem: trailingRightIcon,
                                                     titleItem: trailingTitle)
        self.leadingItemSpacing = leadingItemSpacing
        self.trailingItemSpacing = trailingItemSpacing
        self.enableObservable = enableObservable
        self.clickHandler = clickHandler
    }
    
    public init(leadingItem: SpaceCommonListItemModel? = nil,
                trailingItem: SpaceCommonListItemModel? = nil,
                leadingItemSpacing: CGFloat? = nil,
                trailingItemSpacing: CGFloat? = nil,
                enableObservable: Observable<Bool> = .just(true),
                clickHandler: (() -> Void)? = nil) {
        self.leadingItem = leadingItem
        self.trailingItem = trailingItem
        self.leadingItemSpacing = leadingItemSpacing
        self.trailingItemSpacing = trailingItemSpacing
        self.enableObservable = enableObservable
        self.clickHandler = clickHandler
    }
}

public struct SpaceCommonListConfig {
    let items: [SpaceCommonListItem]
    let resetHandler: (() ->Void)?
    
    public init(items: [SpaceCommonListItem], resetHandler: (() -> Void)? = nil) {
        self.items = items
        self.resetHandler = resetHandler
    }
}
