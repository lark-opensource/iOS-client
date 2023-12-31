//
//  QRCodeContentView.swift
//  QRCode
//
//  Created by Yuri on 2022/5/13.
//

import Foundation
import UIKit
import UniverseDesignIcon

final class ScanCodeContentView: UIView {

    lazy var firstDescribeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N00
        label.backgroundColor = UIColor.clear
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    var secondDescribeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N00
        label.backgroundColor = UIColor.clear
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    lazy var videoPreviewView = VideoPreviewView()
    var scanMaskView: ScanMask = ScanMask()
    var alertLabel = UILabel()

    lazy var albumContainerView: UIView = { return UIView() }()
    lazy var torchButton : UIButton = { return UIButton(type: .custom) }()
    var timer: Timer?

    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public func updateViewBy(isInterrupted: Bool, isRunning: Bool, isFullScreen: Bool) {
        /// 只有在非全屏并且 interrupted || !running 的时候才显示提示文案
        if (isInterrupted || !isRunning) && !isFullScreen {
            videoPreviewView.isHidden = true
            scanMaskView.isHidden = true
            alertLabel.isHidden = false
            if UIDevice.current.userInterfaceIdiom == .pad {
                alertLabel.text = BundleI18n.QRCode.Lark_Legacy_iPadSplitViewCamera
            }
        } else {
            videoPreviewView.isHidden = false
            scanMaskView.isHidden = false
            alertLabel.isHidden = true
        }
    }

    private func setupView() {
        self.backgroundColor = UIColor.black
        self.clipsToBounds = true

        videoPreviewView.clipsToBounds = true
        addSubview(videoPreviewView)
        videoPreviewView.frame = self.bounds

        addSubview(scanMaskView)
        self.scanMaskView.frame = self.bounds

        alertLabel.textColor = UIColor.white
        alertLabel.numberOfLines = 0
        alertLabel.backgroundColor = UIColor.clear
        alertLabel.font = UIFont.systemFont(ofSize: 18)
        alertLabel.textAlignment = .center
        alertLabel.isHidden = true
        addSubview(alertLabel)
        alertLabel.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.left.greaterThanOrEqualToSuperview().offset(16)
            maker.right.lessThanOrEqualToSuperview().offset(-16)
        }

        setupAlbumButton()
        setupTorchButton()

        addSubview(firstDescribeLabel)
        addSubview(secondDescribeLabel)
    }

    private func setupAlbumButton() {
        albumContainerView.layer.cornerRadius = 58/2
        albumContainerView.layer.ud.setBackgroundColor(UIColor.ud.bgMask.withAlphaComponent(0.4))

        let textLabel = UILabel()
        textLabel.text = BundleI18n.QRCode.Lark_Legacy_QrCodeAlbum
        textLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        textLabel.font = .systemFont(ofSize: 12)
        let albumImage = UDIcon.getIconByKey(.nopictureFilled, iconColor: UIColor.ud.primaryOnPrimaryFill)
        let albumImageView = UIImageView(image: albumImage)

        albumContainerView.addSubview(textLabel)
        albumContainerView.addSubview(albumImageView)
        addSubview(albumContainerView)

        albumContainerView.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-12)
            maker.centerX.equalToSuperview()
            maker.width.height.equalTo(58)
        }
        albumImageView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(8)
            maker.centerX.equalToSuperview()
        }
        textLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(albumImageView.snp.bottom).offset(3)
            maker.centerX.equalToSuperview()
        }
    }
    
    private func setupTorchButton() {
        let torchOffImage = UIImage(named: "torchOff", in: BundleConfig.QRCodeBundle, compatibleWith: nil) ?? UIImage()
        let torchPressImage = UIImage(named: "torchPress", in: BundleConfig.QRCodeBundle, compatibleWith: nil) ?? UIImage()
        let torchOnImage = UIImage(named: "torchOn", in: BundleConfig.QRCodeBundle, compatibleWith: nil) ?? UIImage()
        torchButton.setTitle(BundleI18n.QRCode.Lark_ScanCode_TapToTurnLightOn_Button, for: .normal)
        torchButton.setTitle(BundleI18n.QRCode.Lark_ScanCode_TapToTurnLightOff_Button, for: .selected)
        torchButton.alpha = 0
        torchButton.titleLabel?.textColor = UIColor.ud.primaryOnPrimaryFill
        torchButton.titleLabel?.font = .systemFont(ofSize: 12)
        torchButton.setImage(torchOffImage, for: .normal)
        torchButton.setImage(torchPressImage, for: .highlighted)
        torchButton.setImage(torchOnImage, for: .selected)
        torchButton.adjustImageTop(spacing: 4)
        torchButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 4, right: 12)
        
        addSubview(torchButton)
        torchButton.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-82)
            maker.centerX.equalToSuperview()
            maker.height.equalTo(80)
            maker.width.greaterThanOrEqualTo(80)
        }
        torchButton.isHidden = true
    }


    override func layoutSubviews() {
        super.layoutSubviews()
        let vw = self.frame.width
        let vh = self.frame.height
        let scanRect = CGRect(
            x: 0,
            y: vh*0.25, // 从屏幕25%起
            width: self.frame.width,
            height: vh*(0.45) // 25%到70%
        )
        videoPreviewView.frame = self.bounds
        self.scanMaskView.frame = self.bounds
        self.scanMaskView.update(frame: self.bounds, scanRect: scanRect)

        let labelSize: CGFloat = vw - 20
        let firstlabelRect = CGRect(
            x: (vw - labelSize) / 2,
            y: scanRect.bottom + 35,
            width: labelSize,
            height: 20
        )
        self.firstDescribeLabel.frame = firstlabelRect

        let secondlabelRect = CGRect(
            x: firstlabelRect.left,
            y: firstlabelRect.bottom + 8,
            width: labelSize,
            height: 20
        )
        self.secondDescribeLabel.frame = secondlabelRect
    }
    
    var blinkingCount = 0
    func setTorchBlinking() {
        blinkingCount = 5
        self.timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(self.blinkingAnimate), userInfo: nil, repeats: true)
    }
    
    func cleanTorchButton() {
        torchButton.isSelected = false
        torchButton.isHidden = true
    }

    /// 切换到多码识别结果样式
    func switchToMulticodeResultStyle() {
        cleanTorchButton()
        albumContainerView.isHidden = true
    }

    /// 切换到正常扫码样式
    func switchToNormalScanStyle() {
        albumContainerView.isHidden = false
    }

    @objc func blinkingAnimate() {
        UIView.animate(withDuration: 0.25, delay: 0 , options: .curveEaseOut) {
            self.torchButton.alpha = CGFloat(self.blinkingCount % 2 )
        }
        blinkingCount -= 1
        if blinkingCount == 0, let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }
}

extension UIButton {
    
    /// 重置图片image与标题title位置(默认间距为0)
    func adjustImageTop(spacing: CGFloat = 0 ) {
        self.sizeToFit()
        let imageWidth = self.imageView?.image?.size.width ?? 0
        let imageHeight = self.imageView?.image?.size.height ?? 0
        // 自适应文本宽高需从intrinsicContentSize获取
        let labelWidth = self.titleLabel?.intrinsicContentSize.width ?? 0
        let labelHeight = self.titleLabel?.intrinsicContentSize.height ?? 0
        imageEdgeInsets = UIEdgeInsets(top: -labelHeight - spacing, left: 0, bottom: 0, right: -labelWidth)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: -imageHeight - spacing, right: 0)
    }
}
