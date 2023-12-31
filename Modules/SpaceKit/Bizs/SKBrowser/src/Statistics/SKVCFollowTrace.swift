//
//  SKVCFollowTrace.swift
//  SKFoundation
//
//  Created by zengsenyuan on 2021/11/30.
//  


import Foundation

public struct SKVCFollowTrace {
    /// trace start
    public static let openVCFollow = create("openVCFollow")
    /// trace finish
    public static let closeVCFollow = create("closeVCFollow")
    /// 注册跟随事件
    public static let implRegisterEvents = create("implRegisterEvents")
    /// 开始成为共享者
    public static let implStartRecord = create("implStartRecord")
    /// 结束成为共享者
    public static let implStopRecord = create("implStopRecord")
    /// 开始成为跟随者
    public static let implStartFollow = create("implStartFollow")
    /// 结束成为跟随者
    public static let implStopFollow = create("implStopFollow")
    /// 跟随内容准备完成
    public static let implFollowDidReady = create("implFollowDidReady")
    /// 跟随内容渲染完成
    public static let implFollowDidRenderFinish = create("implFollowDidRenderFinish")
    /// 跟随内容返回
    public static let implFollowWillBack = create("implFollowWillBack")
    /// 跟随内容添加附件
    public static let implFollowAddSubHost = create("implFollowAddSubHost")
    
    static func create(_ spanName: String) -> String {
        return "CCM_SKVCFollowTrace_" + spanName
    }
}
