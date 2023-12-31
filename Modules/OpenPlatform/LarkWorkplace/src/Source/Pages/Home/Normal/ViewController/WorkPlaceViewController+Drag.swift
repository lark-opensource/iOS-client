//
//  WorkPlaceViewController+Drag.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2021/3/8.
//

import Foundation
import LarkUIKit
import LarkSceneManager
import RxSwift

extension UIImageView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
/// 拖拽相关
extension WorkPlaceViewController {
    func rawCollectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        /// 判断当前环境是否支持多窗口
        guard WorkPlaceScene.supportMutilScene() else {
            let logMessage = """
            workplace not support drag delegate,
            os Version \(UIDevice.current.systemVersion),
            device type \(UIDevice.current.model),
            app support mutilScene \(SceneManager.shared.supportsMultipleScenes)
            """
            Self.logger.info(logMessage)
            return []
        }
        /// 判断当前应用是否支持拖拽生成新窗口
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            Self.logger.info("workplace not support drag delegate, cell is empty")
            return []
        }
        guard let iconCell = cell as? WorkPlaceIconCell else {
            Self.logger.info("workplace not support drag delegate, cell is not WorkPlaceIconCell \(type(of: cell))")
            return []
        }
        guard let appAbility = iconCell.workplaceItem?.badgeAbility(),
              appAbility == .web else {
            let logMessage =
            """
            workplace not support drag delegate,
            cell ability is not h5 type \(iconCell.workplaceItem?.itemId ?? ""),
            \(iconCell.workplaceItem?.itemType.rawValue)
            """
            Self.logger.info(logMessage)
            return []
        }
        /// 配置拖拽信息
        if let scene = iconCell.supportDragScene() {
            scene.sceneSourceID = self.currentSceneID()
            let activity = SceneTransformer.transform(scene: scene)
            let imageView = iconCell.iconView
            let image = imageView.asImage()
            let itemProvider = NSItemProvider()
            let item = UIDragItem(itemProvider: itemProvider)
            item.previewProvider = { () -> UIDragPreview? in
                let imageView = UIImageView(image: image)
                imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                imageView.layer.cornerRadius = 8
                return UIDragPreview(view: imageView)
            }
            itemProvider.registerObject(activity, visibility: .all)
            return [item]
        }
        return []
    }
    func setupDragInteraction() {
        if WorkPlaceScene.supportMutilScene() {
            self.workPlaceCollectionView.dragDelegate = self
        }
    }
    /// 添加常用应用的popover需要移除
    func dismissPressedMenu() {
        if let menuView = self.actMenuShowManager.longPressMenuView {
            menuView.dismiss()
            self.actMenuShowManager.showMenuPopOver?.dismiss(animated: false, completion: nil)
        }
    }
    func deObserveAuxiliarySceneActive() {
        notificationDisposeBag = DisposeBag()
    }

    func observeAuxiliarySceneActive() {
        deObserveAuxiliarySceneActive()

        NotificationCenter.default.rx.notification(AppCenterNotification.activeAuxiliaryScene.name)
            .subscribe(onNext: { [weak self] _ in self?.dismissPressedMenu() })
            .disposed(by: notificationDisposeBag)
    }
}
