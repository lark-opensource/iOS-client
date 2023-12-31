//
//  EmptyListPlaceholderView.swift
//  DocsCommon
//
//  Created by weidong fu on 6/12/2017.
//

import Foundation
import SKResource
import SKFoundation
import UniverseDesignEmpty
import LarkSetting
import UniverseDesignColor
public protocol ErrorPageProtocol: AnyObject {
    func didClickReloadButton()
}
open class EmptyListPlaceholderView: UIView {
    public enum EmptyType: Int {
        case noNet = 1
        case trash
        case noList
        case noShareFolder
        case openFileFail
        case openFileWebviewFail// 通过webview打开文档失败
        case openFileOverTime
        case fileDeleted
        case noPermission
        case cancelLike
        case noResult
        case noSupport
        case empty
    }

    public private(set) lazy var emptyView: UDEmpty = {
        let emptyView = UDEmpty(config: .init(title: .init(titleText: ""),
                                              description: .init(descriptionText: ""),
                                              type: .noContent))
        return emptyView
    }()
    lazy var errCodeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UDColor.textPlaceholder
        return label
    }()
    weak public var delegate: ErrorPageProtocol?
    public override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        self.addSubview(emptyView)
        addSubview(errCodeLabel)
        errCodeLabel.snp.remakeConstraints { make in
            make.height.equalTo(22)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-42) // 设计稿并非safrarea
        }
        errCodeLabel.isHidden = true
        emptyView.snp.makeConstraints { (make) in
            make.centerX.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60) // 考虑到地下有个title，基于美观考虑，设计建议向上偏移60
        }
    }
    public func config(error: ErrorInfoStruct) {
        var config = emptyConfig(for: error.type)
        config.description = .init(descriptionText: error.title ?? "")
        if delegate != nil {
            config.primaryButtonConfig = (BundleI18n.SKResource.LarkCCM_Docs_ErrorRefresh_Button_Mob, { [weak self] (_) in
                guard let self = self else {
                    DocsLogger.error("refresh error, self is nil")
                    return
                }
                guard let dele = self.delegate else {
                    DocsLogger.error("refresh error, self.delegate is nil")
                    return
                }
                DocsLogger.info("tap failView to reload")
                dele.didClickReloadButton()
            })
        }
        emptyView.update(config: config)
        if let errCode = error.domainAndCode {
            errCodeLabel.isHidden = false
            errCodeLabel.text = BundleI18n.SKResource.LarkCCM_Docs_ErrorCode_Mob(errCode.0 + errCode.1)
        } else {
            errCodeLabel.isHidden = true
        }
        return
    }
    
    public func config(_ config: UDEmptyConfig) {
        emptyView.update(config: config)

        emptyView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            //距离顶部1/4
            make.top.equalTo(self.snp.bottom).multipliedBy(0.25)
            make.left.right.equalToSuperview()
        }
    }

    func emptyConfig(for emptyType: EmptyType) -> UDEmptyConfig {
        var config = UDEmptyConfig(type: .noFile)
        switch emptyType {
        case .noList, .noShareFolder:
            config.type = .noFile
        case .noNet:
            config.type = .noWifi
        case .noPermission:
            config.type = .noAccess
        case .cancelLike:
            config.type = .noContact
        case .noResult:
            config.type = .searchFailed
            
        case .openFileFail, .openFileWebviewFail, .openFileOverTime:
            config.type = .loadingFailure
            
        case .trash:
            config.type = .vcRecycleBin
        case .fileDeleted, .empty:
            config.type = .noContent
        case .noSupport:
            config.type = .noPreview
        }
        
        return config
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
