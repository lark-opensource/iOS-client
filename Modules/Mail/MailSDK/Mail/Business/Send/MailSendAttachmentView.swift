//
//  MailSendAttachmentView.swift
//  Action
//
//  Created by tefeng liu on 2019/5/29.
//

import UIKit
import SnapKit
import LarkUIKit
import LarkAlertController
import EENavigator
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon

protocol MailSendAttachmentViewDelegate: AnyObject {
    func mailSendDidClickAttachment(_ attachmentView: MailSendAttachmentView, attachment: MailSendAttachment)
    func mailSendDidClickDeleteAttachment(_ attachmentView: MailSendAttachmentView, attachment: MailSendAttachment)
    func mailSendDidClickAttachmentStateIcon(_ attachmentView: MailSendAttachmentView, attachment: MailSendAttachment)
    func mailSendUploadAttachmentFailed(attachment: MailSendAttachment)
    func replaceTokenFail(tokenList: [String])
    func replaceToken(tokenMap: [String: String], messageBizId: String)
}

private let progressLineHeight: CGFloat = 2
private let maxAttachemntWidth: CGFloat = 423   // 附件容器的最大宽度
private let ProgressDefaultStart: CGFloat = 16

class MailSendAttachmentView: UIView {
    var threadID: String?
    var needReplaceToken: Bool = false
    var fileToken: String?
    var messageBizId: String?
    
    enum UploadState {
        case ready // 等待上传
        case ing
        case success
        case fail
        case replaceToken
        case replaceTokenFail
    }

    enum DownloadState {
        case ready
        case ing
        case success
        case fail
    }

    class ProgressContainer: UIView {
        var progressView: UIView?

        override var frame: CGRect {
            didSet {
                if let progressView = progressView {
                    progressView.frame = CGRect(x: 0, y: frame.height - progressLineHeight, width: frame.width, height: progressLineHeight)
                }
            }
        }
    }

    var downloadState: DownloadState = .ready {
        didSet {
            didUpdateDownloadState(downloadState)
        }
    }

    var state: UploadState = .ready {
        didSet {
            didUpdateUploadState(state)
        }
    }

    var isRiskFile: Bool = false {
        didSet {
            didUpdateRiskFileTag()
        }
    }
    
    var bannedInfo: FileBannedInfo? = nil {
        didSet {
            /// 二期采用合并接口bannedInfo信息, 后续risk风险接口下掉可以从这里取得风险文件标签
            FeatureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) ?             didUpdateNewBannedInfo() : didUpdateBannedInfo()
        }
    }

    override var frame: CGRect {
        didSet {
            reDrawContentView()
        }
    }
    var attachment: MailSendAttachment
    var attachmentLocationFG: Bool
    weak var delegate: MailSendAttachmentViewDelegate?
    private let iconImageView = UIImageView()
    private let progressContainer: ProgressContainer = { // 因为底部有个切割的圆角，所以需要外面包一个view去实现
        let temp = ProgressContainer()
        temp.layer.cornerRadius = 10
        temp.clipsToBounds = true
        return temp
    }()
    private let progressLine: UIView = {
        let temp = UIView()
        temp.backgroundColor = UIColor.ud.colorfulBlue
        temp.layer.cornerRadius = 1
        temp.clipsToBounds = true
        return temp
    }()

    private lazy var contentView: UIButton = {
        let view = UIButton()
        if !attachmentLocationFG {
            view.setBackgroundImage(UIImage.from(color: UIColor.ud.N200), for: .highlighted)
        }
        view.layer.borderColor = attachmentLocationFG ? UIColor.clear.cgColor : UIColor.ud.lineBorderCard.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    private let deleteButton: UIButton = {
        let button = UIButton()
        return button
    }()
    private lazy var deleteImage: UIImageView = {
        let img = UIImageView()
        img.isUserInteractionEnabled = false
        img.image = UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate)
        img.tintColor = UIColor.ud.iconN2
        return img
    }()
    private let retryButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        return button
    }()
    private lazy var retryImage: UIImageView = {
        let img = UIImageView()
        img.isUserInteractionEnabled = false
        img.image = UDIcon.refreshOutlined.withRenderingMode(.alwaysTemplate)
        img.tintColor = UIColor.ud.iconN2
        return img
    }()

    let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    let cloudIcon: UIView = {
        var image = UDIcon.cloudOutlined.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = UIColor.ud.primaryContentDefault

        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = 6
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 8, height: 8))
            make.centerX.centerY.equalToSuperview()
