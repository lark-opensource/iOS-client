//
//  AppSettingVersionCell.swift
//  LarkAppCenter
//
//  Created by tujinqiu on 2020/2/5.
//

import LarkUIKit
import LarkLocalizations
import UIKit
import Lottie
import LKCommonsLogging

class AppSettingVersionLoadingView: UIView {

    let fetchMetaAnimationView: LOTAnimationView = {
        let jsonPath = BundleConfig.LarkOpenPlatformBundle.path(
            forResource: "app_version_fetch_meta",
            ofType: "json",
            inDirectory: "Lottie")
        let view = jsonPath.flatMap { LOTAnimationView(filePath: $0) } ?? LOTAnimationView()
        return view
    }()

    let appUpdateAnimationView: LOTAnimationView = {
        let jsonPath = BundleConfig.LarkOpenPlatformBundle.path(
            forResource: "app_version_update_app",
            ofType: "json",
            inDirectory: "Lottie")
        let view = jsonPath.flatMap { LOTAnimationView(filePath: $0) } ?? LOTAnimationView()
        return view
    }()


    let upgradeImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        fetchMetaAnimationView.loopAnimation = true
        addSubview(fetchMetaAnimationView)
        fetchMetaAnimationView.snp.makeConstraints { (make ) in
            make.edges.equalToSuperview()
        }

        appUpdateAnimationView.loopAnimation = true
        addSubview(appUpdateAnimationView)
        appUpdateAnimationView.snp.makeConstraints { (make ) in
            make.edges.equalToSuperview()
        }

