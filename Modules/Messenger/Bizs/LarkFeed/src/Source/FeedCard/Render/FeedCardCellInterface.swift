//
//  FeedCardCellInterface.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/5/22.
//

import Foundation
import UIKit
import LarkOpenFeed
import LarkFeedBase
import LarkContainer
import LarkSwipeCellKit
import RustPB
import LarkSceneManager
import LarkModel
import LarkUIKit
import UniverseDesignTheme

// TODO: open feed 这两个协议有些多余，未来看能否下掉
// feed card cell 的一些通用协议
protocol FeedCardCellWithPreview {
    var feedPreview: FeedPreview? { get }
}

protocol FeedUniversalListCellProtocol: FeedCardCellWithPreview {
    var viewModel: FeedCardCellViewModel? { get }
    func didSelectCell(from: UIViewController, trace: FeedListTrace, filterType: Feed_V1_FeedFilter.TypeEnum)
}
