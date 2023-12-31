//
//  NewFavoritePostMessageCell.swift
//  LarkChat
//
//  Created by JackZhao on 2021/10/11.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import LarkModel
import LarkCore
import LarkRichTextCore
import LarkUIKit
import LarkContainer
import EENavigator
import LKRichView
import LarkMessageCore
import LarkMessengerInterface

// 使用新富文本渲染框架的cell
final class NewFavoritePostMessageCell: FavoriteMessageCell {
    override class var identifier: String {
        return NewFavoritePostMessageViewModel.identifier
    }

    public override var bubbleContentMaxWidth: CGFloat {
        didSet {
            self.postView.preferredMaxLayoutWidth = bubbleContentMaxWidth
        }
    }

    /// 需要监听事件的Tag
    private let propagationSelectors: [[CSSSelector]] = [
        [CSSSelector(value: RichViewAdaptor.Tag.a)],
        [CSSSelector(value: CodeTag.code)],
        [CSSSelector(value: RichViewAdaptor.Tag.at)],
        [CSSSelector(match: .className, value: RichViewAdaptor.ClassName.abbreviation)],
        [CSSSelector(match: .className, value: RichViewAdaptor.ClassName.unavailableMention)]
    ]

    var postViewModel: NewFavoritePostMessageViewModel? {
        return self.viewModel as? NewFavoritePostMessageViewModel
    }

    var postView: NewPostView = .empty

    public var styleSheets: [CSSStyleSheet] {
        return RichViewAdaptor.createStyleSheets(config: RichViewAdaptor.Config(normalFont: NewFavoritePostMessageViewModel.ParseProps.textFont,
                                                                                atColor: AtColor()))
    }

    override public func setupUI() {
        super.setupUI()

        /// postView
        let postView = NewPostView(numberOfLines: 2,
                                   isReply: false,
                                   preferredMaxLayoutWidth: self.bubbleContentMaxWidth)
        postView.clipsToBounds = true
        postView.bindEvent(selectorLists: self.propagationSelectors, isPropagation: true)
        postView.loadStyleSheets(styleSheets)
        self.contentWraper.addSubview(postView)
        postView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.postView = postView
    }

    override public func updateCellContent() {
        super.updateCellContent()

        guard let postVM = self.postViewModel else {
            return
        }

        postView.setRichViewDelegate(postVM)
        postViewModel?.sourceView = self

        /// Show post image with send request.
        postVM.previewPostImageDriver.drive(onNext: { [weak self] (previewImageRequest) in
            self?.dispatcher.send(previewImageRequest)
        }).disposed(by: self.disposeBag)

        // Set post view
        if let element = postVM.listRichElement {
            self.postView.setContent(title: postVM.title,
                                     isUntitledPost: postVM.messageContent?.isUntitledPost ?? false,
                                     element: element)
        }
    }
}
