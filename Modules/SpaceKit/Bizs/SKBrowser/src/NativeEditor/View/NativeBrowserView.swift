//
//  NativeBrowserView.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2021/7/5.
//

import SKFoundation
import SKUIKit
import SKCommon
import SKEditor

public final class NativeBrowserView: BrowserView {

    private var nativeEditorView: NativeEditorView
    public var nativeLoader: NativeLoader?
    public var nativeScrollViewProxy: EditorScrollViewProxy
    public var nativeEditorGestureProxy: EditorGestureProxy

    public override var docsLoader: DocsLoader? {
        return nativeLoader
    }
    public override var editorView: DocsEditorViewProtocol {
        return nativeEditorView
    }
    public override var scrollViewProxy: EditorScrollViewProxy {
        return nativeScrollViewProxy
    }
    public override var viewGestureProxy: EditorGestureProxy {
        return nativeEditorGestureProxy
    }

    deinit {
        DocsLogger.info("\(editorIdentity) BrowserView deinit", component: LogComponents.nativeEditor)
    }

    override init(frame: CGRect, config: BrowserViewConfig) {
        nativeEditorView = EditorSDK.create(frame: frame, dependency: DocsEditorDependency()) //NativeEditorView(frame: frame)
        nativeEditorView.docsListenToToSubViewResponder = true
        nativeLoader = NativeLoader(editorView: nativeEditorView)
        nativeScrollViewProxy = NativeEditorScrollViewProxyImpl()
        nativeEditorGestureProxy = EditorGestureProxy()
        super.init(frame: frame, config: config)

        nativeEditorView.editorInvokeDelegate = self
        nativeLoader?.delegate = self
        nativeScrollViewProxy.setScrollView(nativeEditorView.getContentScrollView())
        self.backgroundColor = .green

    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func browserDidAppear() {
        super.browserDidAppear()
    }

    public override func browserDidDisappear() {
        super.browserDidDisappear()
    }

    override func clear() {
        DocsLogger.info("NativeBrowserView clear", component: LogComponents.nativeEditor)
        super.clear()
    }

    override public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        DocsLogger.info("callFunction, name=\(function), param=\(String(describing: params))", component: LogComponents.nativeEditor)
        nativeEditorView.excute(EditorServiceName(function.rawValue), params: params)
    }

}
