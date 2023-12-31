//
//  MemberInviteViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/11.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import CoreGraphics
import UniverseDesignToast
import LarkModel
import LarkFeatureGating
import LarkSDKInterface
import LarkFoundation
import LarkRustClient
import LarkAccountInterface
import LarkMessengerInterface
import LKCommonsLogging
import LKMetric
import LarkAddressBookSelector
import EENavigator
import LarkContainer
import LarkLocalizations

enum SegmentIndex: Int {
    case email
    case phone
}
typealias FieldListType = SegmentIndex

protocol MemberInviteRouter: ShareRouter {
    func pushToContactsImportViewController(controller: BaseUIViewController,
                                            source: MemberInviteSourceScenes,
                                            presenter: ContactBatchInvitePresenter,
                                            contactType: ContactContentType?,
                                            contactImportHandler: @escaping (AddressBookContact) -> Void)
    func presentCountryCodeViewController(_ controller: BaseUIViewController, selectCompletionHandler: @escaping (String) -> Void)
    func pushToGroupNameSettingController(_ controller: BaseUIViewController, nextHandler: @escaping (Bool) -> Void)
    func pushToNonDirectionalInviteController(_ controller: BaseUIViewController,
                                              sourceScenes: MemberInviteSourceScenes,
                                              departments: [String],
                                              priority: MemberNoDirectionalDisplayPriority)
    func pushToTeamCodeInviteController(_ controller: BaseUIViewController,
                                        sourceScenes: MemberInviteSourceScenes,
                                        departments: [String])
}

final class MemberInviteViewModel: NSObject, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {

    /// Dependencies
    private let dependency: UnifiedInvitationDependency
    let isOversea: Bool
    let departments: [String]
    let router: MemberInviteRouter
    var userResolver: LarkContainer.UserResolver
    private let passportUserService: PassportUserService
    var memberInviteAPI: MemberInviteAPI
    @ScopedProvider var chatApplicationAPI: ChatApplicationAPI?
    @ScopedProvider var userAPI: UserAPI?
    let batchInvitePresenter: ContactBatchInvitePresenter
    let sourceScenes: MemberInviteSourceScenes

    /// Output
    /// Compliance policy restrictions
    let shouldShowEmailInvitation: Bool
    let shouldShowPhoneInvitation: Bool
    /// Other
    enum Displayable {
        case none, mayDisplay, display
    }
    var nonDirectionalEntranceDisplayable: Displayable = .none
    var currentTenantIsSimpleB: Bool {
        let userType = passportUserService.user.type
        return userType == .undefined || userType == .simple
    }
    let isFromInviteSplitPage: Bool

    var currentType: FieldListType
    let emailFieldViewModel: EmailFieldViewModel
    var phoneFieldViewModel: PhoneFieldViewModel {
        didSet {
            reloadFieldSubject.onNext((.phone, true, nil))
        }
    }
    let nameFieldViewModelForEmail: NameFieldViewModel
    let nameFieldViewModelForPhone: NameFieldViewModel
    var nameFieldViewModel: NameFieldViewModel {
        return currentType == .email ? nameFieldViewModelForEmail : nameFieldViewModelForPhone
    }

    let pushToLinkInviteSubject: PublishSubject<Void> = PublishSubject()
    let pushToQRCodeInviteSubject: PublishSubject<Void> = PublishSubject()
    let pushToTeamCodeInviteSubject: PublishSubject<Void> = PublishSubject()
    let pushToContactImportSubject: PublishSubject<Void> = PublishSubject()
    let presentLarkChatInviteSubject: PublishSubject<Void> = PublishSubject()
    let pushToCountryCodePageSubject: PublishSubject<String> = PublishSubject()
    let startInviteSubject: PublishSubject<Void> = PublishSubject()
    let inviteRequestOnCompletedSubject: PublishSubject<Void> = PublishSubject()
    let reloadFieldSubject: PublishSubject<((type: FieldListType, allReload: Bool, reloadPath: IndexPath?))> = PublishSubject()
    let activeSpecifiedRowSubject: PublishSubject<(type: FieldListType, activePath: IndexPath)> = PublishSubject()
    let inviteButtonEnableSubject: PublishSubject<(type: FieldListType, buttonEnable: Bool)> = PublishSubject()
    let disposeBag = DisposeBag()

    weak var vc: MemberInviteViewController!
    static let logger = Logger.log(MemberInviteViewModel.self, category: "LarkContact.MemberInviteViewModel")

