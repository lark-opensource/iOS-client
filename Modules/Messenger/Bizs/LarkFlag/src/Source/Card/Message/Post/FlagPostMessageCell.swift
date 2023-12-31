//
//  FlagPostMessageCell.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
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
final class FlagPostMessageCell: FlagMessageCell {

    override class var identifier: String {
        return FlagPostMessageViewModel.identifier
    }

    /// 需要监听事件的Tag
    private let propagationSelectors: [[CSSSelector]] = [
        [CSSSelector(value: RichViewAdaptor.Tag.a)],
        [CSSSelector(value: CodeTag.code)],
        [CSSSelector(value: RichViewAdaptor.Tag.at)],
        [CSSSelector(match: .className, value: RichViewAdaptor.ClassName.abbreviation)],
        [CSSSelector(match: .className, value: RichViewAdaptor.ClassName.unavailableMention)]
    ]

    var postViewModel: FlagPostMessageViewModel? {
        return self.viewModel as? FlagPostMessageViewModel
    }

    var postView: NewPostView = .empty

    public var styleSheets: [CSSStyleSheet] {
        return RichViewAdaptor.createStyleSheets(config: RichViewAdaptor.Config(normalFont: FlagPostMessageViewModel.ParseProps.textFont, atColor: AtColor()))
    }

    var screenWidth: CGFloat = UIScreen.main.bounds.width

    override public func setupUI() {
        super.setupUI()
        /// postView
        let postView = NewPostView(numberOfLines: 2,
                                   isReply: false,
                                   preferredMaxLayoutWidth: bubbleContentMaxWidth)
        postView.clipsToBounds = true
        postView.bindEvent(selectorLists: self.propagationSelectors, isPropagation: true)
        postView.loadStyleSheets(styleSheets)
        self.contentWraper.addSubview(postView)
        self.isShowName = false
        postView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-Cons.contentRightMargin)
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

        guard let vm = viewModel as? FlagPostMessageViewModel else { return }
        isShowName = false
        guard let element = postVM.listRichElement,
             let title = postVM.messageContent?.title,
             let isUntitledPost = postVM.messageContent?.isUntitledPost else { return }
        let prefix = vm.fromChatterDisplayName + "："
        var mutableAttrStr: NSMutableAttributedString
        if title.isEmpty {
           // 如果是富文本且没有标题，名字后文本换行；此处直接令标题为名字+“：”
           mutableAttrStr = NSMutableAttributedString(string: prefix)
           mutableAttrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.ud.body0, range: NSRange(location: 0, length: prefix.count))
        } else {
            // 如果是富文本且有标题，名字后直接拼接标题，标题加粗
            mutableAttrStr = NSMutableAttributedString(string: prefix + title)
            mutableAttrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.ud.body0, range: NSRange(location: 0, length: prefix.count))
            mutableAttrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.ud.headline, range: NSRange(location: prefix.count, length: title.count))
        }
        self.postView.setAttributeTitle(title: NSAttributedString(attributedString: mutableAttrStr), isUntitledPost: isUntitledPost, element: element)
    }
}
