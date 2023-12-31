//
//  LivenessCertViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation

final class LivenessCertViewModel: CertBaseViewModel {
    private let certService: CertService
    private let callback: ((Result<Void, CertError>) -> Void)?
    let name: String

    init(certService: CertService, name: String, callback: ((Result<Void, CertError>) -> Void)?) {
        self.certService = certService
        self.name = name
        self.callback = callback
        super.init()
    }

    func doLivenessCheck(completion: @escaping (Result<Void, Error>) -> Void) {
        return certService.verifyLiveness(completion: completion)
    }

    func handleCallBack(_ result: Result<Void, CertError>) {
        self.callback?(result)
    }

    override func clickClose() {
        LiveCertTracks.trackLivenessPage(nextStep: false)
    }
}
