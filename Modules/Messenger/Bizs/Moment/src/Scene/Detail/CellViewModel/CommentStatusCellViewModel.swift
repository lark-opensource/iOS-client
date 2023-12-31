//
//  CommentStatusCellViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/2/1.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import LarkMessageCore
import EEFlexiable
import LarkContainer
import RxSwift

final class CommentStatusCellViewModel: BaseMomentSubCellViewModel<RawData.CommentEntity, BaseMomentContext>, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy private var postAPI: PostApiService?
    private let disposeBag: DisposeBag = DisposeBag()

    public override var identifier: String {
        return "comment_status"
    }

    var createStatus: RawData.CommentCreateStatus {
        return self.entity.comment.localStatus
    }

    var errorMsg: String {
        return self.entity.error?.displayMessage ?? ""
    }

    var isUnderReview: Bool {
        return self.entity.comment.isUnderReview
    }

    func retryCreateComment() {
        self.postAPI?.retryCreateComment(commentId: self.entity.id)
            .subscribe().disposed(by: self.disposeBag)
    }

    init(userResolver: UserResolver, entity: RawData.CommentEntity, context: BaseMomentContext, binder: ComponentBinder<BaseMomentContext>) {
        self.userResolver = userResolver
        super.init(entity: entity, context: context, binder: binder)
    }
}

final class CommentStatusCellViewModelBinder<C: BaseMomentContext>: ComponentBinder<C> {
    private let commentStatusComponentKey: String = "comment_status"
    private let style = ASComponentStyle()
    private var props = CustomIconTextTapComponentProps()
    private var _component: CustomIconTextTapComponent<C>?
    private lazy var font: UIFont = {
        return UIFont.systemFont(ofSize: 14)
    }()
    public override var component: CustomIconTextTapComponent<C> {
        guard let _component else {
            fatalError("should never go here")
        }
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CommentStatusCellViewModel else {
            assertionFailure()
            return
        }
        let newProps = CustomIconTextTapComponentProps()
        style.display = .flex
        newProps.iconNeedRotate = false
        newProps.onViewClicked = nil
        newProps.iconAndLabelSpacing = 5
        newProps.iconSize = CGSize(width: 18, height: 18)
        var iconBlock: (() -> UIImage)?
        var attributedText: NSAttributedString = NSAttributedString(string: "")
        if vm.isUnderReview {
            iconBlock = { Resources.postInIsUnderReview }
            attributedText = NSAttributedString(string: BundleI18n.Moment.Lark_Community_PendingToast, attributes: [.foregroundColor: UIColor.ud.N500, .font: font])
        } else {
            switch vm.createStatus {
            case .success:
                style.display = .none
            case .sending:
                iconBlock = { Resources.postSendingStatus }
                newProps.iconNeedRotate = true
                attributedText = NSAttributedString(string: BundleI18n.Moment.Lark_Community_Sending, attributes: [.foregroundColor: UIColor.ud.colorfulBlue, .font: font])
            case .failed:
                iconBlock = Resources.postSendFail
                attributedText = NSAttributedString(string: BundleI18n.Moment.Lark_Community_ClickRetry, attributes: [.foregroundColor: UIColor.ud.colorfulRed, .font: font])
                newProps.onViewClicked = { [weak vm] in
                    vm?.retryCreateComment()
                }
            case .error:
                iconBlock = Resources.postSendFail
                attributedText = NSAttributedString(string: vm.errorMsg, attributes: [.foregroundColor: UIColor.ud.colorfulRed, .font: font])
                newProps.onViewClicked = nil
            @unknown default:
                assertionFailure("unknow type")
            }
        }
        newProps.iconBlock = iconBlock
        newProps.attributedText = attributedText
        style.marginTop = 8
        _component?.props = newProps
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        self._component = CustomIconTextTapComponent<C>(props: props, style: style, context: context)
    }
}
