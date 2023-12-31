//
//  DKCardModeUnsupportView.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/11/2.
//

import UIKit
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignButton
import UniverseDesignFont

class DKCardModeUnsupportView: UIView {

    weak var delegate: DriveUnSupportFileViewDelegate?

    private var unSupportType: DriveUnsupportPreviewType = .typeUnsupport
    private var config: DriveUnSupportConfig
    private var displayMode: DrivePreviewMode = .card

    private lazy var containView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UDEmptyType.noPreview.defaultImage()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = titleFont
        label.textColor = UDEmptyColorTheme.emptyTitleColor
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.font = descFont
        label.textColor = UDEmptyColorTheme.emptyDescriptionColor
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var openInOtherBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 4.0
        btn.layer.borderWidth = 1
        btn.layer.masksToBounds = true
        btn.layer.ud.setBorderColor(UDEmptyColorTheme.primaryButtonBorderColor)
        btn.setTitleColor(UDEmptyColorTheme.primaryButtonTextColor, for: .normal)
        btn.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        btn.setTitle(BundleI18n.SKResource.Drive_Drive_OpenWithOtherApps, for: .normal)
        btn.backgroundColor = UDEmptyColorTheme.primaryButtonBackgroundColor
        btn.titleLabel?.font = btnFont
        btn.addTarget(self, action: #selector(openClick(_:)), for: .touchUpInside)
        return btn
    }()
    
    private lazy var cannotExportTipsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = BundleI18n.SKResource.Drive_Drive_AttachFileNotSupportPreviewNoPermissionTips
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private var contentCenterOffset: CGFloat {
        return displayMode == .card ? 0 : -60
    }
    
    private var titleFont: UIFont {
        return displayMode == .card ? UIFont.systemFont(ofSize: 14, weight: .medium) : UDFont.title3(.fixed)
    }
    
    private var descFont: UIFont {
        return displayMode == .card ? UIFont.systemFont(ofSize: 12) : UDFont.body2(.fixed)
    }
    private var btnFont: UIFont {
        return displayMode == .card ? UIFont.systemFont(ofSize: 14) : UIFont.systemFont(ofSize: 16)
    }
    
    private var buttonSize: CGSize {
        let size = displayMode == .normal ? CGSize(width: 76, height: 36) : CGSize(width: 60, height: 28)
        return size
    }
    
    private var iconSize: CGFloat {
        return displayMode == .normal ? 120 : 75
    }
    
    private var iconLabelMargin: CGFloat {
        return displayMode == .normal ? 12 : 4
    }
    
    private var labelBtnMargin: CGFloat {
        return displayMode == .normal ? 16 : 8
    }
    
    private var edgeInsets: CGFloat {
        return displayMode == .normal ? 20 : 12
    }

    private var titleHeight: CGFloat {
        return displayMode == .normal ? 24 : 20
    }
    
