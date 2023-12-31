//
//  TimeScaleView.swift
//  Calendar
//
//  Created by zhouyuan on 2018/9/6.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import CalendarFoundation
import LarkUIKit

final class TimeScaleView: UIView {

    typealias BackgroundStyle = CalendarViewStyle.Background
    private let pandingTop: CGFloat
    private let pandingRight: CGFloat = 4
    private let firstWeekday: DaysOfWeek
    private let daysCount: Int
    private let currentDayBackground = UIView()

    init(frame: CGRect,
         daysCount: Int = 3,
         firstWeekday: DaysOfWeek = .sunday,
         pandingTop: CGFloat = BackgroundStyle.topGridMargin) {
        self.daysCount = daysCount
        self.pandingTop = pandingTop
        self.firstWeekday = firstWeekday
        super.init(frame: frame)
        self.setupCurrentDayBackground(view: currentDayBackground)
        self.layoutTimeScale()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCurrentDayBackground(view: UIView) {
        view.backgroundColor = BackgroundStyle.currentDataBackgroundColor
        let today = Date().dayStart()
        let index = Calendar.gregorianCalendar.dateComponents(
            [.day],
            from: today.startOfWeek(firstWeekday: firstWeekday.rawValue),
            to: today
            ).day ?? 0
        view.frame = CGRect(
            x: verticalGridWidth() * CGFloat(index),
            y: 0,
            width: verticalGridWidth() - pandingRight,
            height: self.bounds.height)
        self.addSubview(view)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        timeLineLayers.forEach { (layers) in
            layers.forEach({ (layer) in
                layer.removeFromSuperlayer()
            })
        }
        layoutTimeScale()
    }

    private var timeLineLayers: [[CAShapeLayer]] = []
    private func layoutTimeScale() {
        timeLineLayers = setupTimeScale()
        timeLineLayers.forEach { (layers) in
            layers.forEach({ (layer) in
                self.layer.addSublayer(layer)
            })
        }
    }

    private func setupTimeScale() -> [[CAShapeLayer]] {
        return (0..<daysCount).map(self.setupGridTimeScale)
    }

    private func setupGridTimeScale(of index: Int) -> [CAShapeLayer] {
        return (0...24).map { (indexY) -> CAShapeLayer in
            let line = timeLineLayer(path: timeLinePath(indexX: index, indexY: indexY))
            return line
        }
    }

    private func timeLinePath(indexX: Int, indexY: Int) -> UIBezierPath {
        let path = UIBezierPath()
        let y = BackgroundStyle.hourGridHeight * CGFloat(indexY) + CGFloat(pandingTop)
        let x = verticalGridWidth() * CGFloat(indexX)
        path.move(to: CGPoint(x: x,
                              y: y))
        path.addLine(to: CGPoint(x: x + verticalGridWidth() - pandingRight,
                                 y: y))
        return path
    }

    /// 日程视图分割线
    private func timeLineLayer(path: UIBezierPath) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.ud.setStrokeColor(UIColor.ud.lineDividerDefault, bindTo: self)
        layer.lineWidth = 0.5
        layer.path = path.cgPath
        return layer
    }

    private func verticalGridWidth() -> CGFloat {
        return self.bounds.width / CGFloat(daysCount)
    }
}
