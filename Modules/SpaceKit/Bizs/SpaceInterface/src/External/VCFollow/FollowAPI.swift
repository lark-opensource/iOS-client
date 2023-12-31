//
//  FollowAPI.swift
//  SpaceInterface
//
//  Created by nine on 2019/9/8.
//

import Foundation

public enum FollowAPIType {
    /// 回到上次位置
    case backToLastPosition

    /// 清除位置记录。清除当前 token 文档记录，不传token的话是清除所有文档的位置记录
    case clearLastPosition(_ token: String?)

    /// 记住当前位置
    case keepCurrentPosition
    
    ///MagicShare共享人端发送提频
    case updateOptions(_ paramJson: String?)

    ///MagicShare同步宿主环境给前端
    case updateContext(_ contextString: String?)
}

/// 操作Follow功能的aAPI，通过FollowAPIFactory获取
public protocol FollowAPI {

    typealias FollowStateCallBack = (([FollowState], String?) -> Void)

    /// 当前FollowAPI 所对应的 docs 连接
    var followUrl: String { get }

    /// 当前FollowAPI 所对应的 docs 文档标题
    var followTitle: String { get }

    /// 返回当前Follow的ViewController
    var followVC: UIViewController { get }

    /// 文档是否支持回到上次位置目前只有 doc和wiki-doc
    var canBackToLastPosition: Bool { get }

    /// 返回当前UIScrollView
    var scrollView: UIScrollView? { get }

    /// 返回当前是否为编辑态
    var isEditingStatus: Bool { get }

    /// 设置Follow回调Delgate
    func setDelegate(_ delegate: FollowAPIDelegate)

    /// 开始记录Action
    ///
    /// - Returns: 无
    func startRecord()


    /// 停止记录Action
    ///
    /// - Returns: 无
    func stopRecord()

    /// 开启Follow状态
    /// 参会人端初始化时调用
    /// - Returns: 无
    func startFollow()

    /// 停止跟随
    /// 参会人端自由浏览时调用，结束Follow状态后，有FollowState来时，仍然需要调用 setState()，只是此时FollowState会存在起来不生效，等用户回到跟随浏览状态时，立即应用最新版FollowState。
    /// - Returns: 无
    func stopFollow()

    /// 播放action
    ///
    /// - Parameter actions: 要播放的action
    /// - Parameter meta: 元数据如uuid等
    /// - Returns: 无
    func setState(states: [FollowState], meta: String?)

    ///  获取所有类型的最新动作。
    ///  主持人端VC APP定时调用, 返回最新的FollowState对象。
    /// - Returns: 最新动作数组
    func getState(callBack: @escaping FollowStateCallBack)

    /// 刷新当前页面
    ///
    /// - Returns: 无
    func reload()

    /// 注入JS
    func injectJS(_ script: String)
    
    func invoke(funcName: String,
                paramJson: String?,
                metaJson: String?,
                callBack: FollowStateCallBack?)

    func callFollowAPI(type: FollowAPIType)
    
    /// 即将进入悬浮小窗口
    func willSetFloatingWindow()
    
    /// 已经完成从小窗回到全屏
    func finishFullScreenWindow()
}
