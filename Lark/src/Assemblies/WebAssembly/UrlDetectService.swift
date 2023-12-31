//
//  URLDetectService.swift
//  LarkWebView
//
//  Created by bytedance on 2020/5/9.
//  code from @zhaodong.23
//

import Foundation
import WebKit
import RxSwift
import RxCocoa

//code from zhaodong
/// url恶意链接检测服务
protocol URLDetectService {
    var judgeURL: (String) -> Observable<Bool> { get }

    var secLinkResultDriver: Driver<Bool> { get }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, isAsync: Bool)

    func webViewDidFinish(url: URL?)

    func webViewDidFailProvisionalNavigation(error: Error, url: URL?)

    func webViewDidFail(error: Error, url: URL?)
    func seclinkPrecheck(url: URL, checkReuslt: @escaping (Bool) -> Swift.Void)
}
