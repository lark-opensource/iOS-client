//
//  InMeetRtcComponent.swift
//  ByteView
//
//  Created by ZhangJi on 2021/12/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

final class InMeetRtcComponent: InMeetViewComponent {
    let rtcViewModel: InMeetRtcViewModel
    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.rtcViewModel = viewModel.resolver.resolve()!
        rtcViewModel.canShowUserNetworkToast = true
        rtcViewModel.canShowCellularToast = true
        rtcViewModel.showUserNetworkToastIfNeeded()
    }

    deinit {
        rtcViewModel.canShowUserNetworkToast = false
        rtcViewModel.canShowCellularToast = false
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .rtc
    }
}
