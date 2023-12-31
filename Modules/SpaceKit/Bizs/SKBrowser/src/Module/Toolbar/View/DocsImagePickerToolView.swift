//
//  DocsImagePickerToolView.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/16.
//
// toolbar's second level view of image upload

import Foundation
import LarkUIKit
import SKCommon
import SKUIKit
import SKResource
import LarkAssetsBrowser
import EENavigator
import UIKit
import SKFoundation
import SpaceInterface

class DocsImagePickerToolView: SKSubToolBarPanel {
    /// lark's image picker suit view
    var suiteView: AssetPickerSuiteView?
    override var frame: CGRect {
        didSet {
            super.frame = frame
            updateHeight()
        }
    }

    var presentVC: UIViewController? {
        didSet {
            suiteView?.presentVC = presentVC
        }
    }

    /// Description
    ///
    /// - Parameter frame: frame description
    init(frame: CGRect, fileType: DocsType?, curWindow: UIWindow?) {
        super.init(frame: frame)
        self.clipsToBounds = true
        let presentVC: UIViewController? = UIViewController.docs.topMost(of: curWindow?.rootViewController)
        let isDocFileType: Bool = (fileType == .doc || fileType == .docX)
        //拍照后是否根据权限保存
        var autoSaveType: [DocsType] = [.doc, .docX]
        if UserScopeNoChangeFG.LJW.cameraStoragePermission { autoSaveType.append(.mindnote) }
        var cameraType: CameraType = .custom(true)
        if isDocFileType {
            cameraType = .custom(true)
        } else if autoSaveType.contains(fileType ?? DocsType.unknownDefaultType) {
            cameraType = .systemAutoSave(true)
        } else {
            cameraType = .system
        }
        if isDocFileType {
            suiteView = AssetPickerSuiteView(assetType: .imageOrVideo(imageMaxCount: 9, videoMaxCount: 9),
                                             cameraType: cameraType,
                                             sendButtonTitle: BundleI18n.SKResource.Doc_Facade_Upload,
                                             presentVC: presentVC)
        } else {
            suiteView = AssetPickerSuiteView(assetType: .imageOnly(maxCount: 9),
                                             cameraType: cameraType,
                                             sendButtonTitle: BundleI18n.SKResource.Doc_Facade_Upload,
                                             presentVC: presentVC)
        }

        if let view = suiteView {
            self.addSubview(view)
        }
        suiteView?.snp.makeConstraints { (make) in
            make.left.right.bottom.top.equalToSuperview()
        }
        updateHeight()
    }

    override private init(frame: CGRect) {
        super.init(frame: frame)
    }

    /// Description
    ///
    /// - Parameter aDecoder: aDecoder description
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// update height when the desired frame of second level toolbar panel view changed
    private func updateHeight() {
        DispatchQueue.main.async { [weak self] in
            if let viewHeight = self?.frame.size.height {
                self?.suiteView?.update(height: (viewHeight - (self?.window?.safeAreaInsets.bottom ?? 0)))
            }
        }
    }
}
