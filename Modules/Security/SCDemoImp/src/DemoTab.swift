//
//  DemoTab.swift
//  SCDemo
//
//  Created by qingchun on 2022/9/14.
//

import UIKit
import LarkTab

final class DemoTab: TabRepresentable {
    static var tab: Tab {
        return Tab.feed
    }
    var tab: Tab { Self.tab }
}
