//
//  InputImagesPreview.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/9/18.
//  swiftlint:disable file_length
import SKFoundation
import SKUIKit
import Kingfisher
import SKResource
import RxSwift
import SnapKit
import LarkUIKit
import UIKit
import UniverseDesignColor
import UniverseDesignEmpty
import SpaceInterface
import SKCommon

class CommentCardImagesPreview: UIView, CommentCardImageItemViewProtocol {
    weak var delegate: CommentImagesEventProtocol?
    
    weak var cellDelegate: CommentTableViewCellDelegate?
    
    private let picAndPicGap: CGFloat = 4
    private let picTopGap: CGFloat = 10
    private let picBottomGap: CGFloat = 0
    private let containerLeftRightGap: CGFloat = 0
    private let maxCountInLine: Int = 3
    private let maxLines: Int = 3
    private let sendingNewLoadingViewHW: CGFloat = 14.0
    private var imageInfosArray: [CommentImageInfo] = []
    private var imageItemViews: [CommentCardImageItemView] = []
    private let containerView: UIView = UIView()
    private var isChangeLandscape: Bool {
        return DocsType.commentSupportLandscapaeFg &&
               !SKDisplay.pad &&
               UIApplication.shared.statusBarOrientation.isLandscape
    }
    
    private lazy var picBottomGapView: UIView = {
        let bottomGapview = UIView()
        containerView.addSubview(bottomGapview)
        bottomGapview.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(picBottomGap)
        }
        
