//
//  UniversalCardLynxImageView.swift
//  LarkLynxKit
//
//  Created by bytedance on 2022/11/2.
//

import Foundation
import Lynx
import LKCommonsLogging
import ByteWebImage
import LarkModel
import RustPB
import ByteDanceKit
import UniverseDesignIcon
import EENavigator
import LarkNavigator
import LarkContainer
import LarkSetting
import UniversalCardInterface
import UniverseDesignEmpty
import UniverseDesignColor


private final class UniversalCardImageView: ByteImageView {
    public override var clipsToBounds: Bool {
        didSet { if clipsToBounds == false { clipsToBounds = true } }
    }
}

fileprivate enum ImageLoadingStyle: String {
    case laser = "laser"
}

public final class UniversalCardLynxImageView: LynxUIView {
    
    public static let name: String = "msg-card-image"
    
    static let logger = Logger.log(UniversalCardLynxImageView.self, category: "UniversalCardLynxImageView")
    
    private lazy var viewModel: UniversalCardLynxImageViewModel = {
        return UniversalCardLynxImageViewModel()
    }()
    
    var disableTap: Bool = false
    
    lazy var singleTapGesture = UITapGestureRecognizer(target: self, action:  #selector(clickPreviewImage))

    lazy private var imageView: ByteImageView = {
        var imageView: UniversalCardImageView = UniversalCardImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.addGestureRecognizer(singleTapGesture)
        return imageView
    }()

    lazy private var longImageLabel: UILabel = {
        let longImageLabel = UILabel()
        let text = BundleI18n.UniversalCardBase.Lark_Legacy_MsgCard_LongImgTag
        longImageLabel.text = text
        longImageLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        longImageLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        longImageLabel.textAlignment = .center
        longImageLabel.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.5)
        return longImageLabel
    }()

    lazy private var loadFaildView: UIImageView = {
        let loadFaildView = UIImageView()
        loadFaildView.contentMode = .center
        loadFaildView.image = UDIcon.getIconByKey(.loadfailFilled, iconColor: UDColor.iconDisabled, size: CGSize(width: 35, height: 35))
        return loadFaildView
    }()

    var loadingStyle: String?

    // 将属性和相应的设置属性函数关联
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["props", NSStringFromSelector(#selector(setProps))]
        ]
    }
    
    @objc
    public override func createView() -> UIImageView? {
        return self.imageView
    }
    
    @objc func clickPreviewImage() {
        Self.logger.info("UniversalCardLynxImageView: imageView click")
        guard let cardContext = self.viewModel.cardContext else {
            Self.logger.error("UniversalCardLynxImageView clickPreviewImage fail: cardContext is nil")
            return
        }
        guard let actionService = cardContext.dependency?.actionService,
              let sourceVC = cardContext.sourceVC,
              var images = cardContext.sourceData?.cardContent.attachment.images else {
            Self.logger.error("UniversalCardLynxImageView clickPreviewImage fail: required params is nil, dependency \(cardContext.dependency == nil), sourceData: \(String(describing: cardContext.sourceData)), sourceVC: \(String(describing: cardContext.sourceVC))")
              return
        }
        guard let clickedKey = self.viewModel.imageProperty?.originKey else {
            Self.logger.error("UniversalCardLynxImageView clickPreviewImage fail: originKey is nil, ")
            return
        }
        var result: [String: Basic_V1_RichTextElement.ImageProperty] = [:]
        self.viewModel.previewImageKeys?.forEach { key in
            if let value = images[key] {
                result[key] = value
            }
        }
        images = result
        let properties = images.map { $0.value }
        let index = properties.firstIndex { $0.originKey == clickedKey } ?? 0
        //TODO: UniversalCard 添加 tag 和 id 相关信息
        let actionContext = UniversalCardActionContext(
            trace: cardContext.renderingTrace?.subTrace() ?? cardContext.trace.subTrace()
        )
        actionService.showImagePreview(context: actionContext, properties: properties, index: index, from: sourceVC)
    }
    
