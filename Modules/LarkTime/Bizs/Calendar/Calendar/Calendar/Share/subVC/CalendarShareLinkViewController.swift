//
//  CalendarShareLinkViewController.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/18/23.
//

import Foundation
import RxSwift
import LarkUIKit
import LarkSnsShare
import LarkContainer
import LarkEMM
import LarkSensitivityControl
import CalendarFoundation
import UniverseDesignEmpty
import UniverseDesignToast
import UniverseDesignButton
import UniverseDesignTabs
import UniverseDesignIcon

class ShareCalendarLinkViewData {
    var invitorName: String = ""
    var linkStr: String = ""
    var calTitle: String = ""
    var ownerName: String = ""
    var subscriberNum: Int = 0
    var calDesc: String = ""
}

class CalendarShareLinkViewController: UIViewController, UserResolverWrapper {

    private lazy var loadingView: LoadingView = {
        let loadingView = LoadingView(displayedView: self.view)
        loadingView.backgroundColor = .ud.bgBase
        return loadingView
    }()

    private let fullScreenTipView = PlaceHolderIconLabelView()

    private let guideLabel = UILabel()
    private let linkLabel = UILabel.cd.textLabel(fontSize: 14)
    private let titleLabel = UILabel()
    private let ownerLabel = UILabel()
    private let subscriberNumLabel = UILabel()
    private let descLabel = UILabel()

    private let copyBtn = UDButton(.secondaryBlue)
    private let shareBtn = UDButton(.primaryBlue)

    private var sharePanel: LarkSharePanel?

    private let disposeBag = DisposeBag()

    private let viewModel: CalendarShareViewModel
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    let userResolver: UserResolver

    init(viewModel: CalendarShareViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .ud.bgBase
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var shareBtnConfig = shareBtn.config
        shareBtnConfig.type = .big
        shareBtn.config = shareBtnConfig
        copyBtn.setTitle(I18n.Calendar_Common_Copy, for: .normal)

        var copyBtnConfig = copyBtn.config
        copyBtnConfig.type = .big
        copyBtn.config = copyBtnConfig
        shareBtn.setTitle(I18n.Calendar_Share_ShareButton, for: .normal)

        shareBtn.addTarget(self, action: #selector(doShare), for: .touchUpInside)
        copyBtn.addTarget(self, action: #selector(doCopy), for: .touchUpInside)

        let btnContainer = UIStackView(arrangedSubviews: [copyBtn, shareBtn])
        btnContainer.distribution = .fillEqually
        btnContainer.spacing = 17
        view.addSubview(btnContainer)
        btnContainer.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(12)
        }

        let container = UIScrollView()
        container.showsVerticalScrollIndicator = false
        container.layer.cornerRadius = 12
        container.backgroundColor = .ud.bgFloat
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Display.pad ? 24 : 80)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.lessThanOrEqualTo(btnContainer.snp.top).offset(-80)
        }

