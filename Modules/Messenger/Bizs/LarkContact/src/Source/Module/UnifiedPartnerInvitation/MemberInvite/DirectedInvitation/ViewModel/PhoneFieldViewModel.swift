//
//  PhoneFieldViewModel.swift
//  LarkContact
//
//  Created by SlientCat on 2019/6/9.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkLocalizations
import LarkUIKit

final class PhoneFieldViewModel: NSObject, FieldViewModelAbstractable, UITextFieldDelegate {
    /// FieldViewModelAbstractable
    var state: FieldState
    var cellMapping: String {
        switch state {
        case .edit:
            return NSStringFromClass(PhoneEditFieldCell.self)
        case .failed:
            return NSStringFromClass(PhoneFailedFieldCell.self)
        }
    }
    var FieldCellHeight: CGFloat {
        switch state {
        case .edit:
            return 51.0
        default:
            return 71.0
        }
    }
    var content: String {
        return contentSubject.value
    }

    var commitContent: String {
        return "\(countryCode)\(verificationViewModel.getPurePhoneNumber(content))"
    }
    var countryCode: String {
        return countryCodeSubject.value
    }

    var canEditCountryCode: Bool {
        return mobileCodeProvider.getMobileCodes().count != 1
    }

    var mobileCodeProvider: MobileCodeProvider

    /// common态下
    var contentSubject: BehaviorRelay<String> = BehaviorRelay(value: "")
    lazy var countryCodeSubject: BehaviorRelay<String> = {
        return BehaviorRelay(value: defaultCountryCode)
    }()

    private var defaultCountryCode: String {
        // 优先级：按照语言匹配区域 > 热门区域 > 列表第一个区域
        var countryKey: String = "CN"
        if isOversea {
            switch LanguageManager.currentLanguage {
            case .zh_CN:
                countryKey = "CN"
            case .en_US:
                countryKey = "US"
            case .ja_JP:
                countryKey = "JP"
            default:
                countryKey = "US"
            }
        }

        if let mobileCode = mobileCodeProvider.searchCountry(countryKey: countryKey) {
            return mobileCode.code
        } else {
            let mobileCode = mobileCodeProvider.getFirstTopMobileCode()
                ?? mobileCodeProvider.getMobileCodes().first
            assert(mobileCode != nil, "Failed to get default mobile code")
            return mobileCode?.code ?? "+1"
        }
    }

    /// 编辑态
    var reloadFieldSubject: PublishSubject<PhoneFieldViewModel> = PublishSubject()
    var switchCountryCodeSubject: PublishSubject<PhoneFieldViewModel> = PublishSubject()
    /// 错误态
    var backToEditSubject: PublishSubject<PhoneFieldViewModel> = PublishSubject()
    var failReason: String = ""

    let verificationViewModel: VerificationBaseViewModel
    private let isOversea: Bool

    init(state: FieldState, isOversea: Bool, mobileCodeProvider: MobileCodeProvider) {
        self.state = state
        self.isOversea = isOversea
        self.mobileCodeProvider = mobileCodeProvider
        verificationViewModel = VerificationBaseViewModel(isOversea: isOversea)
        super.init()
    }

    func verify() {
        let isValid = verificationViewModel.verifyPhoneNumberValidation(content, countryCode: countryCode)
        if isValid {
            state = .edit
        } else {
            state = .failed
            failReason = BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberInvalidPhone
        }
    }

    func clear() {
        contentSubject.accept("")
        countryCodeSubject.accept(defaultCountryCode)
    }
}

/// UITextFieldDelegate
extension PhoneFieldViewModel {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if !(textField.text ?? "").isEmpty {
            verify()
            reloadFieldSubject.onNext(self)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
