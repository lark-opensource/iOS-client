//
//  TourApplicationDelegate.swift
//  LarkTour
//
//  Created by Meng on 2020/4/17.
//

import Foundation
import AppContainer
import LKCommonsLogging
import LarkTourInterface
import LarkContainer
import RunloopTools
import LarkAccountInterface
import RxSwift
import BootManager

final class TourSetupTask: UserFlowBootTask, Identifiable {
    static var identify = "TourSetupTask"

    @ScopedProvider private var dependency: TourDependency?
    @ScopedProvider private var deviceService: DeviceService?
    @ScopedProvider private var adEventHandler: AdvertisingEventHandler?
    @ScopedProvider private var advertingService: AdvertisingService?

    private let disposeBag = DisposeBag()
    static let logger = Logger.log(TourSetupTask.self, category: "Tour")

    override func execute(_ context: BootContext) {
        self.setup()
    }

    override var deamon: Bool { return true }

    func setup() {
        self.dependency?.setConversionDataHandler { [weak self](serializedData) in
            self?.adEventHandler?.onConversionDataReceived(serializedData: serializedData)
        }

        TourTracker.advertisingServiceProvider = { [weak self] in
            return self?.advertingService
        }

        RunloopDispatcher.shared.addTask(scope: .container) {
            self.bindDeviceIdEvent()
        }
    }

    private func bindDeviceIdEvent() {
        deviceService?
            .deviceInfoObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (_) in
                self.adEventHandler?.onDeviceIdChanged()
            }).disposed(by: self.disposeBag)
        Self.logger.info("try trigger ad event on finish launching")
        adEventHandler?.onDeviceIdChanged()
    }
}
