//
//  MomentsPostListViewController.swift
//  Moment
//
//  Created by bytedance on 1/18/22.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignToast
import RustPB
import LarkRustClient
import LarkMessengerInterface
import EENavigator
import LarkInteraction
import LarkTab
import LKCommonsLogging

class MomentsBasePostListContainerViewController: MomentsViewAdapterViewController {
    static let logger = Logger.log(ProfilePostListViewController.self, category: "Module.Moments.ProfilePostListViewController")
    var autoRefreshForAnonymousPostCreateSuccessCallBack: (() -> Void)?

    var needToSwitchTabWhenCreatePost: Bool {
        //为true时，打开发帖页面前会先跳转到公司圈tab。子类可以去复写这个值。
        return false
    }

    lazy var createPostButton: UIButton = {
        let createPostButton = SendPostButton(frame: .zero)
        createPostButton.addPointer(.lift)
        createPostButton.addTarget(self, action: #selector(createPostBtnClick), for: .touchUpInside)
        return createPostButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(createPostButton)
        self.contentView.backgroundColor = .clear
    }

    override func setDisplayStyleRegular() {
        super.setDisplayStyleRegular()
        createPostButton.snp.remakeConstraints { make in
            make.right.lessThanOrEqualToSuperview().priority(.required)
            make.left.equalTo(contentView.snp.right).priority(.low)
            make.width.height.equalTo(80)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    override func setDisplayStyleCompact() {
        super.setDisplayStyleCompact()
        createPostButton.snp.remakeConstraints { make in
            make.width.height.equalTo(80)
            make.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.getCurrentVC()?.resetTableViewHeaderFrame()
        }
    }

    func getCreatePostService() -> CreatePostApiService? {
        assertionFailure("need be override")
        return nil
    }

    func getCurrentVC() -> MomentsPostListDelegate? {
        assertionFailure("need be override")
        return nil
    }

    func getMomentsSendPostBodyParams() -> (categoryId: String?, source: Tracer.FeedCardViewSource?, hashtagContent: String?) {
        assertionFailure("need be override")
        return (nil, nil, nil)
    }

    func trackCreatePostBtnClicked() {
        assertionFailure("need be override")
    }

    @objc
    private func createPostBtnClick() {
        let params = getMomentsSendPostBodyParams()
        if needToSwitchTabWhenCreatePost {
            let url = Tab.moment.url
            let isCurrentTabMoments = self.animatedTabBarController?.currentTab == Tab.moment
            userResolver.navigator.switchTab(url, from: self, animated: false) { [weak self] _ in
                if let container = self?.animatedTabBarController?.viewController(for: Tab.moment)?.tabRootViewController as? MomentsFeedContainerViewController {
                    Self.logger.info("User clicked a SendPostButton, while MomentSendPostViewController can't be presented on current VC, so that the Tab is switched to Moments.")
                    if !isCurrentTabMoments,
                       Display.pad {
                        container.closeChildViewControllers()
                    }
                    container.createPost(categoryId: params.categoryId, source: params.source, hashtagContent: params.hashtagContent)
                }
            }
        } else {
            createPost(categoryId: params.categoryId, source: params.source, hashtagContent: params.hashtagContent)
        }
    }

    func createPost(categoryId: String? = nil, source: Tracer.FeedCardViewSource? = nil, hashtagContent: String? = nil) {
        let body = MomentsSendPostBody(categoryID: categoryId,
                                       source: source?.rawValue,
                                       hashTagContent: hashtagContent) { [weak self] (categoryID, isAnonymous, richText, imageMediaInfos) in
            self?.createPostWith(categoryID: categoryID, isAnonymous: isAnonymous, richText: richText, imageMediaInfos: imageMediaInfos)
        }
        userResolver.navigator.present(body: body, from: self, animated: !Display.pad)
        trackCreatePostBtnClicked()
    }

    private func createPostWith(categoryID: String?, isAnonymous: Bool, richText: RustPB.Basic_V1_RichText?, imageMediaInfos: [PostImageMediaInfo]?) {
        var hud: UDToast?
        if isAnonymous { //是匿名发帖
            hud = UDToast.showLoading(with: BundleI18n.Moment.Lark_Community_Sending, on: self.presentedViewController?.view ?? self.view)
        }
        self.getCreatePostService()?.createPostWith(categoryId: categoryID, isAnonymous: isAnonymous, content: richText, imageMediaInfos: imageMediaInfos) { [weak self] (error) in
            hud?.remove()
            if let error = error,
               self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) == true {
                return
            }
            if let error = error as? RCError {
                var errorMessage = BundleI18n.Moment.Lark_Community_SendFailed
                switch error {
                case .businessFailure(errorInfo: let info)
                    where (!info.displayMessage.isEmpty && info.code == 330_501):
                    errorMessage = info.displayMessage
                default:
                    break
                }
                UDToast.showFailure(with: errorMessage, on: self?.presentedViewController?.view ?? UIView())
            } else {
                if isAnonymous {
                    self?.autoRefreshForAnonymousPostCreateSuccess(categoryID)
                }
                /// 如果present的是PadLargeModalViewController，在dismiss之前清空背景
                (self?.presentedViewController as? PadLargeModalViewController)?.clearBackgroundColor()
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }

    private func autoRefreshForAnonymousPostCreateSuccess(_ categoryID: String?) {
        UDToast.showTips(with: BundleI18n.Moment.Lark_Community_PostedToast, on: self.presentedViewController?.view.window ?? UIView(), delay: 1.5)
        /// 匿名且是当前的板块 自动刷新
        if let vc = self.getCurrentVC() {
            let pageType = vc.getPageType()
            switch pageType {
            case .hashtag:
                DispatchQueue.main.asyncAfter(deadline: .now() + momentsAnonymousPostRefreshInterval) {
                    vc.autoRefresh()
                }
            default:
                if let categoryID = categoryID,
                   categoryID == pageType.getCategoryId {
                    DispatchQueue.main.asyncAfter(deadline: .now() + momentsAnonymousPostRefreshInterval) {
                        vc.autoRefresh()
                    }
                }
            }
        }
        self.autoRefreshForAnonymousPostCreateSuccessCallBack?()
    }
}

protocol MomentsPostListDelegate: AnyObject {
    func autoRefresh()
    func resetTableViewHeaderFrame()
    func getPageType() -> MomentsTracer.PageType
    func getTracker() -> MomentsCommonTracker
}
