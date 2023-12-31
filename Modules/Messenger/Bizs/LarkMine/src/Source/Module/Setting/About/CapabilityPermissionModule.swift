//
//  CapabilityPermissionModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/28.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import EventKit
import AVFoundation
import Contacts
import UserNotifications
import NotificationCenter
import Photos
import UniverseDesignColor
import LarkUIKit
import LarkPrivacySetting
import LarkOpenSetting
import LarkContainer
import LarkSetting
import LarkCoreLocation
import LarkSettingUI
import LarkSensitivityControl

enum CapabilityPermissionModuleToken: String {
    case requestAuthorization
    case requestAccessCamera
    case requestAccess
    case requestRecordPermission
    case requestAccessCalendar

    var token: Token {
        switch self {
        case .requestAuthorization:
            return Token("LARK-PSDA-CapabilityPermission_requestAuthorization")
        case .requestAccessCamera:
            return Token("LARK-PSDA-CapabilityPermission_requestAccessCamera")
        case .requestAccess:
            return Token("LARK-PSDA-CapabilityPermission_requestAccess")
        case .requestRecordPermission:
            return Token("LARK-PSDA-CapabilityPermission_requestRecordPermission")
        case .requestAccessCalendar:
            return Token("LARK-PSDA-CapabilityPermission_requestAccessCalendar")
        }
    }
}

final class CapabilityPermissionModule: BaseModule {
    let locationManager = CLLocationManager()

    private lazy var systemLocationFG: Bool = {
        guard let featureGatingService = try? self.userResolver.resolve(assert: FeatureGatingService.self) else { return false }
        let value = featureGatingService.staticFeatureGatingValue(with: "messenger.location.force_original_system_location")
        SettingLoggerService.logger(.module(self.key)).info("fg/messenger.location.force_original_system_location: \(value)")
        return value
    }()

    /// 请求定位权限 PSDA管控Token
    private let locationAuthorizationToken: Token = Token("LARK-PSDA-CapabilityPermission-requestLocationAuthorization", type: .location)

