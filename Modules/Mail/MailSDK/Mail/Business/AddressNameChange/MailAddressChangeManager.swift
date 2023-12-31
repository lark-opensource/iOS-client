//
//  MailAddressChangeManager.swift
//  MailSDK
//
//  Created by tanghaojin on 2022/12/8.
//

import UIKit
import RxSwift
import ThreadSafeDataStructure
import RustPB
struct MailUidAddressItem {
    var uid: String
    var address: String
}
class MailAddressChangeManager {
    static let shared: MailAddressChangeManager = MailAddressChangeManager()
    let serialQueue = DispatchQueue(label: "MailSDK.AddresChange.Queue",
                                                       attributes: .init(rawValue: 0))
    var addressNameMap = SafeDictionary<String, String>(synchronization: .readWriteLock)
    var uidNameMap = SafeDictionary<String, String>(synchronization: .readWriteLock)
   
    let disposeBag = DisposeBag()
    init() {
        PushDispatcher
            .shared
            .$mailAddressUpdatePush
            .wrappedValue
            .observeOn(MainScheduler.instance)
            .subscribe({ [weak self] change in
                if let addressChange = change.element {
                    self?.updateMap(change: addressChange)
                }
            }).disposed(by: disposeBag)
    }
    

    func addressNameOpen() -> Bool {
        return FeatureManager.open(.replaceAddressName) && !Store.settingData.mailClient
    }
    
    func noUpdate(type: Email_Client_V1_AddressName.AddressType) -> Bool {
        if FeatureManager.open(.groupShareReplace) {
            return false
        }
        if type == .unknown || type == .mailShare || type == .mailGroup {
            return true
        }
        return false
    }
    
    func updateMap(change: MailAddressUpdatePushChange) {
        guard addressNameOpen() else { return }
        serialQueue.async {
            var needPush = false
            let namelist = change.addressNameList
            for item in namelist {
                if self.noUpdate(type: item.addressType) {
                    self.addressNameMap.removeValue(forKey: item.address)
                } else if item.reqType == .addressOnly {
                    if !item.address.isEmpty {
                        if item.name.isEmpty {
                            self.addressNameMap.removeValue(forKey: item.address)
                        } else {
                            needPush = true
                            self.addressNameMap[item.address] = item.name
                        }
                    }
                    if !item.larkEntityID.isEmpty && item.larkEntityID != "0" {
                        if item.name.isEmpty {
                            self.uidNameMap.removeValue(forKey: item.larkEntityID)
                        } else {
                            needPush = true
                            self.uidNameMap[item.larkEntityID] = item.name
                        }
                    }
                } else if item.reqType == .entityID {
                    if !item.larkEntityID.isEmpty && item.larkEntityID != "0" {
                        if item.name.isEmpty {
                            self.uidNameMap.removeValue(forKey: item.larkEntityID)
                        } else {
                            needPush = true
                            self.uidNameMap[item.larkEntityID] = item.name
                        }
                    }
                }
            }
            if needPush {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_ADDRESS_NAME_CHANGE, object: nil)
                }
            }
        }
    }
}
