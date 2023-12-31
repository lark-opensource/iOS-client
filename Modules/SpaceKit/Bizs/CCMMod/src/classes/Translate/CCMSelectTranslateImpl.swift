//
//  TranslateImpl.swift
//  CCMMod
//
//  Created by liujinwei on 2023/7/27.
//  


import Foundation
import SKBrowser
import LarkContainer
import SKResource
import SKFoundation
#if MessengerMod
import LarkMessengerInterface
#endif
///接im划词翻译
public final class CCMSelectTranslateImpl: CCMTranslateAPI {
    
    public static let shared = CCMSelectTranslateImpl()
    
    #if MessengerMod
    @InjectedLazy private var selectTranslateService: SelectTranslateService
    #endif
    
    public func showTranslatePanel(text: String, from vc: UIViewController, canCopy: Bool, encryptId: String?) {
        #if MessengerMod
        let config = TranslateCopyConfig(canCopy: canCopy, denyCopyText: SKResource.BundleI18n.SKResource.LarkCCM_Docs_Translate_CopyRestricted_Toast, pointId: encryptId, hideSystemMenu: UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable)
        selectTranslateService.showSelectTranslateView(selectString: text,
                                                       fromVC: vc,
                                                       copyConfig: config,
                                                       trackParam: [:])
        #endif
    }
}