    private var locationAuth: LocationAuthorization?

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.locationAuth = try? self.userResolver.resolve(assert: LocationAuthorization.self)
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.context?.reload()
            }).disposed(by: disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        if key == ModulePair.CapabilityPermission.cameraAndPhoto.createKey {
            let str = BundleI18n.LarkMine.Lark_CoreAccess_SystemAccessManagement_Desc()
            return SectionProp(items: [createCameraProp(), createPhotoProp()], header: .title(str))
        } else if key == ModulePair.CapabilityPermission.location.createKey {
            guard LarkLocationAuthority.checkAuthority() else { return nil }
            return SectionProp(items: [createLocationProp()])
        } else if key == ModulePair.CapabilityPermission.contactAndMicrophone.createKey {
            return SectionProp(items: [createContactProp(), createMicrophoneProp()])
        } else if key == ModulePair.CapabilityPermission.calendar.createKey {
            return SectionProp(items: [createCalendarProp()])
        }
        return nil
    }

    private func useSystemRequestLocationAuthorization(manager: CLLocationManager) {
        do {
            try LocationEntry.requestWhenInUseAuthorization(forToken: locationAuthorizationToken, manager: manager)
        } catch let error {
            if let checkError = error as? CheckError {
                SettingLoggerService.logger(.module(self.key)).info("requestLocationAuthorization for locationEntry error \(checkError.description)")
            }
        }
    }

    func permissionStr(_ val: Bool?) -> String {
        return (val ?? false) ? BundleI18n.LarkMine.Lark_CoreAccess_AccessPermissionOn_Status
            : BundleI18n.LarkMine.Lark_CoreAccess_AccessPermission_GoToSettings
    }

    func createPhotoProp() -> CellProp {
        enum PhotoAuthState {
            case all
            case limited
            case addOnly
            case notDetermined
            case denied
        }
        let state: PhotoAuthState
        if #available(iOS 14, *) {
            let readWrite = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            let addOnly = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            switch readWrite {
            case .authorized:
                state = .all
            case .limited:
                state = .limited
            case .notDetermined, .restricted, .denied:
                switch addOnly {
                case .authorized, .limited:
                    state = .addOnly
                case .notDetermined:
                    state = .notDetermined
                case .restricted, .denied:
                    state = .denied
                @unknown default:
                    assertionFailure("should handle all cases")
                    state = .denied
                }
            @unknown default:
                assertionFailure("should handle all cases")
                state = .denied
            }
        } else {
            let auth = PHPhotoLibrary.authorizationStatus()
            switch auth {
            case .authorized:
                state = .all
            case .notDetermined:
                state = .notDetermined
            case .restricted, .denied:
                state = .denied
            case .limited:
                assertionFailure("system below iOS 14 should't have limited case")
                state = .limited
            @unknown default:
                assertionFailure("should handle all cases")
                state = .denied
            }
        }
        let onClick = state != .notDetermined ? self.goToSetting : {
            try? AlbumEntry.requestAuthorization(forToken: CapabilityPermissionModuleToken.requestAuthorization.token) { _ in }
        }
        let permissionString: String = {
            switch state {
            case .all:
                return BundleI18n.LarkMine.Lark_IM_PhotosAccess_Allow_Option
            case .limited:
                return BundleI18n.LarkMine.Lark_IM_PhotosAccess_Selected_Option
            case .addOnly:
                return BundleI18n.LarkMine.Lark_IM_PhotosAccess_SaveOnly_Option
            case .notDetermined, .denied: // PM 说场景太小众了，不单独处理 .notDetermined 的文案
                return BundleI18n.LarkMine.Lark_IM_PhotosAccess_Deny_Option
            }
        }()
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_CoreAccess_PhotosAccess_Option,
                                         detail: BundleI18n.LarkMine.Lark_CoreAccess_PhotosAccess_Desc,
                                         accessories: [.text(permissionString)],
                                         onClick: { _ in onClick() })
        return item
    }

    func createCameraProp() -> CellProp {
        let permission: Bool? = {
            let p = AVCaptureDevice.authorizationStatus(for: .video)
            return p == .notDetermined ? nil : p == .authorized
        }()
        let onClick = permission != nil ? self.goToSetting : {
            try? CameraEntry.requestAccessCamera(forToken: CapabilityPermissionModuleToken.requestAccessCamera.token) { _ in }
        }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_CoreAccess_CameraAccess_Option,
                                         detail: BundleI18n.LarkMine.Lark_CoreAccess_CameraAccess_Desc,
                                         accessories: [.text(permissionStr(permission))],
                                         onClick: { _ in onClick() })
        return item
    }

    func createLocationProp() -> CellProp {
        let permission: Bool? = {
            let p = systemLocationFG ? CLLocationManager.authorizationStatus() : (locationAuth?.authorizationStatus() ?? .notDetermined)
            if p == .notDetermined {
                return nil
            }
            return p == .authorizedAlways || p == .authorizedWhenInUse
        }()
        let onClick = permission != nil ? self.goToSetting : { [weak self] in
            guard let self = self else { return }
            if self.systemLocationFG {
                self.useSystemRequestLocationAuthorization(manager: self.locationManager)
            } else {
                self.locationAuth?.requestWhenInUseAuthorization(forToken: self.locationAuthorizationToken, complete: { _ in })
            }
        }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_CoreAccess_LocationServiceAccess_Option,
                                         detail: BundleI18n.LarkMine.Lark_CoreAccess_LocationServiceAccess_Desc,
                                         accessories: [.text(permissionStr(permission))],
                                         onClick: { _ in onClick() })
        return item
    }

    func createContactProp() -> CellProp {
        let permission: Bool? = {
            let p = CNContactStore.authorizationStatus(for: .contacts)
            return p == .notDetermined ? nil : p == .authorized
        }()
        let onClick = permission != nil ? self.goToSetting : {
            try? ContactsEntry.requestAccess(forToken: CapabilityPermissionModuleToken.requestAccess.token, contactsStore: CNContactStore(), forEntityType: .contacts) { _, _  in }
        }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_CoreAccess_ContactsAccess_Option,
                                         detail: BundleI18n.LarkMine.Lark_CoreAccess_ContactsAccess_Desc,
                                         accessories: [.text(permissionStr(permission))],
                                         onClick: { _ in onClick() })
        return item
    }

    func createMicrophoneProp() -> CellProp {
        let permission: Bool? = {
            let p = AVAudioSession.sharedInstance().recordPermission
            return p == .undetermined ? nil : p == .granted
        }()
        let onClick = permission != nil ? self.goToSetting : {
            try? AudioRecordEntry.requestRecordPermission(forToken: CapabilityPermissionModuleToken.requestRecordPermission.token,
                                                     session: AVAudioSession.sharedInstance()) { _ in }
        }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_CoreAccess_MicrophoneAccess_Option,
                                         detail: BundleI18n.LarkMine.Lark_CoreAccess_MicrophoneAccess_Desc,
                                         accessories: [.text(permissionStr(permission))],
                                         onClick: { _ in onClick() })
        return item
    }

    func createCalendarProp() -> CellProp {
        let permission: Bool? = {
            let p = EKEventStore.authorizationStatus(for: .event)
            return p == .notDetermined ? nil : p == .authorized
        }()
        let onClick = (permission != nil) ? self.goToSetting : {
            try? CalendarEntry.requestAccess(forToken: CapabilityPermissionModuleToken.requestAccessCalendar.token,
                                        eventStore: EKEventStore(), toEntityType: .event) { _, _  in } }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_CoreAccess_CalendarAccess_Title,
                                         detail: BundleI18n.LarkMine.Lark_CoreAccess_CalendarAccess_Desc,
                                         accessories: [.text(permissionStr(permission))],
                                         onClick: { _ in onClick() })
        return item
    }
}
