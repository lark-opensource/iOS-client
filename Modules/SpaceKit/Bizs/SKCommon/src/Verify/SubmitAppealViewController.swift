//
//  SubmitAppealViewController.swift
//  SKSpace
//
//  Created by majie on 2021/9/22.
//

import Foundation
import SnapKit
import SKResource
import SKFoundation
import UniverseDesignToast
import UniverseDesignColor
import SwiftyJSON
import EENavigator
import UniverseDesignEmpty
import UniverseDesignDialog
import SpaceInterface
import SKInfra

public protocol AppealInfoProvider {
    typealias AppealInfo = SubmitAppealViewController.AppealInfo
    // wiki 文件夹和 space 文件夹有一句文案不一样，考虑到其他文案没区别，暂时不拆得太细，只对一句文案特殊处理下
    var appealingTipsLine1: String { get }
    var appealingTipsLine2: String { get }
    var appealingTipsLine3: String { get }
    //drive文件
    var appealingTitle: String { get }
    var appealingSubmitTitle: String { get }
    func fetchAppealInfo(completion: @escaping (Result<SubmitAppealViewController.AppealInfo, Error>) -> Void)
}

extension SubmitAppealViewController {
    public struct AppealInfo {
        public let title: String
        public let contentDescription: String?
        public init(title: String, contentDescription: String?) {
            self.title = title
            self.contentDescription = contentDescription
        }
    }
}

public enum FromScenes {
    case driveFile(title: String)
    case folder
}

public final class SubmitAppealViewController: BaseViewController, UIGestureRecognizerDelegate {

