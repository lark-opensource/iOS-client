//
//  PostStatusCellViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/1/24.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import LarkMessageCore
import EEFlexiable
import LarkContainer
import RxSwift
import LarkAlertController
import EENavigator
import LarkCore
import UniverseDesignToast

final class PostStatusCellViewModel: BaseMomentSubCellViewModel<RawData.PostEntity, BaseMomentContext>, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy private var postAPI: PostApiService?
    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?
    private let disposeBag: DisposeBag = DisposeBag()
    let manageMode: RawData.ManageMode

    public override var identifier: String {
        return "post_status"
    }

    var createStatus: RawData.PostCreateStatus {
        return self.entity.post.localStatus
    }
    var errorMsg: String {
        return self.entity.error?.displayMessage ?? ""
    }
    var isUnderReview: Bool {
        return self.entity.post.isUnderReview
    }

    func retryCreatePost() {
        self.postAPI?.retryCreatePost(postId: self.entity.id)
            .subscribe().disposed(by: self.disposeBag)
    }

    func onPostSendFailMenuTapped(pointView: UIView) {
        guard let pageVC = self.context.pageAPI else {
            return
        }
        let popoverMenuItemTypes: [MomentsPopOverMenuActionType] = [.delete]
        MomentsPopOverMenuManager.showMenuVCWith(presentVC: pageVC, pointView: pointView, itemTypes: popoverMenuItemTypes) { [weak self] (type) in
            guard let self = self else { return }
            switch type {
            case .delete:
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.Moment.Lark_Community_AreYouSureYouWantToDeleteThisPost)
                alertController.addCancelButton()
                alertController.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_DeleteConfirm, dismissCompletion: { [weak self] in
                    self?.deletePost()
                })
                self.userResolver.navigator.present(alertController, from: pageVC)
            default:
                break
            }
        }
    }

    private func deletePost() {
        guard let pageVC = self.context.pageAPI, let momentsAccountService else {
            return
        }
        DelayLoadingObservableWraper.wraper(observable: self.postAPI?.deletePost(byID: self.entity.id, categoryIds: self.entity.post.categoryIds) ?? .empty(),
                                            showLoadingIn: pageVC.view)
                                            .observeOn(MainScheduler.instance)
                                            .subscribe(onNext: { (_) in
                                            }, onError: { (error) in
                                                if momentsAccountService.handleOfficialAccountErrorIfNeed(error: error, from: pageVC) == true {
                                                    return
                                                }
                                                UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_DeleteFailed, on: pageVC.view)
                                            }).disposed(by: self.context.disposeBag)
    }

    init(userResolver: UserResolver, entity: RawData.PostEntity, context: BaseMomentContext, binder: ComponentBinder<BaseMomentContext>, manageMode: RawData.ManageMode) {
        self.userResolver = userResolver
        self.manageMode = manageMode
        super.init(entity: entity, context: context, binder: binder)
    }
}

final class PostStatusCellViewModelBinder<C: BaseMomentContext>: ComponentBinder<C> {
    private let postStatusComponentKey: String = "post_status_component"
    private let style = ASComponentStyle()
    private var props = CustomIconTextTapComponentProps()
    private var textTapcomponent: CustomIconTextTapComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private lazy var font: UIFont = {
        return UIFont.systemFont(ofSize: 14)
    }()
    private lazy var _component: ASLayoutComponent<C> = .init(key: "", style: .init(), context: nil, [])
    public override var component: ASLayoutComponent<C> {
        return _component
    }

    lazy var deleBtnProps: TappedImageComponentProps = {
        let props = TappedImageComponentProps()
        props.image = Resources.momentsMore
        props.iconSize = CGSize(width: 18, height: 18)
        return props
    }()

    /// 删除帖子
    lazy var deleBtn: TappedImageComponent<C> = {
        let style = ASComponentStyle()
        style.paddingLeft = 5
        return TappedImageComponent(props: self.deleBtnProps, style: style)
    }()

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? PostStatusCellViewModel else {
            assertionFailure()
            return
        }
        props = CustomIconTextTapComponentProps()
        style.display = .flex
        props.iconAndLabelSpacing = 5
        props.iconSize = CGSize(width: 18, height: 18)
        props.iconNeedRotate = false
        props.onViewClicked = nil
        deleBtn._style.display = .none
        if vm.manageMode == .recommendV2Mode {
            deleBtnProps.iconSize = CGSize(width: 20, height: 20)
            deleBtnProps.image = Resources.momentsMoreN2
        } else {
            deleBtnProps.iconSize = CGSize(width: 18, height: 18)
            deleBtnProps.image = Resources.momentsMore
        }
        deleBtn.props = deleBtnProps
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
                props.iconNeedRotate = true
                attributedText = NSAttributedString(string: BundleI18n.Moment.Lark_Community_Sending, attributes: [.foregroundColor: UIColor.ud.colorfulBlue, .font: font])
            case .failed:
                iconBlock = Resources.postSendFail
                attributedText = NSAttributedString(string: BundleI18n.Moment.Lark_Community_ClickRetry, attributes: [.foregroundColor: UIColor.ud.colorfulRed, .font: font])
                deleBtn._style.display = .flex
                props.onViewClicked = { [weak vm] in
                    vm?.retryCreatePost()
                }
            case .error:
                iconBlock = Resources.postSendFail
                attributedText = NSAttributedString(string: vm.errorMsg, attributes: [.foregroundColor: UIColor.ud.colorfulRed, .font: font])
                props.onViewClicked = nil
                deleBtn._style.display = .flex
            @unknown default:
                assertionFailure("unknow type")
            }
        }
        props.iconBlock = iconBlock
        props.attributedText = attributedText
        textTapcomponent.props = props
        deleBtn.props.onClicked = { [weak vm] (view) in
            vm?.onPostSendFailMenuTapped(pointView: view)
        }
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        self.textTapcomponent = CustomIconTextTapComponent<C>(props: props, style: ASComponentStyle(), context: context)
        style.alignItems = .center
        style.justifyContent = .spaceBetween
        self._component = ASLayoutComponent<C>(style: style, [textTapcomponent, deleBtn])
    }
}
