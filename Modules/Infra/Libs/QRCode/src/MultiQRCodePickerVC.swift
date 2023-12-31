//
//  MultiQRCodePickerVC.swift
//  QRCode
//
//  Created by Saafo on 2023/10/8.
//

import UIKit
import SnapKit
import LarkExtensions
import UniverseDesignShadow

final class MultiQRCodePickerVC: UIViewController {

    var image: UIImage?
    /// 如果 image 大小不是原图片的真实大小（而是缩略图），可以在此写入真实大小。布局箭头时会按此值布局
    var imageSize: CGSize?
    /// 这里 info.position 是需要转换成相对原图大小&左上角的坐标系
    var codeInfos: [CodeItemInfo] = []
    var didPickQRCode: ((CodeItemInfo?) -> Void)?
    var optimizeArrowPosition: Bool = true
    var needAppearAnimation: Bool = false

    private let imageView = UIImageView()
    private var imageContentRect: CGRect = .zero
    private var imageContentScale: CGFloat = 1
    private let maskView = UIView()
    private let hintLabel = UILabel()
    private var arrowViews: [ArrowView] = []
    #if DEBUG
    var debug: Bool = false
    private var debugViews: [UIView] = []
    #endif
    private var lastSize: CGSize = .zero
    private var firstAppear: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ud.staticBlack
        // 底图
        view.addSubview(imageView)
        imageView.image = image
        imageView.backgroundColor = .ud.staticBlack
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // 遮罩
        view.addSubview(maskView)
        maskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // 取消 & 提示文案
        let cancelButton = UIButton() // 不使用 navigationBar，因为箭头需要盖在按钮上
        cancelButton.setTitle(BundleI18n.QRCode.Lark_Legacy_Cancel, for: .normal)
        cancelButton.setTitleColor(UIColor.ud.staticWhite, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17)
        cancelButton.addTarget(self, action: #selector(tapCancel), for: .touchUpInside)
        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(28)
            make.left.equalTo(16)
            make.size.equalTo(cancelButton.titleLabel?.intrinsicContentSize ?? .zero)
        }
        hintLabel.text = BundleI18n.QRCode.Lark_QRcodeScan_MultiCodeTapToChoose_Text
        hintLabel.textColor = UIColor.ud.staticWhite
        hintLabel.font = .systemFont(ofSize: 16)
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
        view.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(160)
            make.width.equalToSuperview().multipliedBy(0.7)
        }
        // 箭头
        arrowViews = codeInfos.map { info in
            let arrow = ArrowView(codeContent: info, didPickQRCode: didPickQRCode)
            arrow.needAppearAnimation = needAppearAnimation
            view.addSubview(arrow)
            return arrow
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        guard lastSize != view.bounds.size else { return }
        lastSize = view.bounds.size

        updateContentRect()
        layoutHintLabel()
        layoutArrowViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard firstAppear else { return }
        firstAppear = false
        let setMaskBackground = {
            self.maskView.backgroundColor = UIColor.ud.bgMask.withAlphaComponent(0.55)
        }
        if needAppearAnimation {
            UIView.animate(withDuration: 0.6) {
                setMaskBackground()
            }
        } else {
            setMaskBackground()
        }
    }

    // scaleAspectFit 不支持获取 scale 和 rect，这里手动计算下
    private func updateContentRect() {
        guard let image else {
            imageContentRect = .zero
            imageContentScale = 1
            return
        }
        let imageSize = imageSize ?? image.pixelSize
        // imageView 和 view 大小一致，因为是 AutoLayout 布局，这里直接取 view 大小
        imageContentScale = min(view.bounds.width / imageSize.width,
                                view.bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * imageContentScale,
                          height: imageSize.height * imageContentScale)
        let x = (view.bounds.width - size.width) / 2
        let y = (view.bounds.height - size.height) / 2
        imageContentRect = CGRect(x: x, y: y, width: size.width, height: size.height)
    }

    private func layoutHintLabel() {
        hintLabel.snp.updateConstraints { make in
            make.bottom.equalTo(view.bounds.height < 600 ? -60 : -160)
        }
    }

    private func layoutArrowViews() {
        #if DEBUG
        debugViews.forEach { $0.removeFromSuperview() }
        debugViews = []
        #endif
        arrowViews.forEach { arrowView in
            // 码相对于整张图片的坐标
            let imageRelativeRect = arrowView.imageRelativeRect
            // 码相对于 View 的坐标
            let viewRelativeRect = CGRect(x: imageRelativeRect.minX * imageContentScale + imageContentRect.minX,
                                          y: imageRelativeRect.minY * imageContentScale + imageContentRect.minY,
                                          width: imageRelativeRect.width * imageContentScale,
                                          height: imageRelativeRect.height * imageContentScale)
            arrowView.center = viewRelativeRect.center
            if optimizeArrowPosition, !imageContentRect.contains(arrowView.center) {
                // 码相对于 View 的可视区域
                let viewVisibleRect = viewRelativeRect.intersection(imageContentRect)
                arrowView.center = viewVisibleRect.center
            }
            #if DEBUG
            if debug {
                let debugView = UIView(frame: viewRelativeRect)
                debugView.backgroundColor = .systemRed.withAlphaComponent(0.2)
                debugView.isUserInteractionEnabled = false
                debugViews.append(debugView)
                view.addSubview(debugView)
            }
            #endif
        }
    }

    @objc
    private func tapCancel() {
        didPickQRCode?(nil)
    }
}

