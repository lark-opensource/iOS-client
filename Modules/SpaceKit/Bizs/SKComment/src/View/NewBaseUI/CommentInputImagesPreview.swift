//
//  InputImagesPreview.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/9/18.
//

import SKFoundation
import SKUIKit
import Kingfisher
import SKResource
import RxSwift
import SnapKit
import CoreGraphics
import SpaceInterface

protocol CommentInputImagesPreviewProtocol: AnyObject {
    func didClickPreviewImage(imageInfo: CommentImageInfo)
    func didClickDeleteImgBtn(imageInfo: CommentImageInfo)
}

class CommentInputImagesPreview: UIView, ImageEditViewProtocol {
    weak var delegate: CommentInputImagesPreviewProtocol?
    private let supportEdit: Bool
    private let picAndPicGap: CGFloat = 4
    private let picViewWidth: CGFloat = 80
    private let picViewWidthLandscape: CGFloat = 40
    private let picTopGap: CGFloat = 2
    private let picBottomGap: CGFloat = 12
    private let containerleftRightGap: CGFloat = 0
    private let countInLine: Int = CommentImageInfo.commentImageMaxCount
    private var imageInfosArray: [CommentImageInfo] = []
    private var imageItemViews: [ImageItemView] = []
    private let scrollView: UIScrollView
    private var containerView: UIView
    private var isChangeLandscape: Bool = false
    /// 竖屏下的约束
    private var portraitScreenConstraints: [SnapKit.Constraint] = []
    /// 横屏下的约束
    private var landscapeScreenConstraints: [SnapKit.Constraint] = []
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(supportEdit: Bool) {
        self.supportEdit = supportEdit
        scrollView = UIScrollView()
        scrollView.alwaysBounceHorizontal = true
        containerView = UIView()
        super.init(frame: .zero)

        scrollView.addSubview(containerView)
        self.addSubview(scrollView)
        updateContainerViewStatus(itemCount: 0)
    }

    func updateContainerViewStatus(itemCount: Int) {
        scrollView.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(containerleftRightGap)
            make.right.equalToSuperview().offset(-containerleftRightGap)
            make.top.bottom.equalToSuperview()
            if itemCount <= 0 {
//                make.height.equalTo(0)
                portraitScreenConstraints.append(make.height.equalTo(0).constraint)
                landscapeScreenConstraints.append(make.width.equalTo(0).constraint)
            } else {
                portraitScreenConstraints.append(make.height.equalTo(picViewWidth + picTopGap + picBottomGap).constraint)
//                make.height.equalTo(picViewWidth + picTopGap + picBottomGap)
                let widthLandscape: CGFloat = CGFloat(itemCount) * picViewWidthLandscape + CGFloat(itemCount - 1) * picAndPicGap
                landscapeScreenConstraints.append(make.width.equalTo(widthLandscape).constraint)
            }
        }

