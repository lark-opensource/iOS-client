//
//  TemplateBaseCell.swift
//  SKCommon
//
//  Created by bytedance on 2021/3/24.

import UIKit
import SKUIKit
import RxSwift
import RxCocoa
import SnapKit
import Kingfisher
import SKResource
import SKFoundation
import SkeletonView
import LarkTimeFormatUtils
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignEmpty
import SpaceInterface
import SKInfra
import LarkDocsIcon
import LarkContainer

protocol TemplateBaseCellDelegate: AnyObject {
    func didClickMoreButtonOfCell(cell: TemplateBaseCell)
}

class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer } // swiftlint:disable:this all
}
// swiftlint:disable type_body_length file_length
class TemplateBaseCell: UICollectionViewCell {
    struct BottomViewConfig {
        static let `default` = BottomViewConfig(
            style: .normal,
            typeIconSize: CGSize(width: 13, height: 13),
            titleFontSize: 11,
            descFontSize: 10,
            typeIconTopPadding: 8,
            subTitleTopPadding: 4,
            topColor: UIColor.ud.N50 & UIColor.docs.rgb("202020"),
            bottomColor: UDColor.bgBody & UIColor.docs.rgb("2E2E2E")
        )
        var style: Style
        var typeIconSize: CGSize
        var titleFontSize: CGFloat
        var descFontSize: CGFloat
        var typeIconTopPadding: CGFloat
        var subTitleTopPadding: CGFloat
        var topColor: UIColor
        var bottomColor: UIColor
        enum Style {
            case normal
            case onlyTitle
        }
    }
    struct ShadowConfig {
        let xOffset: CGFloat
        let yOffset: CGFloat
        let opacity: Float
        let shadowRadius: CGFloat
    }
    weak var delegate: TemplateBaseCellDelegate?
    
    var whiteBgViewHeight: CGFloat { 0 }// 子类根据实际情况return
    var whiteBgViewWidth: CGFloat { 0 } // 子类根据实际情况return
    var imageViewSize: CGSize = .zero
    var themeImageViewSize: CGSize = .zero
    var bottomContainerViewHeight: CGFloat { TemplateCellLayoutInfo.suggestBottomContainerHeight }
    var templateContentViewHieght: CGFloat = 0
    var bottomViewConfig: BottomViewConfig { return .default }
    var needPressButton: Bool { true }
    static let edgePadding: CGFloat = 4

    var loadingLinePaddingV: CGFloat { return 6 }
    var loadingViewTop: CGFloat { return 12 }
    let leftPadding: CGFloat = 10
    let typeImgViewPadding: CGFloat = 8
    var shadowConfig: ShadowConfig {
        ShadowConfig(xOffset: 0, yOffset: 4, opacity: 1, shadowRadius: 6)
    }
    
