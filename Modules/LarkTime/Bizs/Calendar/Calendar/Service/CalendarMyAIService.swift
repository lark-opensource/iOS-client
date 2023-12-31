//
//  CalendarMyAIService.swift
//  Calendar
//
//  Created by pluto on 2023/8/9.
//

import Foundation
import LarkAIInfra
import LKCommonsLogging
import LarkContainer
import RxSwift

public protocol CalendarMyAIService {
    /// 注册插件勾选回调
    func registSelectedExtensionObservers()
    /// 获取myAI Info
    func myAIInfo() -> MyAIInfo
    /// 编辑页触发蓝牙扫描流程
    func activeBleScanForEdit(fromVC: UIViewController, canPopDialogCallBack: (()-> Bool)?)
}

final class CalendarMyAIServiceImpl: CalendarMyAIService, UserResolverWrapper {
    let logger = Logger.log(CalendarMyAIServiceImpl.self, category: "Calendar.CalendarAIService")
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    
    let myAIExtensionService: MyAIExtensionService
    let myAIInfoService: MyAIInfoService
    
    let userResolver: UserResolver
    let disposeBag = DisposeBag()
    let bleManager: BLEManager
    
    init(userResolver: UserResolver, myAIExtensionService: MyAIExtensionService, myAIInfoService: MyAIInfoService) {
        self.userResolver = userResolver
        self.myAIExtensionService = myAIExtensionService
        self.myAIInfoService = myAIInfoService
        self.bleManager = BLEManager(userResolver: userResolver)
    }
    
    /// 注册插件选择回调
    func registSelectedExtensionObservers() {
        self.logger.info("registSelectedExtensionObservers called")

        myAIExtensionService.selectedExtension
            .subscribe(onNext: { [weak self] (info) in
                self?.logger.info("myAIExtensionService selectedExtension info: \(info)")
                guard let self = self else { return }
                let enableBluetoothScanRooms = FeatureGating.bluetoothScanRooms(userID: self.userResolver.userID)
                if !enableBluetoothScanRooms {
                    self.logger.info("FG bluetoothScanRooms:\(enableBluetoothScanRooms)")
                    return
                }
                
                if let calendarConfigSetting = self.calendarDependency?.getSettingJson(key: .make(userKeyLiteral: "calendar_config")),
                   let lark_extension_id: String =  calendarConfigSetting["lark_extension_id"] as? String {
                    let extensionInfo = info.extensionList.filter { $0.id == lark_extension_id }
                    self.logger.info("myAIExtensionService extensionInfo: \(extensionInfo)")
                    if !extensionInfo.isEmpty {
                        self.bleManager.actionForBleTrigger()
                        self.bleManager.fromVC = info.fromVc
                    }
                }
            }, onError: { [weak self] error in
                self?.logger.error(" myAIExtensionService.selectedExtension error with:\(error)")
            })
            .disposed(by: self.disposeBag)
    }
    
    /// 获取AI基本信息
    func myAIInfo() -> MyAIInfo {
        return myAIInfoService.info.value
    }

    func activeBleScanForEdit(fromVC: UIViewController, canPopDialogCallBack: (()-> Bool)?) {
        let enableBluetoothScanRooms = FeatureGating.bluetoothScanRooms(userID: self.userResolver.userID)
        if !enableBluetoothScanRooms {
            self.logger.info("activeBleScanForEdit FG bluetoothScanRooms:\(enableBluetoothScanRooms)")
            return
        }
        bleManager.actionForBleTrigger()
        bleManager.fromVC = fromVC
        bleManager.canPopDialogCallBack = canPopDialogCallBack
    }
}
