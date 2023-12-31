//
//  BitableAdPermApplyView.swift
//  SKCommon
//
//  Created by zhysan on 2022/10/17.
//

import Foundation
import SKResource
import SnapKit
import SKFoundation
import SwiftyJSON
import UniverseDesignEmpty
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignButton
import UniverseDesignToast
import SKInfra
import EENavigator

class BitableAdPermApplyView: UIView {
    
    // MARK: - public
    func refreshApplyStatus() {
        guard let pm = DocsContainer.shared.resolve(PermissionManager.self) else {
            return
        }
        applyStatusRequest = pm.getBitableAdPermApplyStatus(token: token, completion: { status in
            self.updateApplyStatus(status)
        })
    }
    
    // MARK: - private vars
    
    private let wrapperView: UIView = {
        UIView()
    }()
    
    private let imageView: UIImageView = {
        UIImageView(image: UDEmptyType.noAccess.defaultImage())
    }()
    
    private let titleLabel: UILabel = {
        let vi = UILabel()
        vi.font = UDFont.title3
        vi.textColor = UDColor.textTitle
        vi.textAlignment = .center
        vi.numberOfLines = 0
        vi.text = BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessBitable_Title
        return vi
    }()
    
    private let detailLabel: UILabel = {
        let vi = UILabel()
        vi.numberOfLines = 0
        vi.textAlignment = .center
        vi.font = UDFont.body2
        vi.textColor = UDColor.textTitle
        return vi
    }()
    
    private let operationWrapper: UIView = {
        let vi = UIView()
        vi.backgroundColor = UDColor.bgBodyOverlay
        vi.layer.cornerRadius = 8.0
        vi.layer.masksToBounds = true
        return vi
    }()
    
    private let tipsLabel: UILabel = {
        let vi = UILabel()
        vi.font = UDFont.body2
        vi.textAlignment = .center
        vi.numberOfLines = 0
        vi.lineBreakMode = .byWordWrapping
        vi.setContentHuggingPriority(.required, for: .vertical)
        return vi
    }()
    
    private let textField: UDTextField = {
        let config = UDTextFieldUIConfig(
            isShowBorder: true,
            backgroundColor: UDColor.udtokenComponentOutlinedBg,
            borderColor: UDColor.lineBorderComponent,
            errorMessege: BundleI18n.SKResource.Bitable_AdvancedPermission_MaxNotesLength
        )
        let vi = UDTextField(config: config)
        vi.input.attributedPlaceholder = NSAttributedString(
            string: BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessBitable_AddNote_Placeholder,
            attributes: [.foregroundColor: UDColor.textPlaceholder,
                         .font: UDFont.body0]
        )
        vi.cornerRadius = 6.0
        vi.input.returnKeyType = .done
        return vi
    }()
    
