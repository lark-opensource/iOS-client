//
//  SearchCardViewModel.swift
//  LarkSearch
//
//  Created by bytedance on 2021/8/6.
//

import UIKit
import Foundation
import LarkSearchCore
import LarkContainer
protocol SearchCardViewModel: SearchCellViewModel {

    var jsBridgeDependency: ASLynxBridgeDependencyDelegate? { get set }
    var indexPath: IndexPath? { get set }
    var preferredWidth: CGFloat? { get set }
    var isMainTab: Bool { get set }
    var isContentChangeByJSB: Bool { get set }
    var userResolver: UserResolver { get }
}
