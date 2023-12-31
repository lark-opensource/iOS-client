//
//  DriveUnSupportFileView.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/16.
//

import UIKit
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignButton

protocol DriveUnSupportFileViewDelegate: AnyObject {
    func didClickOpenWith3rdApp(button: UIButton)
}

enum DriveUnsupportPreviewType {
    case typeUnsupport
    case sizeTooBig
    case sizeIsZero
    case typeUnsupportInArchive
    case fileRenderFailed
    case notRealType // 文件类型不真实，可能是文件后缀被修改
    case fileEncrypt
    case imfileEncrypted // IM文件被加密，如IP-Guard等
    case unknown(rawValue: Int?)

    init(previewStatus: Int?) {
        switch previewStatus {
        case 4:
            self = .typeUnsupport
        case 5:
            self = .sizeTooBig
        case 6:
            self = .sizeIsZero
        case 9:
            self = .fileEncrypt
        default:
            DocsLogger.error("Drive.UnsupportPreviewType --- Unknown unsupport preview type from server, rawValue: \(String(describing: previewStatus))")
            self = .unknown(rawValue: previewStatus)
        }
    }

    init(previewStatus: DriveFilePreview.PreviewStatus) {
        switch previewStatus {
        case .unsupport:
            self = .typeUnsupport
        case .sizeTooBig:
            self = .sizeTooBig
        case .sizeIsZero:
            self = .sizeIsZero
        case .fileEncrypt:
            self = .fileEncrypt
        default:
            DocsLogger.error("Drive.UnsupportPreviewType --- Failed to convert DriveFilePreview.PreviewStatus to UnsupportPreviewType, rawValue: \(previewStatus.rawValue)")
            self = .unknown(rawValue: previewStatus.rawValue)
        }
    }
}

struct DriveUnSupportConfig {
    var fileName: String
    var fileType: String
    var fileSize: UInt64
    var buttonVisiable: Bool
    var buttonEnable: Bool
}

class DriveUnSupportFileView: UIView {

    weak var delegate: DriveUnSupportFileViewDelegate?

    private var unSupportType: DriveUnsupportPreviewType = .typeUnsupport
    private var config: DriveUnSupportConfig
    private var displayMode: DrivePreviewMode = .normal

    private lazy var contentView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()

    private lazy var emptyView: UDEmpty = {
        let emptyView = UDEmpty(config: emptyConfig)
        return emptyView
    }()
    private lazy var emptyConfig: UDEmptyConfig = {
        let config = UDEmptyConfig(type: .noPreview)
        return config
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

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBase
        cannotExportTipsLabel.isHidden = true
        addSubview(contentView)

        contentView.addSubview(cannotExportTipsLabel)
        contentView.addSubview(emptyView)

        contentView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60)
            make.width.equalToSuperview()
        }

        emptyView.snp.makeConstraints { (make) in
            make.center.left.right.equalToSuperview()
        }

        cannotExportTipsLabel.snp.makeConstraints { (make) in
            make.top.equalTo(emptyView.snp.bottom).offset(0)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview()
            make.height.equalTo(0)
        }
    }

    private func updateLayout() {
        // 横屏下居中展示
        let offset = LKDeviceOrientation.isLandscape() ? 0 : -60
        contentView.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(offset)
            make.width.equalToSuperview()
        }
    }

    func setUnsupportType(type: DriveUnsupportPreviewType, config: DriveUnSupportConfig) {
        self.unSupportType = type
        self.config = config
        let (title, description) = Self.titleAndSubTitle(type: type, config: config)
        if config.buttonVisiable {
            emptyConfig.primaryButtonConfig = (BundleI18n.SKResource.Drive_Drive_OpenWithOtherApps, { [weak self] button in
                guard config.buttonEnable else { return }
                self?.delegate?.didClickOpenWith3rdApp(button: button)
            })
        } else {
            emptyConfig.primaryButtonConfig = nil
        }
        emptyConfig.title = .init(titleText: title)
        emptyConfig.description = .init(descriptionText: description)
        emptyView.update(config: emptyConfig)
    }

    func setPreviewButton(visiable: Bool) {
        guard config.buttonVisiable != visiable else { return }
        config.buttonVisiable = visiable
        setUnsupportType(type: unSupportType, config: config)
    }

    func setPreviewButton(enable: Bool) {
        guard config.buttonEnable != enable else { return }
        config.buttonEnable = enable
        let buttonThemeColor = enable ? UDEmpty.primaryColor : UDEmpty.primaryDisableColor
        emptyView.primaryButtonConfig = UDButtonUIConifg(normalColor: buttonThemeColor, type: .middle)
        setUnsupportType(type: unSupportType, config: config)
    }

    func showExportTips(_ show: Bool) {
        if show {
            cannotExportTipsLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(emptyView.snp.bottom).offset(10)
                make.left.equalToSuperview().offset(8)
                make.right.equalToSuperview().offset(-8)
                make.bottom.equalToSuperview()
            }
        } else {
            cannotExportTipsLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(emptyView.snp.bottom).offset(0)
                make.left.equalToSuperview().offset(8)
                make.right.equalToSuperview().offset(-8)
                make.bottom.equalToSuperview()
                make.height.equalTo(0)
            }
        }
        cannotExportTipsLabel.isHidden = !show
    }

}

extension DriveUnSupportFileView {
    static func memoryFormat(_ byte: UInt64) -> String {
        var size = Double(byte)
        let unit = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "BB"]
        var index: Int = 0
        while size >= 1024 && (index + 1) < unit.count {
            size /= 1024
            index += 1
        }
        return String(format: "%.2f", Double(size)) + unit[index]
    }

    static func titleAndSubTitle(type: DriveUnsupportPreviewType, config: DriveUnSupportConfig) -> (title: String, description: String) {
        let content: String
        let needType: Bool
        var description = memoryFormat(config.fileSize)
        switch type {
        case .typeUnsupport:
            content = BundleI18n.SKResource.Drive_Drive_PreviewTypeUnsupport
            needType = true
        case .sizeTooBig:
            content = BundleI18n.SKResource.Drive_Drive_PreviewOversize
            needType = false
        case .sizeIsZero:
            content = BundleI18n.SKResource.Drive_Drive_PreviewSizeZero
            description = ""
            needType = false
        case .typeUnsupportInArchive:
            content = BundleI18n.SKResource.Drive_Drive_PreviewUnsupportInArchive(config.fileType)
            description = BundleI18n.SKResource.Drive_Drive_OpenArchiveWithOtherApp(config.fileName)
            needType = false
        case .fileRenderFailed:
            content = BundleI18n.SKResource.Drive_Drive_File_Preview_Failed
            description = ""
            needType = false
        case .unknown(let rawValue):
            DocsLogger.error("Drive.Preview.Unsupport --- Unknown Preview Type From Server: \(String(describing: rawValue))")
            content = BundleI18n.SKResource.Drive_Drive_PreviewTypeUnsupport
            needType = true
        case .notRealType:
            content = BundleI18n.SKResource.CreationMobile_Preview_ExtensionMismatch_placeholder
            needType = false
        case .fileEncrypt:
            content = BundleI18n.SKResource.CreationMobile_Docs_decompress_encrypted
            needType = false
        case .imfileEncrypted:
            content = BundleI18n.SKResource.Lark_IM_OpenFile_CantPreviewCorrupteEncrypted_Mobile_Text
            needType = false
        }
    
        var title = content
        if !config.fileType.isEmpty && needType {
            title = "\(title).\(config.fileType)"
        }
        return (title, description)
    }
}
