//
//  BannerCellViewModel.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/27.
//

import Foundation

class BannerCellViewModel {
    let bannerResponse: BannerResponse
    let bannerResource: BannerResource
    var loading: Bool = false
    
    init(bannerResponse: BannerResponse, bannerResource: BannerResource, loading: Bool = false) {
        self.bannerResponse = bannerResponse
        self.bannerResource = bannerResource
        self.loading = loading
    }
}

extension BannerCellViewModel {
    
    func hasImage() -> Bool {
        return bannerResource.resourceView.image_url_themed?.isValid() ?? bannerResource.resourceView.image_key_themed?.isValid() ?? false
    }
    
    func getText() -> String {
        return I18nUtils.getLocal(i18n: bannerResource.resourceView.text_i18n)
    }
}
