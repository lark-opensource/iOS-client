//
//  TourFlowMockAPI.swift
//  LarkTourDev
//
//  Created by Meng on 2020/6/11.
//

import Foundation
import LarkTour
import RxSwift
import RustPB
import SwiftProtobuf
import RoundedHUD

class TourFlowMockAPI: TourFlowAPI {
    private let fakeData = FakeData()

    func pullDynamicFlow(context: FlowQueryContext) -> Observable<GetDynamicFlowResponse> {
        return fakeData.fetchFakePB()
    }

    func pullDynamicFlowStep(context: FlowQueryContext, rootStepId: String) -> Observable<GetDynamicFlowStepResponse> {
        return .just(GetDynamicFlowStepResponse())
    }

    func reportFlowEvent(suiteId: Int64, stepId: String, slotId: String) -> Observable<Void> {
        return .just(())
    }
}