    init(router: MemberInviteRouter,
         sourceScenes: MemberInviteSourceScenes,
         isFromInviteSplitPage: Bool,
         isOversea: Bool,
         departments: [String],
         needShowType: MemberInviteNeedShowType? = .all,
         dependency: UnifiedInvitationDependency,
         mobileCodeProvider: MobileCodeProvider,
         resolver: UserResolver
    ) throws {
        /// DI
        self.router = router
        self.sourceScenes = sourceScenes
        self.isFromInviteSplitPage = isFromInviteSplitPage
        self.departments = departments
        self.dependency = dependency
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.memberInviteAPI = MemberInviteAPI(resolver: resolver)
        self.batchInvitePresenter = ContactBatchInvitePresenter(
            isOversea: isOversea,
            departments: departments,
            memberInviteAPI: memberInviteAPI,
            sourceScenes: sourceScenes,
            resolver: userResolver
        )
        self.isOversea = isOversea

        switch needShowType {
        case .email:
            shouldShowEmailInvitation = true
            shouldShowPhoneInvitation = false
        case .phone:
            shouldShowEmailInvitation = false
            shouldShowPhoneInvitation = true
        case .all:
            shouldShowEmailInvitation = userResolver.fg.staticFeatureGatingValue(with: "invite.member.email.enable")
            shouldShowPhoneInvitation = true
        case .none:
            shouldShowEmailInvitation = userResolver.fg.staticFeatureGatingValue(with: "invite.member.email.enable")
            shouldShowPhoneInvitation = true
        }
        /// Priority:
        /// FG(invite.member.channels.page.enable) > FG(invite.member.non_admin.non_directional.invite.enable)
        if isFromInviteSplitPage {
            nonDirectionalEntranceDisplayable = .none
        } else {
            nonDirectionalEntranceDisplayable = userResolver.fg.staticFeatureGatingValue(with: "invite.member.non_admin.non_directional.invite.enable") ? .display : .mayDisplay
        }
        currentType = (shouldShowEmailInvitation ? .email : .phone)
        /// Init ViewModels
        emailFieldViewModel = EmailFieldViewModel(state: .edit, isOversea: isOversea)
        phoneFieldViewModel = PhoneFieldViewModel(state: .edit, isOversea: isOversea, mobileCodeProvider: mobileCodeProvider)
        nameFieldViewModelForEmail = NameFieldViewModel(state: .edit, scenes: sourceScenes)
        nameFieldViewModelForPhone = NameFieldViewModel(state: .edit, scenes: sourceScenes)

        super.init()
        setupObserve()
    }

    func resignCurrentResponder() {
        guard let mainWindow = navigator.mainSceneWindow else {
            assertionFailure()
            return
        }
        mainWindow.endEditing(true)
    }
}

// MARK: - Private Methods
// Observe
private extension MemberInviteViewModel {

    func setupObserve() {
        observeAnyBuzRequestAction()
        observeAnyRoute()
        observeSubViewModel()
    }

    func observeAnyBuzRequestAction() {
        startInviteSubject.asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.resignCurrentResponder()
                let inviteInfo = self.currentType == .email ?
                    self.emailFieldViewModel.commitContent :
                    self.phoneFieldViewModel.commitContent
                let name = self.nameFieldViewModel.commitContent

                var inviteWay: MemberInviteAPI.InviteWay = .email
                switch self.currentType {
                case .email:
                    inviteWay = .email
                case .phone:
                    inviteWay = .phone
                }
                self.commitAdminInviteByField(inviteInfos: [inviteInfo], names: [name], inviteWay: inviteWay)
                    .subscribe(onNext: { [weak self] (result) in
                        guard let `self` = self else { return }
                        self.inviteRequestOnCompletedSubject.onNext(())
                        self.handleSubmitResponse(with: result)
                    }, onError: { [weak self] (error) in
                        guard let `self` = self else { return }
                        self.inviteRequestOnCompletedSubject.onNext(())
                        /// update invite button enable
                        self.inviteButtonEnableSubject.onNext( (self.currentType, self.isValid(self.currentType)) )
                        guard let wrappedError = error as? WrappedError,
                            let rcError = wrappedError.metaErrorStack.first(where: { $0 is RCError }) as? RCError else { return }
                        MemberInviteViewModel.logger.info("SetAdminInvitationResponse.error >>> \(rcError.localizedDescription)")
                        switch rcError {
                        case .businessFailure(let buzErrorInfo):
                            guard let window = self.vc?.view.window else { return }
                            UDToast.showTips(with: buzErrorInfo.displayMessage, on: window)
                        default: break
                        }
                    })
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    func observeAnyRoute() {
        pushToLinkInviteSubject.asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.router.pushToNonDirectionalInviteController(self.vc,
                                                                 sourceScenes: self.sourceScenes,
                                                                 departments: self.departments,
                                                                 priority: .inviteLink)
            }).disposed(by: disposeBag)

