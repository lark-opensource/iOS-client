//
//  VChatMeetingCardViewComponent.swift
//  Action
//
//  Created by Prontera on 2019/6/4.
//

import Foundation
import AsyncComponent
import EEFlexiable
import RustPB
import RxSwift
import LarkSDKInterface
import LarkModel

class VChatMeetingCardViewComponent<C: Context>: ASComponent<VChatMeetingCardViewComponent.Props, EmptyState, VChatMeetingCardView, C> {

    final class Props: ASComponentProps {
        var content: VChatMeetingCardContent?
        var contentPreferMaxWidth: CGFloat = 0
        var realVM: VChatMeetingCardViewModelImpl!
    }

    override var isComplex: Bool {
        return true
    }

    override var isSelfSizing: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return self.props.realVM.calculateSize(maxWidth: props.contentPreferMaxWidth,
                                               topic: props.content?.topic,
                                               meetNumber: props.content?.meetNumber,
                                               meetingTagType: props.realVM.getMeetingTagType(),
                                               meetingSource: props.realVM.meetingSource,
                                               isShowHour: props.realVM.computeIsShowHour(),
                                               isWebinar: props.content?.isWebinar,
                                               joinedDeviceDesc: props.realVM.joinedDeviceDesc.value)
    }

    override func update(view: VChatMeetingCardView) {
        super.update(view: view)
        view.bindViewModel(self.props.realVM)
        if props.content != nil {
            view.updateUI(maxWidth: props.contentPreferMaxWidth, isShowHour: props.realVM.computeIsShowHour())
        }
    }

    override func create(_ rect: CGRect) -> VChatMeetingCardView {
        let view = VChatMeetingCardView(viewModel: props.realVM, frame: rect)
        return view
    }
}
