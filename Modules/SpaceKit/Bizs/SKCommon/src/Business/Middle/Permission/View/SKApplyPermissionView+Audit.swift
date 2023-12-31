//
//  SKApplyPermissionView+Audit.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/11/17.
//

import Foundation
import SKFoundation
import SKInfra
import SKResource
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignInput
import SnapKit
import SwiftyJSON
import RxSwift

/// 云文档审计的相关逻辑
extension SKApplyPermissionView {

    func makeAuditApplyView() -> SKAuditApplyView {
        let view = SKAuditApplyView()
        view.onApply = { [weak self] reason in
            self?.applyForAudit(reason: reason)
        }
        return view
    }

    private func applyForAudit(reason: String?) {
        auditApplyView.applyReasonField.resignFirstResponder()
        auditApplyView.applyButton.showLoading()
        auditApplyView.applyButton.setTitle(BundleI18n.SKResource.LarkCCM_Perm_PermissionRequesting_Mobile, for: .normal)

        AuditExemptAPI.requestExempt(objToken: token,
                                     objType: type,
                                     exemptType: .view,
                                     reason: reason)
        .subscribe { [weak self] in
            guard let self else { return }
            self.auditApplyView.applyButton.hideLoading()
            self.auditApplyView.applyButton.setTitle(BundleI18n.SKResource.Doc_Permission_SendRequest, for: .normal)
            self.showToast(text: BundleI18n.SKResource.Drive_Drive_SendRequestSuccess, type: .success)
        } onError: { [weak self] error in
            DocsLogger.error("apply for audit control exempt failed", error: error)
            guard let self else { return }
            self.auditApplyView.applyButton.hideLoading()
            self.auditApplyView.applyButton.setTitle(BundleI18n.SKResource.Doc_Permission_SendRequest, for: .normal)
            let exemptError = AuditExemptAPI.parse(error: error)
            switch exemptError {
            case .tooFrequent:
                self.showToast(text: BundleI18n.SKResource.Drive_Drive_OperationsTooFrequent, type: .failure)
            case .other:
                self.showToast(text: BundleI18n.SKResource.Drive_Drive_SendRequestFail, type: .failure)
            }
        }
        .disposed(by: disposeBag)

        permStatistics?.reportPermissionWithoutPermissionClick(click: .applyPermission,
                                                               target: .noneTargetView,
                                                               triggerReason: .applyAuditExempt,
                                                               applyList: .read,
                                                               isAddNotes: !(reason?.isEmpty ?? true))
    }
}

class SKAuditApplyView: UIView {

    private lazy var applyReasonContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        return view
    }()

    fileprivate lazy var applyReasonField: UDTextField = {
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

    fileprivate lazy var applyButton: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .middle
        let button = UDButton(config)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitle(BundleI18n.SKResource.Doc_Permission_SendRequest, for: .normal)
        button.layer.cornerRadius = 4.0
        button.addTarget(self, action: #selector(handleApplyButtonClick), for: .touchUpInside)
        return button
    }()

    fileprivate var onApply: ((String?) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UDColor.bgBodyOverlay
        layer.cornerRadius = 4

        addSubview(applyReasonContainer)
        addSubview(applyButton)
        applyReasonContainer.addSubview(applyReasonField)

        applyReasonContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(18)
            make.left.right.equalToSuperview().inset(12)
            make.height.equalTo(44)
        }

        applyReasonField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(1)
        }

        applyButton.snp.makeConstraints { make in
            make.top.equalTo(applyReasonContainer.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(12)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(18)
        }
    }

    @objc
    private func handleApplyButtonClick() {
        onApply?(applyReasonField.text)
    }
}

extension SKAuditApplyView: UDTextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        applyReasonField.resignFirstResponder()
        return true
    }
}