        containerView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ImagesCountHadChanged"), object: nil)
    }

    func dequeueImageView(index: Int, itemCount: Int) -> ImageItemView {
        var imageItem: ImageItemView!
        if index < imageItemViews.count {
            imageItem = imageItemViews[index]
        } else {
            imageItem = ImageItemView(frame: .zero, supportEdit: self.supportEdit)
            imageItem.isUserInteractionEnabled = true
            imageItem.delegate = self
            containerView.addSubview(imageItem)
            imageItemViews.append(imageItem)
//            imageItem.rightInset = CGFloat(-ImageItemView.deleteBtnWidth / 2)
//            imageItem.topInset = CGFloat(-ImageItemView.deleteBtnWidth / 2)
        }

        if imageItem.superview != nil {
            imageItem.snp.remakeConstraints {(make) in
                portraitScreenConstraints.append(make.top.equalToSuperview().offset(picTopGap).constraint)
                portraitScreenConstraints.append(make.bottom.equalToSuperview().offset(-picBottomGap).constraint)
                portraitScreenConstraints.append(make.width.height.equalTo(picViewWidth).constraint)
                portraitScreenConstraints.append(make.left.equalTo((picViewWidth + picAndPicGap) * CGFloat(index)).constraint)
//                make.top.equalToSuperview().offset(picTopGap)
//                make.bottom.equalToSuperview().offset(-picBottomGap)
//                make.width.height.equalTo(picViewWidth)
//                make.left.equalTo((picViewWidth + picAndPicGap) * CGFloat(index))
//                landscapeScreenConstraints.append(make.top.bottom.equalToSuperview().constraint)
//                landscapeScreenConstraints.append(make.centerY.equalToSuperview().constraint)
                landscapeScreenConstraints.append(make.top.equalToSuperview().constraint)
                landscapeScreenConstraints.append(make.bottom.equalToSuperview().constraint)
                landscapeScreenConstraints.append(make.width.height.equalTo(picViewWidthLandscape).constraint)
                landscapeScreenConstraints.append(make.left.equalTo((picViewWidthLandscape + picAndPicGap) * CGFloat(index)).constraint)
                if index == itemCount - 1 {
                    make.right.equalToSuperview()
                }
            }
        }
        return imageItem
    }

    func updateView(imageInfos: [CommentImageInfo]) {
        let isIncrease: Bool = imageInfos.count > imageInfosArray.count
        imageInfosArray = imageInfos
        guard imageInfosArray.count > 0 else {
            imageItemViews.forEach { (itemView) in
                if itemView.superview != nil {
                    itemView.snp.remakeConstraints { (make) in
                         make.height.width.equalTo(0)
                    }
                }
                itemView.isHidden = true
            }
            updateContainerViewStatus(itemCount: 0)
            return
        }
        updateContainerViewStatus(itemCount: imageInfosArray.count)
        // 多余的imageView隐藏掉
        for (index, itemView) in imageItemViews.enumerated() {
            itemView.isHidden = (index >= imageInfosArray.count)
            itemView.snp.removeConstraints()
        }
        portraitScreenConstraints.removeAll()
        landscapeScreenConstraints.removeAll()

        for (index, info) in imageInfosArray.enumerated() {
            if index < countInLine {
                let imageView = dequeueImageView(index: index, itemCount: imageInfosArray.count)
                imageView.updateImage(imageInfo: info)
            } else {
                DocsLogger.info("imageInfo数量超了，imageInfos.count=\(imageInfos.count)")
            }
        }

        if isIncrease {
            //如果是新增，滚动到最后位置
            DispatchQueue.main.async {
                self.layoutIfNeeded()
                let bottomOffset: CGPoint = CGPoint(x: self.scrollView.contentSize.width - self.scrollView.bounds.size.width, y: 0)
                if bottomOffset.x > 0 {
                    self.scrollView.setContentOffset(bottomOffset, animated: true)
                }
            }
        }
        
        self.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: self.isChangeLandscape)
    }

    func didClickDeleteImgBtn(imageItemView: ImageItemView) {
        let indexTemp = imageItemViews.firstIndex(of: imageItemView)
        guard let index = indexTemp, index < imageInfosArray.count else {
            DocsLogger.info("删除图片失败，imageItemViews.count=\(imageItemViews.count), imageInfos.count=\(imageInfosArray.count)")
            return
        }
        let imageinfo = imageInfosArray[index]
        self.delegate?.didClickDeleteImgBtn(imageInfo: imageinfo)
    }

    func didClickPreviewImage(imageItemView: ImageItemView) {
        let indexTemp = imageItemViews.firstIndex(of: imageItemView)
        guard let index = indexTemp, index < imageInfosArray.count else {
            DocsLogger.info("点击preview，Error，imageItemViews.count=\(imageItemViews.count), imageInfos.count=\(imageInfosArray.count)")
            return
        }
        let imageinfo = imageInfosArray[index]
        self.delegate?.didClickPreviewImage(imageInfo: imageinfo)
    }
    
    
}

extension CommentInputImagesPreview {
    /// 根据是否支持横屏下评论和当前设备方向更改布局
    public func updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: Bool) {
        self.isChangeLandscape = isChangeLandscape
        
        if isChangeLandscape {
            portraitScreenConstraints.forEach { $0.deactivate() }
            landscapeScreenConstraints.forEach { $0.activate() }
        } else {
            landscapeScreenConstraints.forEach { $0.deactivate() }
            portraitScreenConstraints.forEach { $0.activate() }
        }
        
        imageItemViews.forEach { item in
            item.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: isChangeLandscape)
        }
    }
}
