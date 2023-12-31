//
//  MomentsCommentReplyCellComponent.swift
//  Moment
//
//  Created by liluobin on 2021/1/27.
//
import UIKit
import Foundation
import AsyncComponent

final class MomentsCommentReplyCellComponent<C: AsyncComponent.Context>: ASComponent<MomentsCommentReplyCellComponent.Props, EmptyState, MomentsCommentReplyView, C> {

    final class Props: ASComponentProps {
        var replyComment: NSAttributedString?
        var preferredMaxWidth: CGFloat = 0
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return CGSize(width: props.preferredMaxWidth, height: MomentsCommentReplyView.replayViewHeight)
    }

    public override func create(_ rect: CGRect) -> MomentsCommentReplyView {
        return MomentsCommentReplyView(replyComment: props.replyComment ?? NSAttributedString(), preferredMaxWidth: props.preferredMaxWidth)
    }

    override func update(view: MomentsCommentReplyView) {
        super.update(view: view)
        view.updateViewWith(replyComment: props.replyComment ?? NSAttributedString(), preferredMaxWidth: props.preferredMaxWidth)
    }
}
