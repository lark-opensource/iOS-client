//
//  MomentsKeyBoardImageItemView.swift
//  Moment
//
//  Created by bytedance on 2021/1/18.
//

import Foundation
import UIKit
import SnapKit

final class MomentsKeyBoardImageItemView: UIView {
    let imageView = UIImageView()
    @objc let deleCallBack: ((UIView) -> Void)?
    @objc let clickCallBack: (() -> Void)?
    init(image: UIImage, deleCallBack: ((UIView) -> Void)?, clickCallBack: (() -> Void)?) {
        self.imageView.image = image
        self.deleCallBack = deleCallBack
        self.clickCallBack = clickCallBack
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        imageView.layer.cornerRadius = 4
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.ud.N900.withAlphaComponent(0.15).cgColor
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(60)
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        let removeView = PhotoRemoveView { [weak self] in
            self?.deleClick()
        }
        removeView.setCornerStyle(width: PhotoRemoveView.bestSize.width)
        self.addSubview(removeView)
        removeView.snp.makeConstraints { (make) in
            make.top.equalTo(imageView).offset(-5)
            make.right.equalTo(imageView).offset(5)
            make.size.equalTo(PhotoRemoveView.bestSize)
        }
        self.lu.addTapGestureRecognizer(action: #selector(selfClick))
    }

    func deleClick() {
        self.deleCallBack?(self)
    }

    @objc
    func selfClick() {
        self.clickCallBack?()
    }
}
