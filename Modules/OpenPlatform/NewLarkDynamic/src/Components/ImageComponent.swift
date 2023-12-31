//
//  LDImageComponent.swift
//  NewLarkDynamic
//
//  Created by Jiayun Huang on 2019/6/23.
//

import Foundation
import AsyncComponent
import LarkModel
import LarkFeatureGating
import ByteWebImage
import UniverseDesignTheme
import UniverseDesignColor

final class ImageComponentFactory: ComponentFactory {
    override var tag: RichTextElement.Tag {
        return .img
    }

    override func parseStyle(style: [String: String], context: LDContext?, elementId: String? = nil) -> LDStyle {
        let ldStyle = super.parseStyle(style: style, context: context, elementId: elementId)
        detailLog.info("Image Component style \(style) set ldstyle \(ldStyle.styleValues)")
        return ldStyle
    }

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
        detailLog.info("Create Image Component style.aspectRatio \(style.aspectRatio) elementSyle \(element.style)")
        let props = LDImageComponentProps()
        props.imageProperty = element.property.image
        let component =  LDImageComponent<C>(props: props, style: style, context: context)
        component.tryAddLongImageLabel()
        return component
    }
}

class LDImageView: ByteImageView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.animateRunLoopMode = .default
        self.layer.addSublayer(imageMaskView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var imageMaskView: CALayer = {
        let mask = CALayer()
        mask.anchorPoint = CGPoint(x: 0, y: 0)
        mask.position = CGPoint(x: 0, y: 0)
        mask.frame = self.bounds
        return mask
    }()

    var isRotaing: Bool = false {
        didSet {
            if isRotaing {
                layer.add({ () -> CABasicAnimation in
                    let rotate = CABasicAnimation(keyPath: "transform.rotation")
                    rotate.fromValue = 0
                    rotate.toValue = Double.pi * 2
                    rotate.duration = 1
                    rotate.repeatCount = .greatestFiniteMagnitude
                    return rotate
                }(), forKey: "rotate")
            } else {
                layer.removeAnimation(forKey: "rotate")
            }
        }
    }

    fileprivate var tapCallback: ((LDImageView) -> Void)?

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.tapCallback?(self)
    }
}

class LDImageComponentProps: ASComponentProps {
    var contentMode: UIView.ContentMode = .scaleAspectFill
    var clipsToBounds: Bool = true
    var imageProperty: RichTextElement.ImageProperty?
    var isLongImage: Bool = false
}

class LDImageComponent<C: LDContext>: LDComponent<LDImageComponentProps, LDImageView, C> {

    enum ImageShowMode: Int {
        case cropCenter = 0
        case stretch = 1
    }

    private let stretchImageAspectRatioLimit = CGFloat(9) / 16

    override func render() -> BaseVirtualNode {
        let node = super.render()
        detailLog.info("render Image node style \(style.height) \(style.minHeight) \(style.width) \(style.minWidth) \(style.maxWidth) \(style.aspectRatio)")
        return node
    }
    override func update(view: LDImageView) {
        super.update(view: view)
        if let cardVersion = context?.cardVersion, cardVersion >= 2 {
            view.imageMaskView.frame = view.bounds
            view.imageMaskView.backgroundColor = UIColor.ud.fillImgMask.currentColor().cgColor
            view.imageMaskView.isHidden = (props.imageProperty?.localImage != nil)
        } else {
            view.imageMaskView.isHidden = true
        }
        view.contentMode = props.contentMode
        view.clipsToBounds = props.clipsToBounds
        view.isRotaing = false
        guard let property = props.imageProperty else {
            return
        }
        view.isUserInteractionEnabled = property.imgCanPreview
        view.tapCallback = { [weak self] (imageView) in
            self?.context?.imagePreview(imageView: imageView, imageKey: property.originKey)
        }
        /// 如果是本地图片
        let localImage = property.localImage
        if let localImg = localImage {
            view.image = localImg
            applyImageShowMode(view)
            view.isRotaing = property.localImageRotaing
            return
        }
        /// 如果是网络图片
        if let imageProperty = props.imageProperty, let context = self.context {
            if (!imageProperty.hasToken || imageProperty.token.isEmpty), let url = imageProperty.urls.first {
                context.setImageOrigin(
                    (key: imageProperty.originKey, url: url + imageProperty.originKey), placeholderImg: nil,
                    imageView: view,
                    nil)
                applyImageShowMode(view)
                return
            }
            context.setImageProperty(imageProperty, imageView: view, completion: { [weak self] _ , _  in
                self?.applyImageShowMode(view)
            })
        }
        return
    }

