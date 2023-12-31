//
//  EventListRedLine.swift
//  Calendar
//
//  Created by zhu chao on 2018/8/13.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
final class EventListRedLine: UIView {

    var redlinePosition: RedlinePositionInfo?

    init(leading: CGFloat = 53, tailing: CGFloat = 5) {
        let height: CGFloat = 7.0
        super.init(frame: CGRect(x: leading, y: 0, width: UIScreen.main.bounds.size.width - leading - tailing, height: height))
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: height, height: height))
        let color = UIColor.ud.functionDangerContentDefault
        dot.backgroundColor = color
        dot.layer.cornerRadius = height / 2.0
        self.addSubview(dot)

        let lineHeight: CGFloat = 1.0
        let line = UIView(frame: CGRect(x: 8, y: (height - lineHeight) / 2.0, width: self.frame.width - 8, height: lineHeight))
        line.backgroundColor = color
        self.addSubview(line)
    }

    func updateOriginY(_ originY: CGFloat, tableView: UITableView) {
        if self.superview !== tableView {
            tableView.addSubview(self)
        }
        var frame = self.frame
        frame.origin.y = originY
        self.frame = frame
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
