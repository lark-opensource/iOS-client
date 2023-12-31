//
//  CommentImageItemView.swift
//  SKCommon
//
//  Created by huangzhikai on 2022/9/22.
//

import Foundation
import SKResource
import SKUIKit
import RxSwift
import SKFoundation
import SpaceInterface

protocol ImageEditViewProtocol: NSObjectProtocol {
    func didClickDeleteImgBtn(imageItemView: ImageItemView)
    func didClickPreviewImage(imageItemView: ImageItemView)
}

class ImageItemView: DocsClickView {
    private let deleteBtnWidth: Int = 30
    private let deleteBtnWidthLandscape: Int = 22
    private var disposeBag: DisposeBag = DisposeBag()
    weak var delegate: ImageEditViewProtocol?
    private var currentImageInfo: CommentImageInfo?
    private var imageView: UIImageView = UIImageView()
    private var deleteBtn: UIButton = UIButton()

    init(frame: CGRect, supportEdit: Bool) {
        super.init(frame: .zero)

        //图片
        self.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 4.0
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0.5
        imageView.ud.setLayerBorderColor(UIColor.ud.lineBorderCard)
        imageView.isUserInteractionEnabled = true
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickPreviewImage))
        imageView.addGestureRecognizer(singleTapGesture)

        if supportEdit {
            //删除按钮
            let deleteBtn = UIButton()
            deleteBtn.setImage(BundleResources.SKResource.Common.Comment.icon_comment_delete_img, for: .normal)
            self.addSubview(deleteBtn)
            deleteBtn.snp.makeConstraints { (make) in
                make.width.height.equalTo(deleteBtnWidth)
                make.right.equalTo(self.snp.right).offset(-0)
                make.top.equalTo(self.snp.top).offset(0)
            }
            deleteBtn.rx.tap
                .bind { [weak self] in
                    self?.didClickDeleteImgBtn()
                }.disposed(by: disposeBag)
            self.deleteBtn = deleteBtn
        }
    }

    func updateImage(imageInfo: CommentImageInfo) {
        currentImageInfo = imageInfo
        let util = CommentFetchImageUtil.shared
        util.getCacheImage(imageInfo: imageInfo, useOriginalSrc: false, completion: { [weak self] (image1, _) in // 尝试获取缩略图缓存
            if let image = image1 {
                self?.imageView.image = image
                self?.imageView.backgroundColor = .clear
            } else if imageInfo.originalSrc != nil {
                // 尝试获取原图缓存
                util.getCacheImage(imageInfo: imageInfo, useOriginalSrc: true, completion: { [weak self] (image2, _) in
                    if let image = image2 {
                        self?.imageView.image = image
                        self?.imageView.backgroundColor = .clear
                    } else {
                        self?.fetchNetworkImage(imageInfo)
                    }
                })
            } else {
                self?.fetchNetworkImage(imageInfo)
            }
        })
    }
    
    //从网络拉取图片
    private func fetchNetworkImage(_ imageInfo: CommentImageInfo) {
        self.imageView.image = nil
        self.imageView.backgroundColor = UIColor.ud.N200
        CommentFetchImageUtil.shared.fetchImage(urlStr: imageInfo.src, picToken: imageInfo.token) { (urlStr, image, _) in
            if urlStr == self.currentImageInfo?.src {
                self.imageView.backgroundColor = .clear
                self.imageView.image = image ?? BundleResources.SKResource.Common.Comment.icon_comment_fail_img
            }
            if image == nil {
                DocsLogger.info("CommentInputImagesPreview，fetch image fail， urlStr=\(urlStr.encryptToken)，infoSource=\(String(describing: self.currentImageInfo?.src.encryptToken))")
            }
        }
    }

    private func didClickDeleteImgBtn() {
        self.delegate?.didClickDeleteImgBtn(imageItemView: self)
    }

    @objc
    private func didClickPreviewImage() {
        self.delegate?.didClickPreviewImage(imageItemView: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ImageItemView {
    /// 根据是否支持横屏下评论和当前设备方向更改布局
    public func updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: Bool) {
        
        if isChangeLandscape {
            self.deleteBtn.snp.updateConstraints { (make) in
                make.width.height.equalTo(deleteBtnWidthLandscape)
            }
        } else {
            self.deleteBtn.snp.updateConstraints { (make) in
                make.width.height.equalTo(deleteBtnWidth)
            }
        }
    }
}