    private var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UDColor.bgBody
        return v
    }()
    private var label: UILabel = {
       let v = UILabel()
        v.backgroundColor = .clear
        v.text = BundleI18n.SKResource.CreationMobile_appealing_folder_descripiton
        v.textColor = UDColor.textTitle
        v.textAlignment = .left
        v.font = UIFont.docs.pfsc(16)
        v.numberOfLines = 0
        return v
    }()
    private var button: UILabel = {
        let v = UILabel()
        v.backgroundColor = UIColor.ud.colorfulBlue
        v.text = BundleI18n.SKResource.CreationMobile_appealing_folder_submit
        v.textAlignment = .center
        v.font = UIFont.docs.pfsc(16)
        v.textColor = UDColor.primaryOnPrimaryFill
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 6
        v.isUserInteractionEnabled = true
        return v
    }()

    private lazy var submittedEmptyView: UDEmpty = {
        let title = UDEmptyConfig.Title(titleText: BundleI18n.SKResource.CreationMobile_appealing_folder_pending_title,
                                        font: .systemFont(ofSize: 17))
        let description = UDEmptyConfig.Description(descriptionText: BundleI18n.SKResource.CreationMobile_Appealing_folder_Result,
                                                    font: .systemFont(ofSize: 16))
        let config = UDEmptyConfig(title: title,
                                   description: description,
                                   spaceBelowImage: 16,
                                   spaceBelowTitle: 8,
                                   type: .done)
        let empty = UDEmpty(config: config)
        return empty
    }()

    private var appealDescripteView: AppealDescripteView = {
        let v = AppealDescripteView()
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 6
        return v
    }()

    private var topReviewTips = ReviewTips()
    private var midReviewTips = ReviewTips()
    private var bottomReviewTips = ReviewTips()
    private var request: DocsRequest<JSON>?
    private let token: String
    private let objType: DocsType
    private let fromScene: FromScenes
    private let appealInfoProvider: AppealInfoProvider

    public var submitCompletion: (() -> Void)?

    public init(token: String, objType: DocsType, provider: AppealInfoProvider, fromScene: FromScenes = .folder) {
        self.token = token
        self.objType = objType
        appealInfoProvider = provider
        self.fromScene = fromScene
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addGestureRecognizer()
        fetchAppealInfo()
    }

    func setupUI() {
        self.title = BundleI18n.SKResource.CreationMobile_appealing_folder_title
        self.view.backgroundColor = UDColor.bgBase
        self.view.addSubview(containerView)
        containerView.addSubview(label)
        containerView.addSubview(button)
        containerView.addSubview(appealDescripteView)
        containerView.addSubview(topReviewTips)
        containerView.addSubview(midReviewTips)
        containerView.addSubview(bottomReviewTips)
        topReviewTips.setLabelTitle(appealInfoProvider.appealingTipsLine1)
        midReviewTips.setLabelTitle(appealInfoProvider.appealingTipsLine2)
        bottomReviewTips.setLabelTitle(appealInfoProvider.appealingTipsLine3)
        setLabelTitle(appealInfoProvider.appealingTitle)

        containerView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }

        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        appealDescripteView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        topReviewTips.snp.makeConstraints { make in
            make.top.equalTo(appealDescripteView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        midReviewTips.snp.makeConstraints { make in
            make.top.equalTo(topReviewTips.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        bottomReviewTips.snp.makeConstraints { make in
            make.top.equalTo(midReviewTips.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        button.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-44)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(44)
        }
    }

    private func addGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(postAppeal))
        tapGesture.delegate = self
        button.addGestureRecognizer(tapGesture)
    }

    @objc
    func postAppeal(sender: UIGestureRecognizer) {
        UDToast.showDefaultLoading(on: self.containerView, disableUserInteraction: true)
        if UserScopeNoChangeFG.TYP.appealingForbidden {
            postAppealRequest2(completion: { [weak self] result in
                guard let self = self else { return }
                if result {
                    self.clickRefreshView()
                    self.submitCompletion?()
                }
            })
        } else {
            postAppealRequest(completion: { [weak self] result in
                guard let self = self else { return }
                if result {
                    self.clickRefreshView()
                    self.submitCompletion?()
                }
            })
        }
    }

    func postAppealRequest(completion: @escaping ((Bool) -> Void)) {
        let params: [String: Any] = ["obj_type": objType.rawValue, "obj_token": token]
        request = DocsRequest<JSON>(path: OpenAPI.APIPath.postComplaintInfo, params: params)
            .set(method: .POST)
            .start(result: { result, error in
                UDToast.removeToast(on: self.containerView)
                guard let json = result,
                      let code = json["code"].int else {
                    DocsLogger.error("request failed data invalide")
                    return
                }
                if code == 0 {
                    completion(true)
                    return
                } else if code == 10_004 {
                    UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_Folder_SubmitThreeTimesToast, on: self.containerView)
                    completion(false)
                    return
                } else if code == 10_005 {
                    UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_Folder_SubmitMaximumToast(BundleI18n.SKResource.CreationMobile_ECM_Folder_SubmitMaximumToast2),
                                     on: self.containerView)
                    completion(false)
                    return
                } else if code == 10_003 {
                    UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_appealing_folder_identical, on: self.containerView)
                    completion(false)
                    return
                } else {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: self.containerView)
                    completion(false)
                    return
                }
            })
    }

    func postAppealRequest2(completion: @escaping ((Bool) -> Void)) {
        let params: [String: Any] = ["obj_type": objType.rawValue, "obj_token": token]
        request = DocsRequest<JSON>(path: OpenAPI.APIPath.postComplaintInfo, params: params)
            .set(method: .POST)
            .start(result: { result, error in
                UDToast.removeToast(on: self.containerView)
                guard let json = result,
                      let code = json["code"].int else {
                    DocsLogger.error("request failed data invalide")
                    return
                }
                let config = UDDialogUIConfig(style: .horizontal)
                let dialog = UDDialog(config: config)
                dialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_Appeal_SubmitToFS_OverLimit_GotIt_Button)
                dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Appeal_SubmitToFS_OverLimit_FindStaff_Button, dismissCompletion: { [weak self] in
                    guard let self = self else { return }
                    let mpDomain = DomainConfig.mpAppLinkDomain
                    let urlString = "https://\(mpDomain)/TdSgr1y9"
                    if let url = URL(string: urlString) {
                        Navigator.shared.docs.showDetailOrPush(url, from: self)
                    }
                })
                if code == 0 {
                    completion(true)
                    return
                } else if code == 10_004 {
                    dialog.setContent(text: BundleI18n.SKResource.LarkCCM_Appeal_SubmitToFS_OverLimit_Descrip, style: .defaultContentStyle)
                    self.present(dialog, animated: true, completion: nil)
                    completion(false)
                    return
                } else if code == 10_005 {
                    dialog.setContent(text: BundleI18n.SKResource.CreationMobile_ECM_SubmitMaximumToast, style: .defaultContentStyle)
                    self.present(dialog, animated: true, completion: nil)
                    completion(false)
                    return
                } else {
                    dialog.setContent(text: BundleI18n.SKResource.LarkCCM_Appeal_SubmitToFS_NotApproved_Toast, style: .defaultContentStyle)
                    self.present(dialog, animated: true, completion: nil)
                    completion(false)
                    return
                }
            })
    }

    private func clickRefreshView() {
        containerView.addSubview(submittedEmptyView)
        containerView.addSubview(appealDescripteView)
        setSubmitLabelTitle(appealInfoProvider.appealingSubmitTitle)
        self.label.isHidden = true
        self.button.isHidden = true
        self.topReviewTips.isHidden = true
        self.midReviewTips.isHidden = true
        self.bottomReviewTips.isHidden = true

        submittedEmptyView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(45)
            make.left.right.equalToSuperview()
        }
        appealDescripteView.snp.makeConstraints { make in
            make.top.equalTo(submittedEmptyView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
    }

    private func fetchAppealInfo() {
        switch fromScene {
        case .folder:
            appealInfoProvider.fetchAppealInfo { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(info):
                    self.appealDescripteView.setFolderNameAndDescription(info.title, info.contentDescription)
                case let .failure(error):
                    DocsLogger.error("request appeal info failed with error", error: error)
                }
            }
        case .driveFile(title: let title):
            self.appealDescripteView.setFolderNameAndDescription(title, nil)
        }
    }

    func setLabelTitle(_ title: String) {
        label.text = title
    }

    func setSubmitLabelTitle(_ title: String) {
        let description = UDEmptyConfig.Description(descriptionText: title,
                                                                  font: .systemFont(ofSize: 16))
        let title = UDEmptyConfig.Title(titleText: BundleI18n.SKResource.CreationMobile_appealing_folder_pending_title,
                                        font: .systemFont(ofSize: 17))
        let config = UDEmptyConfig(title: title,
                                   description: description,
                                   spaceBelowImage: 16,
                                   spaceBelowTitle: 8,
                                   type: .done)
        submittedEmptyView.update(config: config)
    }
}

