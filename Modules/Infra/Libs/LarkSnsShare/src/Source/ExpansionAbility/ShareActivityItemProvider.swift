//
//  ShareActivityItemProvider.swift
//  LarkSnsShare
//
//  Created by jiangxiangrui on 2022/9/22.
//

import UIKit
import Foundation

final class ActivityItemProvider: UIActivityItemProvider {
    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if activityType == .copyToPasteboard {
            return nil
        }
        return self.placeholderItem
    }
}

final class LinkActivityItemProvider: UIActivityItemProvider {
    var url: String
    var title: String
    init(title: String, url: String) {
        self.title = title
        self.url = url
        super.init(placeholderItem: title)
    }
    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if activityType == .copyToPasteboard {
            return title + url
        }
        return self.placeholderItem
    }
}
