//
//  LarkBadgeManager.swift
//  Calendar
//
//  Created by 朱衡 on 2018/10/27.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import RxCocoa
import RustPB

//swiftlint:disable identifier_name
enum BadgeID: String {
    case none
    case cal_setting        //日历设置按钮
    case cal_local_item     //本地日历cell
    case cal_view           //日历视图切换按钮
    case cal_month_view     //月视图按钮
    case cal_dark_mode      //深色皮肤
    case cal_menu           //日历汉堡按钮
    case cal_import         //导入日历
}

struct BadgeDefaultSetting {
    static let redDotColor = UIColor.ud.functionWarningContentDefault
    static let redDotSize = CGSize(width: 10, height: 10)
    static let topRightPoint = CGPoint(x: 0, y: 0)    //相对右上角
    static let newImageSize = CGSize(width: 34, height: 34)
    static let newImageName = "rectangle5"
}

final class LarkBadgeManager {
    private static var api: CalendarRustAPI?
    private static var disposeBag = DisposeBag()
    private static let lock = DispatchSemaphore(value: 1)
    private static var badgeIdMap: [BadgeID: BehaviorSubject<BadgeStatus>] = [:]
    private static var badgeRelatedMap: [BadgeID: [BadgeID]] = [:]  //行为ID:被操作的ID
    internal static var redDotConfigMap: [String: RedDotUiItem] = [String: RedDotUiItem]() {
        didSet {
            for (badgeID, subject) in badgeIdMap {
                subject.onNext(getConfigStatus(badgeID))
            }
        }
    }

    static func setRedDotItems(_ redDotItems: [RedDotUiItem], calendarApi: CalendarRustAPI) {
        api = calendarApi
        var map: [String: RedDotUiItem] = [String: RedDotUiItem]()
        for item in redDotItems {
            map[item.name] = item
        }
        redDotConfigMap = map
    }

    private static func getConfigStatus(_ badgeID: BadgeID) -> BadgeStatus {
        //初始化时是否显示由配置决定
        return (redDotConfigMap[badgeID.rawValue] != nil) ? .show : .hidden
    }

    public static func configRedDot(badgeID: BadgeID,
                                    view: UIView,
                                    relatedBadges: [BadgeID]? = nil,
                                    topRightPoint: CGPoint = BadgeDefaultSetting.topRightPoint,
                                    redDotColor: UIColor = BadgeDefaultSetting.redDotColor,
                                    redDotSize: CGSize = BadgeDefaultSetting.redDotSize,
                                    isEqualCenterY: Bool = false) {
        DispatchQueue.main.async {
            view.setBadgeStyle(.redDot)
            view.setBadgeTopRightOffset(topRightPoint)
            view.setRedDotColor(redDotColor)
            view.setBadgeSize(redDotSize)
            if isEqualCenterY {
                view.setBadgeEqualCenterY(topRightPoint.x)
            }
            configBadge(badgeID: badgeID, view: view, relatedBadges: relatedBadges)
        }
    }

    public static func configNew(badgeID: BadgeID,
                                 view: UIView,
                                 relatedBadges: [BadgeID]? = nil,
                                 topRightPoint: CGPoint = BadgeDefaultSetting.topRightPoint,
                                 redDotColor: UIColor = BadgeDefaultSetting.redDotColor,
                                 imageSize: CGSize = BadgeDefaultSetting.newImageSize,
                                 imageName: String = BadgeDefaultSetting.newImageName) {
        DispatchQueue.main.async {
            view.setBadgeStyle(.new)
            view.setBadgeTopRightOffset(topRightPoint)
            view.setBadgeSize(imageSize)
            view.setBadgeImageName(imageName)
            configBadge(badgeID: badgeID, view: view, relatedBadges: relatedBadges)
        }
    }

    private static func configBadge(badgeID: BadgeID, view: UIView, relatedBadges: [BadgeID]?) {
        let subject = requestSubject(badgeID)
        subject.observeOn(MainScheduler.asyncInstance).subscribe { [weak view] event in
            view?.changeStatus(event.element ?? .hidden)
        }.disposed(by: disposeBag)

        if let badges = relatedBadges {
            let newRelated = badges.filter({ (releatedID) -> Bool in
                return getConfigStatus(releatedID) == .show
            })

            if newRelated.isEmpty, !badges.isEmpty {
                subject.onNext(.hidden)
            }

            badgeRelatedMap[badgeID] = newRelated
        }

    }

    public static func hidden(_ badgeID: BadgeID) {
        DispatchQueue.main.async {
            //遍历移除所有关联badgeID的对象
            markRedDotDisappear(with: badgeID)
            hiddenReleateDot(badgeID)
        }
    }

    private static func markRedDotDisappear(with badgeID: BadgeID, doUIHidden: Bool = true) {
        if let item = redDotConfigMap[badgeID.rawValue] {
            api?.markRedDotDisappear(items: [item]).subscribe { event in
                if event.error == nil {
                    redDotConfigMap.removeValue(forKey: badgeID.rawValue)
                    if doUIHidden {
                        requestSubject(badgeID).onNext(.hidden)
                    }
                }
            }.disposed(by: disposeBag)
        }
    }

    private static func hiddenReleateDot(_ badgeID: BadgeID) {
        for (relatedID, badges) in badgeRelatedMap {
            let newArr = badges
                .filter { $0.rawValue != badgeID.rawValue }
            badgeRelatedMap[relatedID] = newArr
            //移除badgeID后，对象关联的ID数量为0，hidden该对象
            if newArr.isEmpty {
                markRedDotDisappear(with: relatedID)
            }
        }
    }

    private static func requestSubject(_ badgeID: BadgeID) -> BehaviorSubject<BadgeStatus> {
        lock.wait()
        defer { lock.signal() }
        if let subject = self.badgeIdMap[badgeID] {
            return subject
        } else {
            let subject = BehaviorSubject(value: getConfigStatus(badgeID))
            self.badgeIdMap[badgeID] = subject
            return subject
        }
    }

}
