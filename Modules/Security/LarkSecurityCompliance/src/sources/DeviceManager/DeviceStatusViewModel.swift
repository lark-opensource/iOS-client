//
//  DeviceStatusViewModel.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/12.
//

import Foundation
import LarkContainer
import LarkUIKit
import RxSwift
import RxCocoa
import LarkSecurityComplianceInfra

struct DeviceStatusCellModel {
    let deviceInfo: GetDeviceInfoResp?
    let checkResult: GetDeviceApplySwitchResp?
    let isRejectReasonEnabled: Bool
}

final class DeviceStatusViewModel: BaseViewModel {

    enum Alert {
        case success
        case successImmediately
        case waiting
        case rejected
    }

    enum Toast {
        case success(String)
        case failed(String)
        case info(String)
        case warning(String)
    }

    private(set) var cellModel: DeviceStatusCellModel?
    private let api = DeviceManagerAPI()
    private let userResolver: UserResolver
    private let isApplyReasonEnabled: Bool

    let isAccessLimited: Bool
    let bag = DisposeBag()
    /// deviceInfo接口请求结果，刷新tableView
    let deviceInfoResp = PublishSubject<DeviceStatusCellModel>()
    /// deviceApply接口请求结果，通知申报理由页
    let applicationResp = PublishSubject<Bool>()
    /// 点击了确认申报按钮
    let applyConfirmedButton = PublishSubject<Void>()
    /// 点击了去申报按钮
    let applyEntryButton = PublishSubject<Void>()
    /// 申报理由页回调
    let deviceDeclarationDismissed = BehaviorSubject<Bool>(value: true)
    /// 点击了刷新按钮
    let refreshButton = PublishSubject<Void>()
    /// 展示弹框
    let showAlert = PublishSubject<Alert>()
    /// 展示toast
    let toast = PublishSubject<Toast>()
    
    // 展示申报理由页
    var showJustificationSheet: Binder<UIViewController?> {
        return Binder(self) { [weak self] _, from in
            guard let self else { return }
            if self.isApplyReasonEnabled {
                Logger.info("show device declaration justification Sheet")
                self.showDeclarationJustificationSheet(from)
            }
        }
    }
    
    /// 申报理由
    let applyReasonText: BehaviorRelay<String>
    /// 申报设备类型
    var applyOwnership: Ownership = .unknown
    
    init(resolver: UserResolver, isLimited: Bool) throws {
        self.userResolver = resolver
        
        self.isAccessLimited = isLimited
        self.applyReasonText = BehaviorRelay(value: "")
        let fgService = try userResolver.resolve(assert: SCFGService.self)
        isApplyReasonEnabled = fgService.staticValue(SCFGKey.enableDeviceApplyReason)
        super.init()
        setup()
        Logger.info("will display device status page: isLimited: \(isLimited), isApplyReasonEnabled: \(isApplyReasonEnabled)")
    }

    deinit {
        Logger.info("end display device status page")
    }

