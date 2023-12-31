//
//  MeetingRecordView.swift
//  ByteView
//
//  Created by chentao on 2020/4/7.
//

import UIKit
import UniverseDesignIcon

class MeetingRecordView: BaseInMeetStatusView {

    struct Layout {
        static let iconImageViewNormalLeftOffset: CGFloat = 2.0
        static let iconSize: CGSize = CGSize(width: 12, height: 12)
        static let iconSizeWithoutText: CGSize = CGSize(width: 12, height: 12)
    }

    enum ImagesStatus {
        case normal
        case omit
    }

    var animationImages: [ImagesStatus: [UIImage]] = [:]
    private let recordIcon: UIImageView = {
        let icon = UIImageView()
        icon.animationDuration = 1.2
        return icon
    }()

    private let recordLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 10.0)
        label.text = I18n.View_MV_Recording_StatusTopBar
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(recordIcon)
        addSubview(recordLabel)
        // layout
        resetIconViewImages(Layout.iconSize, .normal)
        updateLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(handleEnterForegroundNotification(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // 黑白切换需要重新开始动画
        if #available(iOS 13.0, *),
           let pre = previousTraitCollection,
           pre.hasDifferentColorAppearance(comparedTo: traitCollection) {
            recoverAnimationIfNeed()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHidden: Bool {
        didSet {
            recoverAnimationIfNeed()
        }
    }

    var isRecordLaunching: Bool = false {
        didSet {
            recoverAnimationIfNeed()
        }
    }

    // 页面退到后台、或者所属页面被其他页面遮盖(FullScreen方式modal会从渲染层级中去除，导致动画被移除)
    func recoverAnimationIfNeed() {
        let size: CGSize
        if shouldHiddenForOmit {
            resetIconViewImages(Layout.iconSizeWithoutText, .omit)
            size = Layout.iconSizeWithoutText
        } else {
            resetIconViewImages(Layout.iconSize, .normal)
            size = Layout.iconSize
        }
        if isRecordLaunching {
            recordIcon.stopAnimating()
            let img = UDIcon.getIconByKey(.recordingColorful, iconColor: UIColor.ud.N500, size: size).imageWithColor(color: UIColor.ud.N500)
            recordIcon.image = img
            recordIcon.animationImages = []
        }
        if isHidden {
            recordIcon.stopAnimating()
        } else {
            recordIcon.startAnimating()
        }
    }

    func setLabel(_ text: String) {
        recordLabel.text = text
    }

    func setIcon(_ icon: UIImage?) {
        guard let image = icon else { return }
        recordIcon.image = image
    }

    @objc
    private func handleEnterForegroundNotification(_ notification: NSNotification) {
        recoverAnimationIfNeed()
    }

    private func resetIconViewImages(_ size: CGSize, _ imageStatus: ImagesStatus) {
        if let images = animationImages[imageStatus], !images.isEmpty {
            recordIcon.image = images.first
            recordIcon.animationImages = images
        } else {
            let imageFillDefault = UDIcon.getIconByKey(.recordingColorful, iconColor: UIColor.ud.functionDangerFillDefault, size: size).imageWithColor(color: UIColor.ud.functionDangerFillDefault)
            let imageFillHover = UDIcon.getIconByKey(.recordingColorful, iconColor: UIColor.ud.functionDangerFillHover, size: size).imageWithColor(color: UIColor.ud.functionDangerFillHover)
            animationImages[imageStatus] = [imageFillDefault, imageFillHover]
            recordIcon.image = imageFillDefault
            recordIcon.animationImages = [imageFillDefault, imageFillHover]
        }
    }

    override func updateLayout() {
        if shouldHiddenForOmit {
            recordLabel.isHidden = true
            resetIconViewImages(Layout.iconSizeWithoutText, .omit)
            recordIcon.snp.remakeConstraints {
                $0.edges.equalToSuperview()
                $0.size.equalTo(Layout.iconSizeWithoutText)
            }

        } else {
            recordLabel.isHidden = false
            resetIconViewImages(Layout.iconSize, .normal)
            recordIcon.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.size.equalTo(Layout.iconSize)
                maker.left.equalToSuperview()
            }

            recordLabel.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.height.equalTo(13.0)
                maker.left.equalTo(recordIcon.snp.right).offset(Layout.iconImageViewNormalLeftOffset)
                maker.right.equalToSuperview()
            }
        }
    }
}

class FloatingRecordView: UIView {

    let recordIcon: UIImageView = {
        let icon = UIImageView()
        icon.animationDuration = 1.2
        return icon
    }()

    private let recordLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.text = I18n.View_MV_Rec_StatusTopBar
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.N00.withAlphaComponent(0.9)
        layer.cornerRadius = 6.0
        layer.masksToBounds = true
        addSubview(recordIcon)
        addSubview(recordLabel)
        recordIcon.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().inset(4.0)
            $0.size.equalTo(CGSize(width: 9, height: 9))
        }
        recordLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.height.equalTo(13.0)
            maker.left.equalTo(recordIcon.snp.right).offset(1.0)
            maker.right.equalToSuperview().offset(-4.0)
        }
        setIconViewImages(CGSize(width: 9, height: 9))
        NotificationCenter.default.addObserver(self, selector: #selector(handleEnterForegroundNotification(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // 黑白切换需要重新开始动画
        if #available(iOS 13.0, *),
           let pre = previousTraitCollection,
           pre.hasDifferentColorAppearance(comparedTo: traitCollection) {
            recoverAnimationIfNeed()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHidden: Bool {
        didSet {
            recoverAnimationIfNeed()
        }
    }

    override var intrinsicContentSize: CGSize {
        let labelWidth = recordLabel.intrinsicContentSize.width
        let width = 4.0 + 9.0 + 1.0 + labelWidth + 4.0
        let height = 16.0
        return CGSize(width: width, height: height)
    }

    // 页面退到后台、或者所属页面被其他页面遮盖(FullScreen方式modal会从渲染层级中去除，导致动画被移除)
    func recoverAnimationIfNeed() {
        if isHidden {
            recordIcon.stopAnimating()
        } else {
            recordIcon.startAnimating()
        }
    }

    @objc
    private func handleEnterForegroundNotification(_ notification: NSNotification) {
        recoverAnimationIfNeed()
    }

    private func setIconViewImages(_ size: CGSize) {
        let imageR400 = UDIcon.getIconByKey(.recordFilled, iconColor: UIColor.ud.R400, size: size).imageWithColor(color: UIColor.ud.R400)
        let imageR600 = UDIcon.getIconByKey(.recordFilled, iconColor: UIColor.ud.R600, size: size).imageWithColor(color: UIColor.ud.R600)
        recordIcon.image = imageR400
        recordIcon.animationImages = [imageR400, imageR600]
    }

}

// 当使用colorful的icon做动画的时候，不产生效果，需要画一个新的image
extension UIImage {
    func imageWithColor(color: UIColor) -> UIImage {
        let render = UIGraphicsImageRenderer(bounds: .init(origin: .zero, size: self.size))
        let newImage = render.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: 0, y: self.size.height)
            cgContext.scaleBy(x: 1.0, y: -1.0)
            cgContext.setBlendMode(.normal)
            let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
            if let cgImage = self.cgImage {
                cgContext.clip(to: rect, mask: cgImage)
            }
            color.setFill()
            cgContext.fill(rect)
        }
        return newImage
    }
}
