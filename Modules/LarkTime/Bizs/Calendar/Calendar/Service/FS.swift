//
//  FS.swift
//  Calendar
//
//  Created by zhuheng on 2021/5/28.
//

import Foundation

public struct FS {
    public static func suiteReport(userID: String) -> Bool {
        return FeatureGating.getFSValue(fsKey: .suiteReport, userID: userID, debugValue: true)
    }

    public static func suiteVc(userID: String) -> Bool {
        return FeatureGating.getFSValue(fsKey: .suiteVc, userID: userID, debugValue: true)
    }
}
