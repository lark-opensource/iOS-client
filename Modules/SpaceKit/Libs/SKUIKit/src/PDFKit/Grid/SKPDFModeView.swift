//
//  SKPDFModeView.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/7/9.
//

import UIKit
import SnapKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

public protocol SKPDFModeDelegate: AnyObject {
    func previewModeChanged(currentMode: SKPDFModeView.PreviewMode)
}

public final class SKPDFModeView: UIView {

    public enum PreviewMode {
        case preview
        case grid
    }

    weak var delegate: SKPDFModeDelegate?
    private(set) var currentMode: PreviewMode

    private var imageForModeButton: UIImage {
        switch currentMode {
        case .preview:
            return UDIcon.appOutlined.ud.withTintColor(UDColor.primaryOnPrimaryFill)
        case .grid:
            return BundleResources.SKResource.Drive.drive_pdf_preview.ud.withTintColor(UDColor.primaryOnPrimaryFill)
        }
    }
    
    private var imageForModeButtonPress: UIImage {
        switch currentMode {
        case .preview:
            return UDIcon.appOutlined.ud.withTintColor(UDColor.staticWhitePressed)
        case .grid:
            return BundleResources.SKResource.Drive.drive_pdf_preview.ud.withTintColor(UDColor.staticWhitePressed)
        }
    }

    private lazy var previewModeButton: UIButton = {
        let button = UIButton()
        button.setImage(imageForModeButton, for: .normal)
        button.setImage(imageForModeButtonPress, for: .highlighted)
        return button
    }()

    public init(mode: PreviewMode, delegate: SKPDFModeDelegate?) {
        currentMode = mode
        self.delegate = delegate
        super.init(frame: .zero)
        setupUI()
        setupHandler()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.N900.withAlphaComponent(0.6).nonDynamic
        alpha = 0.9
        layer.cornerRadius = 4
        layer.masksToBounds = true
        layer.ud.setBorderColor(UDColor.lineBorderCard)
        layer.borderWidth = 1
        layer.ud.setShadowColor(UDColor.shadowDefaultMd)
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowOpacity = 1

        addSubview(previewModeButton)
        previewModeButton.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.width.equalTo(previewModeButton.snp.height)
            make.edges.equalToSuperview()
        }
    }

    private func setupHandler() {
        previewModeButton.addTarget(self, action: #selector(switchMode), for: .touchUpInside)
    }

    @objc
    private func switchMode() {
        if currentMode == .preview {
            currentMode = .grid
        } else {
            currentMode = .preview
        }
        previewModeButton.setImage(imageForModeButton, for: .normal)
        previewModeButton.setImage(imageForModeButtonPress, for: .highlighted)
        delegate?.previewModeChanged(currentMode: currentMode)
    }

    /// 退出缩略图模式，重置为正常预览模式
    public func reset() {
        currentMode = .preview
        previewModeButton.setImage(imageForModeButton, for: .normal)
        previewModeButton.setImage(imageForModeButtonPress, for: .highlighted)
        delegate?.previewModeChanged(currentMode: currentMode)
    }
}
