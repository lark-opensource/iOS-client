//
//  LarkRoomWebViewVC+LoadAndRetry.swift
//  LarkRVC
//
//  Created by zhouyongnan on 2022/7/12.
//

import Foundation
import SnapKit

extension LarkRoomWebViewVC {
    /// 显示加载视图
    func showLoadingView() {
        self.logger.info("show loadingview")
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(2)
        }
        // 必须通过更改LoadingPlaceholderView的isHidden状态来开始/停止动画，未暴露play/stop接口 @liyuguo.jeffrey
        loadingView.isHidden = false
    }

    /// 移除加载视图
    func removeLoadingView() {
        // 必须通过更改LoadingPlaceholderView的isHidden状态来开始/停止动画，未暴露play/stop接口 @liyuguo.jeffrey
        self.logger.info("remove loadingview")
        loadingView.isHidden = true
        loadingView.removeFromSuperview()
    }

    /// 开始loading
    func startLoading() {
        removeFailView()
        state = .loading
    }

    /// 显示失败视图
    func showFailView() {
        self.logger.info("show failview")
        view.addSubview(failView)
        failView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // 必须通过更改LoadWebFailPlaceholderView的isHidden状态，
        // 因为它在retryTapped方法内强行设置了isHidden=true @zhaochen.09
        failView.isHidden = false
    }

    /// 移除失败视图
    func removeFailView() {
        self.logger.info("remove failview")
        // 与上面的isHidden = false配对使用，为预防LarkUIKit内相关逻辑被更改时对这里造成影响
        failView.isHidden = true
        failView.removeFromSuperview()
    }

    /// action for tapping fail view
    func failViewTap() {
        self.logger.info("failViewTap")
        loadURL(self.url, showLoading: true)
    }

    /// 加载URL，并定制是否显示loading
    func loadURL(_ url: URL, showLoading: Bool = false) {
        removeFailView()
        if showLoading {
            showLoadingView()
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        if (LarkRoomWebViewManager.env.isStaging) {
            request.setValue("1", forHTTPHeaderField: "x-use-boe")
            request.setValue(LarkRoomWebViewManager.URLParams.featureEnvValue, forHTTPHeaderField: "x-tt-env")
            let boeFd = LarkRoomWebViewManager.URLParams.boeFdValue.components(separatedBy: ":")
            if boeFd.count == 2 {
                let key = boeFd[0]
                let value = boeFd[1]
                request.setValue(value, forHTTPHeaderField: "Rpc-Persist-Dyecp-Fd-\(key)")
            }
        }
        self.logger.info("Current debug header is \(request.allHTTPHeaderFields)")
        webView.load(request)
    }

    /// 加载失败视图
    func loadFail(error: Error) {
        removeLoadingView()
        showFailView()
        state = .failed
    }

    /// 处理网页加载异常
    func handleWebError(error: Error) {
        loadFail(error: error)
        self.logger.error("load page error: \(error)")
    }
}

// MARK: loading & retry
/// webview加载状态枚举
enum LoadingState {
    case `default`
    case willStartLoading
    case loading
    case failed
    case finish
}