//            make.centerY.equalToSuperview().offset(-1)
        }
        return view
    }()
    let sep: UIView = {
        let sep = UIView()
        sep.backgroundColor = UIColor.ud.lineDividerDefault
        return sep
    }()

    let disposeBag = DisposeBag()

    // MARK: life Circle
    init(_ attachment: MailSendAttachment, threadID: String?, attachmentLocationFG: Bool) {
        self.attachment = attachment
        self.threadID = threadID
        self.attachmentLocationFG = attachmentLocationFG
        super.init(frame: CGRect.zero)
        configUI()
        MailCommonDataMananger
            .shared
            .sharePermissionChange
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (change) in
                self?.shareMailPermissionChange(change)
            }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reDrawContentView()
    }

    func hideDelete(isHidden: Bool = true) {
        deleteButton.isHidden = isHidden
        remakeNameLabelConstraints()
    }

    private func configUI() {
        contentView.addTarget(self, action: #selector(didClickAttachmentView), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonDidClick), for: .touchUpInside)
        retryButton.addTarget(self, action: #selector(didClickRetryButton), for: .touchUpInside)
        self.addSubview(contentView)
        progressContainer.progressView = progressLine
        progressContainer.addSubview(progressLine)
        contentView.addSubview(progressContainer)
        iconImageView.contentMode = .scaleAspectFit
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(deleteButton)
        deleteButton.addSubview(deleteImage)
        contentView.addSubview(statusLabel)
        contentView.addSubview(cloudIcon)
        contentView.addSubview(retryButton)
        retryButton.addSubview(retryImage)
        contentView.addSubview(sep)
        configConstraints()
        configModel(attachment)
    }

    func shareMailPermissionChange(_ change: ShareMailPermissionChange) {
        guard change.threadId == threadID else {
            return
        }
        if change.permissionCode == .view {
            hideDelete()
        } else if change.permissionCode == .owner || change.permissionCode == .edit {
            hideDelete(isHidden: false)
        }
    }

    private func configModel(_ model: MailSendAttachment) {
        nameLabel.text = model.displayName
        iconImageView.image = model.attachmentIcon()
        if model.type != .large {
            cloudIcon.isHidden = true
            statusLabel.text = ""
        } else {
            cloudIcon.isHidden = false
            statusLabel.isHidden = false
            if model.expireTime != 0 {
                let expireInfo = model.expireDisplayInfo
                statusLabel.text = expireInfo.expireText
                statusLabel.textColor = expireInfo.textColor
            }
        }
        if model.fileExtension.isHarmful && model.expireDisplayInfo.expireDateType != .expired {
            infoLabel.text = BundleI18n.MailSDK.Mail_Attachment_ScanAttachmentsBlockedUploadReason
            infoLabel.textColor = UIColor.ud.functionDangerContentDefault
            sep.isHidden = true
            statusLabel.isHidden = true
        } else {
            sep.isHidden = model.type != .large || model.expireDisplayInfo.expireDateType == .none
            statusLabel.isHidden = model.type != .large || model.expireDisplayInfo.expireDateType == .none
            infoLabel.text = FileSizeHelper.memoryFormat(UInt64(model.fileSize))
            infoLabel.textColor = UIColor.ud.textPlaceholder
        }
    }

    private func configConstraints() {
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        iconImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 32, height: 32))
            make.left.equalTo(10)
            make.centerY.equalToSuperview()
        }

        remakeNameLabelConstraints()

        infoLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(-1)
            make.left.equalTo(nameLabel.snp.left)
            make.height.equalTo(18)
        }
        infoLabel.snp.contentHuggingHorizontalPriority = 750

        progressContainer.snp.makeConstraints { (make) in
            make.top.bottom.left.right.equalToSuperview()
        }
        deleteButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
        }
        deleteImage.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.center.equalToSuperview()
        }
        retryButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.centerY.equalTo(deleteButton.snp.centerY)
            make.right.equalTo(deleteButton.snp.left).offset(-4)
        }
        retryImage.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.center.equalToSuperview()
        }

        sep.snp.makeConstraints { make in
            make.height.equalTo(12)
            make.width.equalTo(1)
            make.left.equalTo(infoLabel.snp.right).offset(6)
            make.centerY.equalTo(infoLabel.snp.centerY)
        }

        statusLabel.snp.makeConstraints { make in
            make.height.equalTo(18)
            make.left.equalTo(sep.snp.right).offset(6)
            make.right.equalTo(nameLabel.snp.right)
            make.centerY.equalTo(infoLabel.snp.centerY)
//            make.right.equalTo(retryButton.snp.left).offset(-1)
        }
        statusLabel.snp.contentCompressionResistanceHorizontalPriority = 50
        cloudIcon.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 12, height: 12))
            make.centerX.equalTo(iconImageView.snp.right).offset(-5)
            make.centerY.equalTo(iconImageView.snp.bottom).offset(-4)
        }
    }

    // MARK: Helper
    /// 更新下载标志
    private func didUpdateDownloadState(_ newState: DownloadState) {
        switch newState {
        case .ready:
            progressContainer.isHidden = true
            progressLine.frame = CGRect(x: 0, y: progressContainer.frame.height - progressLineHeight, width: ProgressDefaultStart, height: progressLineHeight)
            contentView.layer.borderColor = attachmentLocationFG ? UIColor.clear.cgColor : UIColor.ud.lineBorderCard.cgColor
        case .success:
            updateUploadProgress(1.0)
            progressContainer.isHidden = true
            contentView.layer.borderColor = attachmentLocationFG ? UIColor.clear.cgColor : UIColor.ud.lineBorderCard.cgColor
        case .fail:
            progressContainer.isHidden = true
            delegate?.mailSendUploadAttachmentFailed(attachment: attachment)
            contentView.layer.borderColor = attachmentLocationFG ? UIColor.clear.cgColor : UIColor.ud.lineBorderCard.cgColor
            sep.isHidden = true
            infoLabel.text = FileSizeHelper.memoryFormat(UInt64(attachment.fileSize))
        case .ing:
            progressContainer.isHidden = false
            contentView.layer.borderColor = attachmentLocationFG ? UIColor.clear.cgColor : UIColor.ud.lineBorderCard.cgColor
        }
        infoLabel.isHidden = false
        statusLabel.isHidden = true
        retryButton.isHidden = true
    }
    /// 更新上传标志
    private func didUpdateUploadState(_ newState: UploadState) {
        switch newState {
        case .ready:
            progressContainer.isHidden = true
            progressLine.frame = CGRect(x: 0, y: progressContainer.frame.height - progressLineHeight, width: 0, height: progressLineHeight)
            if statusLabel.text == BundleI18n.MailSDK.Mail_Attachment_UploadFailed {
                statusLabel.text = ""
            }
            contentView.layer.borderColor = attachmentLocationFG ? UIColor.clear.cgColor : UIColor.ud.lineBorderCard.cgColor
            infoLabel.isHidden = false
            resetStatusLabelLayout()
        case .success:
            progressContainer.isHidden = true
            updateStatusLabelUI()
            contentView.layer.borderColor = attachmentLocationFG ? UIColor.clear.cgColor : UIColor.ud.lineBorderCard.cgColor
            infoLabel.isHidden = false
            resetStatusLabelLayout()
        case .fail, .replaceTokenFail:
            delegate?.mailSendUploadAttachmentFailed(attachment: attachment)
            progressFailUpdateUI()
        case .ing, .replaceToken:
            progressContainer.isHidden = false
            contentView.layer.borderColor = attachmentLocationFG ? UIColor.clear.cgColor : UIColor.ud.lineBorderCard.cgColor
            infoLabel.isHidden = false
            resetStatusLabelLayout()
        }
        retryButton.isHidden = (newState != .fail && newState != .replaceTokenFail)
        remakeNameLabelConstraints()
    }

    private func remakeNameLabelConstraints() {
        nameLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(8.5)
            make.left.equalTo(iconImageView.snp.right).offset(6)
            make.height.equalTo(22)
            if let button = [retryButton, deleteButton].first(where: { !$0.isHidden }) {
                make.right.equalTo(button.snp.left).offset(-12)
            } else {
                make.right.equalToSuperview().offset(-12)
            }
        }
    }

    func resetStatusLabelLayout() {
        statusLabel.snp.remakeConstraints { make in
            make.height.equalTo(18)
            make.left.equalTo(sep.snp.right).offset(6)
            make.right.equalTo(nameLabel.snp.right)
            make.centerY.equalTo(infoLabel.snp.centerY)
        }
    }

    private func reDrawContentView() {
        // 用于重绘背景色
        if attachmentLocationFG {
            contentView.backgroundColor = attachment.attachmentBgColor(withSize: contentView.frame.size)
        }
    }
    func updateProgressLineFrame(frame: CGRect) {
        self.progressLine.frame = frame
    }
    
    private func updateStatusLabelUI() {
        // 超大附件管理：超大附件永久有效，不再需要 expireTime
        if attachment.type == .large && FeatureManager.open(.largeAttachment) && !FeatureManager.open(.largeAttachmentManage, openInMailClient: false) {
            if attachment.expireTime == 0 || statusLabel.text == BundleI18n.MailSDK.Mail_Attachment_Uploading {
                statusLabel.textColor = UIColor.ud.textPlaceholder
                statusLabel.text = BundleI18n.MailSDK.Mail_Attachments_DaysExpired(Const.attachExpireDay)
                attachment.expireTime = MailSendAttachment.genExpireTime()
                statusLabel.textColor = attachment.expireDisplayInfo.textColor
            }
            sep.isHidden = false
        } else if attachment.type == .large && attachment.expireDisplayInfo.expireDateType != .none {
            let expireInfo = attachment.expireDisplayInfo
            statusLabel.text = expireInfo.expireText
            statusLabel.textColor = expireInfo.textColor
            sep.isHidden = false
        } else {
            statusLabel.text = ""
            sep.isHidden = true
        }
    }
    
    private func progressFailUpdateUI() {
        progressContainer.isHidden = true
        statusLabel.isHidden = false
        statusLabel.textColor = UIColor.ud.functionDangerContentDefault
        statusLabel.text = BundleI18n.MailSDK.Mail_Attachment_UploadFailed
        contentView.layer.borderColor = UIColor.ud.functionDangerContentDefault.cgColor
        infoLabel.isHidden = true
        sep.isHidden = true
        statusLabel.snp.remakeConstraints { make in
            make.height.equalTo(18)
            make.left.equalTo(nameLabel.snp.left)
            make.right.equalTo(nameLabel.snp.right)
            make.centerY.equalTo(infoLabel.snp.centerY)
//            make.right.equalTo(retryButton.snp.left).offset(-1)
        }
    }

    func updateUploadProgress(_ progress: Float, fakeProgress: Bool = true) {
        progressContainer.isHidden = false
        statusLabel.isHidden = true
        statusLabel.textColor = UIColor.ud.textPlaceholder
        if !Store.settingData.mailClient {
            statusLabel.text = BundleI18n.MailSDK.Mail_Attachment_Uploading // 后面再抽一下 progress
        }
        let progressFix = min(1.0, max(0, progress))
        self.progressLine.frame = CGRect(x: 0,
                                         y: self.progressContainer.frame.height - progressLineHeight,
                                         width: self.progressLine.frame.width,
                                         height: progressLineHeight)
        let threshold: Double = 0.2
        UIView.animate(withDuration: ((Double(progressFix) > threshold || !fakeProgress) ? timeIntvl.ultraShort : timeIntvl.short)) { // 延长给用户loadinng的感觉
            var targetProgress = fakeProgress ? max(progressFix, 0.2) : progressFix // 主要让用户感知正在上传
            self.progressLine.frame = CGRect(x: 0,
                                             y: self.progressContainer.frame.height - progressLineHeight,
                                             width: max(CGFloat(targetProgress) * self.progressContainer.frame.width,
                                                        ProgressDefaultStart), // 16是UX需要的初始化宽度
                                             height: progressLineHeight)
        }
        updateProgressLabelInfo(progress: progress)
    }
    private func updateProgressLabelInfo(progress: Float) {
        if progress >= 1.0 {
            statusLabel.isHidden = false
            sep.isHidden = attachment.type != .large || FeatureManager.open(.largeAttachmentManage, openInMailClient: false)
            infoLabel.text = FileSizeHelper.memoryFormat(UInt64(attachment.fileSize))
        } else {
            sep.isHidden = true
            let finishSize = Float(attachment.fileSize) * progress
            if !finishSize.isInfinite && !finishSize.isNaN {
                infoLabel.text = "\(FileSizeHelper.memoryFormat(UInt64(finishSize))) / \(FileSizeHelper.memoryFormat(UInt64(attachment.fileSize)))"
            } else {
                mailAssertionFailure("convert err fileSize \(attachment.fileSize), progress \(progress)")
            }
        }
    }
    
    /// 更新文件风险标志
    /// 写信页优先级：已失效 > 有害附件（文件后缀命中） > 高危附件（风险）
    func didUpdateRiskFileTag() {
        if isRiskFile,
           bannedInfo?.isBanned != true,
           attachment.expireDisplayInfo.expireDateType != .expired,
           !attachment.fileExtension.isHarmful {
            infoLabel.text = BundleI18n.MailSDK.Mail_HighRiskContentDetected_Text
            infoLabel.textColor = UIColor.ud.functionDangerContentDefault
            sep.isHidden = true
            statusLabel.isHidden = true
        }
    }

    /// 更新文件封禁标志
    /// 文件Owner：显示“发现违规内容”
    /// 非文件Owner：显示“已失效”
    func didUpdateBannedInfo() {
        if let bannedInfo = bannedInfo,
           bannedInfo.isBanned,
           attachment.expireDisplayInfo.expireDateType != .expired {
            if bannedInfo.isOwner {
                infoLabel.text = BundleI18n.MailSDK.Mail_UserAgreementViolated_Text
                infoLabel.textColor = UIColor.ud.functionDangerContentDefault
                sep.isHidden = true
                statusLabel.isHidden = true
            } else {
                sep.isHidden = false
                statusLabel.isHidden = false
                statusLabel.text = BundleI18n.MailSDK.Mail_Expired_Text
                statusLabel.textColor = UIColor.ud.textPlaceholder
            }
        }
    }
    
    /// 更新文件标志合并接口
    /// 优先级：已删除 > 已失效 > 有害附件（文件后缀命中） > 高危附件（风险）
    func didUpdateNewBannedInfo() {
        if let bannedInfo = bannedInfo {
            if bannedInfo.status == .deleted { // 待删除
                infoLabel.text = BundleI18n.MailSDK.Mail_Shared_LargeAttachmentAlreadyDeleted_Text
                infoLabel.textColor = UIColor.ud.functionDanger500
                sep.isHidden = true
                statusLabel.isHidden = true
            } else if bannedInfo.status == .banned, // 封禁
            attachment.expireDisplayInfo.expireDateType != .expired {
                if bannedInfo.isOwner { // 发现违规内容
                   infoLabel.text = BundleI18n.MailSDK.Mail_UserAgreementViolated_Text
                   infoLabel.textColor = UIColor.ud.functionDanger500
                   sep.isHidden = true
                   statusLabel.isHidden = true
               } else { // 已失效
                   sep.isHidden = false
                   statusLabel.isHidden = false
                   statusLabel.text = BundleI18n.MailSDK.Mail_Expired_Text
                   statusLabel.textColor = UIColor.ud.textPlaceholder
               }
            } else if bannedInfo.status == .highRisk { // 高风险
                if bannedInfo.isBanned != true,
                   attachment.expireDisplayInfo.expireDateType != .expired,
                   !attachment.fileExtension.isHarmful {
                    infoLabel.text = BundleI18n.MailSDK.Mail_HighRiskContentDetected_Text
                    infoLabel.textColor = UIColor.ud.functionDanger500
                    sep.isHidden = true
                    statusLabel.isHidden = true
                }
            }
        }
    }

    // MARK: action handler
    @objc
    private func deleteButtonDidClick() {
        delegate?.mailSendDidClickDeleteAttachment(self, attachment: attachment)
    }

    @objc
    private func didClickAttachmentView() {
        delegate?.mailSendDidClickAttachment(self, attachment: attachment)
    }

    @objc
    private func didClickStateIcon() {
        delegate?.mailSendDidClickAttachmentStateIcon(self, attachment: attachment)
    }

    @objc
    private func didClickRetryButton() {
        if self.needReplaceToken, let token = self.fileToken, !token.isEmpty {
            MailDataServiceFactory
                .commonDataService?.translateLargeTokenRequest(tokenList: [token], messageBizId: self.messageBizId ?? "").observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (dic) in
                guard let `self` = self else { return }
                    // model replaceToken
                    self.delegate?.replaceToken(tokenMap: dic, messageBizId: self.messageBizId ?? "")
            }, onError: { [weak self] (err) in
                guard let `self` = self else { return }
                MailLogger.info("[replace_token] err \(err)")
                self.delegate?.replaceTokenFail(tokenList: [token])
            }).disposed(by: disposeBag)
        } else {
            self.state = .ready
            delegate?.mailSendDidClickAttachmentStateIcon(self, attachment: attachment)
        }
    }
    
    func updateEmlAttachmentProgressFail() {
        progressFailUpdateUI()
        self.retryButton.isHidden = false
        remakeNameLabelConstraints()
    }
    
    private func containerHeight() -> CGFloat {
        var containerHeight = self.progressContainer.frame.height
        if containerHeight <= 0 {
            containerHeight = self.bounds.size.height
        }
        return containerHeight
    }
    
    func updateEmlAttachmentPending() {
        progressContainer.isHidden = false
        statusLabel.isHidden = true
        sep.isHidden = true
        self.progressLine.frame = CGRect(x: 0,
                                         y: self.containerHeight() - progressLineHeight,
                                         width: ProgressDefaultStart,
                                         height: progressLineHeight)
    }
    
    func updateEmlAttachmentProgressToHalf() {
        progressContainer.isHidden = false
        statusLabel.isHidden = true
        statusLabel.textColor = UIColor.ud.textPlaceholder
        statusLabel.text = BundleI18n.MailSDK.Mail_Attachment_Uploading // 后面再抽一下 progress
        self.progressLine.frame = CGRect(x: 0,
                                         y: self.containerHeight() - progressLineHeight,
                                         width: self.progressLine.frame.width,
                                         height: progressLineHeight)
        UIView.animate(withDuration: 0.3) { // 延长给用户loadinng的感觉
            self.progressLine.frame = CGRect(x: 0,
                                             y: self.containerHeight() - progressLineHeight,
                                             width: max(CGFloat(0.7) * self.progressContainer.frame.width,
                                                        ProgressDefaultStart), // 16是UX需要的初始化宽度
                                             height: progressLineHeight)
        }
        updateProgressLabelInfo(progress: 0.7)
    }
    
    func updateEmlAttachmentProgressDone() {
        UIView.animate(withDuration: 0.05, delay: 0, animations: { [weak self] in
            guard let `self` = self else { return }
            self.progressLine.frame = CGRect(x: 0,
                                             y: self.containerHeight() - progressLineHeight,
                                             width:  self.progressContainer.frame.width, // 16是UX需要的初始化宽度
                                             height: progressLineHeight)
        }) { [weak self] _ in
            guard let `self` = self else { return }
            self.updateProgressLabelInfo(progress: 1.0)
            self.progressContainer.isHidden = true
            self.updateStatusLabelUI()
            self.contentView.layer.borderColor = self.attachmentLocationFG ? UIColor.clear.cgColor : UIColor.ud.lineBorderCard.cgColor
            self.infoLabel.isHidden = false
            self.resetStatusLabelLayout()
        }
    }
}