        pushToQRCodeInviteSubject.asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.router.pushToNonDirectionalInviteController(self.vc,
                                                                 sourceScenes: self.sourceScenes,
                                                                 departments: self.departments,
                                                                 priority: .qrCode)
            }).disposed(by: disposeBag)

        pushToTeamCodeInviteSubject.asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.router.pushToTeamCodeInviteController(self.vc,
                                                           sourceScenes: self.sourceScenes,
                                                           departments: self.departments)
            }).disposed(by: disposeBag)

        pushToContactImportSubject.asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.resignCurrentResponder()
                self.router.pushToContactsImportViewController(controller: self.vc,
                                                               source: self.sourceScenes,
                                                               presenter: self.batchInvitePresenter,
                                                               contactType: self.currentType == .email ? .email : .phone) { [weak self] (contact: AddressBookContact) in
                    guard let `self` = self else { return }
                    self.resignCurrentResponder()
                    if self.currentType == .email {
                        self.handleContactImportByEmail(contacts: [contact])
                    } else {
                        self.handleContactImportByPhoneNumber(contacts: [contact])
                    }
                }
            })
            .disposed(by: disposeBag)

        presentLarkChatInviteSubject.asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.memberInviteAPI.forwardInviteLinkInLark(
                    source: self.sourceScenes,
                    departments: self.departments,
                    router: self.router,
                    from: self.vc) { [weak self] in
                        guard let `self` = self else { return }
                        if self.sourceScenes == .newGuide || self.sourceScenes == .upgrade {
                            self.vc.skipStep()
                        } else {
                            self.vc.quit()
                        }
                }
            }).disposed(by: disposeBag)
    }

    func observeSubViewModel() {
        let mobileCodeProvider = MobileCodeProvider(
            mobileCodeLocale: LanguageManager.currentLanguage,
            topCountryList: [],
            allowCountryList: [],
            blockCountryList: []
        )
        let phoneVM = PhoneFieldViewModel(state: .edit, isOversea: isOversea, mobileCodeProvider: mobileCodeProvider)
        let emailVM = EmailFieldViewModel(state: .edit, isOversea: isOversea)
        let nameVM = NameFieldViewModel(state: .edit, scenes: sourceScenes)

        /// phoneField viewModel
        phoneFieldViewModel.backToEditSubject.asDriver(onErrorJustReturn: phoneVM).drive(onNext: { [weak self] (vm) in
            guard let `self` = self else { return }
            vm.state = .edit
            vm.reloadFieldSubject.onNext(vm)
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
                guard let `self` = self else { return }
                self.activeSpecifiedRowSubject.onNext( (.phone, IndexPath(row: 0, section: 0)) )
            })
        }).disposed(by: disposeBag)

        phoneFieldViewModel.reloadFieldSubject.asDriver(onErrorJustReturn: phoneVM).drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.reloadFieldSubject.onNext( (self.currentType, false, IndexPath(row: 0, section: 0)) )
        }).disposed(by: disposeBag)

        phoneFieldViewModel.switchCountryCodeSubject.asDriver(onErrorJustReturn: phoneVM).drive(onNext: { [weak self] (vm) in
            guard let `self` = self else { return }
            self.resignCurrentResponder()
            self.router.presentCountryCodeViewController(self.vc) { [weak self] (countryCode) in
                guard let `self` = self else { return }
                vm.countryCodeSubject.accept(countryCode)
                if !vm.content.isEmpty {
                    vm.verify()
                    /// update button enable
                    self.inviteButtonEnableSubject.onNext( (self.currentType, self.isValid(self.currentType)) )
                }
                self.reloadFieldSubject.onNext( (self.currentType, false, IndexPath(row: 0, section: 0)) )
            }
        }).disposed(by: disposeBag)

        /// emailField viewModel
        emailFieldViewModel.backToEditSubject.asDriver(onErrorJustReturn: emailVM).drive(onNext: { [weak self] (vm) in
            guard let `self` = self else { return }
            vm.state = .edit
            vm.reloadFieldSubject.onNext(vm)
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
                guard let `self` = self else { return }
                self.activeSpecifiedRowSubject.onNext( (.email, IndexPath(row: 0, section: 0)) )
            })
        }).disposed(by: disposeBag)

        emailFieldViewModel.reloadFieldSubject.asDriver(onErrorJustReturn: emailVM).drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.reloadFieldSubject.onNext( (self.currentType, false, IndexPath(row: 0, section: 0)) )
        }).disposed(by: disposeBag)

        /// nameField viewModel
        nameFieldViewModelForEmail.backToEditSubject.asDriver(onErrorJustReturn: nameVM).drive(onNext: { [weak self] (vm) in
            guard let `self` = self else { return }
            vm.state = .edit
            vm.reloadFieldSubject.onNext(vm)
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
                guard let `self` = self else { return }
                self.activeSpecifiedRowSubject.onNext( (.email, IndexPath(row: 1, section: 0)) )
            })
        }).disposed(by: disposeBag)

        nameFieldViewModelForEmail.reloadFieldSubject.asDriver(onErrorJustReturn: nameVM).drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.reloadFieldSubject.onNext( (.email, false, IndexPath(row: 1, section: 0)) )
        }).disposed(by: disposeBag)

        nameFieldViewModelForPhone.backToEditSubject.asDriver(onErrorJustReturn: nameVM).drive(onNext: { [weak self] (vm) in
            guard let `self` = self else { return }
            vm.state = .edit
            vm.reloadFieldSubject.onNext(vm)
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
                guard let `self` = self else { return }
                self.activeSpecifiedRowSubject.onNext( (.phone, IndexPath(row: 1, section: 0)) )
            })
        }).disposed(by: disposeBag)

        nameFieldViewModelForPhone.reloadFieldSubject.asDriver(onErrorJustReturn: nameVM).drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.reloadFieldSubject.onNext( (.phone, false, IndexPath(row: 1, section: 0)) )
        }).disposed(by: disposeBag)

        Driver.combineLatest(
            emailFieldViewModel.contentSubject.asDriver(),
            nameFieldViewModelForEmail.contentSubject.asDriver()
        ).map { [weak self] (contentTuple) -> Bool in
            guard let `self` = self else { return false }
            return self.emailFieldViewModel.verificationViewModel.verifyEmailValidation(contentTuple.0) &&
                        !contentTuple.1.isEmpty
        }.map { (FieldListType.email, $0) }
        .drive(inviteButtonEnableSubject)
        .disposed(by: disposeBag)

        Driver.combineLatest(phoneFieldViewModel.contentSubject.asDriver(),
                             nameFieldViewModelForPhone.contentSubject.asDriver()
        ).map { [weak self] (contentTuple) -> Bool in
            guard let `self` = self else { return false }
            return self.phoneFieldViewModel.verificationViewModel.verifyPhoneNumberValidation(contentTuple.0, countryCode: self.phoneFieldViewModel.countryCode) &&
                        !contentTuple.1.isEmpty
        }.map { (FieldListType.phone, $0) }
        .drive(inviteButtonEnableSubject).disposed(by: disposeBag)
    }
}