private final class ArrowView: UIView, CAAnimationDelegate {

    var needAppearAnimation: Bool = false
    private(set) var imageRelativeRect = CGRect.zero

    private var arrowImage = UIImageView()
    private var didPickQRCode: ((CodeItemInfo?) -> Void)?
    private var codeContent: CodeItemInfo
    private let appearAnimationName = "appearAnimation"
    private let breathAnimationName = "breathAnimation"
    private var firstAppear = true

    init(codeContent: CodeItemInfo, didPickQRCode: ((CodeItemInfo?) -> Void)?) {
        self.codeContent = codeContent
        self.imageRelativeRect = codeContent.position
        self.didPickQRCode = didPickQRCode
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
        arrowImage.frame = bounds
        arrowImage.image = Resources.arrow
        addSubview(arrowImage)
        arrowImage.layer.ud.setShadow(type: .s5Down)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didSelect))
        addGestureRecognizer(tapGesture)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard firstAppear else { return }
        firstAppear = false
        // 动画需要在 didAppear 之后添加
        if needAppearAnimation {
            layer.add(appearAnimation(), forKey: appearAnimationName)
        } else {
            layer.add(breathAnimation(), forKey: breathAnimationName)
        }
    }

    @objc
    private func didSelect() {
        didPickQRCode?(codeContent)
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim == layer.animation(forKey: appearAnimationName) {
            layer.removeAnimation(forKey: appearAnimationName)
            // 出现动画结束之后，添加呼吸动画
            if needAppearAnimation {
                layer.add(breathAnimation(), forKey: breathAnimationName)
            }
        }
    }

    private func appearAnimation() -> CAAnimation {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.6
        scaleAnimation.toValue = 1
        let alphaAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        alphaAnimation.fromValue = 0
        alphaAnimation.toValue = 1
        let appearAnimation = CAAnimationGroup()
        appearAnimation.animations = [scaleAnimation, alphaAnimation]
        appearAnimation.duration = 0.3
        appearAnimation.delegate = self
        appearAnimation.isRemovedOnCompletion = false // 结束时手动移除
        return appearAnimation
    }
    private func breathAnimation() -> CAAnimation {
        let breathAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        breathAnimation.values = [1, 0.8, 1, 0.8, 1]
        breathAnimation.keyTimes = Array<Double>(
            arrayLiteral: 0, 1 / 12, 2 / 12, 3 / 12, 4 / 12
        ).map { NSNumber(value: $0) }
        breathAnimation.duration = 3
        breathAnimation.repeatCount = .infinity
        breathAnimation.calculationMode = .cubic
        breathAnimation.isRemovedOnCompletion = false
        if needAppearAnimation {
            breathAnimation.beginTime = CACurrentMediaTime() + 0.3 // 等待 mask animation 结束
        }
        return breathAnimation
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
