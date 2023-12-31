//
//  EmailFieldViewModel.swift
//  LarkContact
//
//  Created by SlientCat on 2019/6/9.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

final class EmailFieldViewModel: NSObject, FieldViewModelAbstractable, UITextFieldDelegate {
    /// FieldViewModelAbstractable
    var state: FieldState
    var cellMapping: String {
        switch state {
        case .edit:
            return NSStringFromClass(EmailEditFieldCell.self)
        case .failed:
            return NSStringFromClass(EmailFailedFieldCell.self)
        }
    }
    var FieldCellHeight: CGFloat {
        switch state {
        case .edit:
            return 51.0
        case .failed:
            return 71.0
        }
    }
    var content: String {
        return contentSubject.value
    }

    var commitContent: String {
        return contentSubject.value
    }

    var contentSubject: BehaviorRelay<String> = BehaviorRelay(value: "")
    /// 编辑态
    var reloadFieldSubject: PublishSubject<EmailFieldViewModel> = PublishSubject()
    /// 错误态
    var backToEditSubject: PublishSubject<EmailFieldViewModel> = PublishSubject()
    var failReason: String = ""

    let verificationViewModel: VerificationBaseViewModel

    init(state: FieldState, isOversea: Bool) {
        self.state = state
        verificationViewModel = VerificationBaseViewModel(isOversea: isOversea)
        super.init()
    }

    func verify() {
        let isValid = verificationViewModel.verifyEmailValidation(content)
        if isValid {
            state = .edit
        } else {
            state = .failed
            failReason = BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberInvalidEmail
        }
    }

    func clear() {
        contentSubject.accept("")
    }
}

/// UITextFieldDelegate
extension EmailFieldViewModel {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if !(textField.text ?? "").isEmpty {
            verify()
            reloadFieldSubject.onNext(self)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
