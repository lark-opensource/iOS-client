//
//  OpenProcessManager.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/28.
//
// 展示打开过程中的信息，仅供调试

import Foundation
import SKCommon
import SKUIKit
import UniverseDesignToast
import EENavigator
import SKInfra
import SKFoundation
import LarkContainer

class OpenProcessManager {
    lazy private var openProcessRecord = DocsOpenProcessRecord()
    private var openProcessView = DocsOpenProcessView()
    let shouldShowOpenInfo = OpenAPI.docs.shouldShowFileOpenBasicInfo
    weak var hostView: UIView?
    let userResolver: UserResolver
    init(lifeCycle: BrowserViewLifeCycle, hostview: UIView?, userResolver: UserResolver) {
        self.userResolver = userResolver
        self.hostView = hostview
        lifeCycle.addObserver(self)
    }

    private func startRecordOpenProcessIfNeeded() {
        guard shouldShowOpenInfo else { return }
        stopRecordOpenProcessIfNeeded(now: true)
        openProcessRecord = DocsOpenProcessRecord()
        openProcessView = DocsOpenProcessView()
        hostView?.addSubview(openProcessView)
//        DocsLogger.debug("append message   did add subview: \(hostView)")
        openProcessView.alpha = 0.3
        openProcessView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(10)
        }
        openProcessRecord.currentInfo.bind(target: openProcessView) { [unowned openProcessView] text in
            openProcessView.updateInfo(text)
        }
        keepInfoViewTop()
    }

    private func stopRecordOpenProcessIfNeeded(now: Bool = true) {
        guard shouldShowOpenInfo else { return }
        if now {
            openProcessView.removeFromSuperview()
        } else {
            let infoView = self.openProcessView
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10) {
                infoView.removeFromSuperview()
            }
        }
    }

    func appendInfo(_ info: @autoclosure () -> String ) {
        guard shouldShowOpenInfo else { return }
//        DocsLogger.debug("append message: \(info())  \(hostView)")
        openProcessRecord.appendInfo(info())
    }

    func showOpenBasicInfoIfNeeded(isPreload: Bool, url: URL, usedCount: Int) {
        appendInfo( "isPreload: \(isPreload)  scheme: \(url.scheme ?? "null")  useCount: \(usedCount)" )
        guard shouldShowOpenInfo == true else { return }
        let info = "isPreload: \(isPreload)\nscheme: \(url.scheme ?? "null")\nuseCount: \(usedCount)"
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000) {
            guard let hostView = self.userResolver.navigator.mainSceneWindow?.rootViewController?.view else { return }
            UDToast.showSuccess(with: info, on: hostView)
        }
    }

    func keepInfoViewTop() {
        guard shouldShowOpenInfo else { return }
        openProcessView.superview.map { (superView) in
            superView.bringSubviewToFront(openProcessView)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: {
                self.keepInfoViewTop()
            })
        }
    }
}

extension OpenProcessManager: BrowserViewLifeCycleEvent {
    func browserWillLoad() {
        startRecordOpenProcessIfNeeded()
    }

    func browserWillClear() {
        stopRecordOpenProcessIfNeeded(now: true)
    }

    func browserDidHideLoading() {
        stopRecordOpenProcessIfNeeded(now: false)
    }
}
