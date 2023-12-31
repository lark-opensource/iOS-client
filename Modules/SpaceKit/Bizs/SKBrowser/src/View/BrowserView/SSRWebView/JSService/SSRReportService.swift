//
//  SSRReportService.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/6/6.
//  


import Foundation
import SKCommon
import SKFoundation

final class SSRReportService: ReportService {
    override var isSSRWebView: Bool { true }
    override var renderSSRType: RenderSSRWebviewType {
        if let ssrWebView = self.ui as? WebBrowserView, let webLoader = ssrWebView.webLoader {
            return webLoader.renderSSRWebviewType
        }
        return .none
    }
}

