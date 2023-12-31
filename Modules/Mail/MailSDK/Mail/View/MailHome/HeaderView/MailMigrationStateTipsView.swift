//
//  MailSyncStatusTipsView.swift
//  MailSDK
//
//  Created by majx on 2020/2/08.
//

import Foundation
import UIKit
import SnapKit
import LarkAlertController
import UniverseDesignIcon

protocol MailMigrationStateTipsViewDelegate: AnyObject {
    func didClickMailMigrationStateDetails(type: MailMigrationStateTipsView.MigrationType)
    func didClickDismissMailMigrationStateTips(type: MailMigrationStateTipsView.MigrationType)
    func dismissMailMigrationStateTips(type: MailMigrationStateTipsView.MigrationType)
}

extension MailMigrationStateTipsViewDelegate {
    func didClickMailMigrationStateDetails(type: MailMigrationStateTipsView.MigrationType) {}
    func didClickDismissMailMigrationStateTips(type: MailMigrationStateTipsView.MigrationType) {}
}

class MailMigrationStateTipsView: UIView {
    // 搬家类型
    enum MigrationType {
        case api // api搬家
        case imap // imap对接搬家
    }
    struct MigrationTipsConfig {
        let type: MigrationType
        let tips: String
        let detailButton: String
        let showDetail: Bool
        let showClose: Bool
    }
    enum MigrationStage: Int {
        case invalid = 0
        case initial = 1
        case inProgress = 2
        case done = 3
        case doneWithError = 4
        case terminated = 5
    }
    weak var delegate: MailMigrationStateTipsViewDelegate?
    var currentState: MigrationStage = .invalid
    private var migrationType: MigrationType = .api

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        self.alpha = 0.0
        self.transform = CGAffineTransform(scaleX: 0.88, y: 0.96)
        UIView.animate(
            withDuration: 0.25,
            delay: 0.08,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 5,
            options: .curveEaseOut,
            animations: {
                self.alpha = 1.0
                self.transform = .identity
            },
            completion: nil
        )
    }

    func setupViews() {
        backgroundColor = UIColor.ud.primaryFillSolid02
        iconImgView.layer.cornerRadius = 8
        iconImgView.clipsToBounds = true
        addSubview(progressBar)
        addSubview(iconImgView)
        addSubview(titleLabel)
        addSubview(detailsButton)
        addSubview(closeButton)
        progressBar.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalTo(0)
            make.trailing.equalTo(0)
            make.height.equalTo(4)
        }

        iconImgView.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.centerY.equalToSuperview().offset(-2)
        }

        let detailBtnWidth = strWidth(str: detailsButton.titleLabel?.text, font: detailsButton.titleLabel?.font)

        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(iconImgView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().offset(-16 - 8 - detailBtnWidth)
            make.centerY.equalToSuperview().offset(-2)
        }

        detailsButton.snp.makeConstraints { (make) in
            make.width.equalTo(detailBtnWidth)
            make.trailing.lessThanOrEqualToSuperview().offset(-16).priority(.high)
            make.centerY.equalToSuperview().offset(-2)
        }
        
        closeButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.right.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
    }

    func strWidth(str: String?, font: UIFont?, height: CGFloat = 15) -> CGFloat {
        guard let str = str, let font = font else {
            return 0
        }
        let rect = str.boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: height),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: 48)
    }

    func config(state: MigrationStage, progressPct: Int, stateInfo: String = "") {
        currentState = state
        
        var stateText = BundleI18n.MailSDK.Mail_Migration_ProgressText(progressPct)
        var backgroundColor = UIColor.ud.primaryFillSolid02
        var icon = UDIcon.infoColorful
        var detailHidden = false
        var closeHidden = true
        var isDone = false
        if state == .done || state == .doneWithError {
            if state == .done {
                if let setting = Store.settingData.getCachedCurrentSetting(), setting.userType == .exchangeApiClient || setting.userType == .gmailApiClient {
                    stateText = BundleI18n.MailSDK.Mail_Migration_MigrationCompletedMobile
                } else {
                    stateText = BundleI18n.MailSDK.Mail_LinkAccount_EmailSyncingCompleted_Title
                }
            } else if state == .doneWithError {
                stateText = BundleI18n.MailSDK.Mail_Migration_DoneWithErrorsTitle
            }
            backgroundColor = .ud.functionSuccessFillSolid02
            icon = UDIcon.succeedColorful
            detailHidden = true
            closeHidden = false
            isDone = true
        } else if let setting = Store.settingData.getCachedCurrentSetting(), setting.userType == .exchangeApiClient || setting.userType == .gmailApiClient {
            stateText = BundleI18n.MailSDK.Mail_Migration_MailMovingMobile(progressPct)
        }
        if !stateInfo.isEmpty {
            stateText = stateInfo
        }
        let shouldHideProgressBar = (state == .terminated || isDone)
        UIView.animate(withDuration: timeIntvl.uiAnimateNormal) {
            self.titleLabel.text = stateText
            self.backgroundColor = (state == .terminated) ? UIColor.ud.functionDangerFillSolid02 : backgroundColor
            self.iconImgView.image = (state == .terminated) ? UDIcon.errorColorful : icon
            if !stateInfo.isEmpty {
                self.detailsButton.isHidden = true // 预加载场景屏蔽
            } else {
                self.detailsButton.isHidden = (state == .terminated) ? true : detailHidden
            }
            self.closeButton.isHidden = closeHidden
            self.progressBar.alpha = shouldHideProgressBar ? 0.0 : 1.0
        }
        UIView.animate(withDuration: timeIntvl.short, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1.0, options: .curveEaseIn, animations: {
            self.progressBar.progressPct = progressPct
        }) { _ in
        }

        [iconImgView, detailsButton, closeButton, titleLabel].forEach { view in
            view.snp.updateConstraints { make in
                make.centerY.equalToSuperview().offset(shouldHideProgressBar ? 0 : -2)
            }
        }
    }
    
    // 旧接口掺杂了很多业务逻辑，先不改动
    func newConfig(state: MigrationStage, progressPct: Int, config: MigrationTipsConfig) {
        currentState = state
        migrationType = config.type
        var backgroundColor = UIColor.ud.primaryFillSolid02
        var icon = UDIcon.infoColorful
        var isDone = false
        if state == .done || state == .doneWithError {
            backgroundColor = .ud.functionSuccessFillSolid02
            icon = UDIcon.succeedColorful
            isDone = true
        }
        let shouldHideProgressBar = (state == .terminated || isDone)
        UIView.animate(withDuration: timeIntvl.uiAnimateNormal) {
            self.titleLabel.text = config.tips
            self.backgroundColor = (state == .terminated) ? UIColor.ud.functionDangerFillSolid02 : backgroundColor
            self.iconImgView.image = (state == .terminated) ? UDIcon.errorColorful : icon
            self.detailsButton.isHidden = !config.showDetail
            self.closeButton.isHidden = !config.showClose
            self.progressBar.alpha = shouldHideProgressBar ? 0.0 : 1.0
            self.detailsButton.setTitle(config.detailButton, for: .normal)
            let detailBtnWidth = config.detailButton.getWidth(font: UIFont.systemFont(ofSize: 14))
            let detailsTrailing = config.showClose ? -36 : -16
            if config.showDetail {
                self.detailsButton.snp.updateConstraints { make in
                    make.width.equalTo(detailBtnWidth)
                    make.trailing.lessThanOrEqualToSuperview().offset(detailsTrailing).priority(.high)
                }
            }
        }
        UIView.animate(withDuration: timeIntvl.short, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1.0, options: .curveEaseIn, animations: {
            self.progressBar.progressPct = progressPct
        }) { _ in
        }

        [iconImgView, detailsButton, closeButton, titleLabel].forEach { view in
            view.snp.updateConstraints { make in
                make.centerY.equalToSuperview().offset(shouldHideProgressBar ? 0 : -2)
            }
        }
    }

    @objc
    func onClickDetails() {
        delegate?.didClickMailMigrationStateDetails(type: migrationType)
    }
    
    @objc
    func onClickClose() {
        delegate?.didClickDismissMailMigrationStateTips(type: migrationType)
    }

    lazy var iconImgView: UIImageView = {
        let iconImgView = UIImageView()
        iconImgView.image = UDIcon.infoColorful
        iconImgView.backgroundColor = .clear
        return iconImgView
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        return titleLabel
    }()

    lazy var detailsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.MailSDK.Mail_Migration_FailureDetailsButton, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(onClickDetails), for: .touchUpInside)
        return button
    }()
    
    lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .ud.iconN2
        button.setImage(UDIcon.closeOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(onClickClose), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    lazy var progressBar: ProgressBar = {
        let progressBar = ProgressBar(frame: .zero)
        return progressBar
    }()

    static func alertOfMigrationState(_ state: MigrationStage,
                                      onClickOK: (() -> Void)?) -> LarkAlertController? {
        var text = ""
        var title = ""
        
        if let setting = Store.settingData.getCachedCurrentSetting(), setting.userType == .exchangeApiClient || setting.userType == .gmailApiClient {
            // not show terminated
        } else if state == .terminated {
            title = BundleI18n.MailSDK.Mail_Migration_FailTitle
            text = BundleI18n.MailSDK.Mail_Migration_FailDesc
            InteractiveErrorRecorder.recordError(event: .migration_terminated, tipsType: .alert)
        }

        if text.isEmpty {
            return nil
        }
        let alert = LarkAlertController()
        if !title.isEmpty {
            alert.setTitle(text: title)
        }
        if !text.isEmpty {
            alert.setContent(text: text, alignment: .center)
        }
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_OK, dismissCompletion: {
            onClickOK?()
        })
        return alert
    }
}

class ProgressBar: UIView {
    private var progressView = UIView(frame: .zero)
    var progressColor: UIColor = UIColor.ud.primaryContentDefault {
        didSet {
            progressView.backgroundColor = progressColor
        }
    }
    var progressPct: Int = 0 {
        didSet {
            updateProgress()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N300
        self.addSubview(progressView)
        self.clipsToBounds = true
        self.progressView.layer.cornerRadius = 2.0
        self.progressView.clipsToBounds = true
        self.progressView.backgroundColor = progressColor
        self.progressPct = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateProgress() {
        let progressWidth = CGFloat(progressPct) / 100 * (bounds.width + 4)
        progressView.frame = CGRect(x: -2, y: 0, width: progressWidth, height: bounds.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateProgress()
    }
}
