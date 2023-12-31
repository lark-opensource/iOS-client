//
//  SearchNativeAppService.swift
//  LarkSearch
//
//  Created by chenyanjie on 2023/10/13.
//

import Foundation
import LarkContainer
import LarkQuickLaunchInterface
import RustPB
import LarkRustClient
import RxSwift
import RxCocoa
import LarkSearchCore
import LarkLocalizations

final class SearchNativeAppService: OpenNavigationProtocol, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy var rustService: RustService?
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func notifyNavigationAppInfos(appInfos: [OpenNavigationAppInfo]) {
        guard SearchFeatureGatingKey.enableSpotlightNativeApp.isUserEnabled(userResolver: self.userResolver) else { return }
        let searchInfos = transformToSearchInfos(originAppInfos: appInfos)
        postNativeAppSearchInfo(searchInfos: searchInfos)
    }

    private func transformToSearchInfos(originAppInfos: [OpenNavigationAppInfo]) -> [Search_V2_NavigationSearchInfo] {
        return originAppInfos.filter { $0.appType == .native }
                             .map { appInfo in
                                 var searchInfo = Search_V2_NavigationSearchInfo()
                                 searchInfo.id = appInfo.uniqueId
                                 let lang = LanguageManager.currentLanguage.rawValue.lowercased()
                                 searchInfo.name = appInfo.i18nName[lang] ?? (appInfo.i18nName[Lang.en_US.rawValue.lowercased()] ?? "")
                                 searchInfo.sourceKey = appInfo.key
                                 searchInfo.i18NNames = appInfo.i18nName
                                 return searchInfo
                             }
    }

    private func postNativeAppSearchInfo(searchInfos: [Search_V2_NavigationSearchInfo]) {
        guard SearchFeatureGatingKey.enableSpotlightNativeApp.isUserEnabled(userResolver: self.userResolver) else { return }
        var request = RustPB.Search_V2_PutNavigationSearchRequest()
        request.appInfos = searchInfos

        guard let rustService = rustService else { return }

        rustService.async(message: request)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (response: Search_V2_PutNavigationSearchResponse) in
                guard response != nil else { return } //这句话只是为了解决静态检测问题
            })
            .disposed(by: self.disposeBag)
    }
}
