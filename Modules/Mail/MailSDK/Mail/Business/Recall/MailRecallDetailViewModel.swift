//
//  MailRecallDetailViewModel.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/5/12.
//

import Foundation
import RxSwift
import RxCocoa

enum MailRecallDetailState {
    case recalling(percentage: String)
    case success
    case failed(comment: String)
}

struct MailRecallDetailCellViewModel: Equatable {
    let name: String
    let address: String
    let avatarKey: String
    let status: MailRecallDetailState
    let isMaillingList: Bool
    let numberOfSuccess: Int64
    let numberOfFailure: Int64

    let statusText: String
    let initial: String

    init(name: String, address: String, avatarKey: String, status: MailRecallDetailState, isMaillingList: Bool, numberOfSuccess: Int64, numberOfFailure: Int64) {
        self.name = name
        self.address = address
        self.avatarKey = avatarKey
        self.status = status
        self.isMaillingList = isMaillingList
        self.numberOfSuccess = numberOfSuccess
        self.numberOfFailure = numberOfFailure

        self.initial = name.components(separatedBy: " ").reduce("") { (res, str) -> String in
            if res.count < 2, let first = str.first {
                return res + String(first).uppercased()
            } else {
                return res
            }
        }

        switch status {
        case .recalling(let percentage):
            if percentage.isEmpty {
                MailLogger.info("[Mail_Recall_Optimiz] percentage is empty")
                statusText = BundleI18n.MailSDK.Mail_Recall_StatusRecalling
            } else {
                MailLogger.info("[Mail_Recall_Optimiz] percentage is \(percentage)")
                statusText = BundleI18n.MailSDK.Mail_RecallDetails_RecallPercentage_Text(percentage: percentage)
            }
        case .success:
            if isMaillingList && numberOfFailure > 0 {
                statusText = BundleI18n.MailSDK.Mail_Recall_FailNumber_Text1(numberOfFailure)
            } else {
                statusText = BundleI18n.MailSDK.Mail_Recall_StatusSucceed
            }
        case .failed(let comment):
            if isMaillingList && numberOfFailure > 0 {
                statusText = BundleI18n.MailSDK.Mail_Recall_FailNumber_Text1(numberOfFailure)
            } else {
                statusText = comment
            }
        }
    }

    static func newFrom(_ vm: MailRecallDetailCellViewModel, newAvatarKey: String) -> MailRecallDetailCellViewModel {
        return MailRecallDetailCellViewModel(name: vm.name,
                                             address: vm.address,
                                             avatarKey: newAvatarKey,
                                             status: vm.status,
                                             isMaillingList: vm.isMaillingList,
                                             numberOfSuccess: vm.numberOfSuccess,
                                             numberOfFailure: vm.numberOfFailure)
    }

    static func == (lhs: MailRecallDetailCellViewModel, rhs: MailRecallDetailCellViewModel) -> Bool {
        return lhs.name == rhs.name && lhs.address == rhs.address
    }
}

class MailRecallDetailViewModel {
    var cellVMs: Driver<[MailRecallDetailCellViewModel]> {
        return recallDetailCellVMs.asDriver(onErrorJustReturn: [])
    }
    private let recallDetailCellVMs = BehaviorSubject<[MailRecallDetailCellViewModel]>(value: [])

    var showLoading: Driver<Bool> {
        return showLoadingVariable.asDriver(onErrorJustReturn: false)
    }
    private let showLoadingVariable = BehaviorSubject<Bool>(value: true)

    var showError: Driver<Bool> {
        return showErrorVariable.asDriver(onErrorJustReturn: false)
    }
    private let showErrorVariable = BehaviorSubject<Bool>(value: false)

    private let messageId: String
    let title: String = BundleI18n.MailSDK.Mail_Recall_DetailTitle
    var bannerText: String {
        guard let recallingNumbers = recallingNumbers else { return "" }
        var text = ""
        let total = recallingNumbers.recalling + recallingNumbers.success + recallingNumbers.fail
        text += BundleI18n.MailSDK.Mail_Recall_DetailTotal(total)
        if recallingNumbers.success > 0 {
            text += BundleI18n.MailSDK.Mail_Recall_DetailSuccess(recallingNumbers.success)
        }
        if recallingNumbers.fail > 0 {
            text += BundleI18n.MailSDK.Mail_Recall_DetailFail(recallingNumbers.fail)
        }
        if recallingNumbers.recalling > 0 {
            text += BundleI18n.MailSDK.Mail_Recall_DetailRecalling(recallingNumbers.recalling)
        }
        text += BundleI18n.MailSDK.Mail_Recall_DetailListBelow
        return text
    }
    private var recallingNumbers: (recalling: Int64, success: Int64, fail: Int64)?

    private let bag = DisposeBag()

    init(messageId: String) {
        self.messageId = messageId
        fetch()
        observeNetStatusChange()
    }

