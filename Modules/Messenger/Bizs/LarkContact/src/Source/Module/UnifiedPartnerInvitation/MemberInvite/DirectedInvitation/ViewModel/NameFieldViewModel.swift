//
//  NameFieldViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/11.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkMessengerInterface

final class NameFieldViewModel: NSObject, FieldViewModelAbstractable, UITextFieldDelegate {
    /// FieldViewModelAbstractable
    var cellMapping: String {
        switch state {
        case .edit:
            return NSStringFromClass(NameEditFieldCell.self)
        case .failed:
            return NSStringFromClass(NameFailedFieldCell.self)
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
        return contentSubject.value.trimmingCharacters(in: .whitespaces)
    }

    /// common
    var contentSubject: BehaviorRelay<String> = BehaviorRelay(value: "")
    /// 编辑态下
    var reloadFieldSubject: PublishSubject<NameFieldViewModel> = PublishSubject()
    /// 错误态
    var backToEditSubject: PublishSubject<NameFieldViewModel> = PublishSubject()
    var failReason: String = ""

    var state: FieldState
    private let scenes: MemberInviteSourceScenes
    init(state: FieldState, scenes: MemberInviteSourceScenes) {
        self.state = state
        self.scenes = scenes
        super.init()
    }

    func verify() {
        let isValid = !commitContent.isEmpty
        if isValid {
            state = .edit
        } else {
            state = .failed
            failReason = BundleI18n.LarkContact.Lark_Invitation_AddMembersNameCantEmpty
        }
    }

    func clear() {
        contentSubject.accept("")
    }
}

/// UITextFieldDelegate
extension NameFieldViewModel {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        Tracer.trackAddMemberInputName(source: scenes)
    }

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