    @objc func setProps(props: Any?, requestReset _: Bool) {
        self.viewModel.cleanImageData()
        guard let props = props as? [AnyHashable: Any] else { return }

        //根据组件的需要动态绑定禁用点击事件
        self.disableTap = props["disableTap"] as? Bool ?? false
        //数据更新后，无需展示裂图
        self.setLoadFailedIfNeed(false)
        //myai定制在loading时展示laser背景色
        self.loadingStyle = props["loadingStyle"] as? String

        var previewImageKeys: [String] = []
        if let previewArray = props["previewImages"] as? Array<Any> {
            for previewKey in previewArray {
                if let imageKey = previewKey as? String {
                    previewImageKeys.append(imageKey)
                }
            }
        }
        self.viewModel.previewImageKeys = previewImageKeys
        self.viewModel.cardContext = self.getCardContext()

        if let cropType = props["crop_type"] as? String {
            switch cropType {
            case "crop_center":
                self.imageView.contentMode = .scaleAspectFill
            case "stretch":
                self.viewModel.imageShowMode = .stretch
            case "left_top":
                self.imageView.contentMode = .topLeft
            default:
                break
            }
        }

        if let isTranslateElement = props["isTranslateElement"] as? Bool {
            Self.logger.info("UniversalCardLynxImageView: set isTranslateElement:\(isTranslateElement)")
            self.viewModel.isTranslateElement = isTranslateElement
        }

        if let imageId = props["image_id"] as? String {
            Self.logger.info("UniversalCardLynxImageView: set imageId:\(imageId)")
            self.viewModel.imageId = imageId
        }

        if let forcePreview = props["forcePreview"] as? Bool {
            self.viewModel.forcePreview = forcePreview
        }

        if let preview = props["preview"] as? Bool {
            self.viewModel.preview = preview
        }

        if let disableLongImageTag = props["disableLongImageTag"] as? Bool {
            self.viewModel.disableLongImageTag = disableLongImageTag
        }

        if let resId = props["res_id"] as? String, let image = BundleResources.UniversalCardBase.iconbyName(iconName: resId) {
            Self.logger.info("UniversalCardLynxImageView: imageView set local image:\(resId)")
            self.imageView.image = image
            if var tintColorStr = props["tint_color"] as? String, !tintColorStr.isEmpty {
                self.imageView.tintColor = UIColor.btd_color(withARGBHexString: tintColorStr)
                self.imageView.image = self.imageView.image?.withRenderingMode(.alwaysTemplate)
            }
            return
        }

        if let resId = props["res_id"] as? String, let udIcon = fetchUDIcon(resId: resId) {
            Self.logger.info("UniversalCardLynxImageView: imageView set UDIcon:\(resId)")
            self.imageView.image = udIcon
            if var tintColorStr = props["tint_color"] as? String, !tintColorStr.isEmpty {
                self.imageView.tintColor = UIColor.btd_color(withARGBHexString: tintColorStr)
                self.imageView.image = self.imageView.image?.withRenderingMode(.alwaysTemplate)
            }
            return
        }
        self.viewModel.calculateData()
        self.updateImageView()
    }
    //图片裁剪
    private func cropImage() -> UIImage? {
        guard let image = self.imageView.image else {
            return nil
        }
        let viewAspectRatio = self.imageView.bounds.width / self.imageView.bounds.height
        let imageAspectRatio = image.size.width / image.size.height
        // 若容器宽高比小于图片宽高比, 则顶部裁剪使用居中裁剪模式
        if viewAspectRatio < imageAspectRatio {
            self.imageView.contentMode = .scaleAspectFill
            return image
        }
        let imageCropHeight = image.size.width / viewAspectRatio
        return UniversalCardImageUtils.cropImage(image: image, imageCropHeight: imageCropHeight)
   }
    
    private func fetchUDIcon(resId: String) -> UIImage? {
        switch resId {
        case "icon_loading_outlined":
            return UDIcon.getIconByKey(.loadingOutlined)
        case "ud_icon_calendar_outlined":
            return UDIcon.getIconByKey(.calendarLineOutlined)
        case "ud_icon_time_outlined":
            return UDIcon.getIconByKey(.timeOutlined)
        case "ud_icon_more_outlined":
            return UDIcon.getIconByKey(.moreOutlined)
        case "ud_icon_loading_outlined":
            return UDIcon.getIconByKey(.loadingOutlined)
        case "ud_icon_down_outlined":
            return UDIcon.getIconByKey(.downOutlined)
        case "illustration_empty_neutral_404":
            return UDEmptyType.code404.defaultImage()
        case "icon_up_bold_outlined":
            return UDIcon.getIconByKey(.upBoldOutlined)
        case "icon_down_bold_outlined", "ud_icon_down_bold_outlined":
            return UDIcon.getIconByKey(.downBoldOutlined)
        case "illustration_empty_neutral_to_be_upgraded":
            return EmptyBundleResources.image(named: "emptyNeutralToBeUpgraded")
        default:
            return nil
        }
    }

    
    public override func frameDidChange() {
        super.frameDidChange()
        self.updateImageView()
    }
    
