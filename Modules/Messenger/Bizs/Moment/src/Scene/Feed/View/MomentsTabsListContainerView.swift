//
//  MomentsTabsListContainerView.swift
//  Moment
//
//  Created by liluobin on 2021/4/19.
//

import Foundation
import UIKit
import UniverseDesignTabs
protocol MomentsTabsListContainerViewDelegate: UDTabsListContainerViewDelegate {
    var appearDate: Date { get }
}
final class MomentsTabsListContainerView: UDTabsListContainerView {
    let maxCacheCount = 5

    func clearCacheObjectIfNeed() {

        if self.validListDict.count <= maxCacheCount {
            return
        }
        var tuples: [(Int, MomentsTabsListContainerViewDelegate)] = []
        for key in self.validListDict.keys {
            if let value = self.validListDict[key] as? MomentsTabsListContainerViewDelegate {
                tuples.append((key, value))
            }
        }
        tuples = tuples.sorted { (tuple1, tuple2) -> Bool in
            return tuple2.1.appearDate.compare(tuple1.1.appearDate) == .orderedDescending ? true : false
        }
        let removeObjects = Array(tuples.prefix(tuples.count - maxCacheCount))
        removeObjects.forEach { (tuple) in
            self.validListDict.removeValue(forKey: tuple.0)
            tuple.1.listView().removeFromSuperview()
            if let vc = tuple.1 as? UIViewController, vc.parent != nil {
                vc.removeFromParent()
            }
        }
    }
}
