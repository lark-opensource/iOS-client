//
//  blocklistEntryModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/7/6.
//

import Foundation
import RxSwift
import EENavigator
import LarkContainer
import LarkOpenSetting
import LarkSDKInterface
import LarkMessengerInterface
import LarkSettingUI

let blockListEntryModuleProvider: ModuleProvider = { userResolver in
    return BlockListEntryModule(userResolver: userResolver)
}

final class BlockListEntryModule: BaseModule {
    private var blockNum: Int32?

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.addStateListener(.viewWillAppear) { [weak self] in
            guard let self = self else { return }
            let configureAPI = try? self.userResolver.resolve(assert: ConfigurationAPI.self)
            configureAPI?.getBlockUserNum()
                .subscribe(onNext: { [weak self] (response) in
                    self?.blockNum = response.blockUserNums
                    self?.context?.reload()
                }).disposed(by: self.disposeBag)
        }
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        var contentText: String = ""
        if let blockNum = self.blockNum {
            contentText = BundleI18n.LarkMine.Lark_NewSettings_BlocklistCountUser("\(blockNum)")
        }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_Blocklist,
                                  accessories: [.text(contentText), .arrow()],
                                  onClick: { [weak self] _ in
            guard let from = self?.context?.vc else { return }
            if let configureAPI = try? self?.userResolver.resolve(assert: ConfigurationAPI.self),
               let monitor = try? self?.userResolver.resolve(assert: SetContactInfomationMonitorService.self),
               let userNavigator = self?.userResolver.navigator {
                let vm = BlockListViewModel(userNavigator: userNavigator, configAPI: configureAPI, monitor: monitor)
                self?.userResolver.navigator.push(BlockListViewController(viewModel: vm), from: from)
            }
        })
        return SectionProp(items: [item],
                           footer: .title(BundleI18n.LarkMine.Lark_NewSettings_BlocklistDescription))
    }
}
