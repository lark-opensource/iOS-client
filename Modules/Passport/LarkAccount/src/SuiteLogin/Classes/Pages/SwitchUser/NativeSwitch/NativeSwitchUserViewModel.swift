//
//  NativeSwitchUserViewModel.swift
//  LarkAccount
//
//  Created by bytedance on 2022/4/21.
//

import Foundation
import RxRelay
import RxSwift
import LarkAccountInterface
import LarkContainer

class NativeSwitchUserViewModel {
    @Provider var userManager: UserManager

    var title: String {
        return BundleI18n.suiteLogin.Lark_Shared_Passport_SwitchAccount_Title
    }

    var subTitle: String {
        return BundleI18n.suiteLogin.Lark_Shared_Passport_SwitchAccount_Text
    }

    let context: UniContextProtocol

    let dataSource = BehaviorRelay<[SelectUserCellData]>(value: [])

    private let disposeBag = DisposeBag()

    init(
        context: UniContextProtocol
    ) {
        self.context = context
        makeDataSource()
    }

    private func makeDataSource() {

        UserManager.shared.userListRelay.subscribe(onNext: { [weak self] userList in
            var cellDataList: [SelectUserCellData] = []
            userList.forEach { [weak self] userInfo in
                let isForegroundUser = userInfo.userID == self?.userManager.foregroundUser?.userID // user:current
                let data = SelectUserCellData(userId: userInfo.userID,
                                              tenantId: userInfo.user.tenant.id,
                                              type: .normal,
                                              userName: userInfo.user.name,
                                              iconUrl: userInfo.user.tenant.iconURL,
                                              tenantName: userInfo.user.tenant.name,
                                              status: nil,
                                              enableBtnInfo: nil,
                                              excludeLogin: false,
                                              tag: isForegroundUser ? BundleI18n.suiteLogin.Lark_Shared_SwitchAccount_CurrentAccountLabel : nil, // user:current
                                              isValid: !isForegroundUser, // user:current
                                              isCertificated: userInfo.user.tenant.isCertificated ?? false)
                cellDataList.append(data)
            }
            self?.dataSource.accept(cellDataList)
        }).disposed(by: disposeBag)
    }

    func getData(of index: IndexPath) -> SelectUserCellData {
        let cellDataList = dataSource.value
        guard index.section == 0 && index.row < cellDataList.count else {
            return .placeholder()
        }
        return cellDataList[index.row]
    }
}
