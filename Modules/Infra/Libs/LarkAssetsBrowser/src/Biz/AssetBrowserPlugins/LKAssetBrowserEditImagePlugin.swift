//
//  LKAssetBrowserEditImagePlugin.swift
//  LarkAssetsBrowser
//
//  Created by Hayden Wang on 2022/11/14.
//

import Foundation
import UIKit
import EENavigator
import LarkUIKit
import LarkImageEditor

public final class LKAssetBrowserEditImagePlugin: LKAssetBrowserPlugin {
        
    private weak var assetBrowser: LKAssetBrowser?
    
    public override var type: LKAssetPluginPosition {
        .all
    }
    
    public override var icon: UIImage? {
        Resources.asset_photo_edit
    }
    
    public override var title: String? {
        BundleI18n.LarkAssetsBrowser.Lark_Legacy_Edit
    }
    
    public override func shouldDisplayPlugin(on context: LKAssetBrowserContext) -> Bool {
        guard let imagePage = context.currentPage as? LKAssetBaseImagePage, imagePage.imageView.image != nil else {
            return false
        }
        return true
    }
    
    public override func handleAsset(on context: LKAssetBrowserContext) {
        assetBrowser = context.assetBrowser
        guard let currentPage = context.currentPage, let browser = context.assetBrowser else { return }
        guard let imagePage = currentPage as? LKAssetBaseImagePage, let image = imagePage.imageView.image else {
            return
        }
        let imageEditVC = ImageEditorFactory.createEditor(with: image)
        imageEditVC.delegate = self
        let navigationVC = LkNavigationController(rootViewController: imageEditVC)
        navigationVC.modalPresentationStyle = .fullScreen
        Navigator.shared.present(navigationVC, from: browser, animated: false)
    }
}

extension LKAssetBrowserEditImagePlugin: ImageEditViewControllerDelegate {
    
    public func closeButtonDidClicked(vc: LarkImageEditor.EditViewController) {
        vc.exit()
    }
    
    public func finishButtonDidClicked(vc: LarkImageEditor.EditViewController, editImage: UIImage) {
        guard let currentPage = assetBrowser?.galleryView.currentPage else {
            vc.exit()
            return
        }
        (currentPage as? LKAssetBaseImagePage)?.imageView.image = editImage
        vc.exit()
    }
}
