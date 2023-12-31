//
//  WPBlockViewDelegate.swift
//  LarkWorkplace
//
//  Created by doujian on 2022/7/1.
//

import ECOInfra

protocol WPBlockViewDelegate: NSObjectProtocol {

    /// Block Header 标题区域点击回调
    func onTitleClick(_ view: WPBlockView, link: String?)

    /// Block Header 操作区域点击回调
    func onActionClick(_ view: WPBlockView)

    /// 长按手势事件回调
    func onLongPress(_ view: WPBlockView, gesture: UIGestureRecognizer)

    /// block 加载失败
    func blockDidFail(_ view: WPBlockView, error: OPError)

    /// block 渲染成功
    func blockRenderSuccess(_ view: WPBlockView)

    /// Block 收到 Lynx log 回调
    func blockDidReceiveLogMessage(_ view: WPBlockView, message: WPBlockLogMessage)

    /// Block 内容大小发生变化
    func blockContentSizeDidChange(_ view: WPBlockView, newSize: CGSize)

    func handleAPI(
        _ plugin: BlockCellPlugin,
        api: WPBlockAPI.InvokeAPI,
        param: [AnyHashable: Any],
        callback: @escaping WPBlockAPICallback
    )

    func longGestureShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool

    func tryHideBlock(_ view: WPBlockView)
}

extension WPBlockViewDelegate {
    func tryHideBlock(_ view: WPBlockView) {}
}