        guideLabel.numberOfLines = 0
        linkLabel.numberOfLines = 0
        titleLabel.numberOfLines = 0
        ownerLabel.numberOfLines = 0
        descLabel.numberOfLines = 0
        let verticalStack = UIStackView(arrangedSubviews: [guideLabel, linkLabel, titleLabel, ownerLabel, subscriberNumLabel, descLabel])
        verticalStack.spacing = 4
        verticalStack.axis = .vertical
        verticalStack.setCustomSpacing(16, after: linkLabel)
        container.addSubview(verticalStack)
        verticalStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.height.lessThanOrEqualToSuperview().offset(-32).priority(.medium)
            make.centerX.equalToSuperview()
        }

        view.addSubview(fullScreenTipView)
        fullScreenTipView.isHidden = true
        fullScreenTipView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        bindData()
    }

    private func bindData() {
        viewModel.rxLinkData
            .subscribeForUI { [weak self] linkData in
                guard let self = self, let linkData = linkData else { return }

                let generateAttributedStr = { (prefix: String, content: String) -> NSAttributedString in
                    let wholeString = prefix + content
                    let prefixRange = (wholeString as NSString).range(of: prefix)

                    let pargraphStyle = NSMutableParagraphStyle()
                    pargraphStyle.lineSpacing = 4
                    let attributes: [NSAttributedString.Key: Any] = [
                        .foregroundColor: UIColor.ud.textTitle,
                        .font: UIFont.systemFont(ofSize: 14),
                        .paragraphStyle: pargraphStyle
                    ]
                    let titleAttributedString = NSMutableAttributedString(string: wholeString, attributes: attributes)

                    titleAttributedString.addAttribute(.foregroundColor, value: UIColor.ud.textCaption, range: prefixRange)
                    return titleAttributedString
                }
                self.guideLabel.attributedText = generateAttributedStr(I18n.Calendar_Share_NameInviteYouSubscribe(name: linkData.invitorName), "")
                self.linkLabel.attributedText = generateAttributedStr("", linkData.linkStr)
                self.titleLabel.attributedText = generateAttributedStr(I18n.Calendar_Detail_CalendarNameColon, linkData.calTitle)
                self.ownerLabel.attributedText = generateAttributedStr(I18n.Calendar_Detail_OwnerColon, linkData.ownerName)
                if FG.showSubscribers, linkData.subscriberNum >= 0 {
                    self.subscriberNumLabel.attributedText = generateAttributedStr(I18n.Calendar_Share_HowManySubscribed_Desc, String(linkData.subscriberNum))
                }
                self.subscriberNumLabel.isHidden = self.subscriberNumLabel.attributedText.isNil
                self.descLabel.attributedText = generateAttributedStr(FG.showSubscribers ? I18n.Calendar_Share_CalendarDesc_Desc : I18n.Calendar_Detail_DescriptionColon, linkData.calDesc)
            }.disposed(by: disposeBag)

        viewModel.rxLinkViewStatus
            .subscribeForUI { [weak self] status in
                guard let self = self else { return }
                if case .loading = status {
                    self.loadingView.showLoading()
                }
                if case .error(let error) = status {
                    if error.errorType() == .calendarIsPrivateErr {
                        self.fullScreenTipView.isHidden = false
                        self.fullScreenTipView.image = UDEmptyType.noPreview.defaultImage()
                        self.fullScreenTipView.title = I18n.Calendar_G_CantSharePrivateCalendar
                    } else if error.errorType() == .calendarIsDeletedErr {
                        self.fullScreenTipView.isHidden = false
                        self.fullScreenTipView.image = UDEmptyType.noSchedule.defaultImage()
                        self.fullScreenTipView.title = I18n.Calendar_Common_CalendarDeleted
                    } else {
                        self.loadingView.showFailed(withRetry: { [weak self] in
                            self?.viewModel.fetchData()
                        })
                    }
                }
                if case .dataLoaded = status {
                    self.loadingView.remove()
                }
            }.disposed(by: disposeBag)
    }

    @objc
    private func doShare() {
        guard !linkLabel.text.isEmpty else {
            UDToast.showFailure(with: I18n.Calendar_Common_FailedToLoad, on: view)
            return
        }
        let textPrepare = TextPrepare(content: getCopyText())
        let contentContext = ShareContentContext.text(textPrepare)

        let pop = PopoverMaterial(sourceView: shareBtn,
                                  sourceRect: shareBtn.bounds,
                                  direction: .any)

        let shareContent: CustomShareContent = .text("", ["": ""])
        let icon = UDIcon.getIconByKeyNoLimitSize(.forwardOutlined).ud.resized(to: CGSize(width: 24, height: 24)).renderColor(with: .n1)
        let itemContext = CustomShareItemContext(title: I18n.Calendar_Share_Lark, icon: icon)
        let inapp = CustomShareContext(
            identifier: "inapp",
            itemContext: itemContext,
            content: shareContent
        ) { [weak self] _, _, _ in
            self?.shareToChat()
        }

        sharePanel = LarkSharePanel(userResolver: self.userResolver,
                                    with: [.custom(inapp), .copy],
                                    shareContent: contentContext,
                                    on: self,
                                    popoverMaterial: pop,
                                    productLevel: "calendar",
                                    scene: "calendar_share_in_urlLink",
                                    pasteConfig: .scPasteImmunity)

        sharePanel?.show { [weak self] _, type in
            guard let self = self else { return }
            switch type {
            case .copy: UDToast.showSuccess(with: I18n.Calendar_Share_Copied, on: self.view)
            default: break
            }
        }

        CalendarTracerV2.CalendarShare.traceClick {
            $0.click("link_share")
            $0.calendar_id = self.viewModel.calContext.calID
            $0.is_admin_plus = self.viewModel.calContext.isManager.description
        }
    }

    @objc
    private func doCopy() {
        do {
            var config = PasteboardConfig(token: LarkSensitivityControl.Token(SCPasteboardUtils.getSceneKey(.calendarShareCopy)))
            config.shouldImmunity = true
            try SCPasteboard.generalUnsafe(config).string = self.getCopyText()
            UDToast.showSuccess(with: I18n.Calendar_Share_Copied, on: view)
            CalendarTracerV2.CalendarShare.traceClick {
                $0.click("link_copy")
                $0.calendar_id = self.viewModel.calContext.calID
                $0.is_admin_plus = self.viewModel.calContext.isManager.description
            }
        } catch {
            SCPasteboardUtils.logCopyFailed()
            UDToast.showFailure(with: I18n.Calendar_Share_UnableToCopy, on: view)
        }
    }

    private func getCopyText() -> String {
        let result = [guideLabel, linkLabel]
            .reduce("") { partialResult, sourceLabel in
                guard let text = sourceLabel.text else { return partialResult }
                return partialResult + text + "\n"
            }
        return [titleLabel, ownerLabel, subscriberNumLabel, descLabel]
            .reduce(result + "\n") { partialResult, sourceLabel in
                guard let text = sourceLabel.text else { return partialResult }
                return partialResult + text + "\n"
            }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarShareLinkViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView { view }
}

// MARK: - SharePanel action
extension CalendarShareLinkViewController {
    func shareToChat() {
        let modalStyle: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        calendarDependency?.jumpToTextForwardController(from: self, text: getCopyText(), modalPresentationStyle: modalStyle) { [weak self] _, _ in
            guard let self = self else { return }
            UDToast.showSuccess(with: I18n.Calendar_Share_SucTip, on: self.view)
        }
    }
}