        addSubview(upgradeImageView)
        upgradeImageView.snp.makeConstraints { (make ) in
            make.center.equalToSuperview()
            make.width.height.equalTo(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class AppSettingVersionStateView : UIView {
    static let logger = Logger.oplog(AppSettingVersionStateView.self, category: "app_setting")
    var appSettingVersionState: AppSettingVersionState {
        didSet {
            Self.logger.info("app setting version state view state change state:\(appSettingVersionState)")
            updateStateView()
        }
    }
    private lazy var contentView: UIView = {
        let view = UIView(frame: .zero)
        return view
    }()

    private lazy var loadingView: AppSettingVersionLoadingView = {
        let view = AppSettingVersionLoadingView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
        return view
    }()

    private lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.boldSystemFont(ofSize: 12.0)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.AppDetail.AppDetail_Setting_Downloading
        return label
    }()

    override init(frame: CGRect) {
        appSettingVersionState = .fetchingMeta
        super.init(frame: frame)

        contentView.layer.borderWidth = 0.5
        contentView.layer.cornerRadius = 3.0
        contentView.layer.masksToBounds = true

        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-5)
            make.centerY.equalToSuperview()
            make.height.equalTo(18)
            make.left.equalToSuperview().offset(5)
        }

        contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-4)
        }

        contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.right.equalTo(label.snp.left).offset(-4)
            make.width.height.equalTo(12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateStateView() {
        switch appSettingVersionState {
        case .fetchingMeta:
            contentView.backgroundColor = UIColor.ud.functionWarningFillSolid01
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenTagNeutralBgNormal)
            label.text = BundleI18n.LarkOpenPlatform.LittleApp_AppAuth_UpdateChecking
            label.textColor = UIColor.ud.udtokenTagTextSOrange
            loadingView.upgradeImageView.isHidden = true
            loadingView.appUpdateAnimationView.stop()
            loadingView.appUpdateAnimationView.isHidden = true
            loadingView.fetchMetaAnimationView.isHidden = false
            loadingView.fetchMetaAnimationView.play()
            loadingView.snp.updateConstraints { (make) in
                make.width.equalTo(12)
                make.right.equalTo(label.snp.left).offset(-4)
            }
        case .metaFailed:
            contentView.backgroundColor = UIColor.ud.udtokenTagBgOrange
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenTagBgOrange)
            label.text = BundleI18n.LarkOpenPlatform.LittleApp_AppAuth_UpdateCheckFailed
            label.textColor = UIColor.ud.udtokenTagTextOrange
            loadingView.upgradeImageView.image = BundleResources.LarkOpenPlatform.AppDetail.app_version_check_failed
            loadingView.upgradeImageView.isHidden = false
            loadingView.fetchMetaAnimationView.isHidden = true
            loadingView.appUpdateAnimationView.isHidden = true
            loadingView.snp.updateConstraints { (make) in
                make.width.equalTo(12)
                make.right.equalTo(label.snp.left).offset(-4)
            }
        case .newest:
            contentView.backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenTagNeutralBgNormal)
            label.text = BundleI18n.AppDetail.AppDetail_Setting_NoNewVersion
            label.textColor = UIColor.ud.udtokenTagNeutralTextNormal
            loadingView.upgradeImageView.isHidden = true
            loadingView.fetchMetaAnimationView.isHidden = true
            loadingView.appUpdateAnimationView.isHidden = true
            loadingView.snp.updateConstraints { (make) in
                make.width.equalTo(0)
                make.right.equalTo(label.snp.left).offset(0)
            }
        case .hasNewVersion:
            contentView.backgroundColor = UIColor.ud.udtokenBtnTextBgDangerHover
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenBtnTextBgDangerHover)
            label.textColor = UIColor.ud.functionDangerContentDefault
            label.text = BundleI18n.LarkOpenPlatform.LittleApp_AppAuth_UpgradeBttn
            loadingView.upgradeImageView.image = BundleResources.LarkOpenPlatform.AppDetail.app_version_upgrade
            loadingView.upgradeImageView.isHidden = false
            loadingView.fetchMetaAnimationView.isHidden = true
            loadingView.appUpdateAnimationView.isHidden = true
            loadingView.snp.updateConstraints { (make) in
                make.width.equalTo(12)
                make.right.equalTo(label.snp.left).offset(-4)
            }
        case .downloading:
            contentView.backgroundColor = UIColor.ud.udtokenBtnTextBgDangerHover
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenBtnTextBgDangerHover)
            label.textColor = UIColor.ud.R300
            label.text = BundleI18n.LarkOpenPlatform.LittleApp_AppAuth_AppUpgrade
            loadingView.upgradeImageView.isHidden = true
            loadingView.fetchMetaAnimationView.isHidden = true
            loadingView.fetchMetaAnimationView.stop()
            loadingView.appUpdateAnimationView.isHidden = false
            loadingView.appUpdateAnimationView.play()
            loadingView.snp.updateConstraints { (make) in
                make.width.equalTo(12)
                make.right.equalTo(label.snp.left).offset(-4)
            }
        case .downloadFailed:
            contentView.backgroundColor = UIColor.ud.udtokenBtnTextBgDangerHover
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenBtnTextBgDangerHover)
            label.textColor = UIColor.ud.functionDangerContentDefault
            label.text = BundleI18n.LarkOpenPlatform.LittleApp_AppAuth_FailedDldRetry
            loadingView.upgradeImageView.image = BundleResources.LarkOpenPlatform.AppDetail.app_version_upgrade
            loadingView.upgradeImageView.isHidden = false
            loadingView.fetchMetaAnimationView.isHidden = true
            loadingView.appUpdateAnimationView.isHidden = true
            loadingView.snp.updateConstraints { (make) in
                make.width.equalTo(12)
                make.right.equalTo(label.snp.left).offset(-4)
            }
        case .restart:
            contentView.backgroundColor = UIColor.ud.udtokenBtnTextBgDangerHover
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenBtnTextBgDangerHover)
            label.textColor = UIColor.ud.R300
            label.text = BundleI18n.LarkOpenPlatform.LittleApp_AppAuth_AppRestart
            loadingView.upgradeImageView.isHidden = true
            loadingView.fetchMetaAnimationView.isHidden = true
            loadingView.fetchMetaAnimationView.stop()
            loadingView.appUpdateAnimationView.isHidden = false
            loadingView.appUpdateAnimationView.play()
            loadingView.snp.updateConstraints { (make) in
                make.width.equalTo(12)
                make.right.equalTo(label.snp.left).offset(-4)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event:UIEvent?) {
        super.touchesBegan(touches, with: event)
        if self.appSettingVersionState == .hasNewVersion {
            contentView.backgroundColor = UIColor.ud.udtokenBtnTextBgDangerPressed
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenBtnTextBgDangerPressed)
        } else if self.appSettingVersionState == .metaFailed {
            contentView.backgroundColor = UIColor.ud.functionWarningFillSolid03
            contentView.layer.ud.setBorderColor(UIColor.ud.functionWarningFillSolid03)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event:UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if self.appSettingVersionState == .hasNewVersion {
            contentView.backgroundColor = UIColor.ud.udtokenBtnTextBgDangerHover
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenBtnTextBgDangerHover)
        } else if self.appSettingVersionState == .metaFailed {
            contentView.backgroundColor = UIColor.ud.udtokenTagBgOrange
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenTagBgOrange)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event:UIEvent?) {
        super.touchesEnded(touches, with: event)
        if self.appSettingVersionState == .hasNewVersion {
            contentView.backgroundColor = UIColor.ud.udtokenBtnTextBgDangerHover
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenBtnTextBgDangerHover)
        } else if self.appSettingVersionState == .metaFailed {
            contentView.backgroundColor = UIColor.ud.udtokenTagBgOrange
            contentView.layer.ud.setBorderColor(UIColor.ud.udtokenTagBgOrange)
        }
    }
}

