//
//  EventCheckInLinkViewController.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/16.
//

import UIKit
import Foundation
import UniverseDesignTabs
import RxSwift
import RxCocoa
import UniverseDesignColor
import LarkContainer
import LarkUIKit
import UniverseDesignButton
import UniverseDesignFont
import UniverseDesignToast
import LarkSnsShare
import UniverseDesignIcon
import ServerPB
import CalendarFoundation
import UniverseDesignEmpty
import LarkEMM
import LarkSensitivityControl

extension EventCheckInLinkViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return self.view
    }
}

class EventCheckInLinkViewController: UIViewController, UserResolverWrapper {

    typealias CheckInInfo = ServerPB_Calendarevents_GetEventCheckInInfoResponse

    let userResolver: UserResolver

    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    private lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var copyButton: UDButton = {
        let copyButton = UDButton(.secondaryBlue)
        copyButton.config.type = .big
        copyButton.setTitle(I18n.Calendar_Common_Copy, for: .normal)
        copyButton.addTarget(self, action: #selector(doCopy), for: .touchUpInside)
        return copyButton
    }()

    private lazy var shareButton: UDButton = {
        let shareButton = UDButton(.primaryBlue)
        shareButton.config.type = .big
        shareButton.setTitle(I18n.Calendar_Share_ShareButton, for: .normal)
        shareButton.addTarget(self, action: #selector(doShare), for: .touchUpInside)
        return shareButton
    }()

    private lazy var loadingView: LoadingView = {
        let loadingView = LoadingView(displayedView: self.view)
        loadingView.backgroundColor = view.backgroundColor
        return loadingView
    }()

    private var sharePanel: LarkSharePanel?

    private var rxCheckInInfo: BehaviorRelay<CheckInInfo> = .init(value: CheckInInfo())
    private let disposeBag = DisposeBag()

    private let viewModel: EventCheckInInfoViewModel

    // 埋点需要
    private var eventID: String = ""
    private let startTime: Int64

    init(viewModel: EventCheckInInfoViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        self.startTime = viewModel.startTime
        super.init(nibName: nil, bundle: nil)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.loadingView.showLoading()
        viewModel.getEventCheckInInfo(condition: [.checkInUrl])
            .map({ response in
                guard !response.checkInURL.isEmpty else {
                    throw RxError.unknown
                }
                return response
            })
            .subscribeForUI(onNext: { [weak self] response in
                guard let self = self else { return }
                self.rxCheckInInfo.accept(response)
                self.loadingView.remove()
                self.eventID = String(response.eventID)
                CalendarTracerV2.CheckInfo.traceClick {
                    $0.click("link").target("none")
                    $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.eventID,
                                                                           eventStartTime: self.viewModel.startTime.description,
                                                                           originalTime: self.viewModel.originalTime.description,
                                                                           uid: self.viewModel.key))
                }
            }, onError: { [weak self] error in
                if error.errorType() == .calendarEventCheckInApplinkNoPermission {
                    self?.loadingView.show(image: UDEmptyType.noAccess.defaultImage(), title: I18n.Calendar_Event_NoPermitView)
                } else {
                    self?.loadingView.showFailed(title: I18n.Calendar_Common_FailedToLoad, withRetry: { [weak self] in
                        self?.setup()
                    })
                }
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UDColor.bgBase

        let container = UIView()
        container.backgroundColor = UDColor.bgFloat
        container.layer.cornerRadius = 12

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(80)
            make.left.right.equalToSuperview().inset(24)
        }

        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }

        let stackView = UIStackView(arrangedSubviews: [copyButton, shareButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 17

        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(12)
        }

        bindRxCheckInInfo()
    }

    private func bindRxCheckInInfo() {
        self.rxCheckInInfo
            .subscribeForUI(onNext: { [weak self] checkInInfo in
                guard let self = self else { return }
                self.updateCheckInInfo(checkInInfo: checkInInfo)
            }).disposed(by: disposeBag)
    }

    private func updateCheckInInfo(checkInInfo: CheckInInfo) {
        label.attributedText = checkInInfo.generateAttributeString()
    }

    @objc
    private func doShare() {
        /// 分享内容
        CalendarTracerV2.CheckInfo.traceClick {
            $0.click("share_link").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: eventID,
                                                                   eventStartTime: viewModel.startTime.description,
                                                                   originalTime: viewModel.originalTime.description,
                                                                   uid: viewModel.key))
        }
        guard let string = self.label.attributedText?.string else {
            UDToast.showFailure(with: I18n.Calendar_Common_FailedToLoad, on: view)
            return
        }
        let textPrepare = TextPrepare(content: string)
        let contentContext = ShareContentContext.text(textPrepare)

        let pop = PopoverMaterial(sourceView: shareButton,
                                  sourceRect: shareButton.bounds,
                                  direction: .any)

        let shareContent: CustomShareContent = .text("", ["": ""])
        let icon = UDIcon.getIconByKeyNoLimitSize(.forwardOutlined).ud.resized(to: CGSize(width: 24, height: 24)).renderColor(with: .n1)
        let itemContext = CustomShareItemContext(title: I18n.Calendar_Share_Lark, icon: icon)
        let inapp = CustomShareContext(
            identifier: "inapp",
            itemContext: itemContext,
            content: shareContent) { [weak self] _, _, _ in
                self?.shareToChat()
        }

        sharePanel = LarkSharePanel(userResolver: self.userResolver,
                                    with: [.custom(inapp), .copy],
                                    shareContent: contentContext,
                                    on: self,
                                    popoverMaterial: pop,
                                    productLevel: "calendar",
                                    scene: "event_check_in_urlLink",
                                    pasteConfig: .scPasteImmunity)

        sharePanel?.show { [weak self] _, type in
            guard let self = self else { return }
            switch type {
            case .copy:
                UDToast.showSuccess(with: I18n.Calendar_Share_Copied, on: self.view)
            default:
                break
            }
        }
    }

    @objc
    private func doCopy() {
        CalendarTracerV2.CheckInfo.traceClick {
            $0.click("copy_link").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: eventID,
                                                                   eventStartTime: viewModel.startTime.description,
                                                                   originalTime: viewModel.originalTime.description,
                                                                   uid: viewModel.key))
        }
        if let string = self.label.attributedText?.string {
            do {
                var config = PasteboardConfig(token: LarkSensitivityControl.Token(SCPasteboardUtils.getSceneKey(.eventCheckInLinkCopy)))
                config.shouldImmunity = true
                try SCPasteboard.generalUnsafe(config).string = string
                UDToast.showSuccess(with: I18n.Calendar_Share_Copied, on: view)
            } catch {
                SCPasteboardUtils.logCopyFailed()
                UDToast.showFailure(with: I18n.Calendar_Share_UnableToCopy, on: view)
            }
        }
    }

}

extension EventCheckInLinkViewController {
    func shareToChat() {
        guard let text = self.label.attributedText?.string else { return }
        self.calendarDependency?.jumpToTextForwardController(from: self, text: text, modalPresentationStyle: .formSheet) { [weak self] _, _ in
            guard let self = self else { return }
            UDToast.showSuccess(with: I18n.Calendar_Share_SucTip, on: self.view)
        }
    }
}