// Other Buz
private extension MemberInviteViewModel {
    func handleSubmitResponse(with response: AddMemberFieldResult) {
        if response.isSuccess {
            if response.needApproval {
                Tracer.trackAddMemberInviteApproveDialogShow(source: sourceScenes)
            } else {
                Tracer.trackAddMemberInviteSuccessDialogShow(source: sourceScenes)
            }
            AddMemberFeedbackPresenter.present(
                resolver: userResolver,
                type: currentType,
                needApproval: response.needApproval,
                baseVc: vc,
                doneCallBack: { [weak self] in
                    guard let `self` = self else { return }
                    if response.needApproval {
                        Tracer.trackAddMemberInviteApproveDialogDoneClick(source: self.sourceScenes)
                    } else {
                        Tracer.trackAddMemberInviteSuccessDialogDoneClick(source: self.sourceScenes)
                    }
                    if self.sourceScenes == .newGuide || self.sourceScenes == .upgrade {
                        self.vc.skipStep()
                    } else {
                        self.vc.quit()
                    }
                }) {
                    if response.needApproval {
                        Tracer.trackAddMemberInviteApproveDialogMoreClick(source: self.sourceScenes)
                    } else {
                        Tracer.trackAddMemberInviteSuccessDialogMoreClick(source: self.sourceScenes)
                    }
                if self.currentType == .email {
                    self.emailFieldViewModel.clear()
                    self.nameFieldViewModelForEmail.clear()
                } else {
                    self.phoneFieldViewModel.clear()
                    self.nameFieldViewModelForPhone.clear()
                }
                self.reloadFieldSubject.onNext( (self.currentType, true, nil) )
                /// update invite button enable
                self.inviteButtonEnableSubject.onNext( (self.currentType, false) )
            }
        } else {
            guard let errorType = response.errorType else { return }
            switch errorType {
            case .email:
                emailFieldViewModel.state = .failed
                emailFieldViewModel.failReason = response.errorMsg ?? "unknown error"
            case .phone:
                phoneFieldViewModel.state = .failed
                phoneFieldViewModel.failReason = response.errorMsg ?? "unknown error"
            case .name:
                nameFieldViewModel.state = .failed
                nameFieldViewModel.failReason = response.errorMsg ?? "unknown error"
            case .dynamic:
                if currentType == .email {
                    emailFieldViewModel.state = .failed
                    emailFieldViewModel.failReason = response.errorMsg ?? "unknown error"
                } else if currentType == .phone {
                    phoneFieldViewModel.state = .failed
                    phoneFieldViewModel.failReason = response.errorMsg ?? "unknown error"
                }
            case .other:
                if let window = vc.view.window {
                    UDToast.showTips(with: response.errorMsg ?? "unknown error", on: window)
                }
            }
            reloadFieldSubject.onNext( (currentType, true, nil) )
            /// update invite button enable
            inviteButtonEnableSubject.onNext( (currentType, isValid(currentType)) )
        }
    }

