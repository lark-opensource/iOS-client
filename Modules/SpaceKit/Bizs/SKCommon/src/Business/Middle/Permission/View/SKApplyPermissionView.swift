//
//  SKApplyPermissionView.swift
//  SKUIKit
//
//  Created by CJ on 2020/9/20.
// swiftlint:disable file_length

import UIKit
import SKFoundation
import SKResource
import UniverseDesignActionPanel
import SKUIKit
import SwiftyJSON
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignInput
import UniverseDesignButton
import SpaceInterface
import SKInfra
import RxSwift

public protocol SKApplyPermissionViewDelegate: AnyObject {
    func presentVC(_ vc: UIViewController, animated: Bool)
    func showOwnerProfile(ownerID: String, ownerName: String)
    func getHostVC() -> UIViewController?
}

//部分类型的文件，可能仅支持设置部分权限，如只读，只写，所以定义此枚举
public enum SpecialPermission: Int {
    case normal = 0
    case onlyRead
    case onlyEdit
}

// 支持改变预览模式
public protocol DKViewModeChangable {
    func changeMode(_ mode: DrivePreviewMode, animate: Bool)
}

public enum SKApplyPermissionBlockType: Int {
    case userPermissonBlock = 0  //用户权限管控
    case adminBlock // admin管控 (“文件预览与查看”精细化权限管控)
    case bitablePro // Bitable 高级权限管控
    case shareControlByCAC // cac分享管控
    case previewControlByCAC //cac预览管控
    case viewBlockByAudit // 审计管控阅读权限
}

public final class SKApplyPermissionView: UIView {
    public var tipTitle: String? {
        didSet {
            tipTitleLabel.text = tipTitle
        }
    }
    
    public var iconImage: UIImage? {
        didSet {
            iconImageView.image = iconImage
        }
    }
    
    public var tipDetailLabelHidden: Bool = false {
        didSet {
            tipDetailLabel.isHidden = tipDetailLabelHidden
        }
    }
        
    public var tipDetail: String? {
        didSet {
            tipDetailLabel.text = tipDetail
        }
    }
    
    public var tipDetailLabelText: String? {
        didSet {
            tipDetailLabel.text = tipDetailLabelText
        }
    }
    
    public weak var delegate: SKApplyPermissionViewDelegate?
    private var filePermissionRequest: DocsRequest<[String: Any]>?
    let token: String
    let type: DocsType
    private var canApplyPermission: Bool
    let permStatistics: PermissionStatistics?
    private var ownerName: String
    private var ownerID: String
    private var willShowObserver: NSObjectProtocol?
    private var willHideObserver: NSObjectProtocol?
    private var contentViewMaxY: CGFloat {
        if !applyContainer.isHidden {
            let convertRect = applyContainer.convert(applyContainer.bounds, to: businessWindow)
            return convertRect.maxY
        } else {
            let convertRect = auditApplyView.convert(auditApplyView.bounds, to: businessWindow)
            return convertRect.maxY
        }
    }
    private var offsetY: CGFloat = 0

    private var linkRanges: [NSRange] = []
    private var ownerNameRange: NSRange?
    public var paragraphStyle: NSMutableParagraphStyle?

    private let applyType: SKApplyPermissionBlockType
    let disposeBag = DisposeBag()

    private var businessWindow: UIWindow? {
        return window
    }

