//
//  TreeViewDataBuilder.swift
//  SKWiki
//
//  Created by 邱沛 on 2021/3/23.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast
import SKResource
import UIKit
import SKCommon
import SpaceInterface

public protocol TreeViewDataBuilder {
    // spaceID
    var spaceID: String { get }
    // dataSource
    var sectionRelay: BehaviorRelay<[NodeSection]> { get }
    var actionSignal: Signal<WikiTreeViewAction> { get }

    // delegate
    var input: (
        build: PublishRelay<Void>,
        swipeCell: PublishRelay<(IndexPath, TreeNode)>
    ) { get }

    func configSlideAction(node: TreeNode) -> [TreeSwipeAction]?
}
