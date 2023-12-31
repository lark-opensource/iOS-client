//
//  CalendarExtension.swift
//  LarkEditorJS
//
//  Created by tefeng liu on 2020/6/23.
//

import Foundation

public class CalendarExtension<BaseType> {
    var base: BaseType
    init(_ base: BaseType) {
        self.base = base
    }
}
public protocol CalendarExtensionCompatible {
    associatedtype CalendarCompatibleType
    var calendar: CalendarCompatibleType { get }
    static var calendar: CalendarCompatibleType.Type { get }
}
public extension CalendarExtensionCompatible {
    var calendar: CalendarExtension<Self> {
        return CalendarExtension(self)
    }
    static var calendar: CalendarExtension<Self>.Type {
        return CalendarExtension.self
    }
}

extension LarkEditorJS: CalendarExtensionCompatible {}

public extension CalendarExtension where BaseType == LarkEditorJS {
    public static func getCalendarHtmlPath() -> String {
        let name = "mobile_index.html"
        return CommonJSUtil.executeFilesPath + "/\(name)"
    }

    public static func getCalendarJSPath() -> String {
        let name = "mobile_index.js"
        return CommonJSUtil.executeFilesPath + "/\(name)"
    }
}