protocol MailSendAttachmentContainerDelegate: MailSendAttachmentViewDelegate {
    func getVCWidth() -> CGFloat
}

class MailSendAttachmentContainer: UIView {

    private let attachViewHeight = 56.0
    private let horizontalPadding = 16.0
    private let topPadding = 0.0
    private let bottomPadding = 0.0

    private let attachmentMinWidth = 225.0
    private let attachmentMaxWidth = 358.0
    private var attachmentCardWidth = 225.0
    private var topAttachmentMinWidth = 0.0
    private let topAttachmentMaxWidth = 358.0
    private var topAttachmentCardWidth = 0.0
    private let cardSpacing = 8.0
    private var attachmentRowCount: Int = 0
    private var attachmentColumnCount: Int = 0

    var threadID: String?
    var attachmentLocationFG: Bool
    var attachmentAtTop: Bool

    weak var delegate: MailSendAttachmentContainerDelegate?

    var attachmentViews: [MailSendAttachmentView] = []
    private lazy var topAttachmentScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.bounces = true
        view.isScrollEnabled = true
        return view
    }()

    var preferredHeight: Double {
        return attachmentAtTop ?
        attachViewHeight :
        (Double(attachmentRowCount) * attachViewHeight + Double(max(0, attachmentRowCount - 1)) * cardSpacing + topPadding + bottomPadding)
    }

    var isEmpty: Bool {
        return attachmentViews.isEmpty
    }
    enum EmlUploadState {
        case half
        case done
        case fail
        case pending
    }

    // MARK: lifeCircle
    init(frame: CGRect, attachmentLocationFG: Bool, attachmentAtTop: Bool) {
        self.attachmentLocationFG = attachmentLocationFG
        self.attachmentAtTop = attachmentAtTop
        attachmentCardWidth = attachmentMinWidth
        super.init(frame: frame)
        if attachmentAtTop {
            topAttachmentMinWidth = bounds.width * 0.6
            topAttachmentCardWidth = topAttachmentMinWidth
        }
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func getTargetAttachY(at Index: Int) -> Double { //返回目标附件View的顶部Y方向偏移量
        return Double(Index) * (attachViewHeight + cardSpacing) + topPadding
    }
    func getAttachHeight() -> Double {
        return attachViewHeight
    }
    func getCardSpacing() -> Double {
        return cardSpacing
    }
    func updateAttachmentsLayout() {
        if attachmentAtTop {
            let containerWidth = bounds.width - 2 * horizontalPadding
            topAttachmentMinWidth = bounds.width * 0.6
            topAttachmentCardWidth = attachmentViews.count <= 1
            ? min(containerWidth, topAttachmentMaxWidth)
            : min(topAttachmentMinWidth, topAttachmentMaxWidth)
            topAttachmentScrollView.contentSize = CGSize(width: Double(attachmentViews.count) * (topAttachmentCardWidth + cardSpacing) - cardSpacing + 2 * horizontalPadding, height: 0)
            let setAttachmentCardLayoutBlock: (Int, MailSendAttachmentView) -> Void = { [weak self] (i, card) in
                guard let `self` = self else { return }
                card.frame = CGRect(x: Double(i) * (self.topAttachmentCardWidth + self.cardSpacing) + self.horizontalPadding,
                                    y: 0,
                                    width: self.topAttachmentCardWidth,
                                    height: self.attachViewHeight)
            }
            for (i, card) in attachmentViews.enumerated() {
                // 附件卡片已存在的，需要有动画（删除时）
                if card.frame.minX > 0 {
                    UIView.animate(withDuration: timeIntvl.short, animations: {
                        setAttachmentCardLayoutBlock(i, card)
                    }) { _ in
                        if card.needReplaceToken {
                            card.state = .replaceToken
                            card.updateProgressLineFrame(frame: CGRect(x: 0,
                                                                       y: card.bounds.size.height - 2,
                                                                       width: 26, height: 2))
                        }
                    }
                } else {
                    setAttachmentCardLayoutBlock(i, card)
                    if card.needReplaceToken {
                        card.state = .replaceToken
                        card.updateProgressLineFrame(frame: CGRect(x: 0,
                                                                   y: card.bounds.size.height - 2,
                                                                   width: 26, height: 2))
                    }
                }
            }
        } else {
            let contanerWidth = bounds.width - 2 * horizontalPadding
            var maxCardCount = Int(floor((contanerWidth + cardSpacing) / (attachmentMinWidth + cardSpacing)))
            if maxCardCount <= 0 {
                maxCardCount = 1
            }
            attachmentColumnCount = min(attachmentViews.count, maxCardCount)
            let cardTotalWidth = contanerWidth - Double(attachmentColumnCount - 1) * cardSpacing
            attachmentCardWidth = attachmentColumnCount == 0 ? 0 : min(floor(cardTotalWidth / Double(attachmentColumnCount)), attachmentMaxWidth)
            attachmentRowCount = attachmentColumnCount == 0 ? 0 : attachmentViews.count / attachmentColumnCount
            if attachmentRowCount * attachmentColumnCount < attachmentViews.count {
                attachmentRowCount = attachmentRowCount + 1
            }
            if attachmentColumnCount > 0 {
                for (i, card) in attachmentViews.enumerated() {
                    let columnIdx = i % attachmentColumnCount
                    let rowIdx = floor(Double(i) / Double(attachmentColumnCount))
                    card.frame = CGRect(x: Double(columnIdx) * (attachmentCardWidth + cardSpacing) + horizontalPadding,
                                        y: Double(rowIdx) * (attachViewHeight + cardSpacing),
                                        width: attachmentCardWidth,
                                        height: attachViewHeight)
                    if card.needReplaceToken {
                        card.state = .replaceToken
                        card.updateProgressLineFrame(frame: CGRect(x: 0,
                                                                   y: card.bounds.size.height - 2,
                                                                   width: 26, height: 2))
                    }
                }
            }
        }
    }

    private func setupView() {
        self.backgroundColor = UIColor.ud.bgBody
        if attachmentAtTop {
            addSubview(topAttachmentScrollView)
            topAttachmentScrollView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    func addAttachments(_ attachments: [MailSendAttachment], allSuccess: Bool = false, permCode: MailPermissionCode?) {
        for attachment in attachments {
            let attachmentView = MailSendAttachmentView(attachment, threadID: threadID, attachmentLocationFG: attachmentLocationFG)
            attachmentView.needReplaceToken = attachment.needReplaceToken
            attachmentView.fileToken = attachment.fileToken
            if permCode == .view {
                attachmentView.hideDelete()
            }
            attachmentView.delegate = self
            if allSuccess && !attachment.needReplaceToken {
                attachmentView.state = .success
            }
            if attachmentAtTop {
                topAttachmentScrollView.addSubview(attachmentView)
            } else {
                addSubview(attachmentView)
            }
            attachmentViews.append(attachmentView)
        }
        updateAttachmentsLayout()
    }

    func removeAttachment(_ attacment: MailSendAttachment) {
        for (index, element) in attachmentViews.enumerated() where element.attachment == attacment {
            element.removeFromSuperview()
            attachmentViews.remove(at: index)
            break
        }
        updateAttachmentsLayout()
    }

    func removeAllAttachment() {
        for element in attachmentViews {
            element.removeFromSuperview()
        }
        attachmentViews.removeAll()
        updateAttachmentsLayout()
    }

    func topAttachmentScrollToBottom() {
        let offset = CGPoint(x: max(0, topAttachmentScrollView.contentSize.width - topAttachmentScrollView.bounds.width), y: 0)
        self.topAttachmentScrollView.setContentOffset(offset, animated: true)
    }

    func updateUploadProgress(attachment: MailSendAttachment, progress: Float) {
        for element in attachmentViews where element.attachment == attachment {
            element.updateUploadProgress(progress)
            break
        }
    }
    
    func updateUploadState(attachment: MailSendAttachment, state: MailSendAttachmentView.UploadState) {
        for element in attachmentViews where element.attachment == attachment {
            var attachment = attachment
            element.state = state
            if element.attachment.expireTime != 0 {
                attachment.expireTime = element.attachment.expireTime
            }
            if let path = element.attachment.cachePath, !path.isEmpty {
                attachment.cachePath = path
            }
            element.attachment = attachment
            break
        }
    }

    func updateRiskFileTag(attachment: MailSendAttachment, isRiskFile: Bool) {
        for element in attachmentViews where element.attachment == attachment {
            element.isRiskFile = isRiskFile
        }
    }

    func updateBannedInfo(attachment: MailSendAttachment, bannedInfo: FileBannedInfo) {
        for element in attachmentViews where element.attachment == attachment {
            element.bannedInfo = bannedInfo
        }
    }
    /// 合并接口请求
    func updateNewBannedInfo(attachment: MailSendAttachment, bannedInfo: FileBannedInfo) {
        for element in attachmentViews where element.attachment == attachment {
            element.bannedInfo = bannedInfo
        }
    }
    
    func updateEmlAttachmentProgress(tasks: [EmlUploadTask], state: EmlUploadState) {
        let taskIds = tasks.map { $0.bizId }
        for attachmentView in attachmentViews {
            if let indexTask = attachmentView.attachment.emlUploadTask,
               !indexTask.bizId.isEmpty,
                taskIds.contains(indexTask.bizId) {
                if state == .half {
                    attachmentView.updateEmlAttachmentProgressToHalf()
                    if tasks.count == 1 {
                        break
                    }
                } else if state == .done {
                    attachmentView.updateEmlAttachmentProgressDone()
                    if tasks.count == 1 {
                        break
                    }
                } else if state == .fail {
                    attachmentView.updateEmlAttachmentProgressFail()
                    if tasks.count == 1 {
                        break
                    }
                } else if state == .pending {
                    attachmentView.updateEmlAttachmentPending()
                    if tasks.count == 1 {
                        break
                    }
                }
            }
        }
    }
}

extension MailSendAttachmentContainer: MailSendAttachmentViewDelegate {
    
    func mailSendUploadAttachmentFailed(attachment: MailSendAttachment) {
        delegate?.mailSendUploadAttachmentFailed(attachment: attachment)
    }

    func mailSendDidClickAttachment(_ attachmentView: MailSendAttachmentView, attachment: MailSendAttachment) {
        delegate?.mailSendDidClickAttachment(attachmentView, attachment: attachment)
    }

    func mailSendDidClickDeleteAttachment(_ attachmentView: MailSendAttachmentView, attachment: MailSendAttachment) {
        delegate?.mailSendDidClickDeleteAttachment(attachmentView, attachment: attachment)
    }

    func mailSendDidClickAttachmentStateIcon(_ attachmentView: MailSendAttachmentView, attachment: MailSendAttachment) {
        delegate?.mailSendDidClickAttachmentStateIcon(attachmentView, attachment: attachment)
    }
    func replaceToken(tokenMap: [String: String], messageBizId: String) {
        for (index, element) in attachmentViews.enumerated() where element.needReplaceToken {
            if let token = element.fileToken, !token.isEmpty, tokenMap[token] != nil {
                // update view status
                element.messageBizId = messageBizId
                element.state = .success
                element.fileToken = tokenMap[token]
                element.needReplaceToken = false
                element.attachment.fileToken = tokenMap[token]
            }
        }
        self.delegate?.replaceToken(tokenMap: tokenMap, messageBizId: messageBizId)
    }
    func replaceTokenFail(tokenList: [String]) {
        for (index, element) in attachmentViews.enumerated() where element.needReplaceToken {
            if let token = element.fileToken, !token.isEmpty, tokenList.contains(token) {
                // update view status
                element.state = .replaceTokenFail
            }
        }
    }
}
