//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LarkAppResources
import UniverseDesignEmpty
import UniverseDesignIcon

public final class Resources {
    public static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.MessengerModBundle, compatibleWith: nil) ?? UIImage()
    }
    // calendar
    static let calendar_event = UDIcon.getIconByKey(.calendarFilled).ud.withTintColor(UIColor.ud.colorfulOrange)
    // todo
    static let todo_task = UDIcon.getIconByKey(.tabTodoFilled).ud.withTintColor(UIColor.ud.colorfulIndigo)
    // doc
    static let send_docs = UDIcon.getIconByKey(.spaceFilled).ud.withTintColor(UIColor.ud.primaryContentDefault)
    // app
    static let vote = UDIcon.getIconByKey(.voteFilled).ud.withTintColor(UIColor.ud.colorfulIndigo)
    // meego
    static let meegoPlusItem = UDIcon.getIconByKey(.meegoFilled).ud.withTintColor(UIColor.ud.primaryContentDefault)
}
