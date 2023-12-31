//
//  BitableMultiListController+Others.swift
//  SKSpace
//
//  Created by ByteDance on 2023/12/14.
//

import Foundation
import LarkUIKit
import SKUIKit
import SKFoundation
import LarkSplitViewController

// MARK: - iPad Compatible
extension BitableMultiListController {
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    public override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
    }
}


//MARK: Keyboard Show/Hide event
extension BitableMultiListController {
    func setupKeyboardMonitor() {
        guard SKDisplay.pad else { return }
        keyboard.on(event: .willShow) { [weak self] opt in
            self?.updateCreateButtonIfNeed(keyboardFrame: opt.endFrame, animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .didShow) { [weak self] opt in
            self?.updateCreateButtonIfNeed(keyboardFrame: opt.endFrame, animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .willHide) { [weak self] opt in
            self?.resetCreateButton(animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .didHide) { [weak self] _ in
            self?.resetCreateButton(animationDuration: nil)
        }
        keyboard.start()
    }

    func updateCreateButtonIfNeed(keyboardFrame: CGRect, animationDuration: Double?) {
        let safeAreaViewFrame = view.safeAreaLayoutGuide.layoutFrame
        let buttonX = safeAreaViewFrame.maxX - 16 - 48
        let buttonY = safeAreaViewFrame.maxY - 16 - 48
        let originButtonFrame = CGRect(x: buttonX, y: buttonY, width: 48, height: 48)
        let buttonFrameOnWindow = view.convert(originButtonFrame, to: nil)
        let accessoryViewHeight = UIResponder.sk.currentFirstResponder?.inputAccessoryView?.frame.height ?? 0
        let keyboardMinY = keyboardFrame.minY - accessoryViewHeight
        if buttonFrameOnWindow.intersects(keyboardFrame), keyboardMinY > buttonFrameOnWindow.minY {
            // 仅当键盘与创建按钮有交集，且键盘高度不足以完全遮挡创建按钮时，抬高创建按钮的高度
            let inset = buttonFrameOnWindow.maxY - keyboardFrame.origin.y - accessoryViewHeight + 16
            let realInset = max(inset, 16)
            createButton.snp.updateConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(realInset)
            }
        } else {
            createButton.snp.updateConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            }
        }
        if let duration = animationDuration {
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }

    func resetCreateButton(animationDuration: Double?) {
        createButton.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }
        if let duration = animationDuration {
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }
}

//MARK: 密钥删除
extension BitableMultiListController {
    func setupAppearEvent() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyDeletedEvent), name: .Docs.cipherChanged, object: nil)
    }

    @objc
    func didReceiveKeyDeletedEvent() {
        DispatchQueue.main.async { [self] in
            if isAppear {
                DocsLogger.info("space.home.vc --- refresh immediately when isAppear for cipher changed")
                homeUI.notifyPullToRefresh()
            } else {
                DocsLogger.info("space.home.vc --- wait for appear for cipher changed")
                needRefreshWhenAppear = true
            }
        }
    }
}

//MARK: 文件夹容器
extension BitableMultiListController: SpaceFolderContentViewController {
    public var contentNaviBarCoordinator: SpaceNaviBarCoordinator? {
        return self.naviBarCoordinator
    }
}