    private func observeNetStatusChange() {
        PushDispatcher
            .shared
            .larkEventChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                switch push {
                case .dynamicNetStatusChange(let change):
                    switch change.netStatus {
                    case .excellent, .evaluating, .weak:
                        if let showingError = (try? self?.showErrorVariable.value()), showingError == true {
                            MailLogger.info("MailRecall net online error retry")
                            self?.fetch(showLoading: true)
                        } else {
                            MailLogger.info("MailRecall net online but not error")
                        }
                    case .netUnavailable, .serviceUnavailable, .offline:
                        MailLogger.info("MailRecall network not avaliable")
                    @unknown default:
                        MailLogger.info("MailRecall network unknown netstatus")
                    }
                }
            }).disposed(by: bag)
    }

    private func fetchAvatar(userid: String, cellVM: MailRecallDetailCellViewModel) {
        MailModelManager.shared.getUserAvatarKey(userId: userid).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (avatarKey) in
            guard var currentVMs = try? self?.recallDetailCellVMs.value(), let idx = currentVMs.firstIndex(of: cellVM) else { return }
            let fixedKey = avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
            let updateVM = MailRecallDetailCellViewModel.newFrom(cellVM, newAvatarKey: fixedKey)
            currentVMs[idx] = updateVM
            self?.recallDetailCellVMs.onNext(currentVMs)
        }).disposed(by: bag)
    }

    func fetch(showLoading: Bool = true) {
        showErrorVariable.onNext(false)
        showLoadingVariable.onNext(showLoading)
        Store.fetcher?.getRecallDetail(for: messageId).subscribe(onNext: { [weak self] (res) in
            self?.showLoadingVariable.onNext(false)
            self?.recallingNumbers = (res.numberOfProcessing, res.numberOfSuccess, res.numberOfFailure)
            self?.recallDetailCellVMs.onNext(res.items.map { (item) -> MailRecallDetailCellViewModel in
                let recallState: MailRecallDetailState
                switch item.status {
                case .recallProcessing:
                    MailLogger.info("[Mail_Recall_Optimiz] item status recallProcessing")
                    var percentage = ""
                    if item.hasGroupFinishPercent {
                        percentage = String(item.groupFinishPercent) + "%"
                        MailLogger.info("[Mail_Recall_Optimiz] processing HAS percentage: \(percentage)")
                    } else {
                        MailLogger.info("[Mail_Recall_Optimiz] processing NO percentage")
                    }
                    recallState = .recalling(percentage: percentage)
                case .recallSuccess:
                    MailLogger.info("[Mail_Recall_Optimiz] item status success")
                    recallState = .success
                case .recallFail:
                    MailLogger.info("[Mail_Recall_Optimiz] item status recallFail")
                    var comment: String
                    let failedTextHeader = item.isMailingList ? BundleI18n.MailSDK.Mail_Recall_FailNumber_Text1(item.numberOfFailure) : BundleI18n.MailSDK.Mail_Recall_StatusFailed
                    switch item.comment {
                    case .unknown, .noComment:
                        comment = BundleI18n.MailSDK.Mail_RecallDetail_FailDomainExternal_Text
                    case .messageHasBeenRead:
                        comment = BundleI18n.MailSDK.Mail_Recall_FailHasBeenRead
                    case .notUsingLarkMail:
                        comment = BundleI18n.MailSDK.Mail_Recall_FailNotLarkMail
                    case .notInTheSameTenant:
                        comment = BundleI18n.MailSDK.Mail_Recall_FailNotSameTenant
                    case .invalidAddress:
                        comment = BundleI18n.MailSDK.Mail_Recall_FailedAddressDeleted
                    @unknown default:
                        comment = ""
                    }
                    comment = failedTextHeader + comment
                    recallState = .failed(comment: comment)
                    MailLogger.info("[Mail_Recall_Optimiz] FAILED with text \(comment)")
                @unknown default:
                    recallState = .failed(comment: BundleI18n.MailSDK.Mail_Recall_StatusFailed)
                }
                let vm = MailRecallDetailCellViewModel(name: item.address.mailDisplayName,
                                                       address: item.address.address,
                                                       avatarKey: "",
                                                       status: recallState,
                                                       isMaillingList: item.isMailingList,
                                                       numberOfSuccess: item.numberOfSuccess,
                                                       numberOfFailure: item.numberOfFailure)

                self?.fetchAvatar(userid: item.address.larkEntityIDString, cellVM: vm)
                return vm
            })
            // If processing, fetch every 5 seconds to update list
            let period: Double = 5
            if res.numberOfProcessing > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + period) { [weak self] in
                    self?.fetch(showLoading: false)
                }
            }
        }, onError: { [weak self] (_) in
            self?.showErrorVariable.onNext(true)
        }).disposed(by: bag)
    }
}