    private var descHeight: CGFloat {
        return displayMode == .normal ? 20 : 18
    }
    init(fileName: String, mode: DrivePreviewMode, delegate: DriveUnSupportFileViewDelegate) {
        self.delegate = delegate
        config = DriveUnSupportConfig(fileName: fileName, fileType: "", fileSize: 0, buttonVisiable: true, buttonEnable: true)
        super.init(frame: .zero)
        self.displayMode = mode
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.driveInfo("DriveUnSupportFileView-----deinit")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBase
        cannotExportTipsLabel.isHidden = true
        addSubview(containView)

        containView.addSubview(iconView)
        containView.addSubview(titleLabel)
        containView.addSubview(descLabel)
        containView.addSubview(openInOtherBtn)
        containView.addSubview(cannotExportTipsLabel)
        
        containView.setContentHuggingPriority(.required, for: .vertical)
        containView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
        iconView.setContentHuggingPriority(.required, for: .vertical)
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.height.equalTo(iconSize)
            make.centerX.equalToSuperview()
        }
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconView.snp.bottom).offset(iconLabelMargin)
            make.height.equalTo(titleHeight)
        }
        descLabel.setContentHuggingPriority(.required, for: .vertical)
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.height.equalTo(descHeight)
        }
        let hideBtn = (displayMode == .card)
        let margin = hideBtn ? 0 : labelBtnMargin
        let height = hideBtn ? 0 : buttonSize.height
        openInOtherBtn.isHidden = hideBtn
        openInOtherBtn.setContentHuggingPriority(.required, for: .vertical)
        openInOtherBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: edgeInsets, bottom: 0, right: edgeInsets)
        openInOtherBtn.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(margin)
            make.centerX.equalToSuperview()
            make.height.equalTo(height)
            make.width.greaterThanOrEqualTo(buttonSize.width)
            make.bottom.equalToSuperview()
        }

        cannotExportTipsLabel.snp.makeConstraints { (make) in
            make.top.equalTo(openInOtherBtn.snp.bottom).offset(0)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview()
            make.height.equalTo(0)
        }
    }
    
    func setUnsupportType(type: DriveUnsupportPreviewType, config: DriveUnSupportConfig) {
        self.unSupportType = type
        self.config = config
        let (title, description) = DriveUnSupportFileView.titleAndSubTitle(type: type, config: config)
        
        let hideBtn = !config.buttonVisiable || (displayMode == .card)
        let size: CGSize = hideBtn ? .zero : buttonSize
        let margin: CGFloat = hideBtn ? 0 : labelBtnMargin
        openInOtherBtn.isHidden = hideBtn
        openInOtherBtn.snp.updateConstraints { make in
            make.height.equalTo(size.height)
            make.top.equalTo(descLabel.snp.bottom).offset(margin)
        }
        titleLabel.text = title
        descLabel.text = description
    }

    func setPreviewButton(visiable: Bool) {
        guard config.buttonVisiable != visiable else { return }
        config.buttonVisiable = visiable
        setUnsupportType(type: unSupportType, config: config)
    }
    
    func setPreviewButton(enable: Bool) {
        guard config.buttonEnable != enable else { return }
        config.buttonEnable = enable
        let borderColor = enable ? UDEmptyColorTheme.primaryButtonBorderColor : UIColor.clear
        let backColor = enable ?  UDEmptyColorTheme.primaryButtonBackgroundColor : UIColor.ud.fillDisabled
        openInOtherBtn.isEnabled = enable
        openInOtherBtn.layer.ud.setBorderColor(borderColor)
        openInOtherBtn.backgroundColor = backColor
    }
    
    func showExportTips(_ show: Bool) {
        if show {
            cannotExportTipsLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(openInOtherBtn.snp.bottom).offset(10)
                make.left.equalToSuperview().offset(8)
                make.right.equalToSuperview().offset(-8)
                make.bottom.equalToSuperview()
            }
        } else {
            cannotExportTipsLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(containView.snp.bottom).offset(0)
                make.left.equalToSuperview().offset(8)
                make.right.equalToSuperview().offset(-8)
                make.bottom.equalToSuperview()
                make.height.equalTo(0)
            }
        }
        cannotExportTipsLabel.isHidden = !show
    }

    @objc
    func openClick(_ button: UIButton) {
        guard config.buttonEnable else { return }
        self.delegate?.didClickOpenWith3rdApp(button: button)
    }
}


extension DKCardModeUnsupportView: DKViewModeChangable {
    func changeMode(_ mode: DrivePreviewMode, animate: Bool) {
        guard displayMode != mode else { return }
        displayMode = mode
        
        iconView.snp.updateConstraints { make in
            make.width.height.equalTo(iconSize)
        }
        
        titleLabel.snp.updateConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(iconLabelMargin)
        }

        titleLabel.font = titleFont
        descLabel.font = descFont
        let hideBtn = !config.buttonVisiable || (displayMode == .card)
        let size: CGSize = hideBtn ? .zero : buttonSize
        let margin: CGFloat = hideBtn ? 0 : labelBtnMargin
        openInOtherBtn.isHidden = hideBtn
        openInOtherBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: edgeInsets, bottom: 0, right: edgeInsets)
        openInOtherBtn.snp.updateConstraints { make in
            make.height.equalTo(size.height)
            make.top.equalTo(descLabel.snp.bottom).offset(margin)
        }
        openInOtherBtn.titleLabel?.font = btnFont
        
        if animate {
            UIView.animate(withDuration: 0.25) {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }
}