    private static func handelKeyboard(name: NSNotification.Name, action: @escaping (CGRect, TimeInterval) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { (notification) in
            guard let userinfo = notification.userInfo else {
                assertionFailure()
                return
            }
            let duration = userinfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            guard let toFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                assertionFailure()
                return
            }
            action(toFrame, duration ?? 0)
        }
    }
    
    deinit {
        if canApplyPermission {
            permStatistics?.reportPermissionWithoutPermissionClick(click: .back, target: .noneTargetView, triggerReason: .applyUserPermission)
        } else if applyType == .viewBlockByAudit {
            permStatistics?.reportPermissionWithoutPermissionClick(click: .back, target: .noneTargetView, triggerReason: .applyAuditExempt)
        } else {
            permStatistics?.reportPermissionUnableToApplyClick(click: .back, target: .noneTargetView)
        }
        if let willShow = willShowObserver, let willHide = willHideObserver {
            NotificationCenter.default.removeObserver(willShow)
            NotificationCenter.default.removeObserver(willHide)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(token: String,
                type: DocsType,
                canApplyPermission: Bool,
                ownerName: String,
                ownerID: String,
                specialPermission: SpecialPermission = .normal,
                permStatistics: PermissionStatistics,
                applyType: SKApplyPermissionBlockType
    ) {
        self.token = token
        self.type = type
        self.ownerName = ownerName
        self.ownerID = ownerID
        self.canApplyPermission = canApplyPermission
        self.permStatistics = permStatistics
        self.applyType = applyType
        super.init(frame: .zero)
        
        self.setupUI()
        self.setupLayout()
        self.addTapGesture()
        self.addObserver()
        self.updateData(canApplyPermission: canApplyPermission, ownerName: ownerName)
        self.updatePermissionTypeButton(specialPermission: specialPermission)
        self.updateApplyType()
        if canApplyPermission {
            self.permStatistics?.reportPermissionWithoutPermissionView(triggerReason: .applyUserPermission)
        } else if applyType == .viewBlockByAudit {
            self.permStatistics?.reportPermissionWithoutPermissionView(triggerReason: .applyAuditExempt)
        } else {
            self.permStatistics?.reportPermissionUnableToApplyView()
        }
    }
    
    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(scrollView)
        addSubview(bitableAdPermView)
        scrollView.addSubview(tipContainer)
        scrollView.addSubview(applyContainer)
        scrollView.addSubview(auditApplyView)
        tipContainer.addSubview(iconImageView)
        tipContainer.addSubview(tipTitleLabel)
        tipContainer.addSubview(tipDetailLabel)
        applyContainer.addSubview(applyLabel)
        applyContainer.addSubview(arrowImageView)
        applyContainer.addSubview(permissionTypeButton)
        applyContainer.addSubview(applyCommentContainer)
        applyContainer.addSubview(applyButton)
        applyCommentContainer.addSubview(applyCommentField)
    }
    
    private func setupLayout() {
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tipContainer.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(100)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().offset(-56).priority(999)
            make.width.lessThanOrEqualTo(320)
        }

        auditApplyView.snp.makeConstraints { make in
            make.top.equalTo(tipContainer.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(320).priority(.required)
            make.width.equalToSuperview().offset(-56).priority(.high)
            make.bottom.lessThanOrEqualToSuperview().offset(-40)
        }

        applyContainer.snp.makeConstraints { (make) in
            make.top.equalTo(tipContainer.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().offset(-56).priority(999)
            make.width.lessThanOrEqualTo(320)
            make.bottom.lessThanOrEqualToSuperview().offset(-40)
        }
        iconImageView.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(112)
        }
        tipTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconImageView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
        }
        tipDetailLabel.snp.makeConstraints { (make) in
            make.top.equalTo(tipTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        applyLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(12)
            make.height.equalTo(24)
        }
        permissionTypeButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(applyLabel)
            make.leading.equalTo(applyLabel.snp.trailing).offset(8)
            make.height.equalTo(24)
        }
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(applyLabel)
            make.leading.equalTo(permissionTypeButton.snp.trailing).offset(4)
        }
        applyCommentContainer.snp.makeConstraints { (make) in
            make.top.equalTo(permissionTypeButton.snp.bottom).offset(18)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }
        applyCommentField.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(1)
            make.leading.trailing.equalToSuperview().inset(1)
        }
        applyButton.snp.makeConstraints { (make) in
            make.top.equalTo(applyCommentField.snp.bottom).offset(18)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(-18)
        }
        bitableAdPermView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        addGestureRecognizer(tap)
    }
    
    private func addObserver() {
        willShowObserver =
            SKApplyPermissionView.handelKeyboard(name: UIResponder.keyboardWillShowNotification, action: { [weak self] (keyboardRect, _) in
                guard let self = self else { return }
                if self.scrollView.superview != nil {
                    if keyboardRect.size.height < 120 {
                        return
                    }
                    self.offsetY = keyboardRect.origin.y - self.contentViewMaxY
                    self.updateScrollViewOffsetY(isKeyboardHidden: false)
                }
            })
        willHideObserver =
            SKApplyPermissionView.handelKeyboard(name: UIResponder.keyboardWillHideNotification, action: { [weak self] (_, _) in
                self?.updateScrollViewOffsetY(isKeyboardHidden: true)
            })
    }
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var tipContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var applyContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBodyOverlay
        view.layer.cornerRadius = 4.0
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDEmptyType.noAccess.defaultImage()
        return imageView
    }()
    
    private lazy var tipTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.ud.N900
        return label
    }()
    
    private lazy var tipDetailLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N600
        return label
    }()
    
    private lazy var permissionTypeButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(UDColor.colorfulBlue, for: .normal)
        button.setTitle(BundleI18n.SKResource.Drive_Drive_ReadPermission, for: .normal)
        button.addTarget(self, action: #selector(handlePermissionTypeButtonClick(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var applyLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Drive_Drive_ApplyFor
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ud.N600
        return label
    }()
    
    private lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.SKResource.Doc.docs_trianglesmall_blue
        return imageView
    }()
    
    private lazy var applyCommentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        view.layer.cornerRadius = 6.0
