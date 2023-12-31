//
//  MailLongTaskLoadingView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/3/14.
//

import Foundation
import EENavigator
import RxSwift
import FigmaKit
import LarkAlertController
import UniverseDesignEmpty
import UniverseDesignToast
import UniverseDesignDialog
import UniverseDesignProgressView
import RustPB

protocol MailLongTaskLoadingDelegate: AnyObject {
    func retryManageStrangerThread(type: Email_Client_V1_MailManageStrangerRequest.ManageType, threadIds: [String]?, isSelectAll: Bool, maxTimestamp: Int64)
}

class MailLongTaskLoadingViewController: LarkAlertController {
    private let loadingBgWidth: CGFloat = 304
    private let loadingBgHeight: CGFloat = 156

    private let loadingBackground = UIView()
    private var loadingAnimation: UDToast?
    private let loadingText = UILabel()
    private let failIcon = UIImageView()
    private let sepView = UIView()
    private lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.clipsToBounds = false
        closeButton.setTitle(BundleI18n.MailSDK.Mail_Common_Cancel, for: .normal)
        closeButton.titleLabel?.textAlignment = .center
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        closeButton.titleLabel?.textAlignment = .center
        closeButton.setTitleColor(UIColor.ud.functionDanger500, for: .normal)
        closeButton.backgroundColor = UIColor.ud.bgFloat
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: loadingBgWidth, height: 49),
                                byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 8, height: 8))
        let lay = CAShapeLayer()
        lay.path = path.cgPath
        closeButton.layer.mask = lay
        return closeButton
    }()
    private lazy var retryButton: UIButton = {
        let retryButton = UIButton()
        retryButton.isHidden = self.sessionInfo.status != .failed
        retryButton.clipsToBounds = false
        retryButton.setTitle(BundleI18n.MailSDK.Mail_ThirdClinet_Retry, for: .normal)
        retryButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        retryButton.backgroundColor = UIColor.ud.bgFloat
        retryButton.titleLabel?.textAlignment = .center
        retryButton.addTarget(self, action: #selector(retryButtonClicked), for: .touchUpInside)
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: loadingBgWidth/2.0, height: 49),
                                byRoundingCorners: .bottomRight, cornerRadii: CGSize(width: 8, height: 8))
        let lay = CAShapeLayer()
        lay.path = path.cgPath
        retryButton.layer.mask = lay
        return retryButton
    }()
    private lazy var cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.isHidden = self.sessionInfo.status != .failed
        cancelButton.setTitle(BundleI18n.MailSDK.Mail_Common_Cancel, for: .normal)
        cancelButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        cancelButton.backgroundColor = UIColor.ud.bgFloat
        cancelButton.titleLabel?.textAlignment = .center
        cancelButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        let roundPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: loadingBgWidth / 2.0, height: 49),
                                byRoundingCorners: .bottomLeft, cornerRadii: CGSize(width: 8, height: 8))
        let layer = CAShapeLayer()
        layer.path = roundPath.cgPath
        cancelButton.layer.mask = layer
        return cancelButton
    }()
    private let titleLabel = UILabel()
    private let subTitleLabel = UILabel()
    private let contentView = UIView()

    private var progressView: UDProgressView = {
        let config = UDProgressViewUIConfig(themeColor: UDProgressViewThemeColor(indicatorColor: UIColor.ud.primaryPri500), showValue: true)
        let progress = UDProgressView(config: config)
        return progress
    }()
    private let progressLabel = UILabel()

    private var disposeBag = DisposeBag()
    private var cancelDisposeBag = DisposeBag()
    private var delayDisposeBag = DisposeBag()

    private(set) var didRetry: Bool = false
    private(set) var cancelInFailCase: Bool = false
    private(set) var needDelayShowCancel: Bool = true
    var closeHandler: (() -> Void)? = nil
    weak var delegate: MailLongTaskLoadingDelegate?
    var sessionInfo: MailBatchChangeInfo {
        didSet {
            MailLogger.info("[mail_stranger] sessionInfo change sessionID: \(sessionInfo.sessionID) oldValue: \(oldValue.status) new: \(sessionInfo.status)")
            self.updateSessionInfo(needDelay: oldValue.status == .processing) // Loading至少展示1s
        }
    }
    static let progressRequestInterval = 2
    lazy var timer: Observable<Int> = {
        return Observable<Int>.interval(.seconds(MailLongTaskLoadingViewController.progressRequestInterval),
                                        scheduler: SerialDispatchQueueScheduler(internalSerialQueueName: "com.lark.mail.longTaskProgressRequest"))
    }()
    var timerDisposeBag: DisposeBag?
    private(set) var needShowErrorAlert = false
    init(sessionInfo: MailBatchChangeInfo) {
        self.sessionInfo = sessionInfo
        let config = UDDialogUIConfig(contentMargin: .zero, splitLineColor: .clear, backgroundColor: .clear)
//        if let manageReq = sessionInfo.request as? Email_Client_V1_MailManageStrangerRequest, manageReq.isSelectAll {
            //super.init(config: UDDialogUIConfig())
            super.init(config: config)
            setupCommonView()
            setupSelectAllViews()
            pollingLongTaskStatusIfNeeded()
//        } else {
//            let config = UDDialogUIConfig(contentMargin: .zero, splitLineColor: .clear, backgroundColor: .clear)
//            super.init(config: config)
//            setupCommonView()
//            setupViews()
//            delaySupportCancelIfNeeded()
//        }
    }
    
    func updateSessionInfo(needDelay: Bool = false) {
        /// 需要延迟一秒进行Loading
        if needDelay {
            delayDisposeBag = DisposeBag()
            let delayer = Observable<()>.just(()).delay(.seconds(1), scheduler: MainScheduler.instance)
            delayer.subscribe(onNext: { [weak self] (_) in
                MailLogger.info("[mail_stranger] delayer 1 seconds to updateSessionInfoPage")
                guard let `self` = self else { return }
                self.updateSessionStatusPage()
            }, onError: { (error) in
                MailLogger.error("[mail_stranger] delayer 1 seconds error")
            }).disposed(by: delayDisposeBag)
        } else {
            updateSessionStatusPage()
        }
    }

    func pollingLongTaskStatusIfNeeded() {
        if timerDisposeBag == nil {
            let bag = DisposeBag()
            timerDisposeBag = bag
            timer.subscribe(onNext: { [weak self] _ in
                self?.getStatusAndRefreshProgress()
            }).disposed(by: bag)
        }
    }

    func getStatusAndRefreshProgress() {
        MailLogger.info("[mail_stranger] longtask getStatus SID: \(sessionInfo.sessionID)")
        MailDataServiceFactory
            .commonDataService?.getLongTaskStatus(sessionID: sessionInfo.sessionID)
            .subscribe(onNext: { [weak self] (resp) in
                MailLogger.info("[mail_stranger] longtask getStatus \(resp.taskStatus), progress: \(resp.progress)")
                self?.progressView.setProgress(CGFloat(resp.progress), animated: true)
            }, onError: { (error) in
                MailLogger.error("[mail_stranger] longtask getStatus failed error: \(error)")
            }).disposed(by: disposeBag)
    }
    
    private func updateSessionStatusPage() {
        if sessionInfo.status == .failed { // 现在都可以重试 && (sessionInfo.request as? Email_Client_V1_MailUpdateAccountRequest) != nil {
            contentView.backgroundColor = UIColor.ud.bgMask
            loadingBackground.isHidden = false
            failIcon.isHidden = false
            retryButton.isHidden = false
            cancelButton.isHidden = false
            sepView.isHidden = false
            closeButton.isHidden = true
            loadingAnimation?.remove()
            loadingText.text = upsetLoadingText()
            loadingText.sizeToFit()
        } else {
            loadingBackground.isHidden = true
            retryButton.isHidden = true
            failIcon.isHidden = true
            cancelButton.isHidden = true
            if !isSelectAllReq() {
                contentView.backgroundColor = UIColor.dynamic(light: UIColor.white.withAlphaComponent(0.3), dark: UIColor.black.withAlphaComponent(0.3))
                setupLoadingIfNeeded()
                if didRetry || !needDelayShowCancel { // 重试过或者倒计时完成展示过的都直接展示，否则等待
                    let opConfig = UDToastOperationConfig(text: BundleI18n.MailSDK.Mail_Common_Cancel, displayType: .horizontal)
                    self.loadingAnimation?.updateToast(with: self.upsetLoadingText(), superView: self.contentView, operation: opConfig)
                }
            }
            closeButton.isHidden = true
            sepView.isHidden = true
        }
        if isSelectAllReq() {
            loadingBackground.isHidden = false
            titleLabel.isHidden = false
            sepView.isHidden = false
            subTitleLabel.isHidden = sessionInfo.status != .failed
            progressView.isHidden = sessionInfo.status != .processing
            closeButton.isHidden = sessionInfo.status != .processing
        } else {
            titleLabel.isHidden = true
            subTitleLabel.isHidden = true
            progressView.isHidden = true
        }
        titleLabel.text = upsetLoadingText()
    }

    func isSelectAllReq() -> Bool {
        return true
        if let manageReq = sessionInfo.request as? Email_Client_V1_MailManageStrangerRequest, manageReq.isSelectAll {
            return true
        } else {
            return false
        }
    }

    func setupLoadingIfNeeded() { // 初始化类型为失败后重试的case，可能需要新初始化Toast
        if loadingAnimation == nil {
            self.loadingAnimation = UDToast.showLoading(with: upsetLoadingText(), on: contentView, operationCallBack: { [weak self] _ in
                self?.closeButtonClicked()
            })
        }
    }
    
    func delaySupportCancelIfNeeded() {
        /// 非更新Setting操作才有取消逻辑
        ///guard ((sessionInfo.request as? Email_Client_V1_MailUpdateAccountRequest) == nil) else { return }
        guard needDelayShowCancel else { return }
        cancelDisposeBag = DisposeBag()
        let delayer = Observable<()>.just(()).delay(.seconds(5), scheduler: MainScheduler.instance)
        delayer.subscribe(onNext: { [weak self] (_) in
            MailLogger.info("[mail_stranger] delayer 5 seconds, show cancel button")
            guard let `self` = self else { return }
            if self.sessionInfo.status != .failed {
                self.closeButton.isHidden = false
                let opConfig = UDToastOperationConfig(text: BundleI18n.MailSDK.Mail_Common_Cancel, displayType: .horizontal)
                self.setupLoadingIfNeeded()
                self.loadingAnimation?.updateToast(with: self.upsetLoadingText(), superView: self.contentView, operation: opConfig)
            }
            self.needDelayShowCancel = false
        }, onError: { (error) in
            MailLogger.error("[mail_stranger] delayer 5 cancel error")
        }).disposed(by: cancelDisposeBag)
    }

    @objc
    func closeButtonClicked() {
        MailLogger.info("[mail_stranger] closeButtonClicked sessionInfo: \(sessionInfo.sessionID)")
        if sessionInfo.status == .failed {
            cancelInFailCase = true
        }
        closeHandler?()
    }
    
    @objc
    func retryButtonClicked() {
        didRetry = true
        // UI及时更新响应
        var processSessionInfo = sessionInfo
        var updateSessionInfo = sessionInfo
        processSessionInfo.sessionID = ""
        processSessionInfo.status = .processing
        sessionInfo = processSessionInfo

        cancelDisposeBag = DisposeBag()
        if var updateReq = sessionInfo.request as? Email_Client_V1_MailUpdateAccountRequest {
            let enable = updateReq.account.mailSetting.enableStranger // 方便扩展，目前只有关闭能重试
            MailLogger.info("[mail_stranger] retry updateReq enable: \(enable)")
            Store.settingData.updateSettings(.strangerMode(enable: enable), of: &updateReq.account)
        } else if let manageReq = sessionInfo.request as? Email_Client_V1_MailManageStrangerRequest {

//            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
//                Store.settingData.updateBatchChangeSession(batchChangeInfo: MailBatchChangeInfo(sessionID: "456", request: Email_Client_V1_MailManageStrangerRequest(), status: .processing, totalCount: 0))
//                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
//                    Store.settingData.updateBatchChangeSession(batchChangeInfo: MailBatchChangeInfo(sessionID: "456", request: Email_Client_V1_MailManageStrangerRequest(), status: .success, totalCount: 2))
//                })
//            })
//            updateSessionInfo.status = .canceled
//            Store.settingData.updateBatchChangeSession(batchChangeInfo: updateSessionInfo) //, pushChange: false)
//            return

            MailLogger.info("[mail_stranger] retry manageReq type: \(manageReq.manageType) threadIDs: \(manageReq.threadIds) isSelectAll: \(manageReq.isSelectAll) maxTimeStamp: \(manageReq.maxTimestamp)")
            delegate?.retryManageStrangerThread(type: manageReq.manageType, threadIds: manageReq.threadIds, isSelectAll: manageReq.isSelectAll, maxTimestamp: manageReq.maxTimestamp)
        }
        //Store.settingData.clearBatchChangeSessionIDs(sessionInfo.sessionID) // 取消的话会导致外面消失loading

        updateSessionInfo.status = .canceled
        Store.settingData.updateBatchChangeSession(batchChangeInfo: updateSessionInfo) //, pushChange: false)
    }

    func upsetLoadingText() -> String {
        if sessionInfo.status == .failed {
            return BundleI18n.MailSDK.Mail_StrangerMail_PerformingAction_ActionFailed_Title
        } else if let req = sessionInfo.request as? Email_Client_V1_MailManageStrangerRequest, req.manageType == .reject {
            return BundleI18n.MailSDK.Mail_StrangerMail_EmailsMovedToTrash_Text
        } else {
            return BundleI18n.MailSDK.Mail_StrangerMail_EmailsMovedToInbox_Text
        }
    }

    func setupSelectAllViews() {
        loadingBackground.snp.makeConstraints { make in
            make.width.equalTo(loadingBgWidth)
            make.center.equalToSuperview()
            make.height.equalTo(loadingBgHeight)
        }

        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .center
        loadingBackground.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        titleLabel.text = upsetLoadingText()
        titleLabel.sizeToFit()

        subTitleLabel.isHidden = sessionInfo.status != .failed
        subTitleLabel.numberOfLines = 0
        subTitleLabel.font = UIFont.systemFont(ofSize: 16)
        subTitleLabel.textColor = UIColor.ud.textTitle
        subTitleLabel.textAlignment = .center
        subTitleLabel.text = BundleI18n.MailSDK.Mail_StrangerMail_PerformingAction_ActionFailedRetry_Desc
        loadingBackground.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.height.equalTo(22)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        subTitleLabel.sizeToFit()

        progressView.isHidden = sessionInfo.status != .processing
        loadingBackground.addSubview(progressView)
        progressView.snp.makeConstraints({ make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview()
            make.height.equalTo(4)
            make.top.equalTo(titleLabel.snp.bottom).offset(26)
        })

//        loadingBackground.isHidden = sessionInfo.status != .failed
//        loadingBackground.snp.makeConstraints { make in
//            make.width.equalTo(loadingBgWidth)
//            make.center.equalToSuperview()
////            if sessionInfo.status == .failed {
////                make.bottom.equalTo(subTitleLabel.snp.bottom).offset(36)
////            } else {
////                make.bottom.equalTo(progressView.snp.bottom).offset(36)
////            }
//            make.height.equalTo(loadingBgHeight)
//        }

        sepView.backgroundColor = UIColor.ud.lineDividerDefault
        loadingBackground.addSubview(sepView)
        sepView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.width.equalToSuperview()
            if sessionInfo.status == .failed {
                make.top.equalTo(subTitleLabel.snp.bottom).offset(24)
            } else {
                make.top.equalTo(progressView.snp.bottom).offset(28)
            }
        }

        contentView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.width.equalTo(loadingBgWidth)
            make.height.equalTo(49)
            make.top.equalTo(sepView.snp.bottom)
            make.centerX.equalToSuperview()
        }
        addFailCaseButton()
    }

    func setupCommonView() {
        if !isSelectAllReq() {
            contentView.backgroundColor = UIColor.dynamic(light: UIColor.white.withAlphaComponent(0.3), dark: UIColor.black.withAlphaComponent(0.3))
        } else {
            contentView.backgroundColor = UIColor.ud.bgMask
        }
        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.height.equalTo(Display.height)
            make.centerY.left.right.bottom.equalToSuperview()
        }

        loadingBackground.clipsToBounds = false
        loadingBackground.backgroundColor = UIColor.ud.bgFloat
        loadingBackground.layer.ud.setShadow(type: .s4DownPri)
        loadingBackground.layer.cornerRadius = 8
        loadingBackground.layer.masksToBounds = true
        contentView.addSubview(loadingBackground)
    }

    func setupViews() {
//        loadingAnimation.text = ""
//        loadingAnimation.play()
//        loadingAnimation.backgroundColor = UIColor.ud.bgFloat
//        loadingBackground.addSubview(loadingAnimation)
//        loadingAnimation.snp.makeConstraints { make in
//            make.top.equalTo(24)
//            make.width.height.equalTo(125)
//            make.centerX.equalToSuperview()
//        }
//        loadingAnimation.isHidden = sessionInfo.status == .failed
        
        failIcon.isHidden = sessionInfo.status != .failed
        failIcon.image = Resources.feed_error_icon
        loadingBackground.addSubview(failIcon)
        failIcon.snp.makeConstraints { make in
            make.top.equalTo(24)
            make.width.height.equalTo(125)
            make.centerX.equalToSuperview()
        }

        loadingText.numberOfLines = 0
        loadingText.font = UIFont.systemFont(ofSize: 16)
        loadingText.textColor = UIColor.ud.textCaption
        loadingText.textAlignment = .center
        loadingBackground.addSubview(loadingText)
        loadingText.snp.makeConstraints { make in
            make.top.equalTo(failIcon.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        if sessionInfo.status != .failed {
            self.loadingAnimation = UDToast.showLoading(with: upsetLoadingText(), on: contentView, operationCallBack: { [weak self] _ in
                self?.closeButtonClicked()
            })
        } else {
            loadingText.text = upsetLoadingText()
            loadingText.sizeToFit()
        }
        loadingBackground.isHidden = sessionInfo.status != .failed
        loadingBackground.snp.makeConstraints { make in
            make.width.equalTo(loadingBgWidth)
            //make.height.equalTo(loadingBgHeight)
            make.center.equalToSuperview()
            make.bottom.equalTo(loadingText.snp.bottom).offset(36)
        }

        sepView.backgroundColor = UIColor.ud.lineDividerDefault
        sepView.isHidden = sessionInfo.status != .failed
        loadingBackground.addSubview(sepView)
        sepView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.width.equalToSuperview()
            make.top.equalTo(loadingText.snp.bottom).offset(24)
        }
        addFailCaseButton()
    }

    func addFailCaseButton() {
        contentView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.width.equalTo(loadingBgWidth / 2.0)
            make.left.equalTo(loadingBackground.snp.left)
            make.height.equalTo(49)
            make.top.equalTo(sepView.snp.bottom)
        }
        contentView.addSubview(retryButton)
        retryButton.snp.makeConstraints { make in
            make.width.equalTo(loadingBgWidth / 2.0)
            make.right.equalTo(loadingBackground.snp.right)
            make.height.equalTo(49)
            make.top.equalTo(sepView.snp.bottom)
        }

        let retryButtonSep = UIView()
        retryButtonSep.backgroundColor = UIColor.ud.lineDividerDefault
        retryButton.addSubview(retryButtonSep)
        retryButtonSep.snp.makeConstraints { make in
            make.height.equalTo(49)
            make.width.equalTo(0.5)
            make.left.height.top.equalToSuperview()
        }

        let cancelButtonSep = UIView()
        cancelButtonSep.backgroundColor = UIColor.ud.lineDividerDefault
        cancelButton.addSubview(cancelButtonSep)
        cancelButtonSep.snp.makeConstraints { make in
            make.height.equalTo(49)
            make.width.equalTo(0.5)
            make.right.height.top.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
