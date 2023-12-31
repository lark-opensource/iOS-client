//
//  PSTNAreaCodeViewModel.swift
//  ByteView
//
//  Created by yangyao on 2020/5/21.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import ByteViewNetwork
import ByteViewSetting

final class PSTNAreaCodeViewModel {
    private let disposeBag = DisposeBag()
    let selectedRelay: BehaviorRelay<MobileCode?>
    let logger = Logger.ui
    var showIndexList: Bool = true
    let pstnOutgoingCallCountryDefault: [MobileCode]
    let pstnOutgoingCallCountryList: [MobileCode]
    init(pstnOutgoingCallCountryDefault: [MobileCode], pstnOutgoingCallCountryList: [MobileCode],
         selectedRelay: BehaviorRelay<MobileCode?>) {
        self.selectedRelay = selectedRelay
        self.pstnOutgoingCallCountryDefault = pstnOutgoingCallCountryDefault
        self.pstnOutgoingCallCountryList = pstnOutgoingCallCountryList
        self.updateSponsorAdminSettings()
    }

    deinit {
        logger.info("PSTNAreaCodeViewModel deinit")
    }

    private let dataRelay = BehaviorRelay<[AreaCodeSectionModel<String, MobileCode>]>(value: [])
    private(set) lazy var dataSource = dataRelay.asObservable().observeOn(MainScheduler.instance)
    func updateSponsorAdminSettings() {
        var sections: [AreaCodeSectionModel<String, MobileCode>] = []

        var pstnOutgoingCallCountryList = self.pstnOutgoingCallCountryList
        let pstnOutgoingCallCountryDefault = self.pstnOutgoingCallCountryDefault

        showIndexList = pstnOutgoingCallCountryList.count >= 14
        if showIndexList {
            let keys = Set(pstnOutgoingCallCountryList.map({ $0.key }))
            sections.append(AreaCodeSectionModel(index: "", items: pstnOutgoingCallCountryDefault.filter({ keys.contains($0.key) })))
            pstnOutgoingCallCountryList.filter { !$0.index.isEmpty }.groupBy(keySelector: { $0.index }).forEach { (index, codes) in
                sections.append(AreaCodeSectionModel(index: index, items: codes))
            }
        } else {
            pstnOutgoingCallCountryDefault.forEach { (code) in
                if let index = pstnOutgoingCallCountryList.firstIndex(where: { $0.key == code.key }) {
                    pstnOutgoingCallCountryList.remove(at: index)
                }
            }
            pstnOutgoingCallCountryList.insert(contentsOf: pstnOutgoingCallCountryDefault, at: 0)
            sections.append(AreaCodeSectionModel(index: "", items: pstnOutgoingCallCountryList))
        }
        dataRelay.accept(sections)
    }
}