//        view.layer.borderColor = UIColor.ud.N300.cgColor
//        view.layer.borderWidth = 1
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var applyCommentField: UDTextField = {
        let textField = UDTextField()
        textField.cornerRadius = 6.0
        var config = UDTextFieldUIConfig()
        config.isShowBorder = true
        config.backgroundColor = .clear
        textField.config = config
        textField.input.attributedPlaceholder =
            NSAttributedString(string: BundleI18n.SKResource.Doc_Facade_AddRemarks,
                               attributes: [.foregroundColor: UIColor.ud.N500,
                                            .font: UIFont.systemFont(ofSize: 14)])
        textField.input.returnKeyType = .done
        textField.delegate = self
        return textField
    }()
    
    private lazy var applyButton: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .middle
        let button = UDButton(config)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitle(BundleI18n.SKResource.Doc_Permission_SendRequest, for: .normal)
//        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
//        button.backgroundColor = UIColor.ud.colorfulBlue
        button.layer.cornerRadius = 4.0
        button.addTarget(self, action: #selector(handleApplyButtonClick(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var bitableAdPermView: BitableAdPermApplyView = {
        BitableAdPermApplyView(
            token: token,
            owner: (ownerName, ownerID),
            tracker: permStatistics,
            ownerTapAction: { [weak self] id in
                self?.delegate?.showOwnerProfile(ownerID: id, ownerName: "")
            },
            getHostVCHandler: { [weak self] in
                return self?.delegate?.getHostVC()
            }
        )
    }()

    private(set) lazy var auditApplyView: SKAuditApplyView = makeAuditApplyView()

    private func updateApplyButton(loading: Bool) {
        if loading {
            self.applyButton.showLoading()
            self.applyButton.setTitle(BundleI18n.SKResource.LarkCCM_Perm_PermissionRequesting_Mobile, for: .normal)
        } else {
            self.applyButton.hideLoading()
            self.applyButton.setTitle(BundleI18n.SKResource.Doc_Permission_SendRequest, for: .normal)
        }
    }
    
//    public func changeMode(_ mode: SKCommon.DrivePreviewMode, animate: Bool) {
//        guard displayMode != mode else { return }
//        displayMode = mode
//
//        iconImageView.snp.updateConstraints { make in
//            make.top.centerX.equalToSuperview()
//            make.width.height.equalTo(iconSize)
//        }
//
//        tipDetailLabel.snp.updateConstraints { make in
//            make.top.equalTo(tipTitleLabel.snp.bottom).offset(iconLabelMargin)
//        }
//
//        tipDetailLabel.font = descFont
//
//        if animate {
//            UIView.animate(withDuration: 0.25) {
//                self.setNeedsLayout()
//                self.layoutIfNeeded()
//            }
//        }
//    }
//
//    private var iconSize: CGFloat {
//        return displayMode == .normal ? 112 : 75
//    }
//
//    private var iconLabelMargin: CGFloat {
//        return displayMode == .normal ? 12 : 4
//    }
//
//    private var descFont: UIFont {
//        return displayMode == .card ? UIFont.systemFont(ofSize: 12) : UDFont.body2(.fixed)
//    }
}