class AppealDescripteView: UIView {

    private var reviewContent: UILabel = {
        let v = UILabel()
        v.backgroundColor = .clear
        v.text = BundleI18n.SKResource.CreationMobile_appealing_folder_content
        v.textAlignment = .left
        v.textColor = UDColor.textCaption
        v.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return v
    }()

    private var nameTitleLabel: UILabel = {
        let v = UILabel()
        v.backgroundColor = .clear
        v.text = BundleI18n.SKResource.CreationMobile_appealing_folder_name
        v.textAlignment = .left
        v.textColor = UDColor.textCaption
        v.font = UIFont.docs.pfsc(14)
        return v
    }()

    private var folderNameLabel: UILabel = {
        let v = UILabel()
        v.backgroundColor = .clear
        v.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        v.textColor = UDColor.textTitle
        v.textAlignment = .left
        return v
    }()

    private var descriptionTitleLabel: UILabel = {
        let v = UILabel()
        v.backgroundColor = .clear
        v.text = BundleI18n.SKResource.CreationMobile_appealing_folder_desc
        v.textAlignment = .center
        v.textColor = UDColor.textCaption
        v.font = UIFont.docs.pfsc(14)
        return v
    }()

    private var descriptionContentLabel: UILabel = {
        let v = UILabel()
        v.textAlignment = .left
        v.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        v.textColor = UDColor.textTitle
        v.numberOfLines = 4
        return v
    }()

    private var nameBottomConstraint: Constraint?
    private var descriptionBottomConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        self.backgroundColor = UDColor.bgBase
        self.addSubview(reviewContent)
        self.addSubview(nameTitleLabel)
        self.addSubview(folderNameLabel)
        self.addSubview(descriptionTitleLabel)
        self.addSubview(descriptionContentLabel)

        self.backgroundColor = UIColor.ud.N100
        reviewContent.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(20)
        }

        nameTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(reviewContent.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(16)
        }

        folderNameLabel.snp.makeConstraints { make in
            make.top.equalTo(nameTitleLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(16)
            nameBottomConstraint = make.bottom.equalToSuperview().inset(16).constraint
        }
        nameBottomConstraint?.deactivate()

        descriptionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(folderNameLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(16)
        }

        descriptionContentLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionTitleLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(90)
            descriptionBottomConstraint = make.bottom.equalToSuperview().inset(16).constraint
        }
    }

    func setFolderNameAndDescription(_ name: String, _ description: String?) {
        folderNameLabel.text = name
        descriptionContentLabel.text = description
        if description != nil {
            descriptionBottomConstraint?.activate()
            nameBottomConstraint?.deactivate()
            descriptionTitleLabel.isHidden = false
            descriptionContentLabel.isHidden = false
        } else {
            descriptionBottomConstraint?.deactivate()
            nameBottomConstraint?.activate()
            descriptionTitleLabel.isHidden = true
            descriptionContentLabel.isHidden = true
        }
    }
}

private class ReviewTips: UIView {

    private let point: UIView = {
       let v = UIView()
        v.backgroundColor = UIColor.ud.colorfulBlue
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 3
        return v
    }()

    private let label: UILabel = {
        let v = UILabel()
        v.backgroundColor = .clear
        v.numberOfLines = 0
        v.font = UIFont.docs.pfsc(16)
        v.textColor = UDColor.textTitle
        v.textAlignment = .left
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        self.addSubview(point)
        self.addSubview(label)

        point.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(7)
            make.left.equalToSuperview().offset(5)
            make.height.equalTo(6)
            make.width.equalTo(6)
        }

        label.snp.makeConstraints { make in
            make.left.equalTo(point).offset(13)
            make.top.right.bottom.equalToSuperview()
        }
    }

    func setLabelTitle(_ title: String) {
        label.text = title
    }
}
