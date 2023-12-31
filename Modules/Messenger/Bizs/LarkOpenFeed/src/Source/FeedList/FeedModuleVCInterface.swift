//
//  FeedModuleVCInterface.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/9.
//

import UIKit
import Foundation
import RustPB

public protocol FeedModuleVCInterface: UIViewController {
    var tableView: FeedTableView { get }
    var delegate: FeedModuleVCDelegate? { get set }
    func willActive()
    func willResignActive()
    func willDestroy()
    func setContentOffset(_ offset: CGPoint, animated: Bool)
    func doubleClickTabbar()
}

public protocol FeedModuleVCDelegate: AnyObject {
    func pullupMainScrollView()
    func backFirstList()
    func changeTabWithFilterSelectItem(_ newTab: Feed_V1_FeedFilter.TypeEnum)
    func getFirstTab() -> Feed_V1_FeedFilter.TypeEnum
    func isHasFlagGroup() -> Bool
}
