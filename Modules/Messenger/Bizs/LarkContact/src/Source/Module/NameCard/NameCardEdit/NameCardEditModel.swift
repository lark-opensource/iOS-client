//
//  NameCardEditModel.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/4/19.
//

import Foundation
import RustPB
import LarkFeatureGating
import LarkSetting

enum NameCardEditType: Int {
    case account = 0, name, company, title, phone, email, group, extra
}

class NameCardEditItemViewModel {
    let fgService: FeatureGatingService
    let type: NameCardEditType
    let title: String
    var isSelectable = true
    var isShowStrongReminder = false
    let maxCharLength: Int

    private(set) var content: String?
    private(set) var errorDesc: String?

    init(fgService: FeatureGatingService, type: NameCardEditType, desc: String, maxCharLength: Int) {
        self.fgService = fgService
        self.type = type
        self.title = desc
        self.maxCharLength = maxCharLength
    }

    func updateContent(_ content: String?) {
        self.content = content
    }

    func updateErrorDesc(_ errorDesc: String?) {
        self.errorDesc = errorDesc
    }
}

final class NameCardEditPhoneViewModel: NameCardEditItemViewModel {

    private(set) var districtNumber: String
    private(set) var regionCode: String
    private(set) var phoneNumber: String?
    private(set) var fullPhoneNumber: String?

    init(type: NameCardEditType, fgService: FeatureGatingService, desc: String, phone: Email_Client_V1_Phone?, maxCharLength: Int) {
        if let aPhone = phone, !aPhone.districtNumber.isEmpty {
            self.districtNumber = aPhone.districtNumber
            self.regionCode = aPhone.regionCode
            self.phoneNumber = aPhone.phoneNumber
        } else {
            let regionCode = NameCardEditPhoneViewModel.getDefaultRegionCode()
            self.districtNumber = regionCode.districtNumber
            self.regionCode = regionCode.regionCode
        }
        if let aPhone = phone {
            self.fullPhoneNumber = aPhone.fullPhoneNumber
        }
        super.init(fgService: fgService, type: type, desc: desc, maxCharLength: maxCharLength)
    }

    func updatePhone(_ districtNumber: String, _ regionCode: String) {
        self.districtNumber = districtNumber
        self.regionCode = regionCode
    }

    func updatePhoneNumber(_ phoneNumber: String?) {
        self.phoneNumber = phoneNumber ?? ""
    }

    func updateFullPhoneNumber(_ fullPhoneNumber: String?) {
        self.fullPhoneNumber = fullPhoneNumber ?? ""
    }

    // 构造上传给服务器的Phone
    func getUploadPhone() -> Email_Client_V1_Phone? {
        if let fullPhoneNumber = self.fullPhoneNumber {
            var phone = Email_Client_V1_Phone()
            phone.fullPhoneNumber = fullPhoneNumber.removeAllCharSpace()
            return phone
        }
        return nil
    }

    // 构造页面退出时需要diff的Phone
    func getUIPhone() -> Email_Client_V1_Phone {
        var phone = Email_Client_V1_Phone()

        if let number = fullPhoneNumber {
            phone.fullPhoneNumber = number
        }
        return phone
    }

    static func getDefaultRegionCode() -> (districtNumber: String, regionCode: String) {
        return (districtNumber: "+86", regionCode: "CN")
    }
}
