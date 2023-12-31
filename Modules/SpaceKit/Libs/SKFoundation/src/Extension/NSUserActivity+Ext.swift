//
//  NSUserActivity+Ext.swift
//  SpaceKit
//
//  Created by nine on 2018/10/14.
//

import Foundation

extension NSUserActivity {
    static let openWebPageActivityType = Bundle.main.bundleIdentifier ?? "" + ".OpenWebPage"

    public static func openWebPage(_ urlStr: String) -> NSUserActivity? {
        guard let url = URL(string: urlStr) else { return nil }
        let userActivity = NSUserActivity(activityType: NSUserActivity.openWebPageActivityType)
        userActivity.webpageURL = url
        userActivity.isEligibleForSearch = true
        return userActivity
    }
}
