//
//  DriveOpenFailedView.swift
//  SpaceKit
//
//  Created by liweiye on 2019/7/26.
//swiftlint:disable cyclomatic_complexity

import Foundation
import UIKit
import SKCommon
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignButton

enum DriveImportFailedViewType: Equatable {
    case importFailedRetry              // 导入失败，请重试
    case contactService                 // 联系客服
    case unsupportType                  // 不支持的文件格式
    case unsupportEncryptFile           // 不支持加密文件
    case networkInterruption            // 网络中断，请重试
    case noPermission                   // 无权限
    case numberOfFileExceedsTheLimit    // 文档数已超过限额
    case fileSizeOverLimit              // 文件大小超过限制
    case amountExceedLimit              // 数量超过系统上限
    case hierarchyExceedLimit           // 层级超过系统上限
    case sizeExceedLimit                // 大小超过系统上限
    case spaceBillingUnavailable        // 云盘存储空间不足
    case mountNotExist                  // 目标目录不存在
    case importFileSizeZero             // 文档没有内容
    case importTooLarge                 // 导入内容过多
    case dataLockedForMigration         // 数据迁移中，内容被锁定
    case unavailableForCrossTenantGeo   // 合规-同品牌的跨租户跨Geo
    case unavailableForCrossBrand       // 合规-跨品牌不允许
    case dlpCheckedFailed(String)       //dlp检测失败
    case dlpChecking(String)            //dlp检测中
    case dlpExternalDetcting   // 外部租户DLP拦截
    case dlpExternalSensitive //外部租户dlp拦截
}

class DriveImportFailedView: UIView {

    private(set) var type: DriveImportFailedViewType?
    var retryAction: (() -> Void)?
    var fileSizeText: String?

    var buttonEnable: Bool = true {
        didSet {
            let buttonThemeColor = buttonEnable ? UDEmpty.primaryColor : UDEmpty.primaryDisableColor
            failedView.primaryButtonConfig = UDButtonUIConifg(normalColor: buttonThemeColor, type: .middle)
            guard let type = type else { return }
            render(type: type)
        }
    }
    
    private lazy var emptyConfig: UDEmptyConfig = {
        let config = UDEmptyConfig(title: .init(titleText: ""),
                                   description: .init(descriptionText: ""),
                                   type: .loadingFailure,
                                   labelHandler: nil,
                                   primaryButtonConfig: nil,
                                   secondaryButtonConfig: nil)
        return config
    }()
    
    private(set) lazy var failedView: UDEmpty = {
        let failedView = UDEmpty(config: emptyConfig)
        return failedView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgBase
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func retryButtonClick(_ button: UIButton) {
        retryAction?()
    }

    deinit {
        DocsLogger.driveInfo("DriveOpenFailedView-----deinit")
    }
    
    private func setupSubviews() {
        addSubview(failedView)
        failedView.snp.makeConstraints { (make) in
            make.center.left.right.equalToSuperview()
        }
    }
}

// MARK: - Public
extension DriveImportFailedView {
    func render(type: DriveImportFailedViewType) {
        self.type = type
        var title = ""
        var description = ""
        var buttonTitle: String?
        switch type {
        case .importFailedRetry:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedRetry
            buttonTitle = BundleI18n.SKResource.Drive_Drive_Retry
        case .contactService:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedSupport
            buttonTitle = BundleI18n.SKResource.Drive_Drive_ImportContactSupport
        case .networkInterruption:
            title = BundleI18n.SKResource.Dirve_Drive_ImportNoNetwork
            buttonTitle = BundleI18n.SKResource.Drive_Drive_Retry
        case .noPermission:
            title = BundleI18n.SKResource.Drive_Drive_ImportNoPermisson
        case .unsupportType:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedByType
            description = fileSizeText ?? ""
        case .unsupportEncryptFile:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedByEncrypt
        case .numberOfFileExceedsTheLimit:
            title = BundleI18n.SKResource.Drive_Drive_NumberExceededQuota
            description = BundleI18n.SKResource.Drive_Drive_NumberExceededQuotaTips
            buttonTitle = BundleI18n.SKResource.Drive_Drive_NotifyAdministratorToUpgrade
        case .fileSizeOverLimit:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedBySize(String(DriveConvertFileConfig.fileSizeLimit))
            description = fileSizeText ?? ""
        case .amountExceedLimit:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedRetry
            description = BundleI18n.SKResource.CreationMobile_DocX_import_7000
        case .hierarchyExceedLimit:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedRetry
            description = BundleI18n.SKResource.CreationMobile_DocX_import_7001
        case .sizeExceedLimit:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedRetry
            description = BundleI18n.SKResource.CreationMobile_DocX_import_7002
        case .spaceBillingUnavailable:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedRetry
            description = BundleI18n.SKResource.CreationMobile_DocX_import_failed_NoSpace
        case .mountNotExist:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedRetry
            description = BundleI18n.SKResource.CreationMobile_DocX_import_failed_Nonexist
        case .importFileSizeZero:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedRetry
            description = BundleI18n.SKResource.CreationMobile_import_error_empty
        case .importTooLarge:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedRetry
            description = BundleI18n.SKResource.CreationMobile_DocX_import_failed_TooLarge
        case .dataLockedForMigration:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedRetry
            description = BundleI18n.SKResource.CreationMobile_MultiGeo_900004230
        case .unavailableForCrossTenantGeo:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedRetry
            description = BundleI18n.SKResource.CreationMobile_MultiGeo_900004510
        case .unavailableForCrossBrand:
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedRetry
            description = BundleI18n.SKResource.CreationMobile_MultiGeo_900004511
        case let .dlpCheckedFailed(text):
            title = text
        case let .dlpChecking(text):
            title = text
        default: 
            title = BundleI18n.SKResource.Drive_Drive_ImportFailedSupport
            buttonTitle = BundleI18n.SKResource.Drive_Drive_ImportContactSupport
        }
        
        var primaryButtonConfig: (String?, (UIButton) -> Void)?
        if let buttonTitle = buttonTitle {
            primaryButtonConfig = (buttonTitle, { [weak self] button in
                guard let self = self else { return }
                guard self.buttonEnable else { return }
                self.retryButtonClick(button)
            })
        }
        emptyConfig.title = .init(titleText: title)
        emptyConfig.description = .init(descriptionText: description)
        emptyConfig.primaryButtonConfig = primaryButtonConfig
        failedView.update(config: emptyConfig)
    }
}
