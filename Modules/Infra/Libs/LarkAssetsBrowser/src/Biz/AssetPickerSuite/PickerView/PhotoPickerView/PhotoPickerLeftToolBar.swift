//
//  PhotoPickerLeftToolBar.swift
//  LarkUIKit
//
//  Created by SuPeng on 3/18/19.
//

import UIKit
import Foundation

protocol PhotoPickerLeftToolBarDelegate: AnyObject {
    func leftToolBarDidClickTakePhotoButton(_ leftToolBar: PhotoPickerLeftToolBar)
    func leftToolBarDidClickShowPhotoLibraryButton(_ leftToolBar: PhotoPickerLeftToolBar)
}

final class PhotoPickerLeftToolBar: UIView {
    weak var delegate: PhotoPickerLeftToolBarDelegate?

    private let takePhotoButton = UIButton(type: .custom)
    private let showPhotoLibraryButton = UIButton(type: .custom)

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor.ud.rgb(0x2E2E2E)

        takePhotoButton.setImage(Resources.camera, for: .normal)
        takePhotoButton.addTarget(self, action: #selector(takePhotoButtonDidClick), for: .touchUpInside)
        addSubview(takePhotoButton)
        takePhotoButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(47)
        }

        showPhotoLibraryButton.setImage(Resources.photoLibrary, for: .normal)
        showPhotoLibraryButton.addTarget(self, action: #selector(showPhotoLibraryButtonDidClick), for: .touchUpInside)
        addSubview(showPhotoLibraryButton)
        showPhotoLibraryButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-47)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func takePhotoButtonDidClick() {
        delegate?.leftToolBarDidClickTakePhotoButton(self)
    }

    @objc
    private func showPhotoLibraryButtonDidClick() {
        delegate?.leftToolBarDidClickShowPhotoLibraryButton(self)
    }
}
