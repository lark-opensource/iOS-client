//
//  MagicShareAPI.swift
//  ByteView
//
//  Created by chentao on 2020/4/20.
//

import Foundation
import ByteViewNetwork

protocol MagicShareAPI {

    typealias MagicShareStatesCallBack = (([FollowState], String?) -> Void)

    /// 文档URL
    var documentUrl: String { get }

    /// 【未使用】文档标题
    var documentTitle: String { get }

    /// 文档ViewController
    var documentVC: UIViewController { get }

    /// 【未使用】文档所在ScrollView
    var contentScrollView: UIScrollView? { get }

    /// 文档是否支持回到上次位置，如果本文档不支持，等到出现支持的文档再调用clearStoredLocation()
    var canBackToLastPosition: Bool { get }

    /// 是否文档正在编辑
    var isEditing: Bool { get }

    /// 发送人的ID，格式为"-[userId]-[deviceId]"
    var sender: String { get set }

    /// 【未使用】更新设置Option项
    /// - Parameter settings: 设置Option项
    func updateSettings(_ settings: String)

    /// 更新远端策略（STG）
    /// - Parameter strategies: 远端策略（STG）
    func updateStrategies(_ strategies: [FollowStrategy])

    /// 开始记录自身当前位置
    ///
    /// - Returns: 无
    func startRecord()

    /// 停止记录自身当前位置
    ///
    /// - Returns: 无
    func stopRecord()

    /// 开始跟随
    /// 参会人端初始化时调用
    /// - Returns: 无
    func startFollow()

    /// 停止跟随
    /// 参会人端自由浏览时调用，结束Follow状态后，有FollowState来时，仍然需要调用 setState()，只是此时FollowState会存在起来不生效，等用户回到跟随浏览状态时，立即应用最新版FollowState。
    /// - Returns: 无
    func stopFollow()

    /// 刷新当前页面
    ///
    /// - Returns: 无
    func reload()

    /// 应用全状态
    /// - Parameter states: 状态数据
    /// - Parameter uuid: 唯一标识
    func setStates(_ states: [FollowState], uuid: String?)

    /// 应用增量数据
    /// - Parameter patches: 增量数据
    func applyPatches(_ patches: [FollowPatch])

    /// 获取最近的状态
    /// - Parameter callBack: 回到block
    func getState(callBack: @escaping MagicShareStatesCallBack)

    /// 设置回调Delgate
    func setDelegate(_ delegate: MagicShareAPIDelegate)

    /// 回到（本次MS中）上一次记录的位置
    func returnToLastLocation()

    /// 清除（本次MS中）记录的文档位置
    /// - Parameter token: 如果传入token，清除这一篇文档的记录位置；如果传nil，清除全部文档的记录位置
    func clearStoredLocation(_ token: String?)

    /// 存储当前文档的位置
    func storeCurrentLocation()

    /// 将MS-strategy配置参数透传给CCM前端
    /// - Parameter operations: 配置参数，JSON字符串
    func updateOperations(_ operations: String)

    /// 容器即将消失，调用此方法通知CCM侧收起打开的页面
    func willSetFloatingWindow()

    /// 结束回到全屏
    func finishFullScreenWindow()

    /// VC 将宿主环境的一些上下文同步给 CCM。
    func updateContext(_ context: String)

    /// 根据名字调用CCM前端方法
    /// - Parameters:
    ///   - funcName: 方法名
    ///   - paramJson: 主要参数
    ///   - metaJson: 次要参数（其他参数）
    func invoke(funcName: String,
                paramJson: String?,
                metaJson: String?)

    /// 将followAPI替换为空实现，以释放WebView供复用
    func replaceWithEmptyFollowAPI()
}

protocol MagicShareAPIDelegate: AnyObject {

    /// 文档加载完全结束
    func magicShareAPIDidReady(_ magicShareAPI: MagicShareAPI)

    /// 文档页面渲染完成
    func magicShareAPIDidFinish(_ magicShareAPI: MagicShareAPI)

    /// 文档产生新的FollowState变化
    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onStates states: [FollowState], grootAction: GrootCell.Action, createTime: TimeInterval)

    /// 文档产生新的FollowPatch变化
    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onPatches patches: [FollowPatch], grootAction: GrootCell.Action)

    /// WebView调用VC-Native的方法
    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onJSInvoke invocation: [String: Any])

    /// 用户在文档页面点击链接等操作
    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onOperation operation: MagicShareOperation)

    /// 【已废弃】自由浏览时，主/被共享人位置变化
    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onPresenterFollowerLocationChange location: MagicSharePresenterFollowerLocation)

    /// 自由浏览时，主/被共享人位置变化
    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onRelativePositionChange position: MagicShareRelativePosition)

    /// CCM SDK 内做了统计，iOS负责透传数据并上报埋点
    func magicShareAPI(_ magicShareAPI: MagicShareAPI, onTrack info: String)

    /// CCM首次Apply成功，上报埋点
    /// 参考文档：https://bytedance.feishu.cn/docx/doxcnBumSYKjRdTsNDaOO1QeZdf
    func magicShareAPIDidFirstPositionChangeAfterFollow(_ magicShareAPI: MagicShareAPI)

    /// 上报妙记分段信息
    func magicShareInfoDidChanged(_ magicShareAPI: MagicShareAPI, states: [String])
}
