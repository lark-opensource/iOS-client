//
//  AppSettingCell.swift
//  LarkAppCenter
//
//  Created by yuanping on 2019/4/20.
//

import LarkUIKit
import EEMicroAppSDK
import FigmaKit
import UniverseDesignIcon

enum AppSettingCellType: String {
    case TopView
    case Developer
    case Feedback
    case PermissionComment
    case Permission
    case UserAgreement
    case PrivacyPolicy
    case AppSettingHeader
    case AppSettingCell
    case AppSettingSubtitleCell
    case UnModPermission
    case AppBadgeCell
    case ReportApp
}

class AppSettingCell: UITableViewCell {

    struct AppLogoSize {
        let width: CGFloat = 59
        let height: CGFloat = 59
    }

    /// 权限名标签
    private lazy var title: UILabel = {
        let title = UILabel(frame: .zero)
        title.font = UIFont.systemFont(ofSize: 16.0)
        title.textColor = UIColor.ud.textTitle
        title.textAlignment = .left
        return title
    }()

    /// 通知提醒 标签
    private lazy var notificationLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        return label
    }()
    
    /// 红点的副标题
    private lazy var appBadgeSubtitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()

    /// cell 的副标题
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 4
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()

    /// 一方应用标签
    private lazy var unModPermissionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    ///  举报应用标签
    lazy var reportAppLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        return label
    }()
    
    /// 描述标签
    private lazy var descLabel: UILabel = {
        let description = UILabel(frame: .zero)
        description.numberOfLines = 2
        description.textColor = UIColor.ud.textPlaceholder
        description.font = UIFont.systemFont(ofSize: 14.0)
        description.textAlignment = .right
        description.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return description
    }()

    /// isv 图片
    private lazy var isvImage: UIImageView = {
        let isv = UIImageView(frame: .zero)
        isv.image = BundleResources.LarkOpenPlatform.AppDetail.isv_developer
        isv.clipsToBounds = true
        return isv
    }()

    private lazy var moreImg: UIImageView = {
        let more = UIImageView(frame: .zero)
        more.image = UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.iconN3)
        more.clipsToBounds = true
        return more
    }()

    /// 权限开关
    private lazy var permissionSwitch: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = UIColor.ud.primaryContentDefault
        sw.addTarget(self, action: #selector(permissionChanged(sender:)), for: .valueChanged)
        return sw
    }()

    /// 通知提醒开关
    private lazy var notificationSwitch: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = UIColor.ud.primaryContentDefault
        sw.addTarget(self, action: #selector(notificationChanged(sender:)), for: .valueChanged)
        return sw
    }()

    /// 通知提醒 header
    private lazy var permissionComment: UILabel = {
        let permissionComment = UILabel(frame: .zero)
        permissionComment.textColor = UIColor.ud.textPlaceholder
        permissionComment.numberOfLines = 2
        permissionComment.font = UIFont.systemFont(ofSize: 12.0)
        return permissionComment
    }()

    /// 应用设置 label
    private lazy var appSettingLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 12.0)
        return label
    }()

    /// 分割线
    private lazy var splitLine: UIView = {
        let splitView = UIView(frame: .zero)
        splitView.backgroundColor = UIColor.ud.lineDividerDefault
        return splitView
    }()

    private lazy var appLogoImgView: UIImageView = {
        let resultImgView: UIImageView = UIImageView(frame: .zero)
        resultImgView.backgroundColor = UIColor.ud.bgFiller
        resultImgView.clipsToBounds = true
        resultImgView.contentMode = UIView.ContentMode.scaleAspectFit
        return resultImgView
    }()

    private lazy var appNameLabel: UILabel = {
        let appName = UILabel(frame: .zero)
        appName.textColor = UIColor.ud.textTitle
        appName.numberOfLines = 2
        appName.textAlignment = .center
        appName.font = UIFont.boldSystemFont(ofSize: 20.0)
        return appName
    }()

    private let const = AppLogoSize()
    private var appSettingModel: AppSettingViewModel?
    private var curCellIndex: Int?
    private var curCellType: AppSettingCellType?
    private var isLargeSplit: Bool = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initSubViews() {
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.ud.fillHover
        selectionStyle = .none
        
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(title)
        title.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.leading.equalToSuperview().offset(16)
        }
        title.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        /// 通知标签布局
        contentView.addSubview(notificationLabel)
        notificationLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.leading.equalToSuperview().offset(16)
        }

        contentView.addSubview(descLabel)
        descLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(title)
            make.trailing.equalToSuperview().offset(-16)
        }
        descLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        contentView.addSubview(isvImage)
        isvImage.snp.makeConstraints { (make) in
            make.width.height.equalTo(0)
            make.leading.greaterThanOrEqualToSuperview().offset(152)
            make.top.equalToSuperview().offset(19)
            make.trailing.equalTo(descLabel.snp.leading)
        }
        isvImage.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        contentView.addSubview(moreImg)
        moreImg.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(permissionSwitch)
        permissionSwitch.snp.makeConstraints { (make) in
            make.centerY.equalTo(title)
            make.trailing.equalToSuperview().offset(-16)
        }

        /// 通知开关布局
        contentView.addSubview(notificationSwitch)
        notificationSwitch.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }

        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(notificationLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(notificationSwitch.snp.leading).offset(-24)
        }
        
        contentView.addSubview(appBadgeSubtitleLabel)
        appBadgeSubtitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(title.snp.bottom).offset(11)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(notificationSwitch.snp.leading).offset(-28)
        }

        contentView.addSubview(permissionComment)
        permissionComment.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        contentView.addSubview(unModPermissionLabel)
        unModPermissionLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview().offset(-4)
        }
        
        // 举报应用布局
        contentView.addSubview(reportAppLabel)
        reportAppLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        /// 应用设置标签布局
        contentView.addSubview(appSettingLabel)
        appSettingLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }

        /// 分割线布局
        contentView.addSubview(splitLine)
        splitLine.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        contentView.addSubview(appLogoImgView)
        appLogoImgView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(const.height)
            make.top.equalToSuperview().offset(34)
        }

        contentView.addSubview(appNameLabel)
        appNameLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(appLogoImgView.snp.bottom).offset(16)
        }

        resetViews()
    }

    private func resetViews() {
        title.isHidden = true
        notificationLabel.isHidden = true
        descLabel.isHidden = true
        moreImg.isHidden = true
        permissionSwitch.isHidden = true
        notificationSwitch.isHidden = true
        permissionComment.isHidden = true
        appSettingLabel.isHidden = true
        splitLine.isHidden = true
        isvImage.isHidden = true
        appLogoImgView.isHidden = true
        appNameLabel.isHidden = true
        subtitleLabel.isHidden = true
        unModPermissionLabel.isHidden = true
        appBadgeSubtitleLabel.isHidden = true
        reportAppLabel.isHidden = true
        isLargeSplit = false
    }

    @objc
    private func permissionChanged(sender: UISwitch) {
        if curCellType == .AppBadgeCell, let model = appSettingModel, let badgeModel = model.appBadgePermissionData {
            model.updatePermission(scope: badgeModel.scope, isGranted: sender.isOn)
        } else {
            guard let model = appSettingModel, let index = curCellIndex, let permission = model.permissionStateAt(index: index)?.permission else { return }
            model.updatePermission(scope: permission.scope, isGranted: sender.isOn)
        }
    }

    @objc
    private func notificationChanged(sender: UISwitch) {
        if curCellType == .AppSettingSubtitleCell && !BDPAuthorization.authorizationFree() {
            guard let model = appSettingModel, let permission = model.appBadgeData() else { return }
            model.updatePermission(scope: "appBadge", isGranted: sender.isOn)
        } else {
            appSettingModel?.updateNotificationWith(isOn: sender.isOn)
        }
    }

    func updateCellType(model: AppSettingViewModel, type: AppSettingCellType, index: Int) {
        // 重置
        curCellIndex = index
        curCellType = type
        appSettingModel = model
        splitLine.backgroundColor = UIColor.ud.lineDividerDefault
        splitLine.snp.remakeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        descLabel.textColor = UIColor.ud.textPlaceholder
        descLabel.textAlignment = .right
        isvImage.snp.remakeConstraints { (make) in
            make.width.height.equalTo(0)
            make.top.equalToSuperview().offset(19)
            if model.isSingleDeveloperInfo() {
                make.leading.greaterThanOrEqualToSuperview().offset(152)
            } else {
                make.leading.equalToSuperview().offset(152)
            }
            make.trailing.equalTo(descLabel.snp.leading).offset(0)
        }
        resetViews()

       contentView.backgroundColor = UIColor.ud.bgBody
        let hasPermissionData = !(model.permissionData?.isEmpty ?? true)
        switch type {
        case .TopView:
            splitLine.isHidden = false
            splitLine.backgroundColor = UIColor.ud.bgBase
            isLargeSplit = true
            splitLine.snp.remakeConstraints { (make) in
                make.bottom.leading.trailing.equalToSuperview()
                make.height.equalTo(8)
            }
            appLogoImgView.isHidden = false
            appLogoImgView.bt.setLarkImage(with: .avatar(key: model.appDetailInfo?.avatar ?? "",
                                                         entityID: model.appDetailInfo?.appId ?? "",
                                                         params: .init(sizeType: .size(max(const.width, const.height)))
            ))
            appLogoImgView.layer.ux.setSmoothCorner(radius: 14)
            appLogoImgView.layer.ux.setSmoothBorder(width: 1.5, color: UIColor.ud.lineDividerDefault)
            appNameLabel.isHidden = false
            appNameLabel.text = model.appDetailInfo?.getLocalTitle()
        case .Developer:
            title.isHidden = false
            title.text = BundleI18n.AppDetail.AppDetail_Setting_Developer
            descLabel.isHidden = false
            descLabel.textAlignment = model.isSingleDeveloperInfo() ? .right : .left
            descLabel.text = model.appDetailInfo?.getLocalDeveloperInfo()
            if !(model.appDetailInfo?.developerId ?? "").isEmpty, !(model.appDetailInfo?.isISV() ?? false) {
                descLabel.textColor = UIColor.ud.primaryContentDefault
            }
            isvImage.isHidden = !(model.appDetailInfo?.isISV() ?? false)
            if model.appDetailInfo?.isISV() ?? false {
                isvImage.snp.remakeConstraints { (make) in
                    make.width.height.equalTo(14)
                    make.centerY.equalTo(title)
                    if model.isSingleDeveloperInfo() {
                        make.leading.greaterThanOrEqualToSuperview().offset(152)
                    } else {
                        make.leading.equalToSuperview().offset(152)
                    }
                    make.trailing.equalTo(descLabel.snp.leading).offset(-8)
                }
            }
            if !model.isShowAppSettingHeader,
                model.permissionData?.isEmpty ?? true,
                (!(model.appDetailInfo?.getLocalClauseUrl() ?? "").isEmpty || !(model.appDetailInfo?.getLocalPrivacyUrl() ?? "").isEmpty) {
                splitLine.isHidden = false
                splitLine.backgroundColor = UIColor.ud.bgBase
                isLargeSplit = true
                splitLine.snp.remakeConstraints { (make) in
                    make.bottom.leading.trailing.equalToSuperview()
                    make.height.equalTo(8)
                }
            }
            selectionStyle = (descLabel.textColor == UIColor.ud.primaryContentDefault ? .default : .none)
        case .Feedback:
            selectionStyle = .default
            title.isHidden = false
            title.text = BundleI18n.AppDetail.AppDetail_Setting_Feedback
            moreImg.isHidden = false
            if model.permissionData?.isEmpty ?? true,
                (!(model.appDetailInfo?.getLocalClauseUrl() ?? "").isEmpty || !(model.appDetailInfo?.getLocalPrivacyUrl() ?? "").isEmpty) {
                splitLine.isHidden = false
                splitLine.backgroundColor = UIColor.ud.bgBase
                isLargeSplit = true
                splitLine.snp.remakeConstraints { (make) in
                    make.bottom.leading.trailing.equalToSuperview()
                    make.height.equalTo(8)
                }
            }
        case .UnModPermission:
            unModPermissionLabel.isHidden = false

            let appAuthExemptAuthText = BundleI18n.AppDetail.LittleApp_AppAuth_ExemptAuthorization()
            unModPermissionLabel.setText(appAuthExemptAuthText, lineSpacing: 3)
            /// 阴影
            splitLine.isHidden = false
            splitLine.backgroundColor = UIColor.ud.bgBase
            isLargeSplit = true
            splitLine.snp.remakeConstraints { (make) in
                make.bottom.leading.trailing.equalToSuperview()
                make.height.equalTo(8)
            }
        case .PermissionComment:
            permissionComment.isHidden = false
            permissionComment.text = BundleI18n.AppDetail.AppDetail_Setting_PermissionTitle(app_name: model.appDetailInfo?.getLocalTitle() ?? "")
            contentView.backgroundColor = UIColor.ud.bgBase
        case .AppSettingHeader:
            appSettingLabel.isHidden = false
            appSettingLabel.text = BundleI18n.AppDetail.AppDetail_Setting_Settings
            contentView.backgroundColor = UIColor.ud.bgBase
        case .Permission:
            let permissionState = model.permissionStateAt(index: index)
            guard let curPermission = permissionState else { break }
            let permission = curPermission.permission
            title.isHidden = false
            title.text = permission.name
            permissionSwitch.isHidden = false
            permissionSwitch.isOn = permission.isGranted
            splitLine.isHidden = false
            if curPermission.isLastPermission {
                splitLine.backgroundColor = UIColor.ud.bgBase
                isLargeSplit = true
                splitLine.snp.remakeConstraints { (make) in
                    make.bottom.leading.trailing.equalToSuperview()
                    make.height.equalTo(8)
                }
            }
        case .AppSettingCell:
            notificationLabel.isHidden = false
            notificationLabel.text = BundleI18n.AppDetail.AppDetail_Setting_Notifications
            notificationSwitch.isHidden = false
            /// 处理通知提醒开关
            if let showNotificationCell = model.appDetailInfo?.notificationType,
                showNotificationCell == .Open {
                notificationSwitch.isOn = true
            } else {
                notificationSwitch.isOn = false
            }
            /// 阴影
            splitLine.isHidden = false
            if let curPermission = model.appBadgeData() {
                notificationSwitch.snp.remakeConstraints { (make) in
                    make.centerY.equalToSuperview()
                    make.trailing.equalToSuperview().offset(-16)
                }
                notificationLabel.snp.makeConstraints { (make) in
                    make.center.equalToSuperview()
                    make.leading.equalToSuperview().offset(16)
                }
            } else {
                if !hasPermissionData {
                    // 权限header隐藏的情况下才需要显示大分割
                    splitLine.isHidden = false
                    splitLine.backgroundColor = UIColor.ud.bgBase
                    isLargeSplit = true
                    splitLine.snp.remakeConstraints { (make) in
                        make.bottom.leading.trailing.equalToSuperview()
                        make.height.equalTo(8)
                    }
                    notificationSwitch.snp.remakeConstraints { (make) in
                        make.centerY.equalToSuperview().offset(-4)
                        make.trailing.equalToSuperview().offset(-16)
                    }
                    notificationLabel.snp.makeConstraints { (make) in
                        make.center.equalToSuperview().offset(-4)
                        make.leading.equalToSuperview().offset(16)
                    }
                } else {
                    notificationSwitch.snp.remakeConstraints { (make) in
                        make.centerY.equalToSuperview()
                        make.trailing.equalToSuperview().offset(-16)
                    }
                    notificationLabel.snp.makeConstraints { (make) in
                        make.center.equalToSuperview()
                        make.leading.equalToSuperview().offset(16)
                    }
                }
                
            }
        case .AppSettingSubtitleCell:
            guard let curItem = model.appBadgeData() else { break }
            subtitleLabel.isHidden = false
            notificationLabel.isHidden = false
            notificationLabel.text = curItem.name
            notificationSwitch.isHidden = false
            notificationSwitch.isOn = curItem.isGranted
            subtitleLabel.text = BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_EnableBadge
            /// 阴影
            if !hasPermissionData {
                // 权限header隐藏的情况下才需要显示大分割
                splitLine.isHidden = false
                splitLine.backgroundColor = UIColor.ud.bgBase
                isLargeSplit = true
                splitLine.snp.remakeConstraints { (make) in
                    make.bottom.leading.trailing.equalToSuperview()
                    make.height.equalTo(8)
                }
            }
            notificationSwitch.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview().offset(-4)
                make.trailing.equalToSuperview().offset(-16)
            }
        case .AppBadgeCell:
            guard let appBadgePermissionData = appSettingModel?.appBadgeData() else { break }
            title.isHidden = false
            title.text = appBadgePermissionData.name
            permissionSwitch.isHidden = false
            permissionSwitch.isOn = appBadgePermissionData.isGranted
            permissionSwitch.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview().offset(-4)
                make.trailing.equalToSuperview().offset(-16)
            }
            title.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(16)
                make.leading.equalToSuperview().offset(16)
            }
            appBadgeSubtitleLabel.isHidden = false
            let text = BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_EnableBadge
            appBadgeSubtitleLabel.setText(text, lineSpacing: 6)
            if !hasPermissionData {
                // 权限header隐藏的情况下才需要显示大分割
                splitLine.isHidden = false
                splitLine.backgroundColor = UIColor.ud.bgBase
                isLargeSplit = true
                splitLine.snp.remakeConstraints { (make) in
                    make.bottom.leading.trailing.equalToSuperview()
                    make.height.equalTo(8)
                }
            }
        case .UserAgreement:
            selectionStyle = .default
            title.isHidden = false
            title.text = BundleI18n.AppDetail.AppDetail_Setting_UserAgreement
            moreImg.isHidden = false
            splitLine.isHidden = false
        case .PrivacyPolicy:
            selectionStyle = .default
            title.isHidden = false
            title.text = BundleI18n.AppDetail.AppDetail_Setting_PrivacyPolicy
            moreImg.isHidden = false
        case .ReportApp:
            reportAppLabel.isHidden = false
            reportAppLabel.text =  BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_AppReport
            contentView.backgroundColor = UIColor.ud.bgBase
        }
        if type != .AppBadgeCell {
            title.snp.remakeConstraints { make in
                if isLargeSplit {
                    // 如果包含了底部分割阴影，那么需要向上偏移，底部阴影是8
                    make.centerY.equalToSuperview().offset(-4)
                } else {
                    make.centerY.equalToSuperview()
                }
                make.leading.equalToSuperview().offset(16)
            }
        }
    }
}

extension UILabel {
    fileprivate func setText(_ text: String, lineSpacing height: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = height
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attrString = NSMutableAttributedString(string: text)
        attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.count))
        self.attributedText = attrString
    }
}
