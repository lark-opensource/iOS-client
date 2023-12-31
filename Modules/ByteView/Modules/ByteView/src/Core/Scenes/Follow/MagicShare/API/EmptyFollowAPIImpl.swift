//
//  PlaceHolderFollowAPIImpl.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/11/19.
//

import Foundation

/// 会中妙享场景为了复用Webview，切换页面前，旧followDocument先替换为此空实现以保证documentVC释放
class PlaceHolderFollowAPIImpl: FollowDocument {

    var followUrl: String { "emptyFollowUrl" }

    var followTitle: String { "emptyFollowTitle" }

    var followVC: UIViewController { UIViewController() }

    var canBackToLastPosition: Bool { false }

    var isEditing: Bool { false }

    var scrollView: UIScrollView?

    func setDelegate(_ delegate: FollowDocumentDelegate) {
    }

    func startRecord() {
    }

    func stopRecord() {
    }

    func startFollow() {
    }

    func stopFollow() {
    }

    func setState(states: [String], meta: String?) {
    }

    func getState(callBack: @escaping ([String], String?) -> Void) {
    }

    func reload() {
    }

    func injectJS(_ script: String) {
    }

    func backToLastPosition() {
    }

    func clearLastPosition(_ token: String?) {
    }

    func keepCurrentPosition() {
    }

    func updateOptions(_ options: String?) {
    }

    func willSetFloatingWindow() {
    }

    func finishFullScreenWindow() {
    }

    func updateContext(_ context: String?) {
    }

    func invoke(funcName: String, paramJson: String?, metaJson: String?) {
    }
}
