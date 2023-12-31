//
//  SKAssuitView+SKImagePickerViewController.swift
//  SKCommon
//
//  Created by tanyunpeng on 2022/9/23.
//  


import LarkUIKit
import Photos
import SKResource
import LarkAssetsBrowser
import EENavigator
import UIKit
import ByteWebImage
import SKUIKit
import SKFoundation

public protocol SKAssuiteView: UIView {
    //照相功能
    func takePhoto()
    //展示相册
    func showPhotoLibrary(selectedItems: [PHAsset], useOriginal: Bool)
    //相机消失后处理
    var cameraVCDidDismiss: (() -> Void)? { get set }
    //图片选择器消失后处理
    var imagePickerVCDidCancel: (() -> Void)? { get set }
}

public protocol SKImagePickerViewController: UINavigationController {
    //展示相册
    func showMultiSelectAssetGridViewController()
    
    var imagePickerFinishSelect: ((LarkAssetsBrowser.ImagePickerViewController, LarkAssetsBrowser.ImagePickerPickResult) -> Void)? { get set }
    
    var imagePikcerCancelSelect: ((LarkAssetsBrowser.ImagePickerViewController, LarkAssetsBrowser.ImagePickerPickResult) -> Void)? { get set }
    
    var imagePickerFinishTakePhoto: ((LarkAssetsBrowser.ImagePickerViewController, UIImage) -> Void)? { get set }
}

extension AssetPickerSuiteView: SKAssuiteView {
    
}

extension ImagePickerViewController: SKImagePickerViewController {
    
}
