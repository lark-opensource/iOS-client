//
//  ReuseableViewPool.swift
//  LarkReactionView
//
//  Created by 李晨 on 2019/6/5.
//

import UIKit
import Foundation

final class ReuseableViewPool<T: UIView> {
    private var reusePool: [T] = []

    var poolCount: Int {
        return reusePool.count
    }

    init(count: Int = 0) {
        for _ in 0..<count {
            reusePool.append(T())
        }
    }

    func getUseableViews(count: Int = 1, occupyed: [T] = []) -> [T] {
        // swiftlint:disable:next empty_count
        if count <= 0 {
            return []
        }
        // 如果已有资源大于申请资源，直接从已有资源中截取返回
        if occupyed.count >= count {
            return Array(occupyed.prefix(count))
        }

        var views = occupyed
        for index in 0 ..< reusePool.count {
            let view = reusePool[index]
            // 复用池中该资源可用(superview == nil),且之前申请者没有该资源
            if view.superview == nil && !views.contains(view) {
                // 将该资源补充给申请者
                views.append(view)
                // 如果资源数足够申请数
                if views.count == count {
                    return Array(views)
                }
            }
        }
        while views.count < count {
            // 复用池枯竭，补充新的资源
            let view = T()
            reusePool.append(view)
            views.append(view)
        }
        return Array(views)
    }

    func free(to count: Int) {
        while reusePool.count > count {
            reusePool.removeLast()
        }
    }

    func freeAll() {
        reusePool.removeAll()
    }
}
