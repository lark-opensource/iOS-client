//
//  BTTrackInfo.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/12/25.
//  


import Foundation
import HandyJSON

//From BTViewModel+Tracker.swift
public final class BTTrackInfo {
    ///埋点支持
    public var didSearch: Bool? = false
    public var didClickDone: Bool? = false
    public var isEditPanelOpen: Bool? = false
    public var itemChangeType: BTItemChangeType? = BTItemChangeType.noChange
    public var userDeleteItemSource: BTUserItemDeleteType? = BTUserItemDeleteType.topBar

    public init() {}
}

public enum BTItemChangeType: Int {
    case delete = -1
    case noChange = 0
    case add = 1
}

public enum BTUserItemDeleteType: String {
    case topBar = "top_bar"
    case bottomList = "bottom_list"
}
