//
//  AuthTypeViewModel.swift
//  LarkAccount
//
//  Created by bytedance on 2021/7/26.
//

import Foundation
import RxSwift
import Homeric
import LarkContainer
import ByteWebImage
import UniverseDesignColor
import UniverseDesignIcon

class AuthTypeViewModel: V3ViewModel {
    let title: String
    let authTypeInfo: AuthTypeInfo
    var detailString: NSAttributedString
    var dataSource: [AuthTypeCellData] = []

    init(
        step: String,
        stepInfo: AuthTypeInfo,
        context: UniContextProtocol
    ) {
        self.title = stepInfo.title
        self.detailString = V3ViewModel.attributedString(for: stepInfo.subtitle)
        self.authTypeInfo = stepInfo
        super.init(step: step, stepInfo: stepInfo, context: context)

        self.dataSource = self.generateAuthTypeList(stepInfo.authTypeList)
    }

    private func generateAuthTypeList(_ authTypeList: [Menu]) -> [AuthTypeCellData] {
        let result = authTypeList.map { item -> AuthTypeCellData in
            var image = UIImage()
            var iconUrl: String? = nil
            switch item.actionType {

            case .verifyEmail:
                image = BundleResources.UDIconResources.mailOutlined
            case .verifyMobile:
                image = BundleResources.UDIconResources.cellphoneOutlined
            case .verifyPwd:
                image = BundleResources.UDIconResources.lockOutlined
            case .verifySpareCode:
                image = BundleResources.UDIconResources.safePassOutlined
            case .verifyOTP:
                image = Resource.V3.otp_icon
            case .verifyAppleID:
                image = Resource.V3.appleId.ud.withTintColor(UIColor.ud.iconN1)
            case .verifyGoogle:
                image = Resource.V3.googleAccount
            case .verifyBIdp:
                image = Resource.V3.icon_sso_outlined_24
                iconUrl = authTypeInfo.targetTenantIcon
            case .verifyFIDO:
                image = BundleResources.UDIconResources.fidoOutlined
            default:
                image = Resource.V3.idpAccount.ud.withTintColor(UIColor.ud.iconN1)
            }
            return AuthTypeCellData(icon: image,
                                    iconUrl: iconUrl,
                                    title: item.text,
                                    subtitle: item.desc,
                                    action: { [weak self] in
                                        guard let self = self else { return .just(()) }
                                        if let step = item.next {
                                            return self.verifyPage(stepData: step)
                                        } else {
                                            return .just(())
                                        }
                                    })
            
        }
        return result
    }
    
    private func verifyPage(stepData: V4StepData) -> Observable<Void> {
        return Observable.create { ob -> Disposable in
            // 使用该方法post step，内部会带上self.context，防止在changeGeo场景出问题
            self.post(event: stepData.stepName ?? "",
                      stepInfo: stepData.stepInfo, 
                      additionalInfo: self.additionalInfo) {
                ob.onNext(())
                ob.onCompleted()
            } error: { error in
                ob.onError(error)
            }
            return Disposables.create()
        }
    }
}

struct AuthTypeCellData {
    let icon: UIImage
    let iconUrl: String?
    let title: String
    let subtitle: String
    let action: () -> Observable<Void>
}
// emailAccount
// phoneAccount
// googleAccount
// appleId

class AuthTypeCell: UITableViewCell {

    let container: V3CardContainerView

    var data: AuthTypeCellData? {
        didSet {
            if let iconUrl = data?.iconUrl {
                setImage(urlString: iconUrl, placeholder: Resource.V3.idpAccount.ud.withTintColor(UIColor.ud.iconN1))
            } else {
                avatarImageView.image = data?.icon ?? Resource.V3.idpAccount.ud.withTintColor(UIColor.ud.iconN1)
            }
            titleLabel.text = data?.title ?? ""
            subtitleLabel.text = data?.subtitle ?? ""
        }
    }

    private func setImage(urlString: String, placeholder: UIImage) {
        guard let url = URL(string: urlString) else {
            self.avatarImageView.image = placeholder
            return
        }
        self.avatarImageView.bt.setImage(with: url,
                                         placeholder: placeholder)
    }

    let avatarImageView: UIImageView = {
        let avatarImageView = UIImageView(frame: .zero)
        avatarImageView.layer.cornerRadius = Common.Layer.commonAvatarImageRadius
        avatarImageView.clipsToBounds = true
        return avatarImageView
    }()

    let arrowIconView: UIImageView = {
        let arrowIconView = UIImageView(frame: .zero)
        arrowIconView.image = BundleResources.UDIconResources.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        return arrowIconView
    }()

    let titleLabel: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.numberOfLines = 1
        lbl.font = UIFont.systemFont(ofSize: Layout.titileFontSize, weight: .medium)
        lbl.textColor = UDColor.textTitle
        lbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return lbl
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: Layout.subtitleFontSize, weight: .regular)
        label.numberOfLines = 0
        label.textColor = UDColor.textCaption
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.container = V3CardContainerView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.selectionStyle = .none
        contentView.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(Layout.cellMargin)
        }

        container.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(container)
            make.left.equalTo(container).offset(Layout.margin)
            make.size.lessThanOrEqualTo(CGSize(width: 32, height: 32))
        }

        //设置文字部分内容自适应居中
        let textContentView: UIStackView = UIStackView()
        container.addSubview(textContentView)
        textContentView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Layout.textLeft)
            make.right.equalToSuperview().offset(-Layout.textRight)
            make.top.equalToSuperview().inset(Layout.textMargin)
            make.bottom.equalToSuperview().inset(Layout.textMargin)
            make.centerY.equalToSuperview()
        }
        textContentView.axis = .vertical
        textContentView.spacing = 4
        textContentView.addArrangedSubview(titleLabel)
        textContentView.addArrangedSubview(subtitleLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.height.greaterThanOrEqualTo(Layout.titleMinHeight)
            make.right.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        container.addSubview(arrowIconView)
        arrowIconView.snp.makeConstraints { (make) in
            make.right.equalTo(container).offset(-Layout.margin)
            make.size.equalTo(CGSize(width: Layout.arrowIconWidth, height: Layout.arrowIconWidth))
            make.centerY.equalTo(container)
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSelection(_ selected: Bool) {
        container.updateSelection(selected)
    }

}

extension AuthTypeCell {
    fileprivate enum Layout {
        static let verticalSpace: CGFloat = 15
        static let titileFontSize: CGFloat = 16
        static let subtitleFontSize: CGFloat = 14
        static let textLeft = 52
        static let textRight = 39
        static let cellMargin = 6
        
        static let avatarWidth: CGFloat = 48
        static let tagItemSpace: CGFloat = 12
        static let tagHeight: CGFloat = 14
        static let nameHeight: CGFloat = 24
        static let tenantHeight: CGFloat = 20
        static let shadowHeight: CGFloat = 2
        static let rightMarginForTitleLabel = 30
        static let margin = 16
        static let arrowIconWidth = 17
        static let titleMidSpace = 4
        static let titleTopOrButtom = 21

        static let titleMinHeight = 24
        static let subtitleMinHeight = 20
        static let textMargin = 20

    }
}
