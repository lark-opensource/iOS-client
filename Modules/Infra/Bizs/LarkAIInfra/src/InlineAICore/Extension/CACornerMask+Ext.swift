//
//  CACornerMask+Ext.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/4/28.
//  


import Foundation

extension CACornerMask {
    static var top: CACornerMask { [.layerMinXMinYCorner, .layerMaxXMinYCorner] }
    static var left: CACornerMask { [.layerMinXMinYCorner, .layerMinXMaxYCorner] }
    static var right: CACornerMask { [.layerMaxXMinYCorner, .layerMaxXMaxYCorner] }
    static var bottom: CACornerMask { [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] }
    static var all: CACornerMask { [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner] }
}
