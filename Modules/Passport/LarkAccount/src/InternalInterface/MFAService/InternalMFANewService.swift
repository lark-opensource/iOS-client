//
//  InternalMFANewService.swift
//  LarkAccount
//
//  Created by YuankaiZhu on 2023/9/3.
//

import Foundation
import LarkAccountInterface

protocol InternalMFANewService: AccountServiceNewMFA { // user:current
    var onSuccess: ((String) -> Void)? { get set }
    var onError: ((NewMFAServiceError) -> Void)? { get set }
    var loginNaviMFAResult: NewMFAResult { get set }
    var needSendMFAResultcWhenDissmiss:Bool { get set }
    func setLoginNaviMFAResult(loginNaviMFAResult: NewMFAResult, needSendMFAResultcWhenDissmiss: Bool)
    var isDoingActionStub: Bool { get set }
    var isNotifyVCAppeared: Bool { get set }

}