extension SKApplyPermissionView {
    private func updateData(canApplyPermission: Bool, ownerName: String) {
        self.ownerName = ownerName
        self.canApplyPermission = canApplyPermission
        if canApplyPermission {
            tipTitleLabel.text = BundleI18n.SKResource.Doc_Permission_OwnerNotAuthorizeCross
            tipDetailLabel.attributedText = attributedStringForTipDetail()
            applyContainer.isHidden = false
        } else {
            tipTitleLabel.text = BundleI18n.SKResource.Doc_Permission_AdminNotAuthorizeCross
            tipDetailLabel.attributedText = attributedStringForTipDetail()
            applyContainer.isHidden = true
        }

        if let range = ownerNameRange {
            addTapRange(range)
        }
    }

    private func updatePermissionTypeButton(specialPermission: SpecialPermission) {
        guard specialPermission != .normal else { return }
        permissionTypeButton.isEnabled = false
        arrowImageView.isHidden = true
        switch specialPermission {
        case .onlyRead:
            permissionTypeButton.setTitle(BundleI18n.SKResource.Drive_Drive_ReadPermission, for: .normal)
        case .onlyEdit:
            permissionTypeButton.setTitle(BundleI18n.SKResource.Drive_Drive_EditPermission, for: .normal)
        default: break
        }
    }
    
    private func updateApplyType() {
        switch applyType {
        case .userPermissonBlock, .adminBlock, .shareControlByCAC, .previewControlByCAC:
            scrollView.isHidden = false
            applyContainer.isHidden = !canApplyPermission
            auditApplyView.isHidden = true
            bitableAdPermView.isHidden = true
        case .viewBlockByAudit:
            scrollView.isHidden = false
            applyContainer.isHidden = true
            auditApplyView.isHidden = false
            bitableAdPermView.isHidden = true
        case .bitablePro:
            scrollView.isHidden = true
            bitableAdPermView.isHidden = false
            bitableAdPermView.refreshApplyStatus()
            permStatistics?.reportAdPermApplyView()
        }
    }
    
    private func updateScrollViewOffsetY(isKeyboardHidden: Bool) {
        if self.scrollView.superview != nil {
            if !isKeyboardHidden && offsetY < 0 {
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y - offsetY), animated: true)
            } else {
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: true)
                offsetY = 0
            }
        }
    }
    
    private func attributedStringForTipDetail() -> NSAttributedString {
        var userName = ""
        var tenantName = ""
        if let currentUserInfo = User.current.info {
            userName = currentUserInfo.nameForDisplay()
            tenantName = (currentUserInfo.isToNewC ? BundleI18n.SKResource.Doc_Permission_PersonalAccount : currentUserInfo.tenantName) ?? ""
            if userName.isEmpty {
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                if let userID = User.current.info?.userID,
                   let userInfo = dataCenterAPI?.userInfo(for: userID) {
                    userName = userInfo.nameForDisplay()
                    tenantName = (userInfo.isToNewC ? BundleI18n.SKResource.Doc_Permission_PersonalAccount : userInfo.tenantName) ?? ""
                }
            }
        }
       
        var currentUserName = ""
        if !userName.isEmpty {
            currentUserName = "\(tenantName)-\(userName)"
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.N900, .font: UIFont.systemFont(ofSize: 14), .paragraphStyle: paragraph]
        if applyType == .viewBlockByAudit {
            let string = BundleI18n.SKResource.LarkCCM_CM_Sharing_AskForFurtherViewPerm_Desc(currentUserName)
            let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
            let userNameRange = (string as NSString).range(of: currentUserName)
            if userNameRange.length > 0 {
                attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14, weight: .medium), range: userNameRange)
            }
            return attributedString
        } else if canApplyPermission {
            // 不再需要 "所有者" 前缀
            let currentOwnerName = ownerName
            let string = BundleI18n.SKResource.Doc_Permission_CurrentUserCannotAccessApply(currentUserName, currentOwnerName)
            let attrStr = NSMutableAttributedString(string: string, attributes: attributes)
            let userNameRange = (string as NSString).range(of: currentUserName)
            let ownerNameRange = (string as NSString).range(of: currentOwnerName)
            if userNameRange.length > 0 {
                attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .medium)], range: userNameRange)
            }
            if ownerNameRange.length > 0 {
                attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .medium)], range: ownerNameRange)
                attrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ud.colorfulBlue, range: ownerNameRange)
                self.ownerNameRange = ownerNameRange
            }
            return attrStr
        } else {
            let string = BundleI18n.SKResource.Doc_Permission_CurrentUserCannotAccess(currentUserName)
            let attrStr = NSMutableAttributedString(string: string, attributes: attributes)
            let userNameRange = (string as NSString).range(of: currentUserName)
            if userNameRange.length > 0 {
                attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .medium)], range: userNameRange)
            }
            return attrStr
        }
    }
}


