//
//  VersionServiceImpl.swift
//  LarkVersion
//
//  Created by 姚启灏 on 2018/9/7.
//

import Foundation
import LarkModel
import RxSwift
import LarkFoundation

final class VersionServiceImpl: VersionUpdateService {
    private let versionManager: VersionManager

    /// value equal to isShouldUpdate.value()
    var shouldUpdate: Bool { return versionManager.shouldUpdate }
    /// scenes：1、about lark；2、setting item in system setting
    var isShouldUpdate: BehaviorSubject<Bool> { return versionManager.isShouldUpdate }
    /// scenes：1、top avatar in feed；2、setting item in feed's sidebar
    var shouldNoticeNewVerison: BehaviorSubject<Bool> { return versionManager.shouldNoticeVar }

    init(versionManager: VersionManager) {
        self.versionManager = versionManager
    }

    func setup() {
        versionManager.loadData()
    }

    func getCurrentVersionNotes() -> Observable<String> {
        return versionManager.versionHelper.getVersionNote().map { $0.releaseNotes }
    }

    func updateLark() {
        versionManager.updateLark()
    }

    func tryToCleanUpNotice() {
        versionManager.tryToCleanUpNotice()
    }

    func addCheckTrigger(_ trigger: VersionCheckTrigger) {
        versionManager.addCheckTrigger(trigger)
    }
}
