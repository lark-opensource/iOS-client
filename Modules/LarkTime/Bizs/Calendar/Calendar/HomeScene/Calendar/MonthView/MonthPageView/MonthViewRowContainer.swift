//
//  MonthViewRowContainer.swift
//  Calendar
//
//  Created by zhu chao on 2018/10/17.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit

final class MonthViewRowContainer<T: UIView>: UIView {

    private let items: [T]

    private let previousSize: CGSize
    private let edgeInsets: UIEdgeInsets

    init(subViews: [T], edgeInsets: UIEdgeInsets = .zero) {
        self.items = subViews
        let initFrame = CGRect(x: 0.0,
                               y: 0.0,
                               width: UIScreen.main.bounds.size.width,
                               height: 67)
        self.previousSize = initFrame.size
        self.edgeInsets = edgeInsets
        super.init(frame: initFrame)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.frame.size != self.previousSize {
            self.layoutItems(self.items)
        }
    }

    func onWidthChange(width: CGFloat) {
        self.frame.size.width = width
        layoutItems(items)
    }

    private func layoutItems(_ views: [T]) {
        let itemFrame = CGRect(origin: .zero,
                               size: CGSize(width: self.bounds.width / CGFloat(views.count), height: self.bounds.height))
        var index = 0
        for item in views {
            var frame = itemFrame
            frame.origin.x = frame.width * CGFloat(index)
            item.frame = frame.inset(by: self.edgeInsets)
            index += 1
            if item.superview !== self {
                self.addSubview(item)
            }
        }
    }

    func view(at index: Int) -> T {
        return self.items[index]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
