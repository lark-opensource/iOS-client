//
//  DrivePDFAreaComment.swift
//  SpaceKit
//
//  Created by liweiye on 2019/7/15.
//

import Foundation

// 坐标原点: 左上角
// 坐标的值：相对屏幕的百分比

// 坐标原点: 左上角
// 坐标的值：相对屏幕的百分比
struct DrivePDFPoint {
    let x: CGFloat
    let y: CGFloat
}

// 坐标原点: 左上角
// 坐标的值：相对PDF当前页面的百分比
// 排列顺序为顺时针
struct DrivePDFQuadPoint: Codable {
    let x1: CGFloat
    let x2: CGFloat
    let x3: CGFloat
    let x4: CGFloat
    let y1: CGFloat
    let y2: CGFloat
    let y3: CGFloat
    let y4: CGFloat

    init(p1: DrivePDFPoint, p2: DrivePDFPoint, p3: DrivePDFPoint, p4: DrivePDFPoint) {
        self.x1 = p1.x
        self.x2 = p2.x
        self.x3 = p3.x
        self.x4 = p4.x
        self.y1 = p1.y
        self.y2 = p2.y
        self.y3 = p3.y
        self.y4 = p4.y
    }
}
