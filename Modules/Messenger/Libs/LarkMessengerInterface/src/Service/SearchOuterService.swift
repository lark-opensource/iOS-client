//
//  SearchOuterService.swift
//  LarkMessengerInterface
//
//  Created by chenyanjie on 2023/12/22.
//

import Foundation

public enum SearchEntryAction: String {
    case unKnown
    case inpage_icon        //点击各tab页面内搜索icon
    case navigation_icon    //点击导航栏的搜索icon
    case highlight_search   //划词搜索
    case pageicon_or_shortcut  //目前commend+F 和 tab页面内搜索走的一套链路，不好区分，先以这个字段过渡下，后续以需求区分commend+k和tab页面内搜索行为

    public init?(rawValue: String) {
        switch rawValue {
        case "inpage_icon": self = .inpage_icon
        case "navigation_icon": self = .navigation_icon
        case "highlight_search": self = .highlight_search
        case "pageicon_or_shortcut": self = .pageicon_or_shortcut
        default:
            return nil
        }
    }
}

public struct SearchEnterModel {
    public var fromTabURL: URL?         //跳转到搜索之前tab的url
    public var sourceOfSearchStr: String?     //跳转到搜索的场景，内部使用时会转成枚举类型SourceOfSearch
    public var initQuery: String?       //搜索的初始query
    public var appLinkSource: String?   //
    public var jumpTab: String?         //跳转到搜索的垂类tab，内部使用时会转成枚举类型SearchSectionAction
    public var appId: String?           //跳转到搜索的垂类tab如果是开放搜索的appID
    public var searchTabName: String?   //跳转到搜索的垂类tab如果是开放搜索的tabName
    public let entryAction: SearchEntryAction   //跳转到搜索tab的来源，埋点用, 内部会转换成枚举

    public init(fromTabURL: URL? = nil,
                sourceOfSearchStr: String? = nil,
                initQuery: String? = nil,
                appLinkSource: String? = nil,
                jumpTab: String? = nil,
                appId: String? = nil,
                searchTabName: String? = nil,
                entryAction: SearchEntryAction) {
        self.fromTabURL = fromTabURL
        self.sourceOfSearchStr = sourceOfSearchStr
        self.initQuery = initQuery
        self.appLinkSource = appLinkSource
        self.jumpTab = jumpTab
        self.appId = appId
        self.searchTabName = searchTabName
        self.entryAction = entryAction
    }

    public init(from model: SearchEnterModel) {
        self.fromTabURL = model.fromTabURL
        self.sourceOfSearchStr = model.sourceOfSearchStr
        self.initQuery = model.initQuery
        self.appLinkSource = model.appLinkSource
        self.jumpTab = model.jumpTab
        self.appId = model.appId
        self.searchTabName = model.searchTabName
        self.entryAction = model.entryAction
    }
}

public protocol SearchOuterService: AnyObject {
    // 仅iPad，获取当前SearchRootVC所在的容器VC
    func getCurrentSearchPadVC(searchEnterModel: SearchEnterModel) -> UIViewController?
    // 获取当前的正在展示的SearchRootVC
    func getCurrentSearchRootVCOnWindow() -> UIViewController?
    func setCurrentSearchRootVC(viewController: UIViewController)
    func getSearchOnPadEntranceView() -> UIView
    func changeSelectedState(isSelect: Bool)
    func isCompactStatus() -> Bool
    func closeDetailButton(chatID: String) -> UIButton
    func isNeedChangeCellLayout() -> Bool
    func enableUseNewSearchEntranceOnPad() -> Bool
    func requestWidthOnPad() -> CGFloat
    func currentEntryAction() -> SearchEntryAction?
    func currentIsCacheVC() -> Bool?
    func enableSearchiPadSpliteMode() -> Bool
}