extension SKApplyPermissionView: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        applyCommentField.resignFirstResponder()
    }
}

extension SKApplyPermissionView {
    @objc
    func handleBackgroundTap(_ sender: UIGestureRecognizer) {
        applyCommentField.resignFirstResponder()
    }
    
    @objc
    func handlePermissionTypeButtonClick(_ sender: UIButton) {
        let permissionType = permissionTypeButton.titleLabel?.text ?? BundleI18n.SKResource.Drive_Drive_ReadPermission
        let isReadPermission = permissionType == BundleI18n.SKResource.Drive_Drive_ReadPermission
        var popSource: UDActionSheetSource?
        if SKDisplay.pad {
            popSource = UDActionSheetSource(sourceView: sender,
                                            sourceRect: CGRect(x: sender.bounds.width * 0.5, y: 0, width: 0, height: 0),
                                            preferredContentWidth: 320,
                                            arrowDirection: .down)
        }
        let actionSheet = UDActionSheet.actionSheet(popSource: popSource)
        actionSheet.addItem(text: BundleI18n.SKResource.Drive_Drive_ReadPermission, textColor: isReadPermission ? UIColor.ud.colorfulBlue : UIColor.ud.N900) { [weak self] in
            self?.permissionTypeButton.setTitle(BundleI18n.SKResource.Drive_Drive_ReadPermission, for: .normal)
        }
        actionSheet.addItem(text: BundleI18n.SKResource.Drive_Drive_EditPermission, textColor: !isReadPermission ? UIColor.ud.colorfulBlue : UIColor.ud.N900) { [weak self] in
            self?.permissionTypeButton.setTitle(BundleI18n.SKResource.Drive_Drive_EditPermission, for: .normal)
        }
        if SKDisplay.phone {
            actionSheet.addItem(text: BundleI18n.SKResource.Drive_Drive_Cancel, style: .cancel)
        }
        delegate?.presentVC(actionSheet, animated: true)
    }
    
    @objc
    func handleApplyButtonClick(_ sender: UDButton) {
        applyCommentField.resignFirstResponder()
        sendApplyPermissionRequest(permissionType: permissionTypeButton.titleLabel?.text ?? BundleI18n.SKResource.Drive_Drive_ReadPermission, comment: applyCommentField.text)
    }
    