    private lazy var whiteBgView: UIView = UIView()
    private lazy var topColorView: UIView = UIView()
    private lazy var thumbImageViewContainer: UIView = {
        let container = UIView()
        container.addSubview(thumbImageView)
        thumbImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Self.edgePadding)
            make.left.equalToSuperview().offset(Self.edgePadding)
            make.right.equalToSuperview().offset(-Self.edgePadding)
            make.bottom.equalToSuperview().offset(-Self.edgePadding)
            make.height.equalTo(thumbImageView.snp.width).multipliedBy(91.0 / 156.0)
        }
        let mask = UIView()
        mask.backgroundColor = UDColor.fillImgMask
        container.addSubview(mask)
        mask.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return container
    }()
    private lazy var thumbImageView: UIImageView = UIImageView()
    // 这是运维同学配的image，虽然很久没有出现了，但还是写上兜底，万一哪天又配上了数据呢
    private lazy var themeImageView: UIImageView = {
        let imgView = UIImageView()
        let mask = UIView()
        imgView.contentMode = .scaleAspectFit
        mask.backgroundColor = UDColor.fillImgMask
        imgView.addSubview(mask)
        mask.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return imgView
    }()
    private lazy var failImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.addSubview(failTipLabel)
        failTipLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
        }
        return iv
    }()
    private lazy var failTipLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = UDColor.textPlaceholder
        lb.font = UIFont.systemFont(ofSize: 12)
        lb.numberOfLines = 0
        lb.textAlignment = .center
        return lb
    }()
    private lazy var tagImageView: UIImageView = UIImageView()
    private lazy var bottomView: GradientView = {
        let view = GradientView()
        switch bottomViewConfig.style {
        case .normal:
            view.addSubview(typeImgView)
            view.addSubview(titleLabel)
            view.addSubview(subTitleLabel)
            view.addSubview(moreButton)
            
            typeImgView.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(typeImgViewPadding)
                make.top.equalToSuperview().offset(bottomViewConfig.typeIconTopPadding)
                make.size.equalTo(bottomViewConfig.typeIconSize)
            }
            titleLabel.snp.makeConstraints { (make) in
                titleLabelAlignTypeImgView = make.left.equalTo(typeImgView.snp.left).constraint
                titleLabelAlignTypeImgView?.deactivate()
                titleLabelAfterTypeImgView = make.left.equalTo(typeImgView.snp.right).offset(4.5).constraint
                make.centerY.equalTo(typeImgView)
                make.right.equalToSuperview().offset(-typeImgViewPadding)
            }
            subTitleLabel.snp.makeConstraints { (make) in
                make.left.equalTo(typeImgView).offset(2)
                make.right.equalTo(moreButton.snp.left).offset(-5)
                make.top.equalTo(typeImgView.snp.bottom).offset(bottomViewConfig.subTitleTopPadding)
            }
            moreButton.snp.makeConstraints { (make) in
                make.right.equalToSuperview().offset(-5)
                make.centerY.equalTo(subTitleLabel)
                make.width.equalTo(14)
                make.height.equalTo(14)
            }
        case .onlyTitle:
            view.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(leftPadding)
                make.right.equalToSuperview().offset(-leftPadding)
                make.centerY.equalToSuperview()
            }
        }
        return view
    }()
    private lazy var typeImgView: UIImageView = UIImageView()
    private lazy var titleLabel: UILabel = UILabel()
    private lazy var subTitleLabel: UILabel = UILabel()
    private var titleLabelAlignTypeImgView: Constraint?
    private var titleLabelAfterTypeImgView: Constraint?
    // 右下角的三个点点击按钮
    lazy var moreButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .clear
        btn.setBackgroundImage(UDIcon.moreVerticalOutlined.ud.withTintColor(UDColor.iconN3), for: .normal)
        btn.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
        btn.hitTestEdgeInsets = UIEdgeInsets(horizontal: -18, vertical: -13)
        return btn
    }()
    private lazy var loadingView: TemplateLoadingView = TemplateLoadingView()
    private lazy var loadingContainerView = UIView()
    // 直接设置subviews的alpha会导致UI样式穿透，不好看，所以单独加一个view盖着
    private lazy var netStatusMaskView: UIView = {
        let mask = UIView()
        mask.isUserInteractionEnabled = false
        return mask
    }()
    private var reuseBag = DisposeBag()
    var cacheTag: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }
    
    private func setupUI() {
        addSubviews()
        setupSubviewsLayout()
        setupSubviewsStyle()
    }
    
    private func addSubviews() {
        contentView.addSubview(whiteBgView)
        whiteBgView.addSubview(themeImageView)
        whiteBgView.addSubview(thumbImageViewContainer)
        whiteBgView.addSubview(failImageView)
        whiteBgView.addSubview(topColorView)
        whiteBgView.addSubview(tagImageView)
        whiteBgView.addSubview(bottomView)
        whiteBgView.addSubview(loadingContainerView)
        loadingContainerView.addSubview(loadingView)
        whiteBgView.addSubview(netStatusMaskView)
        
        loadingView.addSKLineView(width: whiteBgViewWidth - (leftPadding + 2) * 2,
                                  paddingV: loadingLinePaddingV)
    }
    
    private func setupSubviewsLayout() {
        whiteBgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        topColorView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            let height = SKDisplay.pad ? 4 : 2
            make.height.equalTo(height)
        }
        thumbImageViewContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topColorView.snp.bottom)
        }
        themeImageView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top)
        }
        failImageView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top)
        }
        tagImageView.snp.makeConstraints { (make) in
            make.right.top.equalToSuperview()
            make.width.equalTo(37)
            make.height.equalTo(14)
        }
        bottomView.snp.makeConstraints { (make) in
            make.top.equalTo(thumbImageViewContainer.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }
        loadingContainerView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top)
        }
        loadingView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(loadingViewTop)
            make.left.equalToSuperview().offset(12)
            make.right.bottom.equalToSuperview().offset(-12)
        }
        netStatusMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupSubviewsStyle() {
        contentView.backgroundColor = UDColor.bgBody
        contentView.layer.ud.setShadowColor(UDColor.shadowDefaultMd)
        contentView.layer.shadowOpacity = shadowConfig.opacity
        contentView.layer.shadowOffset = CGSize(width: shadowConfig.xOffset, height: shadowConfig.yOffset)
        contentView.layer.shadowRadius = shadowConfig.shadowRadius
        contentView.layer.cornerRadius = 6

        whiteBgView.layer.cornerRadius = 6
        whiteBgView.layer.masksToBounds = true // 为了把topColorView切掉
        whiteBgView.backgroundColor = UDColor.primaryOnPrimaryFill
                
        thumbImageView.backgroundColor = UDColor.primaryOnPrimaryFill
        themeImageView.backgroundColor = UDColor.primaryOnPrimaryFill
        failImageView.backgroundColor = UDColor.bgFloat
        // https://www.figma.com/file/JlNdCX48LqbxIZq0tAHijs/🌚🌚🌚-CCM-Dark-Mode?node-id=83%3A30919 设计师要求此次特殊处理
        bottomView.gradientLayer.ud.setColors([bottomViewConfig.topColor, bottomViewConfig.bottomColor])
        bottomView.gradientLayer.locations = [0, 0.5]
        
        titleLabel.font = UIFont.systemFont(ofSize: bottomViewConfig.titleFontSize, weight: .medium)
        subTitleLabel.font = UIFont.systemFont(ofSize: bottomViewConfig.descFontSize)
        subTitleLabel.textColor = UDColor.textCaption
        
        loadingContainerView.backgroundColor = UDColor.bgFloat
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.shadowPath = UIBezierPath(rect: contentView.bounds).cgPath
    }
    
    func configCell(with template: TemplateModel, hostViewWidth: CGFloat, mainTabType: TemplateMainType? = nil) {

        let isThemeAvailable = template.isThemeAvailable
        topColorView.isHidden = isThemeAvailable || template.type == .collection
        topColorView.backgroundColor = getTypeColor(for: template.docsType)
        thumbImageView.isHidden = isThemeAvailable
        themeImageView.isHidden = !isThemeAvailable
        themeImageView.image = nil
        thumbImageView.image = nil
        tagImageView.image = nil

        
        // 设置运营标签
        if let labelUrl = template.opLabelUrlV2, !labelUrl.isEmpty, let tagUrl = URL(string: labelUrl) {
            let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)!
            // 后台的同学将运营标签图片存放在drive平台了，所以url跟drive图片的类似，因此也用缩略图下载接口，同时还能带cookie
            manager.getThumbnail(url: tagUrl, source: .template)
                .asDriver(onErrorJustReturn: UIImage())
                .drive(onNext: { [weak self] (image) in
                    self?.tagImageView.image = image
                })
                .disposed(by: reuseBag)
        }
        
        resetBottomDetailViews(template: template, mainTabType: mainTabType)
        setupThumbnail(template: template, hostViewWidth: hostViewWidth)
    }
        
    private func setupThumbnail(template: TemplateModel, hostViewWidth: CGFloat) {
        if thumbImageView.image == nil, themeImageView.image == nil {
            resetLoadingView(isHidden: false)
        }
        
        var spImageInsets = UIEdgeInsets(top: 5, left: 4, bottom: 5, right: 4)
        let cellSize = TemplateCellLayoutInfo.inCenter(with: hostViewWidth)
        imageViewSize = CGSize(width: cellSize.width, height: cellSize.height - bottomContainerViewHeight)
        var thumbnailUrl: URL?
        var imageSize: CGSize = imageViewSize
        var isUseEncrypt: Bool = false
        
        switch template.imageDisplayType {
        case .themeCover:
            if let url = template.coverDownloadUrl, !url.isEmpty, let thumbUrl = URL(string: url) {
                thumbnailUrl = thumbUrl
                spImageInsets = UIEdgeInsets(top: 10, left: 4, bottom: 10, right: 4)
            }
        case .thumbnail:
            if let thumbnailInfo = template.thumbnailExtra, thumbnailInfo.isAvailable {
                isUseEncrypt = true
            }
        case  .manuSettedThumbnail:
            if let url = template.coverDownloadUrl, !url.isEmpty, let thumbUrl = URL(string: url) {
                thumbnailUrl = thumbUrl
            }
        }

        if thumbnailUrl == nil {
            thumbnailUrl = getSaverUrl(for: template)
        }

        downloadThumbnail(url: thumbnailUrl,
                          template: template,
                          isUseEncrypt: isUseEncrypt,
                          imageSize: imageSize,
                          spImageInsets: spImageInsets)
    }
    
    private func getTypeColor(for type: DocsType) -> UIColor {
        switch type {
        case .doc, .docX:
            return UIColor.ud.B300
        case .sheet:
            return UIColor.ud.G300
        case .mindnote:
            return UIColor.ud.W300
        case .bitable:
            return UIColor.ud.P300
        default:
            return UIColor.ud.B300
        }
    }
    
    private func getSaverUrl(for template: TemplateModel) -> URL? {
        guard let thumbnailURL = URL(string: template.coverUrl) else {
            showFailImage(template: template)
            resetLoadingView(isHidden: true)
            DocsLogger.error("Failed to get thumbnail for template, url is invalid")
            return nil
        }
        return thumbnailURL
    }

    private func downloadThumbnail(url: URL? = nil,
                                   template: TemplateModel,
                                   isUseEncrypt: Bool,
                                   imageSize: CGSize,
                                   spImageInsets: UIEdgeInsets) {

        let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)!
        let resizeInfo = SpaceThumbnailProcesserResizeInfo(targetSize: imageSize,
                                                           imageInsets: spImageInsets)
        let imageProcesser = SpaceTemplateProcesserV2(resizeInfo: resizeInfo,
                                                      imageTargetSize: imageSize,
                                                      isNeedScaleImage: true,
                                                      docsType: template.docsType)
        self.resetLoadingView(isHidden: false)
        if isUseEncrypt {
            manager.getThumbnailV41(templateModel: template,
                                    processer: imageProcesser)
                .retry(2) // If you encounter an error and want it to retry once, then you must use `retry(2)`
                .observeOn(MainScheduler.instance)
                .subscribe({ [weak self] (event) in
                    self?.resetLoadingView(isHidden: true)
                    switch event {
                    case .next(let image):
                        self?.setImage(image, template: template)
                    case .error(let err):
                        DocsLogger.error("\(err)")
                        self?.showFailImage(template: template)
                    default: break
                    }
                })
                .disposed(by: reuseBag)
        } else if let thumbUrl = url {

            manager.getThumbnail(url: thumbUrl, source: .template, processer: imageProcesser, cacheTag: cacheTag)
                .retry(2)
                .observeOn(MainScheduler.instance)
                .subscribe({ [weak self] (event) in
                    self?.resetLoadingView(isHidden: true)
                    switch event {
                    case .next(let image):
                        self?.setImage(image, template: template)
                    case .error(let err):
                        DocsLogger.error("\(err)")
                        self?.showFailImage(template: template)
                    default: break
                    }
                })
                .disposed(by: reuseBag)
        } else {
            spaceAssertionFailure("走到这里时，url 不能为nil")
        }
    }

    private func setImage(_ image: UIImage, template: TemplateModel) {
        failImageView.isHidden = true
        themeImageView.isHidden = !template.isThemeAvailable
        thumbImageView.isHidden = template.isThemeAvailable
        if template.isThemeAvailable {
            themeImageView.image = image
        } else {
            thumbImageView.image = image
        }
    }
    private func showFailImage(template: TemplateModel) {
        failImageView.isHidden = false
        failTipLabel.isHidden = false
        themeImageView.isHidden = true
        thumbImageView.isHidden = true
        var image: UIImage?
        var tipText: String?
        if template.hasShowThumbnailPermission {
            image = UDEmptyType.loadingFailure.defaultImage()
        } else {
            tipText = BundleI18n.SKResource.CreationMobile_Docs_UnableToPreview_SecurityReason_placeholder
        }
        failImageView.image = image
        failTipLabel.text = tipText
    }
    
    private func formateUseCountDesc(_ useCount: Int) -> String {
        if DocsSDK.currentLanguage == .zh_CN || DocsSDK.currentLanguage == .ja_JP {
            if useCount < 10000 {
                return BundleI18n.SKResource.Doc_List_TemplateUseNUmber("\(useCount)")
            } else {
                return BundleI18n.SKResource.LarkCCM_Template_Usedby10kPeople(String(format: "%.1f", Float(useCount) / 10000.0))
            }
        } else {
            if useCount < 1000 {
                return BundleI18n.SKResource.Doc_List_TemplateUseNUmber("\(useCount)")
            } else {
                return BundleI18n.SKResource.LarkCCM_Template_Usedby10kPeople(String(format: "%.1f", Float(useCount) / 1000.0))
            }
        }
    }
    
    private func resetBottomDetailViews(template: TemplateModel, mainTabType: TemplateMainType?) {
        titleLabel.text = template.displayTitle
        guard bottomViewConfig.style == .normal else {
            return
        }
        if let type = template.type, type == .collection {
            typeImgView.image = nil
            titleLabelAfterTypeImgView?.deactivate()
            titleLabelAlignTypeImgView?.activate()
        } else {
            if template.shouldUseNewForm() {
                typeImgView.di.clearDocsImage()
                typeImgView.image = UDIcon.fileFormColorful
            } else {
                typeImgView.di.setDocsImage(iconInfo: template.icon ?? "",
                                            token: template.objToken,
                                            type: DocsType(rawValue: template.objType),
                                            shape: .SQUARE,
                                            userResolver: Container.shared.getCurrentUserResolver())
            }
            titleLabelAlignTypeImgView?.deactivate()
            titleLabelAfterTypeImgView?.activate()
        }
        var finalStr: String = ""
        switch template.bottomLabelShowType {
        case .systemRecommend(let heat):
            let descStr = formateUseCountDesc(heat)
            if let author = template.author, !author.isEmpty {
                let prefix = BundleI18n.SKResource.CreationMobile_Template_ShowAuthor(author)
                finalStr += prefix + "  |  "
            }
            finalStr += descStr
        case .createAt(let createTime):
            let timeStr = timeString(with: createTime)
            finalStr = BundleI18n.SKResource.Doc_List_template_custom_created_by_me_v2(timeStr)
        case .shared(let name):

            if !name.isEmpty {
                finalStr = BundleI18n.SKResource.Doc_List_template_custom_shared_by_v2(name)
            } else {
                finalStr = BundleI18n.SKResource.Doc_List_template_shared_by_failed
            }
        case .useAt(let useTime):
            let timeStr = timeString(with: useTime)
            finalStr = BundleI18n.SKResource.CreationMobile_Template_RecentlyUsedTime(timeStr)
        case .updateAt(let updateTime):
            let timeStr = timeString(with: updateTime)
            finalStr = BundleI18n.SKResource.CreationMobile_Operation_CreatedonSomeTime(timeStr)
        case .hidden:
            finalStr = ""
        }
        
        subTitleLabel.text = finalStr
        let isHiddenMore = mainTabType != .custom || template.templateMainType != .custom
        moreButton.isHidden = isHiddenMore
        
        if subTitleLabel.text?.isEmpty ?? false {
            subTitleLabel.isHidden = true
            typeImgView.snp.remakeConstraints() { (make) in
                make.left.equalToSuperview().offset(typeImgViewPadding)
                make.centerY.equalToSuperview()
                make.size.equalTo(bottomViewConfig.typeIconSize)
            }
        } else {
            subTitleLabel.isHidden = false
            typeImgView.snp.remakeConstraints() { (make) in
                make.left.equalToSuperview().offset(typeImgViewPadding)
                make.top.equalToSuperview().offset(bottomViewConfig.typeIconTopPadding)
                make.size.equalTo(bottomViewConfig.typeIconSize)
            }
        }
        bottomView.layoutIfNeeded()
    }
    
    private func timeString(with timeIntervalSince1970: Double) -> String {
        guard timeIntervalSince1970 > 0 else {
            return ""
        }
        if Calendar.current.isDateInYear(Date(timeIntervalSince1970: timeIntervalSince1970)) {
            return timeIntervalSince1970.shortDate(timeFormatType: .short)
        } else {
            return timeIntervalSince1970.shortDate(timeFormatType: .long)
        }
    }

    private func resetLoadingView(isHidden: Bool) {
        loadingContainerView.isHidden = isHidden
        loadingView.setSKAnimateStart(!isHidden)
    }

    func resetNetStatus(isreachable: Bool) {
        netStatusMaskView.backgroundColor = isreachable ? .clear : UDColor.bgBody.withAlphaComponent(0.4)
    }
    
    @objc
    func moreButtonAction() {
        delegate?.didClickMoreButtonOfCell(cell: self)
    }

}

