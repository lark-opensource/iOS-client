//
//  LarkWebView+Performance.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/21.
//  

import Foundation

extension LarkWebView {
    /// 获取WebView的性能数据 （在页面加载完毕后才能获取到完整数据，如webview navigation didFinish ）
    /// - Parameter onCompleted: 获取PerformanceTiming数据完成回调
    public func fetchPerformanceTimingData(onCompleted: @escaping ((LarkWebView.PerformanceTiming?) -> Void)) {
        self.fetchPerformanceTimingString { [weak self] timingString in
            guard let `self` = self else { return }
            guard let timingString = timingString else {
                onCompleted(nil)
                return
            }
            let data = self.parsePerformanceTimingData(timingString)
            onCompleted(data)
        }
    }

    func fetchPerformanceTimingString(onCompleted: @escaping ((String?) -> Void)) {
        self.evaluateJavaScript("JSON.stringify(window.performance.timing.toJSON())") { timingString, error in
            guard error == nil, let timingString = timingString as? String else {
                logger.error("WKWebView Load Performance JS failed!", error: error)
                onCompleted(nil)
                return
            }
            onCompleted(timingString)
        }
    }

    /// 解析性能数据
    /// - Parameter timingStr:window.performance.timing字符串
    private func parsePerformanceTimingData(_ timingStr: String) -> LarkWebView.PerformanceTiming? {
        guard let data = timingStr.data(using: String.Encoding.utf8) else {
            logger.error("performance.timing is invalid")
            return nil
        }

        guard let timing = try? JSONDecoder().decode(PerformanceTiming.self, from: data) else {
            logger.error("decode performance.timing json failed!")
            return nil
        }
        return timing
    }
}
