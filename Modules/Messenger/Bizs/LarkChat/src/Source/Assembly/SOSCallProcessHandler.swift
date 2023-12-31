//
//  SOSCallProcessHandler.swift
//  LarkApp
//
//  Created by shizhengyu on 2019/8/29.
//

import UIKit
import Foundation
import LarkAlertController
import SnapKit
import Swinject
import LarkFoundation
import EENavigator
import RxSwift
import LarkModel
import UniverseDesignToast
import LarkCore
import libPhoneNumber_iOS
import LarkRustClient
import LarkSDKInterface
import RustPB

private final class SOSAlertContentView: UIView {
    private var textField: UITextField?
    var phoneNumber: String {
        get { return self.textField?.text ?? "" }
        set { self.textField?.text = newValue }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        let tipLabel: UILabel = UILabel()
        tipLabel.numberOfLines = 0
        tipLabel.textAlignment = .center

        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.textColor = UIColor.ud.N900
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.text = ""
        textField.placeholder = BundleI18n.LarkChat.Lark_Legacy_UrgentCallInputPlaceholder
        textField.keyboardType = .numberPad
        self.textField = textField

        let attributedString = NSMutableAttributedString(string: BundleI18n.LarkChat.Lark_Legacy_UrgentCallDesc, attributes: [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.N900
            ])
        tipLabel.attributedText = attributedString

        self.addSubview(tipLabel)
        self.addSubview(textField)

        tipLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        textField.snp.makeConstraints { (make) in
            make.top.equalTo(tipLabel.snp.bottom).offset(20)
            make.height.equalTo(36)
            make.left.right.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CallByChannelHandler {

    private enum SOSCallError: Error {
        case filledNumberUnvalidError(msg: String)
        case sosServerResponseError(msg: String)
        case unknownError
    }

    func startupSOSCallProcess(configurationAPI: ConfigurationAPI,
                               chatAPI: ChatAPI,
                               calleeUserId: String,
                               from: NavigatorFrom,
                               updateCallIdHandler: ((String) -> Void)? = nil,
                               processEndingHandler: ((Bool) -> Void)? = nil) {

        let viewForShowingHUD = from.fromViewController?.viewIfLoaded

        self.fetchDefaultContactPhoneNumber(configurationAPI: configurationAPI)
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] (defaultNumber) -> Observable<String> in
                guard let `self` = self else { return .error(SOSCallError.unknownError) }
                return self.presentSOSAlert(defaultNumber: defaultNumber, from: from)
            }
            .flatMap { [weak self, weak viewForShowingHUD] (callerPhoneNumber) -> Observable<RustPB.Contact_V1_GetEmergencyCallNumberResponse> in
                guard let `self` = self else { return .error(SOSCallError.unknownError) }
                return self.getEmergencyCallNumber(chatAPI: chatAPI, callerPhoneNumber: callerPhoneNumber, calleeUserId: calleeUserId, viewForShowingHUD: viewForShowingHUD)
            }
            .flatMap { [weak self] (bindingInfo) -> Observable<String> in
                guard let `self` = self else { return .error(SOSCallError.unknownError) }
                return self.startSOSCall(callNumber: bindingInfo.emergencyCallNumber, callId: bindingInfo.callID)
            }
            .flatMap { (callId) -> Observable<Void> in
                updateCallIdHandler?(callId)
                return .just(())
            }
            .catchError { [weak viewForShowingHUD] (error) -> Observable<()> in
                processEndingHandler?(false)
                if let sosError = error as? SOSCallError, let view = viewForShowingHUD {
                    switch sosError {
                    case .filledNumberUnvalidError(let msg):
                        UDToast.showTips(with: msg, on: view)
                    case .sosServerResponseError(let msg):
                        UDToast.showTips(with: msg, on: view)
                    case .unknownError: break
                    }
                }
                return .error(error)
            }
            .subscribe(onNext: { (_) in
                processEndingHandler?(true)
            }).disposed(by: self.disposeBag)
    }

    private func fetchDefaultContactPhoneNumber(configurationAPI: ConfigurationAPI) -> Observable<String?> {
        return configurationAPI.getAddFriendPrivateConfig()
            .flatMap { (response) -> Observable<String?> in
                let firstContact = response.findMeSetting.first(where: { $0.hasVerified_p && $0.type == .mobile })?.displayContact ?? ""
                if !firstContact.isEmpty {
                    return .just(firstContact)
                }
                return configurationAPI.fetchAddFriendPrivateConfig()
                .observeOn(MainScheduler.instance)
                .map { (res) -> String? in
                    if res.findMeSetting.isEmpty { return nil }
                    let validPhoneNumbers = res.findMeSetting.filter({ (item) -> Bool in
                        return item.hasVerified_p && item.type == .mobile
                    })
                    if !validPhoneNumbers.isEmpty {
                        let item: RustPB.Settings_V1_WayToFindMeSettingItem = validPhoneNumbers[0]
                        return item.displayContact
                    }
                    return nil
                }
            }.catchErrorJustReturn(nil)
    }

    private func presentSOSAlert(defaultNumber: String?, from: NavigatorFrom) -> Observable<String> {
        return Observable.create({ [navigator](ob) -> Disposable in
            let alertController = LarkAlertController()
            let contentView = SOSAlertContentView(frame: .zero)
            if let phoneNumber = defaultNumber {
                contentView.phoneNumber = phoneNumber.hasPrefix("+") ? phoneNumber[1..<phoneNumber.count] : phoneNumber
            }
            alertController.setTitle(text: BundleI18n.LarkChat.Lark_Legacy_UrgentCallTitleofConfirm)
            alertController.setContent(view: contentView, padding: UIEdgeInsets(top: 14, left: 20, bottom: 17, right: 20))
            alertController.addCancelButton()
            alertController.addPrimaryButton(text: BundleI18n.LarkChat.Lark_Legacy_Sure, dismissCompletion: {
                var nationalNumber: NSString?
                let fullPhoneNumber: String = contentView.phoneNumber.hasPrefix("+") ? contentView.phoneNumber : "+\(contentView.phoneNumber)"
                let countryCode: String? = NBPhoneNumberUtil().extractCountryCode(fullPhoneNumber, nationalNumber: &nationalNumber)?.stringValue
                // 隐式逻辑: extractCountryCode 返回 0 代表没有正确的国家码
                if let code = countryCode,
                   let codeNumber = Int(code),
                   codeNumber > 0,
                   self.verifyPhoneNumberValidation(countryCode: code, phoneNumber: fullPhoneNumber[code.count + 1..<fullPhoneNumber.count]) {
                    ob.onNext(fullPhoneNumber)
                } else {
                    ob.onError(SOSCallError.filledNumberUnvalidError(msg: BundleI18n.LarkChat.Lark_Legacy_UrgentCallInputTips))
                }
            })
            navigator.present(alertController, from: from)
            return Disposables.create()
        })
    }

    private func getEmergencyCallNumber(chatAPI: ChatAPI, callerPhoneNumber: String, calleeUserId: String, viewForShowingHUD: UIView?) -> Observable<RustPB.Contact_V1_GetEmergencyCallNumberResponse> {
        let hud = viewForShowingHUD.map { UDToast.showLoading(on: $0, disableUserInteraction: false) }
        return chatAPI.getEmergencyCallNumber(callerPhoneNumber: callerPhoneNumber, calleeUserId: calleeUserId)
            .observeOn(MainScheduler.instance)
            .do(onNext: { (_) in hud?.remove() },
                onError: { (_) in hud?.remove() })
            .catchError({ [weak self] (error) -> Observable<RustPB.Contact_V1_GetEmergencyCallNumberResponse> in
                guard let `self` = self else { return .error(SOSCallError.unknownError) }
                return .error(self.transformedSOSCallError(error: error))
            })
    }

    private func startSOSCall(callNumber: String, callId: String) -> Observable<String> {
        return Observable.create({ (ob) -> Disposable in
            LarkFoundation.Utils.telecall(phoneNumber: callNumber)
            ob.onNext(callId)
            ob.onCompleted()
            return Disposables.create()
        })
    }

    private func verifyPhoneNumberValidation(countryCode: String, phoneNumber: String) -> Bool {
        let purePhoneNumber = getPurePhoneNumber(origin: phoneNumber)
        let chinaPhoneNumberRegex: String = "^[1]\\d{10}$"
        let overseaPhoneNumberRegex: String = "^\\d{1,14}$"
        let chinaPhoneNumberPredicate: NSPredicate = NSPredicate(format: "SELF MATCHES %@", chinaPhoneNumberRegex)
        let overseaPhoneNumberPredicate: NSPredicate = NSPredicate(format: "SELF MATCHES %@", overseaPhoneNumberRegex)

        if countryCode == "86" {
            return chinaPhoneNumberPredicate.evaluate(with: purePhoneNumber)
        } else { return overseaPhoneNumberPredicate.evaluate(with: purePhoneNumber) }
    }

    private func getPurePhoneNumber(origin: String) -> String {
        let numberArray = origin.components(separatedBy: CharacterSet.decimalDigits.inverted)
        return numberArray.joined(separator: "")
    }

    private func transformedSOSCallError(error: Error) -> SOSCallError {
        guard let wrappedError = error as? WrappedError,
            let rcError = wrappedError.metaErrorStack.first(where: { $0 is RCError }) as? RCError else {
                    return SOSCallError.unknownError
        }
        switch rcError {
        case .businessFailure(let buzErrorInfo):
            return SOSCallError.sosServerResponseError(msg: buzErrorInfo.displayMessage)
        default:
            break
        }
        return SOSCallError.unknownError
    }
}
