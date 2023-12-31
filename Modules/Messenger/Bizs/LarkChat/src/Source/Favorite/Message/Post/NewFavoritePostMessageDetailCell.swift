//
//  NewFavoritePostMessageDetailCell.swift
//  LarkChat
//
//  Created by JackZhao on 2021/10/12.
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

// 使用新富文本渲染框架的的cell
final class NewFavoritePostMessageDetailCell: FavoriteMessageDetailCell {
    override class var identifier: String {
        return NewFavoritePostMessageViewModel.identifier
    }

    var postViewModel: NewFavoritePostMessageViewModel? {
        return self.viewModel as? NewFavoritePostMessageViewModel
    }

    /// 需要监听事件的Tag
    private let propagationSelectors: [[CSSSelector]] = [
        [CSSSelector(value: RichViewAdaptor.Tag.a)],
        [CSSSelector(value: CodeTag.code)],
        [CSSSelector(value: RichViewAdaptor.Tag.at)],
        [CSSSelector(match: .className, value: RichViewAdaptor.ClassName.abbreviation)],
        [CSSSelector(match: .className, value: RichViewAdaptor.ClassName.unavailableMention)]
    ]

    var postView: NewPostView = .empty

    public var maxWidth: CGFloat = UIScreen.main.bounds.width {
        didSet {
            self.postView.preferredMaxLayoutWidth = maxWidth - 2 * self.contentInset
        }
    }

    public var styleSheets: [CSSStyleSheet] {
        return RichViewAdaptor.createStyleSheets(config: RichViewAdaptor.Config(normalFont: NewFavoritePostMessageViewModel.ParseProps.textFont,
                                                                                atColor: AtColor()))
    }

    override public func setupUI() {
        super.setupUI()

        /// postView
        let postView = NewPostView(
            numberOfLines: 0,
            fontSize: UIFont.ud.body0.pointSize,
            isReply: false,
            preferredMaxLayoutWidth: maxWidth - 2 * self.contentInset
        )
        postView.bindEvent(selectorLists: self.propagationSelectors, isPropagation: true)
        postView.loadStyleSheets(styleSheets)
        self.container.addSubview(postView)
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

        /// Show post image with send request.
        postVM.previewPostImageInDetailDriver.drive(onNext: { [weak self] (previewImageRequest) in
            self?.dispatcher.send(previewImageRequest)
        }).disposed(by: self.disposeBag)

        // Set post view
        if let element = postVM.detailRichElement {
            self.postView.setContent(title: postVM.title,
                                     isUntitledPost: postVM.messageContent?.isUntitledPost ?? false,
                                     element: element)
        }
    }
}