    private func setup() {
        // 用户点击刷新按钮
        let refreshClickedRefresh = refreshButton
            .do(onNext: { [weak self] in
                if (self?.isAccessLimited).isFalse { Events.track("scs_device_declare_click", params: ["click": "refresh", "target": "none"]) }
            })
            .map { false }
        // 首次进入刷新设备状态
        let viewDidLoadRefresh = viewDidLoad.take(1)
            .do(onNext: { [weak self] in
                if (self?.isAccessLimited).isFalse { Events.track("scs_device_declare_view") }
            })
            .map { true }

        let refreshTrigger = Observable.merge([viewDidLoadRefresh, refreshClickedRefresh])

        refreshTrigger
            .flatMapLatest { [weak self] isViewDidLoad -> Observable<BaseResponse<GetDeviceInfoResp>?> in
                guard let self else { return .just(nil) }
                return self.api.getDeviceInfo()
                    .map({ $0 as BaseResponse<GetDeviceInfoResp>? })
                    .catchError({ err in
                        Logger.error("get device info resp err: \(err)")
                        return .just(nil)
                    })
                    .do { [weak self] resp in
                        Logger.info("get device info resp: \(String(describing: resp))")
                        guard !isViewDidLoad, let self else { return }
                        // 刷新之后立马有结果，则弹alert提醒
                        if [DeviceApplyStatus.pass, DeviceApplyStatus.reject].contains(resp?.data.applyStatus) {
                            self.handleAlert(status: resp?.data.applyStatus, isApply: false)
                        }
                        // 刷新之后还在审核中，toast提示
                        if resp?.data.applyStatus == .processing {
                            self.toast.onNext(.info(I18N.Lark_Conditions_DeclarationUnderReview))
                        }
                    }
            }
            .subscribe(onNext: { [weak self] resp in
                guard  let self, let data = resp?.data else { return }
                let cellModel = DeviceStatusCellModel(deviceInfo: data,
                                                      checkResult: self.cellModel?.checkResult,
                                                      isRejectReasonEnabled: self.isApplyReasonEnabled)
                self.cellModel = cellModel
                self.deviceInfoResp.onNext(cellModel)
            })
            .disposed(by: bag)

        viewDidLoad
            .flatMapLatest { [weak self] () -> Observable<GetDeviceApplySwitchResp?> in
                guard let self else { return .just(nil) }
                return self.api.getDeviceApplySwitch()
                    .map({ $0.data as GetDeviceApplySwitchResp? })
                    .catchError { err in
                        Logger.error("get device apply switch resp err: \(err)")
                        return .just(nil)
                    }
            }
            .subscribe(onNext: { [weak self] resp in
                guard let data = resp, let self else { return }
                Logger.info("get device apply switch: \(data)")
                let cellModel = DeviceStatusCellModel(deviceInfo: self.cellModel?.deviceInfo,
                                                      checkResult: data,
                                                      isRejectReasonEnabled: self.isApplyReasonEnabled)
                self.cellModel = cellModel
                self.deviceInfoResp.onNext(cellModel)
            })
            .disposed(by: bag)
        
        let clickApplyResult: Observable<BaseResponse<ApplyDeviceResp>?>
        if isApplyReasonEnabled {
            // 点击确认申报按钮，进行设备申报，提供申报理由
            clickApplyResult = applyConfirmedButton
                .do(onNext: { [weak self] _ in
                    Logger.info("apply confirmed button tapped, apply with reason")
                    self?.trackDeviceApply()
                })
                .flatMapLatest { [weak self] _ -> Observable<BaseResponse<ApplyDeviceResp>?> in
                    guard let self else { return .just(nil) }
                    return self.applyDevice(ownership: applyOwnership,
                                            applyReason: applyReasonText.value.trimmingCharacters(in: .whitespacesAndNewlines))
                }
        } else {
            // 点击去申报按钮，进行设备申报，不提供申报理由
            clickApplyResult = applyEntryButton
                .do(onNext: { [weak self] _ in
                    Logger.info("apply entry button tapped, apply without reason")
                    self?.trackDeviceApply()
                })
                .flatMapLatest { [weak self] _ -> Observable<BaseResponse<ApplyDeviceResp>?> in
                    guard let self else { return .just(nil) }
                    return self.applyDevice(ownership: applyOwnership,
                                            applyReason: nil)
                }
        }
        
        clickApplyResult
            .observeOn(MainScheduler.instance)
            .compactMap({ [weak self] model -> DeviceStatusCellModel? in
                guard let self, let aModel = model?.data else { return nil }
                let info = self.cellModel?.deviceInfo
                let exist = info?.exist ?? false
                let ownership = aModel.ownership ?? info?.ownership ?? .unknown
                let rejectReason = info?.rejectReason ?? ""
                let data = GetDeviceInfoResp(exist: exist, 
                                             applyStatus: aModel.applyStatus,
                                             ownership: ownership, 
                                             rejectReason: rejectReason)
                
                return DeviceStatusCellModel(deviceInfo: data,
                                             checkResult: self.cellModel?.checkResult,
                                             isRejectReasonEnabled: self.isApplyReasonEnabled)
            })
            .subscribe(onNext: { [weak self] cellModel in
                guard let self else { return }
                self.cellModel = cellModel
                self.deviceInfoResp.onNext(cellModel)
            })
            .disposed(by: bag)
    }

    private func handleAlert(status: DeviceApplyStatus?, isApply: Bool) {
        Logger.info("device status handling alert status:\(String(describing: status)), isApply:\(isApply)")
        switch status {
        case .pass:
            showAlert.onNext(isApply ? .successImmediately : .success)
        case .reject where !isApply:
            showAlert.onNext(.rejected)
        case .processing:
            showAlert.onNext(.waiting)
        default:
            break
        }
    }
    
    private func trackDeviceApply() {
        if self.isAccessLimited {
            Events.track("scs_device_declare_click", params: ["click": "declare", "target": "none"])
        }
    }
}

// DeviceDeclarationJustification
extension DeviceStatusViewModel {
    private func applyDevice(ownership: Ownership, applyReason: String?) -> Observable<BaseResponse<ApplyDeviceResp>?> {
        return self.api.applyDevice(ownership: ownership.rawValue, applyReason: applyReason ?? "")
            .map({ $0 as BaseResponse<ApplyDeviceResp>? })
            .catchError({ [weak self] err in
                self?.applicationResp.onNext(false)
                Logger.error("apply device api error:\(err)")
                SCMonitor.error(singleEvent: .device_status, error: err, extra: nil)
                return .just(nil)
            })
            .do { [weak self] resp in
                guard let self else { return }
                self.handleAlert(status: resp?.data.applyStatus, isApply: true)
                let code = resp?.code ?? 0
                Logger.info("apply device resp with code:\(code)")
                self.applicationResp.onNext(code == 0)
                if code != 0 {
                    SCMonitor.error(singleEvent: .device_status, error: nil, extra: ["code": code])
                    self.toast.onNext(.failed(I18N.Lark_Conditions_NetworkFailed))
                }
            }
    }
    
    func showDeclarationJustificationSheet(_ from: UIViewController?) {
        guard let from = from else { return }
        let vc = DeviceDeclarationViewController(viewModel: self)
        userResolver.navigator.present(vc,
                                       wrap: LkNavigationController.self,
                                       from: from,
                                       prepare: { $0.modalPresentationStyle = .formSheet },
                                       animated: true) {
            Logger.info("declaration justification vc presented")
            self.deviceDeclarationDismissed.onNext(false)
        }
    }
}
