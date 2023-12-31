//
//  MineSidebarService.swift
//  LarkMessengerInterface
//
//  Created by 李勇 on 2020/7/6.
//

import UIKit
import Foundation
import LarkSDKInterface
import RxCocoa
import LarkModel
import RustPB

/// 封装一层PassportAPI：内存缓存 & 对接push
public protocol MineSidebarService {
    /// Feed侧边栏远端下发的Sidebar
    var sidebars: [RustPB.Passport_V1_GetUserSidebarResponse.SidebarInfo] { get }
    /// 订阅后会立马发射当前内存缓存中的数据
    var sidebarDriver: Driver<[RustPB.Passport_V1_GetUserSidebarResponse.SidebarInfo]> { get }

    /// 根据type返回展示的icon、title信息
    func getInfo(type: RustPB.Passport_V1_GetUserSidebarResponse.SidebarType) -> (UIImage, String)
    /// 根据type返回点击后应该跳转的URL
    func getURL(type: RustPB.Passport_V1_GetUserSidebarResponse.SidebarType) -> URL?
}
