//
//  UtilPartialLoadingService.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/11/27.
//

import Foundation
import WebKit
import SnapKit
import Lottie
import SKCommon
import SKFoundation

class UtilPartialLoadingService: BaseJSService {
    private var _partialLoadingAnimator: PartialLoadingAnimator?

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension UtilPartialLoadingService: BrowserViewLifeCycleEvent {
    func browserWillClear() {
        spaceAssert(Thread.isMainThread)
        model?.jsEngine.isBusy = false
        resetPartialLoadingView()
    }

    func browserKeyboardDidChange(_ keyboardInfo: BrowserKeyboard) {
        partialLoadingAnimator.updatePartialLoadingViewHeightIfNeeded(keyboardInfo.height)
    }
}

extension UtilPartialLoadingService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.utilShowPartialLoading,
                .utilHidePartialLoading]
    }

    func handle(params: [String: Any], serviceName: String) {
//        guard model?.browserInfo.isShowComment == false else { return }
        DocsLogger.info("\(String(describing: model?.jsEngine.editorIdentity)) \(serviceName)")

        switch serviceName {
        case DocsJSService.utilShowPartialLoading.rawValue:
            model?.jsEngine.isBusy = true
            showPartialLoadingViewIfNeeded()
            model?.openRecorder.appendInfo("receive utilShowPartialLoading")
        case DocsJSService.utilHidePartialLoading.rawValue:
            model?.jsEngine.isBusy = false
            hidePartialLoading()
            model?.openRecorder.appendInfo("receive utilHidePartialLoading")
        default:
            return
        }
    }
}

// MARK: - 分屏渲染
extension UtilPartialLoadingService {
    private var hostView: UIView? {
        return ui?.hostView
    }
    private var partialLoadingAnimator: PartialLoadingAnimator {
        if _partialLoadingAnimator == nil {
            _partialLoadingAnimator = PartialLoadingAnimator(hostView: hostView)
        }
        return _partialLoadingAnimator!
    }

    func showPartialLoadingViewIfNeeded() {
        partialLoadingAnimator.showPartialLoadingViewIfNeeded()
    }

    func hidePartialLoading() {
        partialLoadingAnimator.hidePartialLoading()
    }

    func resetPartialLoadingView() {
        partialLoadingAnimator.resetPartialLoading()
    }
}