    private func updateImageView() {
        guard let imageProperty: RustPB.Basic_V1_RichTextElement.ImageProperty = viewModel.imageProperty else {
            return
        }
        guard self.frame.width != 0, self.frame.height != 0 else {
            Self.logger.info("UniversalCardLynxImageView: frame is sizezero")
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                Self.logger.info("UniversalCardLynxImageView: updateImageView self is nil")
                return
            }
            setLoadingBackground()
            self.imageView.isUserInteractionEnabled = (self.viewModel.forcePreview || self.viewModel.preview) && (!self.disableTap)
            self.addLongImageLabelIfNeeded()

            let imageStr = (self.viewModel.imageToken != nil) ? self.viewModel.imageToken : self.viewModel.imageUrl
            guard let imageStr = imageStr else {
                return
            }
            Self.logger.info("UniversalCardLynxImageView: imageView imageStr:\(imageStr)")
            self.imageView.bt.setLarkImage(with: .default(key: imageStr), size: self.frame.size, completion:  {[weak self] (result) in
                guard let self = self else {
                    Self.logger.info("UniversalCardLynxImageView: bt.setLarkImage self is nil")
                    return
                }
                self.imageView.backgroundColor = nil
                switch result {
                case .success(_):
                    if self.viewModel.imageShowMode == .stretch {
                        self.imageView.image = self.cropImage()
                    }
                case .failure(let error):
                    setLoadFailedIfNeed(true)
                    Self.logger.error("UniversalCardLynxImageView: imageView set image fail,error:\(error)")
                }
            })

        }
    }

   private func addLongImageLabelIfNeeded() {
       if viewModel.isLongImage == true {
           Self.logger.info("UniversalCardLynxImageView: add longImage tab")
           imageView.addSubview(longImageLabel)
           let text = BundleI18n.UniversalCardBase.Lark_Legacy_MsgCard_LongImgTag
           let height = text.getHeight(font: UIFont.systemFont(ofSize: 10.0, weight: .medium)) + 4
           longImageLabel.snp.makeConstraints { make in
               make.left.bottom.right.equalToSuperview()
               make.height.equalTo(height)
           }
       } else {
            Self.logger.info("UniversalCardLynxImageView: remove longImage tab, self:\(self), imageId:\(self.viewModel.imageId)")
           if longImageLabel.superview != nil { longImageLabel.removeFromSuperview() }
       }
    }

     private func setLoadFailedIfNeed(_ need: Bool) {
        if need {
            self.imageView.addSubview(loadFaildView)
            loadFaildView.snp.makeConstraints { make in
                make.left.bottom.right.top.equalToSuperview()
            }
        } else {
            loadFaildView.removeFromSuperview()
        }
    }

    private func setLoadingBackground() {
        if self.loadingStyle == ImageLoadingStyle.laser.rawValue {
            self.imageView.backgroundColor = UDColor.AIPrimaryFillSolid01(ofSize: self.frameSize)
        } else {
            let colors = [UIColor.ud.color(31, 35, 41, 0.08), UIColor.ud.color(31, 35, 41, 0.05)]
            self.imageView.backgroundColor = UIColor.fromGradientWithDirection(.bottomToTop, frame: self.frame, colors: colors, cornerRadius: 0, locations: nil)
        }
    }
}

public final class UniversalCardLynxImageViewShadowNode: LynxShadowNode, LynxCustomMeasureDelegate {
    
    public static let name: String = "msg-card-image"
    private static let logger = Logger.log(UniversalCardLynxImageViewShadowNode.self, category: "UniversalCardLynxImageViewShadowNode")
    var contentSize: CGSize?

    // 重载构造函数
    override init(sign: Int, tagName: String) {
        super.init(sign: sign, tagName: tagName)
        customMeasureDelegate = self
    }

    @objc public static func propSetterLookUp() -> [[String]] {
        return [
            ["props", NSStringFromSelector(#selector(setProps))]
        ]
    }
    
    public func measure(with param: MeasureParam, measureContext context: MeasureContext?) -> MeasureResult {
        let (width, widthMode, height, heightMode ) = (param.width, param.widthMode, param.height, param.heightMode)
        let originSize: CGSize = CGSize(width: width, height: height)
        return MeasureResult(size: contentSize ?? originSize, baseline: 0)
    }
    
    public func align(with param: AlignParam, alignContext context: AlignContext) {
        
    }

    // 实现属性响应，响应的属性为 content，方法名称为 setContent，通过 setNeedsLayout() 触发排版。
    @objc private func setProps(props: Any?, requestReset _: Bool) {
        guard let props = props as? [String: Any] else {
            assertionFailure("UniversalCardLynxImageViewShadowNode receive wrong props type: \(String(describing: props.self))")
            Self.logger.error("UniversalCardLynxImageViewShadowNode receive wrong props type: \(String(describing: props.self))")
            return
        }
        if let originWidth = props["originWidth"] as? Double,
           let originHeight = props["originHeight"] as? Double {
            self.contentSize = CGSize(width: originWidth, height: originHeight)
        }
        setNeedsLayout()
    }
    
}

