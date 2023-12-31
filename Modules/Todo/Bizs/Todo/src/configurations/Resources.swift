//
//  BundleResources.swift
//  Todo
//
//  Created by 张威 on 2020/11/18.
//

import Foundation
import UIKit

public final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.TodoBundle, compatibleWith: nil) ?? UIImage()
    }

    public static let share = image(named: "share")

    static let appAlert = Resources.image(named: "bot_card_pin")

    enum QucikCreate {
        static let avatarBoarder = Resources.image(named: "quick_create_avatar_circle")
    }

    enum Card {
        static let pin = appAlert
    }

    enum Chat {
        static let aiSmartReply = share
    }

}
