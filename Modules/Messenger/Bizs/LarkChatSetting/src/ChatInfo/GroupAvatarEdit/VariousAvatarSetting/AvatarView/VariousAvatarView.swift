//
//  VariousAvatarView.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/11/13.
//

import Foundation
import UIKit
import FigmaKit
import LarkBizAvatar
import AvatarComponent
import RustPB
import ByteWebImage
import UniverseDesignColor
import LKCommonsLogging

final class VariousAvatarView: GenericAvatarView {
    /// 相机按钮
    private var cameraButton = UIButton(type: .custom)
    /// 拍照icon被点击
    var cameraButtonClick: ((_ sender: UIView) -> Void)?

    /// 截图的不需要截的
    var screenshotWithoutViews: [UIView] {
        return [self.cameraButton]
    }

    init(defaultImage: UIImage) {
        super.init(defaultImage: defaultImage)
        updateView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateView() {
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                              action: #selector(tapAvatarImageView)))
        self.addSubview(cameraButton)
        cameraButton.setImage(Resources.cameraIcon, for: .normal)
        cameraButton.layer.masksToBounds = true
        cameraButton.backgroundColor = UIColor.ud.N200
        cameraButton.layer.cornerRadius = 18
        cameraButton.layer.borderWidth = 3
        cameraButton.layer.ud.setBorderColor(UIColor.ud.bgBody)
        cameraButton.addTarget(self, action: #selector(buttonClick(sender:)), for: .touchUpInside)
        cameraButton.snp.makeConstraints { (maker) in
            maker.height.width.equalTo(36)
            maker.right.equalTo(imageView)
            maker.bottom.equalTo(imageView)
        }
    }

    @objc
    private func tapAvatarImageView() {
        self.cameraButtonClick?(imageView)
    }

    @objc
    private func buttonClick(sender: UIView) {
        self.cameraButtonClick?(sender)
    }

    override func getAvatarImage() -> UIImage {
        if case .image(let image) = avatarType {
            return image
        } else if case .upload(let image) = avatarType {
            return image
        } else {
            screenshotWithoutViews.forEach { $0.isHidden = true }
            let image = self.lu.screenshot() ?? UIImage()
            screenshotWithoutViews.forEach { $0.isHidden = false }
            return image
        }
    }

}
