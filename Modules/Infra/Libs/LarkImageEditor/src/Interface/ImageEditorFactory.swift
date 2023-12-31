//
//  ImageEditorFactory.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/8/10.
//

import Foundation
import LarkSetting
import UIKit
import RxSwift

/// 图片编辑VC，图片裁剪VC的Mock实现
public final class MockViewController: UIViewController, EditViewController, CropViewController {
    init() { super.init(nibName: nil, bundle: nil) }

    /// eventBlock
    public var eventBlock: ((ImageEditEvent) -> Void)?

    /// successCallback
    public var successCallback: ((UIImage, CropViewController, CGRect) -> Void)?

    /// cancelCallback
    public var cancelCallback: ((CropViewController) -> Void)?

    /// exit
    public func exit() {}

    /// editEventObservable
    public var editEventObservable = Observable<ImageEditEvent>.empty()

    /// delegate
    public weak var delegate: ImageEditViewControllerDelegate?

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// ImageEditorFactory
public enum ImageEditorFactory {
    /// return an ImageEditorVC
    public static func createEditor(with image: UIImage) -> EditViewController {
        var editorV1: EditViewController?
        var editorV2: EditViewController?

        #if LarkImageEditor_V2
        editorV2 = ImageEditorViewController(image: image)
        #endif

        #if LarkImageEditor_V1
        editorV1 = ImageEditViewController(image: image)
        #endif

        if let editorV1 = editorV1, let editorV2 = editorV2 {
            return FeatureGatingManager.shared.featureGatingValue(with: "messenger.image.ve.editor") //Global 调用地方有点多，不好改,和UI有关，和用户数据无关，先不改了。。。
            ? editorV2 : editorV1
        } else {
            return editorV2 ?? editorV1 ?? MockViewController()
        }
    }
}

/// CropperFactory
public enum CropperFactory {
    /// return an CropperVC
    public static func createCropper(with image: UIImage, and config: CropperConfigure = .default,
                                     toolBarTitle: String? = nil) -> CropViewController {
        var cropperV1: CropViewController?
        var cropperV2: CropViewController?

        #if LarkImageCropper_V2
        cropperV2 = ImageEditCropperViewController(image: image, config: config, toolBarTitle: toolBarTitle)
        #endif

        #if LarkImageEditor_V1
        cropperV1 = CropperViewController(image: image, config: config, toolBarTitle: toolBarTitle)
        #endif

        return cropperV2 ?? cropperV1 ?? MockViewController()
    }
}