    func handleContactImportByEmail(contacts: [AddressBookContact]) {
        // Currently only supports radio
        guard let contact = contacts.first, let email = contact.email, !email.isEmpty else { return }
        emailFieldViewModel.contentSubject.accept(email)
        emailFieldViewModel.verify()
        if !contact.fullName.isEmpty {
            nameFieldViewModelForEmail.contentSubject.accept(contact.fullName)
            nameFieldViewModelForEmail.verify()
        }
        reloadFieldSubject.onNext( (currentType, true, nil) )
    }

    func handleContactImportByPhoneNumber(contacts: [AddressBookContact]) {
        // Currently only supports radio
        guard let contact = contacts.first, let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty else { return }
        // Implicit logic: -1 means the country code is not parsed
        if contact.countryCode != "-1" {
            let pureNumber = phoneFieldViewModel.verificationViewModel.getPurePhoneNumber(phoneNumber).substring(from: contact.countryCode.count + 1)
            // If the number except country code is empty, it will not be overwritten
            guard !pureNumber.isEmpty else { return }
            phoneFieldViewModel.countryCodeSubject.accept(contact.countryCode.hasPrefix("+") ?
                contact.countryCode :
                "+\(contact.countryCode)")
            phoneFieldViewModel.contentSubject.accept(pureNumber)
            phoneFieldViewModel.verify()
        } else {
            let pureNumber = phoneFieldViewModel.verificationViewModel.getPurePhoneNumber(phoneNumber)
            // If the number except country code is empty, it will not be overwritten
            guard !pureNumber.isEmpty else { return }
            phoneFieldViewModel.contentSubject.accept(pureNumber)
            phoneFieldViewModel.verify()
        }
        if !contact.fullName.isEmpty {
            nameFieldViewModelForPhone.contentSubject.accept(contact.fullName)
            nameFieldViewModelForPhone.verify()
        }
        reloadFieldSubject.onNext( (currentType, true, nil) )
    }

    func isValid(_ type: FieldListType) -> Bool {
        if type == .email {
            return emailFieldViewModel.verificationViewModel.verifyEmailValidation(emailFieldViewModel.content) &&
                !nameFieldViewModelForEmail.content.isEmpty
        } else if type == .phone {
            return phoneFieldViewModel.verificationViewModel.verifyPhoneNumberValidation(phoneFieldViewModel.content, countryCode: phoneFieldViewModel.countryCode) &&
                !nameFieldViewModelForPhone.content.isEmpty
        }
        return false
    }
}
