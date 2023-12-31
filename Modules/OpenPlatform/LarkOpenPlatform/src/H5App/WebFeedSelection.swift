//
//  WebFeedSelection.swift
//  LarkOpenPlatform
//
//  Created by jiangzhongping on 2023/10/24.
//

import Foundation
import WebBrowser
import LarkMessengerInterface

//适配ipad feed选中场景
extension WebBrowser: FeedSelectionInfoProvider {
    
    public func getFeedIdForSelected() -> String? {
        return self.feedId ?? ""
    }
}