    //判断是否是strech长图，添加长图标签
   fileprivate func tryAddLongImageLabel() {
       guard  LarkFeatureGating.shared.getFeatureBoolValue(for:FeatureGating.messageCardEnableImageStretchMode) else {
           cardlog.warn("FG messageCardEnableImageStretchMode failed")
           return
       }
       guard let property = props.imageProperty else {
           cardlog.warn("imageComponent props.imageProperty is nil")
           return
       }
       guard property.originWidth > 0 && property.originHeight > 0 else { return }
       let curImageAspectRatio = (CGFloat(property.originWidth) / CGFloat(property.originHeight))
       guard property.showMode == ImageShowMode.stretch.rawValue,
             curImageAspectRatio < stretchImageAspectRatioLimit else {
           return
       }
       props.isLongImage = true
       self.style.aspectRatio = stretchImageAspectRatioLimit
       // 图片实际宽度小于60，不显示长图标签,详见https://bytedance.feishu.cn/wiki/wikcnQsu3G1mXZFPADOiIjjBHhf
       if property.hasCustomWidth && property.customWidth < 60 {
           return
       }
       self.style.alignContent = .flexEnd
       self.style.justifyContent = .flexEnd

       let props = UILabelComponentProps()
       props.text = BundleI18n.NewLarkDynamic.Lark_Legacy_MsgCard_LongImgTag
       props.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
       props.textColor = UIColor.ud.primaryOnPrimaryFill
       props.textAlignment = .center
       let style = ASComponentStyle()
       style.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.5)
       style.alignSelf = .flexEnd
       style.paddingTop = 2
       style.paddingBottom = 2
       style.paddingLeft = 6
       style.paddingRight = 6
       let longImageLabel = UILabelComponent<C>(props: props, style: style)
       setSubComponents([longImageLabel])

    }

    func applyImageShowMode(_ view: LDImageView) {
        guard LarkFeatureGating.shared.getFeatureBoolValue(for:FeatureGating.messageCardEnableImageStretchMode),
              let property = props.imageProperty,
              let image = view.image,
              props.isLongImage else {
            return
        }
        guard view.bounds.height > 0 && view.bounds.width > 0 else { return }
        var viewAspectRatio = view.bounds.width / view.bounds.height
        let imageCropHeight = image.size.width / viewAspectRatio
        view.image = cropImage(image,toRect: CGRect(x: 0, y: 0, width: image.size.width, height: imageCropHeight))
    }

    //图片裁剪
     func cropImage(_ image: UIImage, toRect: CGRect) -> UIImage? {
         guard toRect.width > 0 && toRect.height > 0 else { return nil }
         var rect = toRect
         if image.scale != 1 {
             rect.origin.x *= image.scale
             rect.origin.y *= image.scale
             rect.size.width *= image.scale
             rect.size.height *= image.scale
         }
         if let croppedCgImage = image.cgImage?.cropping(to: rect)?.copy() {
             return UIImage(cgImage: croppedCgImage)
         } else if let ciImage = image.ciImage {
             let croppedCiImage = ciImage.cropped(to: rect)
             return UIImage(ciImage: croppedCiImage)
         }
         return nil
    }
}