        return bottomGapview
    }()
    
    // 记录最后一个imageView 和 index
    private var lastImageView: CommentCardImageItemView?
    private var lastIndex = 0
    
    private lazy var newLoadingView: CommentNewLoadingView = {
        let loadingView = CommentNewLoadingView()
        loadingView.isHidden = true
        loadingView.clipsToBounds = true
        containerView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.height.width.equalTo(sendingNewLoadingViewHW)
            make.bottom.left.equalToSuperview()
        }
        return loadingView
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(containerView)
        
        updateContainerViewConstraints(hidden: true)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }

    func updateContainerViewConstraints(hidden: Bool) {

        containerView.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(containerLeftRightGap)
            //+picAndPicGap为了方便等分布局，(itemViewWidth + picAndPicGap) * count
            make.right.equalToSuperview().offset(-containerLeftRightGap + picAndPicGap)
            make.top.bottom.equalToSuperview()
            if hidden {
                make.height.equalTo(0)
            } else {
                make.height.greaterThanOrEqualTo(0)
            }
        }
    }

    func getRowCounts(itemCount: Int) -> (allRows: Int, countPerRow: Int) {
        var allRows: Int = 0
        var countPerRow: Int = 0
        switch itemCount {
        case 0...3:
            allRows = 1
            countPerRow = itemCount
        case 4:
            allRows = 2
            countPerRow = 2
        case 5...6:
            allRows = 2
            countPerRow = 3
        case 7...9:
            allRows = 3
            countPerRow = 3
        default:
            allRows = 3
            countPerRow = 3
        }
        return (allRows, countPerRow)
    }

    func getCurrentRowInfo(countPerRow: Int, index: Int) -> (rowIndex: Int, numInRow: Int) {
        let numInRow = index % countPerRow
        let rowIndex = index / countPerRow
        return (rowIndex, numInRow)
    }

    func dequeueImageView(index: Int, itemCount: Int) -> CommentCardImageItemView {
        var imageItem: CommentCardImageItemView!
        if index < imageItemViews.count {
            imageItem = imageItemViews[index]
        } else {
            imageItem = CommentCardImageItemView(frame: .zero)
            imageItem.isUserInteractionEnabled = true
            imageItem.delegate = self
            containerView.addSubview(imageItem)
            imageItemViews.append(imageItem)
        }

        guard imageItem.superview != nil, itemCount > 0 else {
            spaceAssert(false, "要先addsubview, itemCount=\(itemCount)")
            return CommentCardImageItemView(frame: .zero)
        }

        let (allRows, countPerRow) = getRowCounts(itemCount: itemCount)
        let (rowIndex, numInRow) = getCurrentRowInfo(countPerRow: countPerRow, index: index)
        // 是否是最后一行
        let isLastRow: Bool = rowIndex == (allRows - 1)
        // 上边是否有item
        var upItem: CommentCardImageItemView?
        let upIndex = index - countPerRow
        if rowIndex > 0, upIndex >= 0 {
            upItem = imageItemViews[upIndex]
        }
        var leftItem: CommentCardImageItemView?
        if numInRow > 0 {
            leftItem = imageItemViews[index - 1]
        }

        imageItem.snp.remakeConstraints {(make) in
            if let upItem = upItem {
                make.top.equalTo(upItem.snp.bottom).offset(picAndPicGap)
            } else {
                make.top.equalToSuperview().offset(picTopGap)
            }

            if isLastRow {
                make.bottom.equalTo(picBottomGapView.snp.top)
            }

            // 横屏下，图片大小固定
            // 竖屏下，每张图片占评论气泡的1/3
            imageItem.portraitConstraint = make.width.height.equalTo(containerView.snp.width).multipliedBy(1.0 / CGFloat(maxCountInLine)).offset(-picAndPicGap).constraint
//            make.width.height.equalTo(containerView.snp.width).multipliedBy(1.0 / CGFloat(maxCountInLine)).offset(-picAndPicGap)
            imageItem.landscapeConstraint = make.width.height.equalTo(100).constraint

            if numInRow == 0 {
                make.leading.equalToSuperview()
            } else {
                if DocsType.commentSupportLandscapaeFg, let leftItem = leftItem {
                    make.leading.equalTo(leftItem.snp.trailing).offset(picAndPicGap)
                } else {
                    make.leading.equalTo(containerView.snp.trailing).multipliedBy(CGFloat(numInRow) / CGFloat(maxCountInLine))
                }
            }
        }
        if isChangeLandscape {
            imageItem.portraitConstraint?.deactivate()
            imageItem.landscapeConstraint?.activate()
        } else {
            imageItem.landscapeConstraint?.deactivate()
            imageItem.portraitConstraint?.activate()
        }
        return imageItem
    }
    
    func updateView(item: CommentItem?, imageInfos: [CommentImageInfo]) {
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
            newLoadingView.isHidden = true
            lastIndex = 0
            lastImageView = nil
            updateContainerViewConstraints(hidden: true)
            return
        }
        updateContainerViewConstraints(hidden: false)
        // 多余的imageView隐藏掉
        for (index, itemView) in imageItemViews.enumerated() {
            itemView.isHidden = (index >= imageInfosArray.count)
            itemView.snp.removeConstraints()
        }
        
        _old_internal_updateView(item: item, imageInfos: imageInfos)
    }
    
    private func _old_internal_updateView(item: CommentItem?, imageInfos: [CommentImageInfo]) {
        let previewState: CommentCardImageItemView.PreviewState
        if UserScopeNoChangeFG.CS.commentImageUseDocAttachmentPermission {
            let result = cellDelegate?.commentThumbnailImageSyncGetCanPreview()
            switch result {
            case .none:
                previewState = .requesting
            case .some(let value):
                previewState = value ? .enabled : .disabled
            }
        } else {
            let permission = item?.permission ?? []
            previewState = (permission.contains(.disableImgPreview) == false) ? .enabled : .disabled
        }
        
        for (index, info) in imageInfosArray.enumerated() {
            if index < maxLines * maxCountInLine {
                let imageView = dequeueImageView(index: index, itemCount: imageInfosArray.count)
                imageView.cellDelegate = cellDelegate
                imageView.updatePreviewState(previewState)
                imageView.updateImage(item: item, imageInfo: info) { [weak self] (res) in
                    if !res {
                        self?.delegate?.loadImagefailed(item: item, imageInfo: info)
                    }
                }
                // 记录最后一个imageView 和 index
                lastIndex = index
                lastImageView = imageView
            } else {
                DocsLogger.info("imageInfo count invalid，imageInfos.count=\(imageInfos.count)")
            }
        }
    }
    
    func showLoading(_ isLoading: Bool) {
        
        newLoadingView.snp.removeConstraints()
        if let imageView = lastImageView, isLoading == true {
            
            newLoadingView.isHidden = false
            newLoadingView.startPlay()
            
            //根据最后一个imageview的位置，设置loading的位置
            
            let (_, countPerRow) = getRowCounts(itemCount: imageInfosArray.count)
            var newRow = false
            //3张图一行的，计算loading是否需要换行显示
            //如果整除证明刚好3张图填满了最后一行
            if countPerRow == maxCountInLine, (lastIndex + 1) % countPerRow == 0 {
                newRow = true
            }
            
            if newRow {
                newLoadingView.snp.updateConstraints { make in
                    make.height.width.equalTo(sendingNewLoadingViewHW)
                    make.top.equalTo(imageView.snp.bottom).offset(picAndPicGap)
                    make.left.equalToSuperview()
                }
                picBottomGapView.snp.updateConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.height.equalTo((sendingNewLoadingViewHW + picAndPicGap + picBottomGap))
                }
                
            } else {
                newLoadingView.snp.updateConstraints { make in
                    make.height.width.equalTo(sendingNewLoadingViewHW)
                    make.bottom.equalTo(imageView.snp.bottom)
                    make.left.equalTo(imageView.snp.right).offset(picAndPicGap)
                }
                
                picBottomGapView.snp.updateConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.height.equalTo(picBottomGap)
                }
            }
            
        } else {
            //不显示loading
            newLoadingView.isHidden = true
            newLoadingView.endStop()
            
            newLoadingView.snp.updateConstraints { make in
                make.height.width.equalTo(0)
                make.left.top.equalTo(0)
            }
            
            picBottomGapView.snp.updateConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(picBottomGap)
            }
        }
        
    }

    func didClickPreviewImage(imageItemView: CommentCardImageItemView) {
        let indexTemp = imageItemViews.firstIndex(of: imageItemView)
        guard let index = indexTemp, index < imageInfosArray.count else {
            DocsLogger.info("点击preview，Error，imageItemViews.count=\(imageItemViews.count), imageInfos.count=\(imageInfosArray.count)")
            return
        }
        let imageinfo = imageInfosArray[index]
        self.delegate?.didClickPreviewImage(imageInfo: imageinfo)
    }
    
    @objc
    private func updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: Bool) {
        if isChangeLandscape {
            imageItemViews.forEach {
                $0.portraitConstraint?.deactivate()
                $0.landscapeConstraint?.activate()
            }
        } else {
            imageItemViews.forEach {
                $0.landscapeConstraint?.deactivate()
                $0.portraitConstraint?.activate()
            }
        }
    }
    
    @objc
    func statusBarOrientationChange() {
        guard DocsType.commentSupportLandscapaeFg else { return }
        let isChangeLandscape = !SKDisplay.pad && UIApplication.shared.statusBarOrientation.isLandscape
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
            self.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: isChangeLandscape)
        }
    }
}


