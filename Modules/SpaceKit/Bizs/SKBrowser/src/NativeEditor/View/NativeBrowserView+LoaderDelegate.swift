//
//  NativeBrowserView+LoaderDelegate.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2021/7/9.
//

import SKFoundation
import SKUIKit
import SKCommon

extension NativeBrowserView: NativeLoaderDelegate {
    func requestShowLoadingFor(_ url: URL) {
        loadingDelegate?.updateLoadStatus(.larkLoading(url: url))
    }

    func didUpdateLoadStatus(_ status: NativeLoaderStatus) {
        switch status {
        case .loading:
            // 这里不加loadingView, 如果有需要，会在requestShowLoadingFor拉起loading
            break
        case .success:
            loadingDelegate?.updateLoadStatus(.success)
        case .overtime:
            loadingDelegate?.updateLoadStatus(.overtime)
        case .fail:
            status.errorMsg.map {
                appendInfo($0)
                loadingDelegate?.updateLoadStatus(.fail(msg: $0))
            }
        default:
            break
        }
    }
}
