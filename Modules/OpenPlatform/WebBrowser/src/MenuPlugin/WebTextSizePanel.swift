//
//  WebTextSizePanel.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/6/9.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import LarkZoomable
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor
import LarkStorage
import LarkAccountInterface

enum TextSizeContentCons {
    static var topAndBottomMargin: CGFloat { Self.valueForDisplay(20, pad: 16) }
    static let minLblSz: CGSize = CGSize(width: 12, height: 24)
    static let maxLblSz: CGSize = CGSize(width: 18, height: 34)
    static var sliderW: CGFloat { Self.valueForDisplay(323, pad: 431) }
    static var rulerW: CGFloat { Self.valueForDisplay(299, pad: 407) }
    static var sliderAndLblOffset: CGFloat { Self.valueForDisplay(3, pad: 5) }
    static let sliderAndDescOffset: CGFloat = 16
    static func valueForDisplay(_ phone: CGFloat, pad: CGFloat) -> CGFloat {
        if Display.pad {
            return pad
        }
        return phone
    }
    static func textSizeUserScript(percent: Int) -> String {
        return "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='\(percent)%'"
    }
}

private enum TextSizePanelColor {
    static var endLblColor: UIColor {
        UIColor.ud.N900 & UIColor.ud.textTitle
    }
}

// MARK: - WebTextSizePanelProtocol
protocol WebTextSizePanelProtocol: AnyObject {
    func dismissPanel(animated: Bool, completion: (() -> Void)?)
}

// MARK: - WebTextSizePanel
final class WebTextSizePanel: UIView {
    private static let logger = Logger.webBrowserLog(WebTextSizePanel.self, category: "WebTextSizePanel")
    
    weak var delegate: WebTextSizePanelProtocol?
    
    private var contentAreaH: CGFloat = TextSizeContentCons.valueForDisplay(174, pad: 172)
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tap.delegate = self
        view.addGestureRecognizer(tap)
        return view
    }()
    
    private lazy var bottomWrapper: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()
    
    lazy var rulerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var zoomSlider: ZoomSlider = {
        let slider = ZoomSlider()
        slider.zoom = WebZoom.currentZoom
        return slider
    }()

    private lazy var minLabel: UILabel = {
        let label = UILabel()
        label.textColor = TextSizePanelColor.endLblColor
        label.textAlignment = .center
        label.text = "A"
        label.font = UDFont.getTitle4(for: Zoom.allCases.first!)
        return label
    }()

    private lazy var maxLabel: UILabel = {
        let label = UILabel()
        label.textColor = TextSizePanelColor.endLblColor
        label.textAlignment = .center
        label.text = "A"
        label.font = UDFont.getTitle4(for: Zoom.allCases.last!)
        return label
    }()

    private lazy var normalLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.text = BundleI18n.WebBrowser.Lark_NewSettings_DefaultTextSize
        label.font = UDFont.getTitle4(for: .normal)
        return label
    }()
    
    private lazy var descLbl: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.text = BundleI18n.WebBrowser.OpenPlatform_WebAppSettings_ChangeFontSizeDesc
        label.numberOfLines = 0
        label.font = UDFont.getBody2(for: .normal)
        return label
    }()
    
    private lazy var safeAreaBottom: CGFloat = {
        if let window = UIApplication.shared.keyWindow {
            return window.safeAreaInsets.bottom
        }
        return 0
    }()
    
    init(delegate: WebTextSizePanelProtocol? = nil) {
        super.init(frame: .zero)
        self.delegate = delegate
        setupSubviews()
        setupConstraints()
        setupAppearance()
        setupZoomChanged()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupSubviews() {
        addSubview(contentView)
        contentView.addSubview(bottomWrapper)
        bottomWrapper.addSubview(bottomView)
        bottomView.addSubview(rulerImageView)
        bottomView.addSubview(zoomSlider)
        bottomView.addSubview(minLabel)
        bottomView.addSubview(maxLabel)
        bottomView.addSubview(normalLabel)
        bottomView.addSubview(descLbl)
    }
    
    private func setupConstraints() {
        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        let descLblH = descLbl.sizeThatFits(CGSize(width: TextSizeContentCons.rulerW, height: CGFLOAT_MAX)).height
        let thumbSz = zoomSlider.thumbRect(forBounds: .zero, trackRect: .zero, value: zoomSlider.minimumValue)
        contentAreaH = TextSizeContentCons.topAndBottomMargin + TextSizeContentCons.maxLblSz.height + TextSizeContentCons.sliderAndLblOffset + thumbSz.height + TextSizeContentCons.sliderAndDescOffset + descLblH + TextSizeContentCons.topAndBottomMargin + safeAreaBottom
        bottomWrapper.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(contentAreaH)
        }
        bottomView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        zoomSlider.snp.remakeConstraints { make in
            make.top.equalTo(maxLabel.snp.bottom).offset(TextSizeContentCons.sliderAndLblOffset)
            make.centerX.equalToSuperview()
            make.width.equalTo(TextSizeContentCons.sliderW)
        }
        rulerImageView.snp.remakeConstraints { make in
            make.top.bottom.equalTo(zoomSlider)
            make.left.right.equalTo(zoomSlider).inset(thumbSz.width / 2)
        }
        maxLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(TextSizeContentCons.topAndBottomMargin)
            make.centerX.equalTo(rulerImageView.snp.right)
        }
        minLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(rulerImageView.snp.left)
            make.centerY.equalTo(maxLabel)
        }
        descLbl.snp.remakeConstraints { make in
            make.top.equalTo(zoomSlider.snp.bottom).offset(TextSizeContentCons.sliderAndDescOffset)
            make.centerX.equalToSuperview()
            make.width.equalTo(TextSizeContentCons.rulerW)
            make.height.equalTo(ceil(descLblH))
        }
        let zoomLevels = Zoom.allCases
        let regularIndex = zoomLevels.firstIndex(where: { $0 == .normal })!
        normalLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(maxLabel)
            make.centerX.equalTo(rulerImageView.snp.trailingMargin).multipliedBy(CGFloat(regularIndex) / CGFloat(zoomLevels.count - 1)).offset(3)
        }
    }
    
    private func setupAppearance() {
        bottomWrapper.layer.shadowColor = UIColor.ud.staticBlack.cgColor
        bottomWrapper.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomWrapper.layer.shadowRadius = 2
        bottomWrapper.layer.shadowOpacity = 0.04
    }
    
    private func setupZoomChanged() {
        zoomSlider.onZoomChanged = { zoom in
            if WebZoom.currentZoom != zoom {
                WebZoom.setZoom(zoom)
                Self.logger.info("[WebTextSize] set web zoom: \(zoom)")
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    @objc func tapAction(sender: UITapGestureRecognizer) {
        delegate?.dismissPanel(animated: true, completion: nil)
    }
}

extension WebTextSizePanel: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view?.isDescendant(of: bottomWrapper) ?? false)
    }
}