protocol CommentCardImageItemViewProtocol: NSObjectProtocol {
    func didClickPreviewImage(imageItemView: CommentCardImageItemView)
}


// MARK: - CommentCardImageItemView
class CommentCardImageItemView: UIView {
    
    enum PreviewState {
        case requesting // 正在请求`预览`权限，展示loading
        case disabled // 阻止预览，展示占位图
        case enabled // 允许预览，正常走加载图片逻辑
    }
    
    // 预览状态, 优先级高于加载图片逻辑
    private var previewState: PreviewState = .enabled
    
    private var disposeBag: DisposeBag = DisposeBag()
    weak var delegate: CommentCardImageItemViewProtocol?
    
    weak var cellDelegate: CommentTableViewCellDelegate?
    
    private var imageView: UIImageView = UIImageView()
    lazy private var helper = CommentCardImageHelper()
    
    /// 竖屏下的约束
    var portraitConstraint: SnapKit.Constraint?
    
    /// 横屏下的约束
    var landscapeConstraint: SnapKit.Constraint?

    private lazy var loadingView: UIView = {
        let loadingView = CommentLoadingView(spinColor: .neutralGray)
        loadingView.udpate(backgroundColor: UDColor.N200, alphe: 1)
        loadingView.isHidden = true
        loadingView.layer.borderWidth = 0.5
        loadingView.layer.ud.setBorderColor(UIColor.ud.N300)
        return loadingView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        if UserScopeNoChangeFG.CS.commentImageUseDocAttachmentPermission {
            previewState = .requesting
        } else {
            previewState = .enabled
        }
        
        //图片
        self.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 4.0
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0.5
        imageView.layer.ud.setBorderColor(UIColor.ud.N300)
        imageView.isUserInteractionEnabled = true
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickPreviewImage))
        imageView.addGestureRecognizer(singleTapGesture)
        
        imageView.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    var imageInfo: CommentImageInfo?

    private func setImage(_ image: UIImage) {
        self._setImage(image)
        self.setLoadingViewHidden(true)
    }
    
    func updatePreviewState(_ state: PreviewState) {
        previewState = state
        isUserInteractionEnabled = (state == .enabled)
        switch state {
        case .requesting:
            setLoadingViewHidden(false)
        case .disabled:
            _setImage(UDEmptyType.noPreview.defaultImage())
        case .enabled:
            break
        }
    }
    
    func updateImage(item: CommentItem?, imageInfo: CommentImageInfo, updateResult: @escaping (Bool) -> Void) {
        self.imageInfo = imageInfo
        
        if let image = cellDelegate?.inquireImageCache(by: imageInfo) {
            setImage(image)
            self.imageInfo?.update(status: .success(.cache(image)))
//            DocsLogger.info("[comment image] found ImageCach", component: LogComponents.comment)
            return
        } else if let image = imageInfo.image {
            setImage(image)
            return
        }
        _setImage(nil)
        
        let imageToken = imageInfo.token?.encryptToken ?? ""
        let isFetching = (helper.currentImageInfo == imageInfo || helper.fetchingItem == imageInfo)
        if imageInfo.status == .loading, isFetching { // 1. 正在fetching中的图片不需要重复再调用
            self.setLoadingViewHidden(false)
        } else if imageInfo.status == .fail,
                  let error = item?.enumError,
                  error == .loadImageError { // 2. 处于可刷新状态下，失败的图片不需要fetch
            DocsLogger.info("[comment image] update ignore error image tk:\(imageToken))", component: LogComponents.comment)
            self._setImage(BundleResources.SKResource.Common.Comment.icon_comment_fail_img)
            self.setLoadingViewHidden(true)
        } else {
            fetchCacheImageOrNetworkImage(imageInfo: imageInfo, updateResult: updateResult)
        }

    }
    
    /// 将loadingView是否隐藏，收敛到这一个方法里
    private func setLoadingViewHidden(_ hidden: Bool) {
        switch previewState {
        case .requesting:
            self.loadingView.isHidden = false
        case .enabled, .disabled:
            self.loadingView.isHidden = hidden // 忽略掉
        }
        if loadingView.isHidden {
            imageView.backgroundColor = .clear
        } else {
            imageView.backgroundColor = UIColor.ud.N200
        }
    }

    func fetchCacheImageOrNetworkImage(imageInfo: CommentImageInfo, updateResult: @escaping (Bool) -> Void) {
        helper.fetchCacheImageOrNetworkImage(imageInfo: imageInfo) { [weak self] in
            guard let self = self else { return }
            // 未发现缓存，准备网络下载前
            self._setImage(nil)
            imageInfo.update(status: .loading)
            self.setLoadingViewHidden(false)
        } result: { [weak self] (result, info) in
            guard let self = self else { return }
            guard info == self.imageInfo else {
                if let r = result {
                    switch r {
                    case let .network(image),
                        let .cache(image):
                        self.cellDelegate?.didFinishFetchImage(image, cacheable: info)
                    }
                }
                return
            }
            self.setLoadingViewHidden(true)
            if let r = result { // 成功
                var img: UIImage?
                switch r {
                case let .network(image):
                    img = image
                    self.imageInfo?.update(status: .success(.network(image)))
                case let .cache(image):
                    img = image
                    self.imageInfo?.update(status: .success(.cache(image)))
                }
                if let image = img {
                    self.setImage(image)
                    self.cellDelegate?.didFinishFetchImage(image, cacheable: info)
                }
                updateResult(true)
            } else { // 失败
                self.imageInfo?.update(status: .fail)
                self.imageView.backgroundColor = .clear
                self._setImage(BundleResources.SKResource.Common.Comment.icon_comment_fail_img)
                updateResult(false)
            }
        }
    }
    

    @objc
    private func didClickPreviewImage() {
        self.delegate?.didClickPreviewImage(imageItemView: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func _setImage(_ image: UIImage?) {
        switch previewState {
        case .requesting, .enabled:
            imageView.image = image
        case .disabled:
            imageView.image = UDEmptyType.noPreview.defaultImage()
        }
    }
}

class CommentCardImageHelper {
    fileprivate var currentImageInfo: CommentImageInfo?
    fileprivate var fetchingItem: CommentImageInfo? // 网络请求时才会去设置
    private var hadRetryForThumbnail: Bool = false
    private var hadRetryForOrignal: Bool = false
    
    enum Result {
        case cache(UIImage)
        case network(UIImage)
    }
    
    func fetchCacheImageOrNetworkImage(imageInfo: CommentImageInfo, beginNetworkFetching: @escaping (() -> Void), result: @escaping (Result?, CommentImageInfo) -> Void) {
        if imageInfo != currentImageInfo {
            self.hadRetryForThumbnail = false
            self.hadRetryForOrignal = false
            self.fetchingItem = nil
        }
        currentImageInfo = imageInfo
        
        let setCacheImage: (CommentCardImageHelper?, UIImage, CommentImageInfo) -> Void = { [weak self](obj, image, info) in
            // UI复用+获取图片是异步，需要需要判断是否匹配，防止显示错误
            if info == obj?.currentImageInfo {
                result(.cache(image), info)
                // mark fetching cache end
                self?.currentImageInfo = nil
            }
        }
        let fetchNetworkImage: (CommentCardImageHelper?, CommentImageInfo) -> Void = { [weak self] (obj, info) in
            // UI复用+获取图片是异步，需要需要判断是否匹配，防止显示错误
            if info == obj?.currentImageInfo {
                beginNetworkFetching()
                // 尝试下载缩略图，再获取原图
                obj?.updateImageByFetch(orignal: false, result: { [weak self] image in
                    if let img = image {
                        result(.network(img), info)
                    } else {
                        result(nil, info)
                    }
                    // mark fetching net end
                    if self?.fetchingItem == info {
                        self?.fetchingItem = nil
                    }
                })
            }
        }
        
        let util = CommentFetchImageUtil.shared
        util.getCacheImage(imageInfo: imageInfo, useOriginalSrc: false, completion: { [weak self] (image1, info1) in // 尝试获取缩略图缓存
            if let image = image1 {
                setCacheImage(self, image, info1)
            } else if imageInfo.originalSrc != nil {
                // 尝试获取原图缓存
                util.getCacheImage(imageInfo: imageInfo, useOriginalSrc: true, completion: { [weak self] (image2, info2) in
                    if let image = image2 {
                        setCacheImage(self, image, info2)
                    } else {
                        let tk = info2.token?.encryptToken ?? ""
                        fetchNetworkImage(self, info2)
                    }
                })
            } else {
                fetchNetworkImage(self, info1)
            }
        })
    }

    func updateImageByFetch(orignal: Bool, result: @escaping (UIImage?) -> Void) {
        guard let imageInfo = currentImageInfo, imageInfo != fetchingItem else {
            return
        }
        fetchingItem = imageInfo
        let url = (orignal ? imageInfo.originalSrc : imageInfo.src) ?? imageInfo.src

        CommentFetchImageUtil.shared.fetchImage(urlStr: url, picToken: imageInfo.token) { [weak self] (urlStr, image, error) in
            guard let self = self else { return }
            self.fetchingItem = nil

            if urlStr == self.currentImageInfo?.src || urlStr == self.currentImageInfo?.originalSrc {
                if image == nil {
                    let encryptToken = self.currentImageInfo?.token?.encryptToken ?? ""
                    DocsLogger.error("updateImageByFetch orignal:\(orignal)，fail，token = \(encryptToken)，error=\(String(describing: error))", component: LogComponents.comment)
                }

                if image == nil, error == .docsRequestJsonErr {
                    if !self.hadRetryForThumbnail {
                        self.hadRetryForThumbnail = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) {
                            self.updateImageByFetch(orignal: false, result: result)
                        }
                    } else if !self.hadRetryForOrignal {
                        self.hadRetryForOrignal = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) {
                            self.updateImageByFetch(orignal: true, result: result)
                        }
                    } else {
                        result(image)
                    }
                } else {
                    result(image)
                }
            }
        }
    }
}