class AppSettingVersionCell: UITableViewCell {
    static var identifier = "AppSettingVersionCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.state = .newest
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var viewModel: AppSettingVersionViewModel? {
        didSet {
            if let model = viewModel {
                update(viewModel: model)
            }
        }
    }

    /// title
    private lazy var titleLabel: UILabel = {
        let title = UILabel(frame: .zero)
        title.font = UIFont.systemFont(ofSize: 16.0)
        title.textColor = UIColor.ud.textTitle
        title.textAlignment = .left
        title.numberOfLines = 0
        return title
    }()

    private lazy var appSettingVersionStateView : AppSettingVersionStateView = {
        let view = AppSettingVersionStateView(frame: .zero)
        return view
    }()

    private lazy var gapView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBase
        return view
    }()

    // 当前状态
    private var state: AppSettingVersionState
    {
        didSet {
            appSettingVersionStateView.appSettingVersionState = state
        }
    }

    private func initSubViews() {
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.ud.fillHover
        selectionStyle = .none
        
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(-4)
            make.leading.equalToSuperview().offset(16)
        }
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(appSettingVersionStateView)
        appSettingVersionStateView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalTo(titleLabel)
            make.height.equalTo(28)

        }

        let tap = UITapGestureRecognizer.init(target: self, action: #selector(stateViewClicked))
        tap.cancelsTouchesInView = false
        appSettingVersionStateView.isUserInteractionEnabled = true
        appSettingVersionStateView.addGestureRecognizer(tap)


        contentView.addSubview(gapView)
        gapView.snp.makeConstraints { (make) in
            make.height.equalTo(8)
            make.left.bottom.right.equalToSuperview()
        }
        state = .fetchingMeta
    }

    func update(viewModel: AppSettingVersionViewModel) {
        switch viewModel.scene {
        case .H5:
            appSettingVersionStateView.isHidden = true
        case .MiniApp:
            appSettingVersionStateView.isHidden = false
        }
        let versionTag = viewModel.version.isEmpty ? "" : "V"
        if viewModel.shouldShowDoubleLine() {
            titleLabel.text = BundleI18n.LarkOpenPlatform.LittleApp_AppAuth_VersionNoTtl + "\n" + versionTag + viewModel.version
        } else {
            titleLabel.text = BundleI18n.LarkOpenPlatform.LittleApp_AppAuth_VersionNoTtl + " " + versionTag + viewModel.version
        }
        if viewModel.isShowMarginInset {
            titleLabel.snp.updateConstraints { (make) in
                make.centerY.equalToSuperview().offset(-AppSettingVersionViewModel.marginInset / 2.0)
            }
            gapView.snp.remakeConstraints { (make) in
                make.height.equalTo(AppSettingVersionViewModel.marginInset)
                make.left.bottom.right.equalToSuperview()
            }
            gapView.backgroundColor = UIColor.ud.bgBase
        } else {
            titleLabel.snp.updateConstraints { (make) in
                make.centerY.equalToSuperview()
            }
            gapView.snp.remakeConstraints { (make) in
                make.bottom.trailing.equalToSuperview()
                make.leading.equalToSuperview().offset(16)
                make.height.equalTo(1.0 / UIScreen.main.scale)
            }
            gapView.backgroundColor = UIColor.ud.lineDividerDefault
        }
        appSettingVersionStateView.snp.remakeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalTo(titleLabel)
            make.height.equalTo(28)
        }
        state = viewModel.state
    }
    @objc
    private func stateViewClicked(){
        viewModel?.didUserClickedStateView()
    }
}
