//
//  MagicShareAPIDefaultImpl.swift
//  ByteView
//
//  Created by chentao on 2020/4/20.
//

import Foundation
import ByteViewNetwork

// 默认的兼容实现,如果调用 Docs open url失败则直接返回该MagicShareAPI
class MagicShareAPIDefaultImpl: MagicShareAPI {
    static let logger = Logger.vcFollow
    lazy var metadataDes: String = {
        return "magic share default api \(address(of: self)) "
    }()
    let magicShareDocument: MagicShareDocument
    init(magicShareDocument: MagicShareDocument) {
        self.magicShareDocument = magicShareDocument
        MagicShareAPIDefaultImpl.logger
            .debug("init with share id:\(magicShareDocument.shareID) type:\(magicShareDocument.shareType)")
    }

    var documentUrl: String {
        return magicShareDocument.urlString
    }

    var documentTitle: String {
        return magicShareDocument.docTitle
    }

    lazy var documentVC: UIViewController = {
        return UIViewController()
    }()

    var contentScrollView: UIScrollView? {
        return nil
    }

    var canBackToLastPosition: Bool {
        return false
    }

    let isEditing = false

    var sender: String = ""

    func updateSettings(_ settings: String) {
    }

    func updateStrategies(_ strategies: [FollowStrategy]) {
    }

    func startRecord() {
    }

    func stopRecord() {
    }

    func startFollow() {
    }

    func stopFollow() {
    }

    func reload() {
    }

    func setStates(_ states: [FollowState], uuid: String?) {
    }

    func applyPatches(_ patches: [FollowPatch]) {
    }

    func getState(callBack: @escaping MagicShareStatesCallBack) {
        callBack([], nil)
    }

    func setDelegate(_ delegate: MagicShareAPIDelegate) {
    }

    func returnToLastLocation() {
    }

    func clearStoredLocation(_ token: String?) {
    }

    func storeCurrentLocation() {
    }

    func updateOperations(_ operations: String) {
    }

    func willSetFloatingWindow() {
    }

    func finishFullScreenWindow() {
    }

    func updateContext(_ context: String) {
    }

    func invoke(funcName: String,
                paramJson: String?,
                metaJson: String?) {
    }

    func replaceWithEmptyFollowAPI() {
    }
}
