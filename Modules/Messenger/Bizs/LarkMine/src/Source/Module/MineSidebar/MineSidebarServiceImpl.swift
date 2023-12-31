//
//  MineSidebarServiceImpl.swift
//  LarkMine
//
//  Created by 李勇 on 2020/7/6.
//

import UIKit
import Foundation
import RxSwift
import LarkMessengerInterface
import LarkSDKInterface
import RxCocoa
import LarkModel
import LarkContainer
import LKCommonsLogging
import RustPB

/// 封装一层PassportAPI：内存缓存 & 对接push
final class MineSidebarServiceImpl: MineSidebarService {
    private static let logger = Logger.log(MineSidebarServiceImpl.self)
    private let passportAPI: PassportAPI
    private let disposeBag = DisposeBag()
    private let sidebarVariable = BehaviorRelay<[RustPB.Passport_V1_GetUserSidebarResponse.SidebarInfo]>(value: [])

    /// Feed侧边栏远端下发的Sidebar
    var sidebars: [RustPB.Passport_V1_GetUserSidebarResponse.SidebarInfo] { return self.sidebarVariable.value }
    /// 订阅后会立马发射当前内存缓存中的数据
    var sidebarDriver: Driver<[RustPB.Passport_V1_GetUserSidebarResponse.SidebarInfo]> { return self.sidebarVariable.asDriver() }

    init(passportAPI: PassportAPI, pushCenter: PushNotificationCenter) {
        self.passportAPI = passportAPI
        // 获取数据
        self.passportAPI.getMineSidebar(strategy: .forceServer).subscribe(onNext: { [weak self] (sidebars) in
            guard let `self` = self else { return }
            self.sidebarVariable.accept(sidebars)
        }).disposed(by: self.disposeBag)
        // 对接push
        pushCenter.observable(for: PushMineSidebar.self).subscribe(onNext: { [weak self] (sidebars) in
            guard let `self` = self else { return }
            self.sidebarVariable.accept(sidebars.sidebars)
        }).disposed(by: self.disposeBag)
    }

    /// 根据type返回展示的icon、title信息
    func getInfo(type: RustPB.Passport_V1_GetUserSidebarResponse.SidebarType) -> (UIImage, String) {
        switch type {
        // 企业管理
        case .admin:
            return (Resources.admin_icon, BundleI18n.LarkMine.Lark_Profile_SuiteAdminEntry)
        @unknown default:
            return (UIImage(), "")
        }
    }

    /// 根据type返回点击后应该跳转的URL
    func getURL(type: RustPB.Passport_V1_GetUserSidebarResponse.SidebarType) -> URL? {
        if let urlString = self.sidebars.first(where: { $0.sidebarType == type })?.sidebarLink, let url = URL(string: urlString) {
            return url
        }
        var infoString = "no valid url for \(type), curr infos: "
        self.sidebars.forEach { (sidebar) in
            infoString += "\(sidebar.sidebarType), \(sidebar.sidebarIsshow), \(sidebar.sidebarLink). "
        }
        MineSidebarServiceImpl.logger.info(infoString)
        return nil
    }
}
