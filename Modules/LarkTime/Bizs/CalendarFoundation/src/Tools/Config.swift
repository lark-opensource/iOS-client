//
//  Config.swift
//  Calendar
//
//  Created by linlin on 2018/3/14.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation

public final class Config {
    private static let libraryBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/CalendarFoundation", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle.main
        }
    }()
    private static let bundleUrl = libraryBundle.url(forResource: "ResourcesCalendarBundle", withExtension: "bundle")
    public static let CalendarBundle = (bundleUrl != nil ? Bundle(url: bundleUrl!) : libraryBundle) ?? Bundle.main
}
public let calendarAutoBundle = Bundle(url: Bundle.main.url(forResource: "CalendarAuto", withExtension: "bundle")!)!