extension TemplateCenterCell {
    static func getCell(
        _ collectionView: UICollectionView,
        indexPath: IndexPath,
        template: TemplateModel,
        delegate: TemplateBaseCellDelegate?,
        hostViewWidth: CGFloat,
        mainTabType: TemplateMainType? = nil
    ) -> UICollectionViewCell {
        if template.style == .emptyData {
            return getNoFilterTypeCell(collectionView: collectionView, indexPath: indexPath, template: template, mainTabType: mainTabType)
        } else if template.style == .createBlankDocs {
            return getCreateBlankDocsTypeCell(collectionView: collectionView, indexPath: indexPath, template: template)
        }
        let cellReuse = collectionView.dequeueReusableCell(withReuseIdentifier: TemplateCenterCell.reuseIdentifier, for: indexPath)
        guard let cell = cellReuse as? TemplateCenterCell else {
            return cellReuse
        }
        cell.configCell(with: template, hostViewWidth: hostViewWidth, mainTabType: mainTabType)
        cell.delegate = delegate
        cell.resetNetStatus(isreachable: DocsNetStateMonitor.shared.isReachable)
        TemplateCenterTracker.reportShowSingleTemplateTracker(template)
        return cell
    }
    
    static func getNoFilterTypeCell(collectionView: UICollectionView, indexPath: IndexPath, template: TemplateModel, mainTabType: TemplateMainType? = nil) -> UICollectionViewCell {

        guard let noFilteredCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TemplateEmptyDataCell.cellID,
            for: indexPath
        ) as? TemplateEmptyDataCell else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell", for: indexPath)
        }
        if mainTabType == .custom, template.tag == .customShare {
            noFilteredCell.update(emptyType: .share)
        } else {
            noFilteredCell.update(emptyType: .default)
        }
        noFilteredCell.isUserInteractionEnabled = false
        return noFilteredCell
    }
    
    static func getCreateBlankDocsTypeCell(collectionView: UICollectionView, indexPath: IndexPath, template: TemplateModel) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TemplateCreateBlankDocsCell.cellID,
            for: indexPath
        ) as? TemplateCreateBlankDocsCell else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell", for: indexPath)
        }
        switch template.docsType {
        case .doc, .docX: cell.label.text = BundleI18n.SKResource.CreationMobile_Template_Doc_Blanklabel
        case .sheet: cell.label.text = BundleI18n.SKResource.CreationMobile_Template_Sheet_Blanklabel
        case .bitable: cell.label.text = BundleI18n.SKResource.CreationMobile_Template_Bitable_Blanklabel
        case .mindnote: cell.label.text = BundleI18n.SKResource.CreationMobile_Template_Mindnote_Blanklabel
        default:
            spaceAssertionFailure("未支持的类型")
        }
        if template.shouldUseNewForm() {
            cell.label.text = BundleI18n.SKResource.Bitable_NewSurvey_Template_CreateNewForm
        }
        let disable = !DocsNetStateMonitor.shared.isReachable && (template.docsType != .doc && template.docsType != .sheet && template.docsType != .mindnote)
        cell.disable = disable
        return cell
    }
}
