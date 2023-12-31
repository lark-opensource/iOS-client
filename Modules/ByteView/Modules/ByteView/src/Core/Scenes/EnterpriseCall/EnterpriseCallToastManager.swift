//
//  EnterpriseCallToastManager.swift
//  ByteView
//
//  Created by fakegourmet on 2021/10/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

class EnterpriseCallToastManager {

    static let shared = EnterpriseCallToastManager()
    private init() {}

    @RwAtomic
    private var caches = Set<String>()

    func showToast(i18nKey key: String, httpClient: HttpClient) {
        httpClient.i18n.get(key) { [weak self] result in
            guard let self = self else { return }
            if let content = result.value, !self.caches.contains(content) {
                Toast.show(content) {
                    self.caches.remove(content)
                }
            }
        }
    }
}
