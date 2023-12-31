//
//  ThreadContainer.swift
//  LarkThread
//
//  Created by 李勇 on 2020/10/17.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import LarkModel
import LarkMessageCore

protocol ThreadContainerDelegate: AnyObject {
    /// 为了做Header和TableView的联动动画，添加在ThreadContainerController中的子VC需要主动上抛当前的tableView
    func updateShowTableView(tableView: UITableView)

    var hostSize: CGSize { get }

    func getBannerTopConstraintItem() -> ConstraintItem?

    func topNoticeManager() -> ChatTopNoticeDataManager
}