    private let applyButton: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .middle
        let vi = UDButton(config)
        vi.titleLabel?.font = UDFont.title4
        vi.setTitle(BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessBitable_Apply_Button, for: .normal)
        vi.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        vi.layer.cornerRadius = 6.0
        return vi
    }()
    
    private let token: String
    
    private let owner: (name: String, id: String)
    
    private let tracker: PermissionStatistics?
    
    private let ownerTapAction: ((String) -> Void)?
    
    private var applyRequest: DocsRequest<JSON>?
    
    private var applyStatusRequest: DocsRequest<JSON>?
    
    private var displayUserName: String {
        // 去掉 "所有者" 前缀
        owner.name.isEmpty ? "" : owner.name
    }
    
    private var keyboardAlignCst: Constraint?
    
    private let getHostVCHandler: () -> UIViewController?
    
    // MARK: - life cycle
    
    init(
        token: String,
        owner: (name: String, id: String),
        tracker: PermissionStatistics?,
        ownerTapAction: ((String) -> Void)?,
        getHostVCHandler: @escaping () -> UIViewController?
    ) {
        self.token = token
        self.owner = owner
        self.tracker = tracker
        self.ownerTapAction = ownerTapAction
        self.getHostVCHandler = getHostVCHandler
        super.init(frame: .zero)
        
        subviewsInit()
        stateInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        applyRequest?.cancel()
        applyRequest = nil
        applyStatusRequest?.cancel()
        applyStatusRequest = nil
    }
    
    // MARK: - private
    
    // MARK: - touch actions
    
    private func bindActions() {
        applyButton.addTarget(self, action: #selector(onApplyButtonTapped(_:)), for: .touchUpInside)
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(onBackgroundTapped(_:)))
        addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(onDetailLabelTapped(_:)))
        detailLabel.isUserInteractionEnabled = true
        detailLabel.addGestureRecognizer(tap2)
    }
    
    @objc
    private func onApplyButtonTapped(_ sender: UDButton) {
        textField.resignFirstResponder()
        applyButton.showLoading()
        applyRequest = DocsContainer.shared.resolve(PermissionManager.self)!.applyBitableAdPerm(
            token: token,
            message: textField.text ?? "",
            completion: { [weak self] error in
                guard let self = self else {
                    return
                }
                self.applyButton.hideLoading()
                let container = self.window ?? self
                if let error = error {
                    self.tracker?.reportAdPermApplyClick(.apply(isSuccess: false, isComment: self.textField.text?.isEmpty == false))
                    switch error {
                    case .unknown:
                        UDToast.showFailure(
                            with: BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessBitable_ApplySentFailed_Toast,
                            on: container
                        )
                    case .containSensitiveWords:
                        UDToast.showFailure(
                            with: BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessBitable_ApplySentFailed_NotesContainSensitiveInfo_Toast,
                            on: container
                        )
                    case .alreadyHavePerm:
                        UDToast.showFailure(
                            with: BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessBitable_ApplySentFailed_AlreadyHavePerm_Toast,
                            on: container
                        )
                    }
                    return
                }
                self.tracker?.reportAdPermApplyClick(.apply(isSuccess: true, isComment: self.textField.text?.isEmpty == false))
                self.textField.text = nil
                self.textField.setStatus(.normal)
                UDToast.showSuccess(
                    with: BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessBitable_ApplySent_Toast,
                    on: container
                )
            })
    }
    
    @objc
    private func onBackgroundTapped(_ sender: UITapGestureRecognizer) {
        textField.resignFirstResponder()
    }
    
    @objc
    private func onDetailLabelTapped(_ sender: UITapGestureRecognizer) {
        guard let attrText = detailLabel.attributedText, !displayUserName.isEmpty else {
            return
        }
        let textStorage = NSTextStorage(attributedString: attrText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: CGSize(width: detailLabel.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.maximumNumberOfLines = 100
        textContainer.lineBreakMode = detailLabel.lineBreakMode
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)
        let index = layoutManager.characterIndex(
            for: sender.location(in: sender.view),
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
        let range = (attrText.string as NSString).range(of: displayUserName)
        if range.contains(index) {
            tracker?.reportAdPermApplyClick(.owner_name)
            ownerTapAction?(owner.id)
        }
    }
    
    // MARK: - private funcs
    
    private func updateApplyStatus(_ status: BitableAdPermApplyStatus) {
        detailLabel.attributedText = getDetailAttrText(for: status)
        switch status {
        case .allow:
            self.operationWrapper.isHidden = false
        case .deny:
            self.operationWrapper.isHidden = true
        }
    }
    
    private func getDetailAttrText(for applyStatus: BitableAdPermApplyStatus) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        style.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UDColor.textTitle,
            .font: UDFont.body2,
            .paragraphStyle: style
        ]
        let string: String
        switch applyStatus {
        case .allow:
            string = BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessBitable_Description(displayUserName)
        case .deny:
            string = BundleI18n.SKResource.Bitable_AdvancedPermissions_NoPermissionToAccess_Desc(displayUserName)
        }
        let attrStr = NSMutableAttributedString(string: string, attributes: attributes)
        let linkRange = (string as NSString).range(of: displayUserName)
        if linkRange.location != NSNotFound {
            attrStr.addAttributes(
                [.font: UDFont.body1,
                 .foregroundColor: UDColor.textLinkNormal],
                range: linkRange
            )
        }
        return attrStr
    }
    
    private func updateTips() {
        guard UserScopeNoChangeFG.ZYS.baseAdPermRoleInheritance else {
            tipsLabel.isHidden = true
            return
        }
        tipsLabel.isHidden = false
        let docName = BundleI18n.SKResource.Bitable_AdvancedPermissionsInherit_RequestCard_HowToAssign_Link
        let tips = BundleI18n.SKResource.Bitable_AdvancedPermissionsInherit_RequestCard_ViewDoc_Desc(docName)
        
        let attrStr = NSMutableAttributedString(string: tips, attributes: [.foregroundColor: UDColor.textCaption])
        let range = (tips as NSString).range(of: docName)
        attrStr.setAttributes([.foregroundColor: UDColor.textLinkNormal], range: range)
        tipsLabel.attributedText = attrStr
        
        tipsLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTipsClick(_:)))
        tipsLabel.addGestureRecognizer(tap)
    }
    
    @objc private func onTipsClick(_ sender: UITapGestureRecognizer) {
        guard let from = getHostVCHandler() else {
            DocsLogger.error("[BAP] ad perms tips url open failed: nil from")
            return
        }
        do {
            DocsLogger.info("[BAP] ad perms tips url open!")
            tracker?.reportAdPermApplyClick(.tooltips)
            let url = try HelpCenterURLGenerator.generateURL(article: .baseAdPermSettingTips)
            Navigator.shared.open(url, from: from)
        } catch {
            DocsLogger.error("[BAP] ad perm tips generate error", error: error)
        }
    }
    
    // MARK: - observer (keyboard dismiss handle)
    
    private func bindObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWasShown(_:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillBeHidden(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc
    private func keyboardWasShown(_ sender: Notification) {
        guard let info = sender.userInfo, let kbFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            DocsLogger.error("missing keyboard frame info")
            return
        }
        guard let tfFrame = window?.convert(textField.frame, from: operationWrapper), tfFrame.maxY > kbFrame.minY else {
            return
        }
        keyboardAlignCst?.update(inset: kbFrame.height)
        keyboardAlignCst?.activate()
        UIView.animate(withDuration: 0.1) {
            self.layoutIfNeeded()
        }
    }
    
    @objc
    private func keyboardWillBeHidden(_ sender: Notification) {
        keyboardAlignCst?.deactivate()
        UIView.animate(withDuration: 0.1) {
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - init
    
    private func subviewsInit() {
        addSubview(wrapperView)
        wrapperView.addSubview(imageView)
        wrapperView.addSubview(titleLabel)
        wrapperView.addSubview(detailLabel)
        wrapperView.addSubview(operationWrapper)
        operationWrapper.addSubview(textField)
        operationWrapper.addSubview(applyButton)
        addSubview(tipsLabel)
    
        wrapperView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(28)
            make.centerY.equalToSuperview().offset(-32).priority(.high)
        }
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(100.0)
            make.top.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(12.0)
            make.height.greaterThanOrEqualTo(22.0)
            make.left.right.equalToSuperview()
        }
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16.0)
            make.height.greaterThanOrEqualTo(20)
            make.left.right.equalToSuperview()
        }
        operationWrapper.snp.makeConstraints { make in
            make.top.equalTo(detailLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        textField.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview().inset(12)
            make.height.greaterThanOrEqualTo(48.0)
            self.keyboardAlignCst = make.bottom.equalTo(self).inset(0).constraint
        }
        keyboardAlignCst?.deactivate()
        applyButton.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(10.0)
            make.left.right.equalToSuperview().inset(12)
            make.height.equalTo(48.0)
            make.bottom.equalToSuperview().inset(12)
        }
        tipsLabel.snp.makeConstraints { make in
            make.top.equalTo(wrapperView.snp.bottom).offset(36)
            make.left.right.equalToSuperview().inset(16)
        }
    }
    
    private func stateInit() {
        // 默认允许申请，异步更新状态，后端做兜底拦截
        updateApplyStatus(.allow)
        
        updateTips()
        
        textField.delegate = self
        
        bindActions()
        bindObservers()
    }
}

// MARK: - UDTextFieldDelegate

private let kTextFieldMaxLength = 300

extension BitableAdPermApplyView: UDTextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tracker?.reportAdPermApplyClick(.comment)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {
            return false
        }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        let ok = updatedText.count <= kTextFieldMaxLength
        if ok {
            self.textField.setStatus(.normal)
        } else {
            self.textField.setStatus(.error)
        }
        return ok
    }
}
