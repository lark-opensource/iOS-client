//
//  EventDetailShareCoordinator.swift
//  Calendar
//
//  Created by zhuheng on 2022/3/1.
//

import Foundation
import UIKit
import LarkSnsShare
import LarkContainer
import RxSwift
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignIcon
import LarkEMM

class EventDetailShareCoordinator: UserResolverWrapper {

    /// 分享面板
    private var sharePanel: LarkSharePanel?

    private let bag: DisposeBag = DisposeBag()
    private var shareData: ShareDataModel?

    private let shareTitle: String
    private let shareWebContent: String
    private var shareToChat: (() -> Void)
    private let onShareTracer: (CalendarTracer.ShareType) -> Void
    private let shareDataObserverGetter: (Bool) -> Observable<ShareDataModel>

    let userResolver: UserResolver

    init(userResolver: UserResolver,
         shareTitle: String,
         shareDataObserverGetter: @escaping (Bool) -> Observable<ShareDataModel>,
         shareWebContent: String,
         onShareTracer: @escaping (CalendarTracer.ShareType) -> Void,
         shareToChat: @escaping (() -> Void)) {
        self.userResolver = userResolver
        self.shareTitle = shareTitle
        self.shareWebContent = shareWebContent
        self.shareDataObserverGetter = shareDataObserverGetter
        self.shareToChat = shareToChat
        self.onShareTracer = onShareTracer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // coordinator 需要被外部持有，否则会被释放
    func run(shareButton: UIView, from: UIViewController) {
        let toast = UDToast()
        toast.showLoading(with: I18n.Calendar_Common_LoadingCommon,
                          on: from.view,
                          disableUserInteraction: true)

        shareDataObserverGetter(false)
            .collectSlaInfo(.ShareEventDetail, action: "share_panel", additionalParam: ["need_image": 0])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (shareData) in
                self?.shareData = shareData
                self?.popupSharePanel(shareData: shareData, shareButton: shareButton, from: from)
                toast.remove()
            }, onError: { error in
                toast.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Toast_FailedToLoad,
                                  on: from.view)
            })
            .disposed(by: bag)
    }

    func popupSharePanel(shareData: ShareDataModel, shareButton: UIView, from: UIViewController) {
        /// 分享内容
        let webUrlPrepare = WebUrlPrepare(title: shareTitle, webpageURL: shareData.linkAddress)
        let contentContext = ShareContentContext.webUrl(webUrlPrepare)

        /// popOver下的配置
        var pop = PopoverMaterial(sourceView: shareButton,
                                  sourceRect: shareButton.bounds,
                                  direction: .up)
        /// 分享降级面板信息
        ///  I18n.Calendar_Share_AlbumSaved
        let tipPanelMaterial = DowngradeTipPanelMaterial.text(panelTitle: I18n.Calendar_Share_WechatLink, content: shareData.linkAddress)

        self.sharePanel = LarkSharePanel(userResolver: self.userResolver,
                                         by: "lark.calendar.event.share",
                                         shareContent: contentContext,
                                         on: from,
                                         popoverMaterial: pop,
                                         productLevel: "calendar",
                                         scene: "event",
                                         pasteConfig: .scPasteImmunity)
        let icon = UDIcon.getIconByKeyNoLimitSize(.forwardOutlined).ud.resized(to: CGSize(width: 24, height: 24)).renderColor(with: .n1)
        let itemContext = CustomShareItemContext(title: I18n.Calendar_Share_Lark,
                                                 icon: icon)
        let shareContent: CustomShareContent = .text("", ["": ""])

        self.sharePanel?.customShareContextMapping =
        ["inapp": CustomShareContext(
            identifier: "inapp",
            itemContext: itemContext,
            content: shareContent) { [weak self] _, _, _ in
            self?.onShareTracer(.chat)
            self?.shareToChat()
        }]
        self.sharePanel?.downgradeTipPanel = tipPanelMaterial
        self.sharePanel?.setImageBlock = { [weak self, weak from] panel in
            guard let self = self,
                  let view = from?.view else { return }
            DispatchQueue.main.async {
                let toast = UDToast()
                toast.showLoading(with: I18n.Calendar_Common_LoadingCommon,
                                  on: view,
                                  disableUserInteraction: true)
                self.shareDataObserverGetter(true)
                    .collectSlaInfo(.ShareEventDetail, action: "qr_code", additionalParam: ["need_image": 1])
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak panel] (shareData) in
                        guard let image = shareData.image else { return }
                        toast.remove()
                        panel?.notifyImageReady(with: image)
                    }, onError: { error in
                        toast.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Toast_FailedToLoad,
                                          on: view)
                    }).disposed(by: self.bag)
            }
        }

        self.sharePanel?.show { [weak self, weak from] result, type in
            guard let self = self,
                let toastView = from?.view else { return }
            if case .failure(let errorCode, let debugMsg) = result {
                /// 分享失败 获取失败原因和错误码
                switch errorCode {
                    case .notInstalled:
                    UDToast().showFailure(with: I18n.Calendar_Share_AppNotInstalled, on: toastView)
                    case .saveImageFailed:
                    UDToast().showFailure(with: I18n.Calendar_Share_SavedFailed, on: toastView)
                default:
                    break
                }
                return
            }

            switch type {
            case .more(let shareContext):
                self.onShareTracer(.more)
            case .qq:
                self.onShareTracer(.qq)
            case .weibo:
                self.onShareTracer(.weibo)
            case .wechat:
                self.onShareTracer(.wechat)
            case .timeline: // 朋友圈
                self.onShareTracer(.wechat)
            case .copy:
                SCPasteboard.generalPasteboard(shouldImmunity: true).string = shareData.shareCopy
                UDToast().showSuccess(with: I18n.Calendar_Share_Copied, on: toastView)
                self.onShareTracer(.link)
            case .shareImage:
                self.onShareTracer(.screenshot)
            case .custom(let _):
                break
            case .save:
                UDToast().showSuccess(with: I18n.Calendar_Share_AlbumSaved, on: toastView)
            case .unknown:  // 未知渠道
                break
            }
        }
    }
}
