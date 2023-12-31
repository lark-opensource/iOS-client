//
//  LarkInterface+Navigation.swift
//  LarkMessengerInterface
//
//  Created by aslan on 2023/12/22.
//
import EENavigator

public struct NavigationSearchEnterBody: PlainBody {
    public static let pattern = "//client/navigation/search"

    public var fromTabURL: URL?
    public var sourceOfSearchStr: String?
    public var initQuery: String?
    public var appLinkSource: String?
    public var jumpTab: String?
    public var appId: String?
    public var searchTabName: String?
    public var entryAction: String

    public init(fromTabURL: URL? = nil,
                sourceOfSearchStr: String? = nil,
                initQuery: String? = nil,
                appLinkSource: String? = nil,
                jumpTab: String? = nil,
                appId: String? = nil,
                searchTabName: String? = nil,
                entryAction: String) {
        self.fromTabURL = fromTabURL
        self.sourceOfSearchStr = sourceOfSearchStr
        self.initQuery = initQuery
        self.appLinkSource = appLinkSource
        self.jumpTab = jumpTab
        self.appId = appId
        self.searchTabName = searchTabName
        self.entryAction = entryAction
    }
}