    func sendApplyPermissionRequest(permissionType: String, comment: String?) {
        // 发送权限申请的网络请求 接口文档 https://docs.bytedance.net/doc/NuM5adQ91RnB4BbOw7HwAe#6DS9Ws
        // 阅读是1 编辑是4 分享是8
        var permission = 1
        if permissionType == BundleI18n.SKResource.Drive_Drive_ReadPermission {
            permission = 1
        } else {
            permission = 4
        }
        let isAddNotes = (comment?.count ?? 0) > 0
        let applyList: PermissionSelectOption = (permission == 1) ? .read : .edit
        permStatistics?.reportPermissionWithoutPermissionClick(click: .applyPermission,
                                                               target: .noneTargetView,
                                                               triggerReason: .applyUserPermission,
                                                               applyList: applyList,
                                                               isAddNotes: isAddNotes)

        //与explorer对obj_type的定义一致 doc是2 sheet是3 bitable是8
        var params = ["token": token,
                      "obj_type": type.rawValue,
                      "permission": permission] as [String: Any]
        params.updateValue(comment ?? "", forKey: "message")
        filePermissionRequest = DocsRequest(path: OpenAPI.APIPath.requestFilePermissionUrl, params: params)
        updateApplyButton(loading: true)
        filePermissionRequest?.start(rawResult: { [weak self] (data, response, _) in
            guard let self = self else { return }
            self.updateApplyButton(loading: false)
            let token = self.token
            let type = self.type
            if let response = response as? HTTPURLResponse, response.statusCode == 429 {
                self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendRequestMaxCount, type: .failure)
                self.reportClickSendApplyEditPermission(token: token, type: type, status: 0, message: comment, permission: permission)
                return
            }
            guard let jsonData = data,
                  let json = jsonData.json else {
                self.showToast(text: BundleI18n.SKResource.Drive_Drive_SendRequestFail, type: .failure)
                self.reportClickSendApplyEditPermission(token: token, type: type, status: 0, message: comment, permission: permission)
                return
            }
            guard let code = json["code"].int else {
                self.showToast(text: BundleI18n.SKResource.Drive_Drive_SendRequestFail, type: .failure)
                self.reportClickSendApplyEditPermission(token: token, type: type, status: 0, message: comment, permission: permission)
                return
            }
            guard code == 0 else {
                let statistics = CollaboratorStatistics(docInfo: CollaboratorAnalyticsFileInfo(fileType: self.type.name,
                                                                         fileId: self.token),
                                                        module: self.type.name)
                let manager = CollaboratorBlockStatusManager(requestType: .requestPermissionForBiz,
                                                             fromView: self,
                                                             statistics: statistics)
                manager.showRequestPermissionForBizFaliedToast(json, ownerName: self.ownerName)
                self.reportClickSendApplyEditPermission(token: token, type: type, status: 0, message: comment, permission: permission)
                return
            }
            self.showToast(text: BundleI18n.SKResource.Drive_Drive_SendRequestSuccess, type: .success)
            self.reportClickSendApplyEditPermission(token: token, type: type, status: 1, message: comment, permission: permission)
        })
    }
    
    func reportClickSendApplyEditPermission(token: String, type: DocsType, status: Int, message: String?, permission: Int, isCancel: Bool = false) {
        let note = (message?.isEmpty ?? true) ? "0" : "1"
        let per = (permission == 4) ? "edit" : "read"
        let params: [String: Any] = ["file_type": type.name,
                                     "file_id": DocsTracker.encrypt(id: token),
                                     "action": isCancel ? "cancel" : "send",
                                     "permission": per,
                                     "note": note,
                                     "status": String(status)]
        DocsTracker.log(enumEvent: .clickSendApplyEditPermission, parameters: params)
    }
}

extension SKApplyPermissionView: UDTextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        applyCommentField.resignFirstResponder()
        return true
    }
}

extension SKApplyPermissionView {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        UDToast.docs.showMessage(text, on: self.window ?? self, msgType: type)
    }
}

extension SKApplyPermissionView {
    public func addTapRange(_ range: NSRange) {
        self.linkRanges.append(range)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapTitleLable(_:)))
        self.tipDetailLabel.addGestureRecognizer(tap)
        self.tipDetailLabel.isUserInteractionEnabled = true
    }

    @objc
    func tapTitleLable(_ ges: UITapGestureRecognizer) {
        let characterIndex = characterIndexAtPoint(ges.location(in: ges.view))
        guard let attributedText = self.tipDetailLabel.attributedText,
              characterIndex >= 0,
              characterIndex < attributedText.length,
              !linkRanges.isEmpty else {
            return
        }
        let ranges = linkRanges
        for index in 0..<ranges.count {
            let range = ranges[index]
            if characterIndex >= range.location && (characterIndex <= range.location + range.length) {
                delegate?.showOwnerProfile(ownerID: ownerID, ownerName: ownerName)
            }
        }
    }

    func characterIndexAtPoint(_ location: CGPoint) -> Int {
        guard let titleLabelAttributedText = self.tipDetailLabel.attributedText else { return 0 }
        let textStorage = NSTextStorage(attributedString: titleLabelAttributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: CGSize(width: self.tipDetailLabel.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.maximumNumberOfLines = 100
        textContainer.lineBreakMode = self.tipDetailLabel.lineBreakMode
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)
        return layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}
