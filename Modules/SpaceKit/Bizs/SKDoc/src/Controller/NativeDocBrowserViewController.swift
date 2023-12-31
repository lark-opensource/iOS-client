//
//  NativeDocBrowserViewController.swift
//  SKDoc
//
//  Created by chenhuaguan on 2021/7/15.
//

#if canImport(SKEditor)

import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit


final public class NativeDocBrowserViewController: DocBrowserViewController {

    private var lastFullscreenStoredOffsetY: CGFloat = 0
    
    public override func topContainerDidUpdateSubviews() {
        let topMargin = topContainer.preferredHeight
        let originInset = editor.scrollViewProxy.contentInset
        editor.scrollViewProxy.contentInset = UIEdgeInsets(top: topMargin, left: originInset.left, bottom: originInset.bottom, right: originInset.right)
    }

    public override func configEditorScrollView() {
        let topMargin = topContainer.preferredHeight
        let originInset = editor.scrollViewProxy.contentInset
        editor.scrollViewProxy.contentInset = UIEdgeInsets(top: topMargin, left: originInset.left, bottom: originInset.bottom, right: originInset.right)
        editor.scrollViewProxy.bounces = true
    }

    public override func updateTopPlaceholderHeight(webviewContentOffsetY: CGFloat, scrollView: EditorScrollViewProxy? = nil, forceUpdate: Bool = false) {

    }

    public override func updateEditorConstraints(forOrientation orientation: UIInterfaceOrientation) {
        guard editor.superview != nil else { return }
        switch orientation {
        case .landscapeLeft: // notch right
            editor.snp.remakeConstraints { (make) in
                make.top.equalTo(self.statusBar.snp.bottom)
                make.leading.bottom.equalToSuperview()
                make.trailing.equalTo(self.view.safeAreaLayoutGuide.snp.trailing)
            }
        case .landscapeRight: // notch left
            editor.snp.remakeConstraints { (make) in
                make.top.equalTo(self.statusBar.snp.bottom)
                make.trailing.bottom.equalToSuperview()
                make.leading.equalTo(self.view.safeAreaLayoutGuide.snp.leading)
            }
        default:
            editor.snp.remakeConstraints { (make) in
                make.top.equalTo(self.statusBar.snp.bottom)
                make.leading.bottom.trailing.equalToSuperview()
            }
        }
        view.layoutIfNeeded()
    }

    public override func updateFullScreenProgress(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        updateTopPlaceholderHeight(webviewContentOffsetY: editorViewScrollViewProxy.contentOffset.minY)
        let newProgress = updateFullscreenProgress(with: editorViewScrollViewProxy.contentOffset, contentInset: editorViewScrollViewProxy.contentInset)
        setFullScreenProgress(newProgress, editButtonAnimated: false)
    }
    
}

extension NativeDocBrowserViewController {
    /// 更新沉浸式浏览过程，返回进度
    private func updateFullscreenProgress(with contentOffset: CGPoint, contentInset: UIEdgeInsets) -> CGFloat {
        let threshold = topContainer.preferredHeight
        guard threshold > 0 else {
            return 1
        }
        let realContentOffsetY = contentOffset.minY + contentInset.top
        defer {
            lastFullscreenStoredOffsetY = realContentOffsetY
        }
        let progress = realContentOffsetY / threshold
        if realContentOffsetY < lastFullscreenStoredOffsetY, progress > 1 {
            return 0
        } else {
            return progress
        }
    }
}


#endif
