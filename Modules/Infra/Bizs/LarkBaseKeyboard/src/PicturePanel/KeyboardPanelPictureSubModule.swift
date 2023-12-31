//
//  KeyboardPanelPictureSubModule.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/5.
//

import UIKit
import LarkOpenKeyboard
import LarkAssetsBrowser
import LarkKeyboardView
import Photos
import LarkFoundation

public protocol KeyboardPanelPictureService {
    /// 该方法在检测失败会自动提示error
    func checkMediaSendEnable(assets: [PHAsset], on view: UIView?) -> Bool
    func checkImageSendEnable(image: UIImage, on view: UIView?) -> Bool
    func checkVideoSendEnable(videoURL: URL, on view: UIView?) -> Bool
}

/**
发图片的逻辑各个业务放自行定制，目前没有较为通用的逻辑，只提供基础的FreeDisk检测能力
 */
open class KeyboardPanelPictureSubModule<C:KeyboardContext, M:KeyboardMetaModel>:
    BaseKeyboardPanelDefaultSubModule<C, M>, AssetPickerSuiteViewDelegate {

    open override class var name: String {
        return "KeyboardPanelPictureSubModule"
    }

    open override var panelItemKey: KeyboardItemKey {
        return .picture
    }

    /// 上层会进行注册
    var pictureServiceImp: KeyboardPanelPictureService? {
        return self.context.resolver.resolve(KeyboardPanelPictureService.self)
    }

    public private(set) var pictureKeyboard: AssetPickerSuiteView?

    /// 不是Mac 系统才可以使用
    open override func canHandle(model: M) -> Bool {
        return !Utils.isiOSAppOnMacSystem
    }

    open override func didCreatePanelItem() -> InputKeyboardItem? {
        guard let config = self.getPanelConfig() else { return nil }
        let selectedBlock: () -> Bool = { [weak self] in
            self?.pictureKeyboard?.reset()
            self?.context.keyboardAppearForSelectedPanel(item: KeyboardItemKey.picture)
            return config.1.selectedBlock()
        }

        let photoViewCallback: (AssetPickerSuiteView) -> Void = { [weak self] (view) in
            self?.pictureKeyboard = view
            config.1.photoViewCallback(view)
        }

        return LarkKeyboard.buildPicture(config.0, LarkKeyboard.PictureKeyboardConfig(type: config.1.type,
                                                                                      delegate: config.1.delegate,
                                                                                      selectedBlock: selectedBlock,
                                                                                      photoViewCallback: photoViewCallback,
                                                                                      originVideo: config.1.originVideo,
                                                                                      sendButtonTitle: config.1.sendButtonTitle,
                                                                                      isOriginalButtonHidden: config.1.isOriginalButtonHidden))
    }

    open func getPanelConfig() -> (UIColor?, LarkKeyboard.PictureKeyboardConfig)? {
        assertionFailure("need to be override")
        return nil
    }

    open func assetPickerSuite(_ suiteView: LarkAssetsBrowser.AssetPickerSuiteView, didChangeSelection result: LarkAssetsBrowser.AssetPickerSuiteSelectResult) {
    }

    open func assetPickerSuite(_ suiteView: LarkAssetsBrowser.AssetPickerSuiteView, didPreview asset: PHAsset) {
    }

    open func assetPickerSuiteShouldUpdateHeight(_ suiteView: AssetPickerSuiteView) {
        context.keyboardPanel.updateKeyboardHeightIfNeeded()
    }
    
    open func assetPickerSuite(_ clickType: AssetPickerSuiteClickType) {
    }

    open func assetPickerSuite(_ clickType: AssetPickerPreviewClickType) {
    }

    open func assetPickerSuite(_ suiteView: LarkAssetsBrowser.AssetPickerSuiteView, didFinishSelect result: LarkAssetsBrowser.AssetPickerSuiteSelectResult) {
        guard pictureServiceImp?.checkMediaSendEnable(assets: result.selectedAssets,
                                                      on: context.displayVC.view) == true else {
            return
        }
    }

    open func assetPickerSuite(_ suiteView: LarkAssetsBrowser.AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        guard pictureServiceImp?.checkImageSendEnable(image: photo, on: context.displayVC.view) == true else { return }
    }

    open func assetPickerSuite(_ suiteView: LarkAssetsBrowser.AssetPickerSuiteView, didTakeVideo url: URL) {
        guard pictureServiceImp?.checkVideoSendEnable(videoURL: url, on: context.displayVC.view) == true else { return }
    }
}
