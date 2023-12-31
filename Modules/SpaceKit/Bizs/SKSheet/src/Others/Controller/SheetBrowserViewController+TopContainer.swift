//
// Created by duanxiaochen.7 on 2021/3/10.
// Affiliated with SKSheet.
//
// Description:

import SKBrowser
import SKCommon
import SKFoundation
import SKUIKit
import SKResource

protocol SheetTabSwitcherDelegate: AnyObject {
    func callJSFunction(_ function: DocsJSCallBack, params: [String: Any])
    func forceOrientation(to: UIInterfaceOrientation)
}

extension SheetBrowserViewController: SheetTabSwitcherDelegate {
    func callJSFunction(_ function: DocsJSCallBack, params: [String: Any]) {
        editor.callFunction(function, params: params, completion: { (_, error) in
            guard error == nil else {
                DocsLogger.error("Sheet 工作表调用 JS 发生错误：", error: error, component: LogComponents.sheetTab)
                return
            }
        })
    }

    func forceOrientation(to newOrientation: UIInterfaceOrientation) {
        orientationDirector?.forceSetOrientation(newOrientation, action: .exitLandscape, source: .sheetTabExitLandscapeButton)
    }
}



protocol SheetTabSwitcherViewForbidDropDelegate: AnyObject {
    func addTransparentCollectionViewAboveWebview()
    func removeTransparentCollectionView()
}

extension SheetBrowserViewController: SheetTabSwitcherViewForbidDropDelegate {
    func addTransparentCollectionViewAboveWebview() {
        let fakeView = FakeCollectionView(frame: editor.frame, collectionViewLayout: UICollectionViewFlowLayout())
        fakeView.backgroundColor = .clear
        fakeCollectionView = fakeView
        view.addSubview(fakeView)
    }

    func removeTransparentCollectionView() {
        fakeCollectionView?.removeFromSuperview()
    }

    private class FakeCollectionView: UICollectionView, UICollectionViewDropDelegate {
        func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        }

        func collectionView(_ collectionView: UICollectionView,
                            dropSessionDidUpdate session: UIDropSession,
                            withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
            return UICollectionViewDropProposal(operation: .cancel)
        }
    }
}



public protocol SheetBrowserTopContainerDelegate: BrowserTopContainerDelegate {
    func topContainerDidUpdateTabSwitcherViewAppearance(_: Bool)
}


extension SheetBrowserViewController: SheetBrowserTopContainerDelegate {
    public func topContainerDidUpdateTabSwitcherViewAppearance(_ isAppearing: Bool) {
        topContainerDidUpdateSubviews()
        OnboardingManager.shared.targetView(for: [.sheetCardModeShare], updatedExistence: !isAppearing) // 消失时，代表进入了卡片模式，可以播放卡片模式相关引导
    }
}
