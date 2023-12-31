//
//  DocsVCFollowDelegate.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/30.
//  


import Foundation

//扩展FollowOperation，增加一些内部操作
public enum SpaceFollowOperation {
    case vcOperation(value: FollowOperation) //需要回调给VC的操作
    case exitAttachFile      //web调用退出附件预览
    case onExitAttachFile(isNewAttach: Bool)//native主动退出附件预览
    case onDocumentVCDidMove  //当前BrowserVC被移除
    case nativeStatus(funcName: String, params: [String: Any]?) //通知前端当前native的状态
    case willSetFloatingWindow // VC 界面即将进入小窗口模式
    case onRemoveFollowSameLayerFile(mountToken: String) // 移除同层 Follow 的内容(当同层内容移出屏幕时)
    case finishFullScreenWindow // VC 已结束从小窗回到正常窗口
}

/// Follow角色
public enum FollowRole {
    case none       //自由浏览
    case presenter  //演讲者
    case follower   //跟随者
}

/// VC Follow 视频会议中文档跟随，方便在BrowserVC中follow动作转发到FollowAPIDelegate
public protocol BrowserVCFollowDelegate: AnyObject {
    
    var isFloatingWindow: Bool { get }
    
    /// 需要回调给VC的各种操作
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    ///   - operationInfo: 动作信息，key为动作类型，value为动作参数
    func follow(onOperate operation: SpaceFollowOperation)

    /// Docs相关js加载完毕
    func followDidReady()

    /// Docs渲染完成
    func followDidRenderFinish()

    /// DocsBrowserVC中用户点击返回按钮，页面即将退出
    func followWillBack()

    /// webview回调vc
    func didReceivedJSData(data outData: [String: Any])
}


public protocol SpaceFollowAPIDelegate: AnyObject {

    var meetingID: String? { get }

    var token: String? { get }

    var followRole: FollowRole { get }

    /// 主 MagicShare 内容是否原生文件
    var isHostNativeContent: Bool { get }
    
    /// 当前弹出的预览附件所在文档的位置标记
    var currentFollowAttachMountToken: String? { get set }
    
    /// 注册 Follow 模块
    func follow(_ followableHost: FollowableViewController?, register content: FollowableContent)
    
    /// 反注册 Follow 模块
    func follow(_ followableHost: FollowableViewController?, unRegister content: FollowableContent)
    
    /// 添加子 FollowableViewController，如打开附件或者同层附件
    func follow(_ followableHost: FollowableViewController?, add subHost: FollowableViewController)

    /// 需要回调给VC的各种操作
    /// - Parameters:
    ///   - operation: 动作信息，key为操作类型，value为动作参数
    func follow(_ followableHost: FollowableViewController?, onOperate operation: SpaceFollowOperation)

    /// Docs相关js加载完毕
    func followDidReady(_ followableHost: FollowableViewController?)

    /// 附件加载完毕，可以开始注册 Follow
    func followAttachDidReady()
    
    /// Docs渲染完成
    func followDidRenderFinish(_ followableHost: FollowableViewController?)

    /// 用户点击返回按钮，页面即将退出
    func followWillBack(_ followableHost: FollowableViewController?)

    /// 前端回调
    func didReceivedJSData(data outData: [String: Any])
    
}

/// 默认实现
extension SpaceFollowAPIDelegate {
    func didReceivedJSData(data outData: [String: Any]) {

    }
}
