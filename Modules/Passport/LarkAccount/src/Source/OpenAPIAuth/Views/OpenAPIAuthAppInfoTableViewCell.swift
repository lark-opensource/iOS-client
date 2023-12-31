//
//  OpenAPIAuthAppInfoTableViewCell.swift
//  LarkAccount
//
//  Created by au on 2023/6/7.
//

import Kingfisher
import UIKit
import UniverseDesignFont

class OpenAPIAuthAppInfoTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configCell(authInfo: OpenAPIAuthGetAuthInfo) {

        // 双向箭头 icon
        let connectorView = UIImageView(image: SSOVerifyResources.app_connector.ud.withTintColor(UIColor.ud.iconN3))
        contentView.addSubview(connectorView)
        connectorView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(36)
            make.width.height.equalTo(14)
        }

        // 外部应用图标
        let appIconView = UIImageView()
        appIconView.layer.cornerRadius = Common.Layer.commonAppIconRadius
        appIconView.layer.borderWidth = 1
        appIconView.ud.setLayerBorderColor(UIColor.ud.bgFiller)
        appIconView.clipsToBounds = true
        if let urlString = authInfo.appInfo?.appIconURL, let url = URL(string: urlString) {
            appIconView.kf.setImage(with: url, placeholder: DynamicResource.default_avatar)
        } else {
            appIconView.image = DynamicResource.default_avatar
        }
        contentView.addSubview(appIconView)
        appIconView.snp.makeConstraints { make in
            make.centerY.equalTo(connectorView)
            make.width.height.equalTo(48)
            make.right.equalTo(connectorView.snp.left).offset(-24)
        }

        // 飞书或套件图标
        let larkIconView = UIImageView()
        larkIconView.layer.cornerRadius = Common.Layer.commonAppIconRadius
        larkIconView.layer.borderWidth = 1
        larkIconView.ud.setLayerBorderColor(UIColor.ud.bgFiller)
        larkIconView.clipsToBounds = true
        larkIconView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        if let base64String = authInfo.suiteInfo?.suiteIconURL, let suiteName = authInfo.suiteInfo?.suiteName {
            let cacheKey = "auth-suite-icon-\(suiteName)-\(Date().timeIntervalSince1970)"
            let provider = SafeBase64ImageDataProvider(base64String: base64String, cacheKey: cacheKey)
            larkIconView.kf.setImage(with: provider, placeholder: BundleResources.AppResourceLogo.logo)
        } else {
            larkIconView.image = BundleResources.AppResourceLogo.logo
        }
        contentView.addSubview(larkIconView)
        larkIconView.snp.makeConstraints { make in
            make.centerY.equalTo(connectorView)
            make.width.height.equalTo(48)
            make.left.equalTo(connectorView.snp.right).offset(24)
        }

        let titleLabel = UILabel()
        titleLabel.text = I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_Title(authInfo.appInfo?.appName ?? "")
        titleLabel.font = UDFont.title3
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(appIconView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
    }

}

/// Kingfisher 内置的 Base64ImageDataProvider 会对 Data(base64Encoded:) 进行强制解包，当出现问题时会造成 app 崩溃
/// 此处另行实现一个 provider
struct SafeBase64ImageDataProvider: ImageDataProvider {

    public let base64String: String

    // MARK: Initializers

    public init(base64String: String, cacheKey: String) {
        self.base64String = base64String
        self.cacheKey = cacheKey
    }

    // MARK: Protocol Conforming

    public var cacheKey: String

    public func data(handler: (Result<Data, Error>) -> Void) {
        if let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) {
            handler(.success(data))
        } else {
            handler(.failure(V3LoginError.badLocalData("Cannot handle base64 String")))
        }
    }
}
