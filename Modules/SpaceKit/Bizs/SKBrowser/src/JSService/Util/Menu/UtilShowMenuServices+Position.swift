//
//  UtilShowMenuServices+Position.swift
//  SKBrowser
//
//  Created by lizechuang on 2021/2/4.
//

import Foundation
import SKCommon

extension UtilShowMenuServices {
    func showMenuWithPosition(_ position: [String: CGFloat], menuItems: [BrowserMenuItem]) {
        guard let positionX = position["left"],
              let positionY = position["top"],
              let positionWidth = position["width"],
              let positionHeight = position["height"],
              let editorView = ui?.editorView,
              let hostVC = navigator?.currentBrowserVC as? BrowserViewController else {
            return
        }
        let curSourceRect = CGRect(x: positionX, y: positionY, width: positionWidth, height: positionHeight + 4)
        let vc = ShowMenuViewController(menuItems: menuItems)
        setupPopover(to: vc, containerView: editorView, sourceRect: curSourceRect)
        
        _ = vc.selectAction.subscribe(onNext: { [weak self] (id) in
            guard let self = self else { return }
            if let callback = self.callback {
                self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["id": id], completion: nil)
            }
        })
        ipadMenuVC = vc
        registeredVC?.present(vc, animated: false)
    }

    func setupPopover(to viewController: ShowMenuViewController, containerView: UIView, sourceRect: CGRect) {
        // 由于是指向WebView中的元素，没有具体的sourceView，使用一个替代的View覆盖在其上面
        let tempTargetView = UIView(frame: sourceRect)
        tempTargetView.backgroundColor = .clear
        containerView.addSubview(tempTargetView)
        tempTargetView.snp.makeConstraints { (make) in
            make.left.equalTo(containerView.safeAreaLayoutGuide.snp.left).offset(sourceRect.minX)
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top).offset(sourceRect.minY)
            make.height.equalTo(sourceRect.height)
            make.width.equalTo(sourceRect.width)
        }
        ipadTargetView = tempTargetView
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.sourceView = tempTargetView
        viewController.popoverPresentationController?.sourceRect = tempTargetView.bounds
        viewController.popoverPresentationController?.sourceView = containerView
        viewController.popoverPresentationController?.sourceRect = sourceRect
        viewController.popoverPresentationController?.permittedArrowDirections = [.up]
        viewController.disappearCallBack = { [weak self] in
            self?.ipadTargetView?.removeFromSuperview()
        }
    }
}

extension UtilShowMenuServices {
    // 用于iPad键盘正文滚动隐藏菜单
    func didReceiveWebviewScroll() {
        guard ipadMenuVC != nil else {
            return
        }
        self.ipadMenuVC?.dismiss(animated: true, completion: nil)
    }
}
