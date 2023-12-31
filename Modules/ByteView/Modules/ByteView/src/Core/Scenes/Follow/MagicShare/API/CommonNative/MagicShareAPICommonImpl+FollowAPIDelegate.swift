//
//  MagicShareAPICommonImpl+FollowAPIDelegate.swift
//  ByteView
//
//  Created by chentao on 2020/4/20.
//

import Foundation

extension MagicShareAPICommonImpl: FollowDocumentDelegate {
    /// 传递滚动等followState
    ///
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    ///   - event:  返回的事件，根据 FollowAPI setup 注册
    ///   - actions: Follow Action 数组
    func follow(_ follow: FollowDocument, on event: FollowEvent, with states: [String], metaJson: String?) {
        guard validFollowEvent.contains(event) else {
            Logger.vcFollow.warn("follow api on event: \(event) unregistered thus ignored")
            return
        }
        debugLog(message: "follow api on event: \(event) and states count: \(states.count)")
        switch event {
        case .newAction:
            syncFollowStates(states, metaJson: metaJson)
        case .newPatches:
            syncFollowPatches(states, metaJson: metaJson)
        case .presenterFollowerLocation:
            guard let data = states.last?.data(using: String.Encoding.utf8),
                  let location = try? JSONDecoder().decode(MagicSharePresenterFollowerLocation.self, from: data) else {
                Logger.vcFollow.warn("on .presenterFollowerLocation event, data is invalid, reloading position skipped.")
                return
            }
            delegate?.magicShareAPI(self, onPresenterFollowerLocationChange: location)
        case .relativePositionChange: // relativePositionChange是presenterFollowerLocation的升级，摒弃了重复的回调；presenterFollowerLocation在5.9及以上版本废弃，但保留接口与能力
            guard let data = states.last?.data(using: String.Encoding.utf8),
                  let position = try? JSONDecoder().decode(MagicShareRelativePosition.self, from: data) else {
                Logger.vcFollow.warn("on .relativePositionChange event, data is invalid, reloading position skipped.")
                return
            }
            delegate?.magicShareAPI(self, onRelativePositionChange: position)
        case .track:
            guard let trackInfo = states.last else {
                Logger.vcFollow.warn("on .track event, data is invalid, track skipped.")
                return
            }
            delegate?.magicShareAPI(self, onTrack: trackInfo)
        case .firstPositionChangeAfterFollow:
            delegate?.magicShareAPIDidFirstPositionChangeAfterFollow(self)
        case .magicShareInfo:
            delegate?.magicShareInfoDidChanged(self, states: states)
        default:
            break
        }
    }

    /// 需要回调给VC的各种操作
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    ///   - operation: 动作信息，key为操作类型，value为动作参数
    func follow(_ follow: FollowDocument, onOperate operation: FollowOperation) {
        debugLog(message: "on operation:\(operation)")
        switch operation {
        case let .openUrl(url):
            delegate?.magicShareAPI(self, onOperation: .openUrl(url: url))
        case let .openMoveToWikiUrl(wikiUrl: wikiUrl, originUrl: originUrl):
            delegate?.magicShareAPI(self, onOperation: .openMoveToWikiUrl(wikiUrl: wikiUrl, originUrl: originUrl))
        case let .openUrlWithHandlerBeforeOpen(url: url, handler: handler):
            delegate?.magicShareAPI(self, onOperation: .openUrlWithHandlerBeforeOpen(url: url, handler: handler))
        case let .onTitleChange(title):
            delegate?.magicShareAPI(self, onOperation: .onTitleChange(title: title))
        case let .showUserProfile(userId):
            delegate?.magicShareAPI(self, onOperation: .showUserProfile(userId: userId))
        case let .setFloatingWindow(getFromVCHandler: handler):
            delegate?.magicShareAPI(self, onOperation: .setFloatingWindow(getFromVCHandler: handler))
        case let .openOrCloseAttachFile(isOpen: isOpen):
            delegate?.magicShareAPI(self, onOperation: .openOrCloseAttachFile(isOpen: isOpen))
        default:
            break
        }
    }

    /// WebView调用VC Native的方法
    /// [Magic Share Runtime 技术方案](https://bytedance.feishu.cn/docs/doccnLvQUvvly6MS9GMb9zMgwIg) -> JS SDK Call Follow Runtime
    /// getEnv\zoom(level)\log(msg)...
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    ///   - invocation: 调用信息，key为调用方法，value为调用参数，将透传给VC
    func follow(_ follow: FollowDocument, onJsInvoke invocation: [String: Any]?) {
        debugLog(message: "on js invocation:\(invocation)")
        guard let js = invocation else {
            return
        }
        delegate?.magicShareAPI(self, onJSInvoke: js)
    }

    /// Docs相关js加载完毕
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    func followDidReady(_ follow: FollowDocument) {
        debugLog(message: "did ready")
        delegate?.magicShareAPIDidReady(self)
    }

    /// Docs渲染完成
    ///
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    func followDidRenderFinish(_ follow: FollowDocument) {
        delegate?.magicShareAPIDidFinish(self)
        debugLog(message: "did finish")
    }

    /// DocsBrowserVC中用户点击返回按钮，页面即将退出
    ///
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    func followWillBack(_ follow: FollowDocument) {
        debugLog(message: "will back")
    }
}
