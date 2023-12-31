//
//  BLEManager.swift
//  Calendar
//
//  Created by pluto on 2023/7/19.
//
import nfdsdk
import Foundation
import LKCommonsLogging
import CoreBluetooth
import ServerPB
import CalendarFoundation
import LarkSensitivityControl
import UniverseDesignDialog
import LarkContainer
import RxSwift

final class BLEManager: NSObject, UserResolverWrapper {
    private let logger = Logger.log(BLEManager.self, category: "Calendar.BLEManager")

    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    private let timeOutPeriod: Int32 = 5000
    private let nfdKit: NFDKit = NFDKit()
    private let disposeBag = DisposeBag()
    
    let userResolver: UserResolver
    let token = LarkSensitivityControl.Token("LARK-PSDA-calendar_myai_ble_scan_for_rooms")
    var fromVC: UIViewController?
    var canPopDialogCallBack: (()-> Bool)?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init()
        setUpNfdConfig()
    }
    
    deinit {
        nfdKit.uninit()
    }
    
    private func setUpNfdConfig() {
        logger.info("setup NfdConfig")
        let config: String = calendarDependency?.getSettingJson(key: .make(userKeyLiteral: "nfd_scan_config"), defaultValue: "") ?? ""
        nfdKit.initSDK(self)
        nfdKit.initScanner()
        nfdKit.configScan(config)
        nfdKit.token = token
    }
    
    /// 接受插件回调
    func actionForBleTrigger() {
        logger.info("start BLEScanProcess.")
        calendarApi?.getCalendarDevicePermissionBleRequest()
            .flatMap {[weak self] res -> Observable<ServerPB_Calendarevents_UploadNearbyMeetingRoomInfoResponse> in
                self?.logger.info("getCalendarDevicePermissionBleRequest with: \(res)")
                guard res.needBle, let api = self?.calendarApi else {
                    self?.logger.info("abort with empty")
                    return .empty()
                }
                return api.uploadNearbyMeetingRoomInfoRequest(bleScanResultList: "")
                    .catchErrorJustReturn(ServerPB_Calendarevents_UploadNearbyMeetingRoomInfoResponse.init())
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                switch self.getBlueToothAuthorityStatus() {
                case .denied:
                    guard let fromVC = self.fromVC else {
                        self.logger.error("failed get vc popUpToSettingDialog failed")
                        return
                    }
                    self.popUpToSettingDialog(fromVC: fromVC)
                case .allowed, .notDetermined:
                    self.preSystemCheckWithScan()
                }
            },onError: { [weak self] error in
                self?.logger.info("checkTenantBlEPermission error with: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    /// 获取蓝牙授权状态
    func getBlueToothAuthorityStatus () -> BlueToothAuthorityStatus {
        if #available(iOS 13.1, *) {
            logger.info("getBlueToothAuthorityStatus: \(CBManager.authorization)")
            switch CBManager.authorization {
            case .allowedAlways:
                return .allowed
            case .denied:
                return .denied
            default:
                return .notDetermined
            }
        } else if #available(iOS 13.0, *) {
            // 在方法内实例 CBPeripheralManager 后立即释放，不会触发权限弹窗。
            logger.info("getBlueToothAuthorityStatus: \(CBPeripheralManager().authorization)")

            switch CBPeripheralManager().authorization {
            case .allowedAlways:
                return .allowed
            case .denied:
                return .denied
            default:
                return .notDetermined
            }
        } else {
            return .allowed
        }
    }
    
    /// 调用SDK的SCAN
    func startBLEMeetingRoomScan() {
        logger.info("NFDKitScan begin width timeOutPeriod: \(timeOutPeriod)")
        let resStatus = nfdKit.startScan(timeOutPeriod, andMode: .SCAN_MODE_BLE, andUsage: .BLE_SCAN_ROOMS ) { (result, e) in
            let error = "Calendar NFDKitScanErrorCode(\(e))"
            self.logger.info("Calendar NFDKit.shared().startScan() finished, result = \(result), error = \(error)")
            
            CalendarTracer.shareInstance.writeEvent(
                eventId: "cal_event_ai_create_dev",
                params: ["action_name": "scan_rooms",
                         "is_success": (result != "{}" && e == .NFD_NO_ERROR) ? "true" : "false"])
            
            self.calendarApi?.uploadNearbyMeetingRoomInfoRequest(bleScanResultList: result)
                .subscribe( onError: {[weak self] error in
                    self?.logger.error("uploadNearbyMeetingRoomInfo error with: \(error)")
                }).disposed(by: self.disposeBag)
            self.stopScan()
        }
        
        logger.info("nfdKit.startScan done with resStatus: \(resStatus)")

        CalendarTracer.shareInstance.writeEvent(
            eventId: "cal_event_ai_create_dev",
            params: ["action_name": "invoke_bluetooth",
                     "is_success": (resStatus == .SUCCESS) ? "true" : "false"])
    }
    
    /// 用于notDetermined路径，首次触发系统弹窗，回调后再执行scan
    func preSystemCheckWithScan() {
        logger.info("NFDKit precheck with: applyBlePermission")
        let resStatus = nfdKit.applyBlePermission {[weak self] status in
            self?.logger.info("NFDKit precheck with: \(status)")
            if #available(iOS 10.0, *) {
                if status == CBManagerState.poweredOn.rawValue {
                    self?.startBLEMeetingRoomScan()
                }
            } else {
                if status == CBCentralManagerState.poweredOn.rawValue {
                    self?.startBLEMeetingRoomScan()
                }
            }
        }
        logger.info("NFDKit precheck with resStatus: \(resStatus)")
    }
    
    /// 停止scan 多次调用无异常
    func stopScan() {
        logger.info("NFDKitScan Stop is called")
        nfdKit.stopScan()
    }
    
    /// 弹出去设置弹窗
    func popUpToSettingDialog(fromVC: UIViewController) {
        if !(canPopDialogCallBack?() ?? true) {
            logger.info("can not PopDialog")
            return
        }

        if KVValues.hasShownGoSettingDialog { return }
        let alertVC = UDDialog(config: UDDialogUIConfig())
        alertVC.setTitle(text: I18n.Calendar_M_BluetoothAccess_PopupTitle)
        alertVC.setContent(text: I18n.Calendar_M_BluetoothAccess_PopupDescription)

        alertVC.addSecondaryButton(text: I18n.Calendar_M_BluetoothAccess_Cancel_Button)

        alertVC.addPrimaryButton(text: I18n.Calendar_M_BluetoothAccess_Settings_Button, dismissCompletion:  {
            self.openSettings()
        })
        KVValues.hasShownGoSettingDialog = true
        fromVC.present(alertVC, animated: true, completion: nil)
    }
    
    /// 跳转应用设置
    func openSettings() {
        logger.info("onNFDKit open Setting")
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    enum BlueToothAuthorityStatus {
        case allowed
        case denied
        case notDetermined
    }
}

extension BLEManager: NFDKitDelegate {
    func onNFDKitLogging(_ level: NFDKitLogLevel, andContent content: String) {
        switch level {
        case .LEVEL_ERROR:
            logger.error("onNFDKitLogging: \(content)")
        case .LEVEL_WARN:
            logger.warn("onNFDKitLogging: \(content)")
        case .LEVEL_INFO:
            logger.info("onNFDKitLogging: \(content)")
        default:
            break
        }
    }

    func onNFDKitTracking(_ event: String, andParams params: String) {
        logger.info("onNFDKitTracking: \(event), params: \(params)")
        if let data = params.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            logger.info("onNFDKitTrackingevent: \(event), params: \(params), data: \(data), json: \(json)")
            CalendarTracer.shareInstance.writeEvent(eventId: event, params: json)
        } else {
            logger.info("onNFDKitTracking event: \(event), params: \(params)")
            CalendarTracer.shareInstance.writeEvent(eventId: event)
        }
    }
}
