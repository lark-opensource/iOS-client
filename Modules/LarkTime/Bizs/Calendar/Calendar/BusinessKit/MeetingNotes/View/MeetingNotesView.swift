//
//  MeetingNotesView.swift
//  Calendar
//
//  Created by huoyunjie on 2023/5/26.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont
import RxSwift
import RxCocoa
import LarkUIKit
import CalendarFoundation
import LKRichView
import LarkActivityIndicatorView
import LarkContainer
import FigmaKit
import LarkGuide

struct MeetingNotesViewData {
    var docTitle: String = ""
    var showDocIcon: Bool = false
    var isDocReadable: Bool = false
    var isDocDeletable: Bool = false
    var showPermissionTip: Bool = false
    var permissionTipStr: String = ""
    var permissionSettingStr: String = ""
    var rxThumbnailImage: Observable<UIImage>?
    var eventPermission: CalendarNotesEventPermission?
}

protocol MeetingNotesViewDelegate: CalendarTemplateHorizontalListViewDelegate, MeetingNotesPermissionViewDelegate {
    /// 进入 Permission 控制页面
    func onClickPermissionButton(_ view: MeetingNotesView)
    /// 点击重试 Label
    func onClickRetryButton(_ view: MeetingNotesView)
    /// 进入 DocComponent
    func onEnterDocComponent(_ view: MeetingNotesView)
    /// 创建空白 Doc
    func onCreateEmptyDoc(_ view: MeetingNotesView)
    /// 不可用状态下点击操作
    func onDisableStatus(_ view: MeetingNotesView)
    /// 进入关联文档页面
    func onAssociateDoc(_ view: MeetingNotesView)
    /// 通过 AI 创建 Doc
    func onCreateAIDoc(_ view: MeetingNotesView)
    /// 获取横向模版列表View
    func createTemplateHorizontalListView(_ view: MeetingNotesView) -> CalendarTemplateHorizontalListViewProtocol?
}

enum MeetingNotesViewStatus: Equatable {
    static func == (lhs: MeetingNotesViewStatus, rhs: MeetingNotesViewStatus) -> Bool {
        switch (lhs, rhs) {
        case
            (.hidden, .hidden),
            (.loading, .loading),
            (.failed, .failed),
            (.viewData, .viewData),
            (.createEmpty, .createEmpty),
            (.templateList, .templateList),
            (.disabled, .disabled),
            (.createMeetingNotes, .createMeetingNotes): return true
        default: return false
        }
    }

    /// 不显示
    case hidden
    /// 加载中
    case loading
    /// 加载失败
    case failed(retryAction: (() -> Void))
    /// 正常显示 MeetingNotes
    case viewData(MeetingNotesViewData)
    /// 一行显示创建文档
    case createEmpty
    /// 横向模版列表
    case templateList
    /// 不可用状态
    case disabled(title: String, iconShow: Bool, reason: String?)
    /// 创建 meetingNotes
    case createMeetingNotes
}

class MeetingNotesView: UIView, ViewDataConvertible, UserResolverWrapper {
    @ScopedInjectedLazy var newGuideManager: NewGuideService?
    let userResolver: UserResolver
    var viewData: MeetingNotesViewStatus? {
        didSet {
            guard let viewData = viewData else { return }
            self.imageDisposeBag = DisposeBag()
            self.isHidden = false
            switch viewData {
            case .hidden:
                self.isHidden = true
            case .loading:
                startLoading()
            case .failed:
                showFailView()
            case .viewData(let data):
                showNormalView(viewData: data)
            case .createEmpty:
                showCreateEmptyView()
            case .templateList:
                showTemplateList()
            case .disabled(let title, let iconShow, _):
                showDisableStatus(title: title, iconShow: iconShow)
            case .createMeetingNotes:
                showCreateMeetingNotesView()
            }
            showOrHiddenGuideView()
        }
    }

    // MARK: Guide
    private(set) lazy var guideView: MeetingNotesGuideView = {
        let view = MeetingNotesGuideView()
        view.closeAction = { [weak self] in
            self?.closeGuideView()
        }
        return view
    }()

    // MARK: Top Title View

    private lazy var loadingView: ActivityIndicatorView = {
        let view = LarkActivityIndicatorView.ActivityIndicatorView(color: UIColor.ud.primaryPri500)
        return view
    }()

    private(set) lazy var title: DocTitleLabel = DocTitleLabel(frame: .zero)

    private lazy var topTitleView: UIView = {
        let stackView = UIStackView(arrangedSubviews: [loadingView, title])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.isUserInteractionEnabled = true
        stackView.alignment = .center
        return stackView
    }()


    // MARK: Image & Bottom View
    private(set) lazy var docImageView: UIImageView = {
        let view = UIImageView(image: nil)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        view.layer.cornerRadius = 4
        view.backgroundColor = UDColor.staticWhite
        return view
    }()

    private lazy var seprator: UIView = {
        let seprator = UIView()
        seprator.backgroundColor = UDColor.lineDividerDefault.withAlphaComponent(0.15)
        return seprator
    }()

    private lazy var imageContainerView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [docImageView, seprator])
        view.axis = .vertical
        view.spacing = 8
        return view
    }()

    private(set) lazy var permissionPromptView = {
        let permissionPromptView = PermissionPromptView()
        permissionPromptView.clickAction = { [weak self] in
            self?.trailingTextLinkClickHandler()
        }
        return permissionPromptView
    }()

    private(set) lazy var guestPermissionView = MeetingNotesPermissionView()

    private(set) lazy var permissionViews = {
        let view = UIStackView(arrangedSubviews: [permissionPromptView, guestPermissionView])
        view.axis = .vertical
        return view
    }()

    private lazy var bottomContainerView: UIView = {
        let view = UIView()
        view.addSubview(permissionViews)
        return view
    }()

    private lazy var imageAndBottomView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [imageContainerView, bottomContainerView])
        stackView.axis = .vertical
        return stackView
    }()

    private(set) lazy var meetingNotesCreateView: MeetingNotesCreateView = {
        let view = MeetingNotesCreateView(createViewType: self.createViewType)
        view.delegate = self
        return view
    }()

    // MARK: Template List View
    private lazy var templateList: CalendarTemplateHorizontalListViewProtocol = {
        return self.delegate?.createTemplateHorizontalListView(self) ?? CalendarTemplateHorizontalListEmptyView()
    }()

    private lazy var rightOverlayView: UIView = {
        let view = FKGradientView()
        view.type = .linear
        view.direction = .leftToRight
        view.locations = [0, 0.5]
        view.colors = [UDColor.bgFloat.withAlphaComponent(0), UDColor.bgFloat]
        return view
    }()

    private lazy var leftOverlayView: UIView = {
        let view = FKGradientView()
        view.type = .linear
        view.direction = .rightToLeft
        view.locations = [0, 0.27]
        view.colors = [UDColor.bgFloat.withAlphaComponent(0), UDColor.bgFloat]
        return view
    }()

    private lazy var templateContainerView: UIView = {
        let view = UIView()
        view.addSubview(templateList)
        templateList.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.leading.equalToSuperview().offset(-15)
        }
        view.addSubview(leftOverlayView)
        view.addSubview(rightOverlayView)
        leftOverlayView.snp.makeConstraints() {
            $0.width.equalTo(15)
            $0.top.bottom.equalToSuperview()
            $0.trailing.equalTo(view.snp.leading)
        }
        rightOverlayView.snp.makeConstraints() {
            $0.width.equalTo(24)
            $0.top.trailing.bottom.equalToSuperview()
        }
        return view
    }()

    // MARK: ContainerView
    private lazy var containerView: UIStackView = {
        let containerView = UIStackView(arrangedSubviews: [topTitleView, imageAndBottomView, templateContainerView, meetingNotesCreateView])
        containerView.axis = .vertical
        containerView.spacing = 8
        return containerView
    }()

    private lazy var containerWrapperView: UIView = {
        let view = UIView()
        view.addSubview(containerView)
        return view
    }()
    
    private lazy var notesContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 7
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var aiContainerInnerView: UIView = {
        let view = UIView()
        return view
    }()

    weak var delegate: MeetingNotesViewDelegate? {
        didSet {
            guestPermissionView.delegate = delegate
        }
    }
    /// 控制GuideView的总开关，false 时 GuideView 始终隐藏
    private let needGuideView: Bool

    private let createViewType: MeetingNotesCreateView.CreateViewType

    private var imageDisposeBag = DisposeBag()

    init(userResolver: UserResolver,
         delegate: MeetingNotesViewDelegate? = nil,
         createViewType: MeetingNotesCreateView.CreateViewType = .label,
         needGuideView: Bool = true) {
        self.delegate = delegate
        self.createViewType = createViewType
        self.needGuideView = needGuideView
        self.userResolver = userResolver
        super.init(frame: .zero)
        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {

        addSubview(guideView)
        addSubview(notesContainerView)
        layoutContentWrapperView()
        
        setupSubviewsLayout()
        showOrHiddenGuideView()

        let tap1 = UITapGestureRecognizer(target: self, action: #selector(didViewClick))
        topTitleView.addGestureRecognizer(tap1)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(didViewClick))
        imageContainerView.addGestureRecognizer(tap2)
    }

    private func adjustContentWrapperView() {
        notesContainerView.snp.remakeConstraints { make in
            if guideView.isHidden {
                make.top.equalToSuperview()
            } else {
                make.top.equalTo(guideView.snp.bottom).offset(FG.myAI ? 13 : 8)
            }
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func layoutContentWrapperView() {
        notesContainerView.addSubview(aiContainerInnerView)
        aiContainerInnerView.addSubview(containerWrapperView)
        
        notesContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        aiContainerInnerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(0)
        }
        
        containerWrapperView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func updateAIContainerStyle(shouldShowAIStyle: Bool) {
        notesContainerView.snp.remakeConstraints { make in
            if guideView.isHidden {
                make.top.equalToSuperview().offset(shouldShowAIStyle ? -6 : 0)
            } else {
                if shouldShowAIStyle {
                    make.top.equalTo(guideView.snp.bottom).offset(FG.myAI ? 5 : 0)
                } else {
                    make.top.equalTo(guideView.snp.bottom).offset(FG.myAI ? 11 : 6)
                }
            }
            make.leading.trailing.bottom.equalToSuperview().inset(shouldShowAIStyle ? -6 : 0)
        }

        aiContainerInnerView.snp.updateConstraints { make in
            if shouldShowAIStyle {
                make.edges.equalToSuperview().inset(6)
            } else {
                make.edges.equalToSuperview().inset(0)
            }
        }

        notesContainerView.backgroundColor = shouldShowAIStyle ? UDColor.AIPrimaryFillTransparent01(ofSize: CGSize(width: notesContainerView.bounds.width + 16, height: notesContainerView.bounds.height + 16)) : .clear
    }

    private func setupSubviewsLayout() {

        guideView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        adjustContentWrapperView()

        loadingView.snp.makeConstraints {
            $0.width.height.equalTo(14)
        }

        docImageView.snp.makeConstraints {
            $0.height.equalTo(docImageView.snp.width).multipliedBy(9.0 / 16.0)
        }

        seprator.snp.makeConstraints {
            $0.height.equalTo(1)
        }
    }

    @objc
    private func didViewClick() {
        guard let viewData = viewData else { return }
        switch viewData {
        case .createEmpty:
            delegate?.onCreateEmptyDoc(self)
        case .viewData:
            delegate?.onEnterDocComponent(self)
        case .disabled:
            delegate?.onDisableStatus(self)
        default:
            return
        }
    }

    // 尾部可点击文案 点击事件
    private func trailingTextLinkClickHandler() {
        guard let viewData = viewData else { return }
        switch viewData {
        case .failed:
            delegate?.onClickRetryButton(self)
        case .viewData(let data):
            if data.showPermissionTip {
                delegate?.onClickPermissionButton(self)
            }
        default:
            return
        }
    }

    private func startLoading() {
        hidenAll()

        topTitleView.isHidden = false
        loadingView.isHidden = false
        loadingView.startAnimating()

        title.isHidden = false
        title.updateContent(text: I18n.Calendar_Notes_LoadNotes,
                            color: UDColor.textCaption,
                            font: UDFont.body2,
                            hiddenImg: true)
    }

    private func showFailView() {
        hidenAll()
        imageAndBottomView.isHidden = false
        bottomContainerView.isHidden = false
        permissionPromptView.isHidden = false
        permissionPromptView.updateTrailClickableViewContent(
            prompt: I18n.Calendar_Notes_FailToLoad,
            trailingText: I18n.Calendar_Attachment_RetryUploadButtonTag
        )
    }

    private func showNormalView(viewData: MeetingNotesViewData) {
        showAll()

        templateContainerView.isHidden = true
        loadingView.isHidden = true
        meetingNotesCreateView.isHidden = true
        docImageView.isHidden = false

        let color = viewData.isDocReadable ? UDColor.textTitle : UDColor.textLinkNormal
        let font: UIFont = UIFont.cd.mediumFont(ofSize: 16)
        let fontWeight: FontWeight? = viewData.isDocReadable ? .medium : nil
        title.updateContent(text: viewData.docTitle,
                            color: color,
                            font: font,
                            hiddenImg: true,
                            fontWeight: fontWeight,
                            numberOfLine: 1,
                            wrapEllipsis: viewData.isDocReadable)
        bindRxImage(viewData.rxThumbnailImage)

        updateBottomContainerView(viewData: viewData)
    }

    private func updateBottomContainerView(viewData: MeetingNotesViewData) {
        if viewData.showPermissionTip {
            bottomContainerView.isHidden = false
            permissionPromptView.isHidden = false
            guestPermissionView.isHidden = true
            permissionPromptView.updateTrailClickableViewContent(prompt: viewData.permissionTipStr, trailingText: viewData.permissionSettingStr)
        } else if let eventPermission = viewData.eventPermission {
            bottomContainerView.isHidden = false
            permissionPromptView.isHidden = true
            guestPermissionView.isHidden = false
            guestPermissionView.updateClickLabel(permission: eventPermission)
        } else {
            bottomContainerView.isHidden = true
        }
        seprator.isHidden = bottomContainerView.isHidden
    }

    private func showDisableStatus(title: String, iconShow: Bool) {
        hidenAll()

        topTitleView.isHidden = false
        self.title.isHidden = false
        self.title.updateContent(text: title,
                                 color: UDColor.textDisabled,
                                 font: UIFont.cd.regularFont(ofSize: 16),
                                 hiddenImg: !iconShow)
    }


    private func bindRxImage(_ rxImage: Observable<UIImage>?) {
        guard let rxImage = rxImage else { return }
        rxImage
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribeForUI(onNext: { [weak self] image in
                self?.docImageView.image = image
            }).disposed(by: imageDisposeBag)
    }

    private func showCreateEmptyView() {
        hidenAll()

        topTitleView.isHidden = false
        title.isHidden = false
        title.updateContent(text: I18n.Calendar_G_CreateMeetingNotes_Click,
                            color: UDColor.primaryContentDefault,
                            font: UIFont.cd.regularFont(ofSize: 16),
                            hiddenImg: true)
    }

    private func showTemplateList() {
        hidenAll()

        topTitleView.isHidden = false
        templateContainerView.isHidden = false

        title.isHidden = false
        title.updateContent(text: I18n.Calendar_Notes_FromTemplate_Onboarding,
                            color: UDColor.textTitle,
                            font: UIFont.cd.regularFont(ofSize: 16),
                            hiddenImg: true)
        templateList.start()
    }

    private func showCreateMeetingNotesView() {
        hidenAll()
        meetingNotesCreateView.isHidden = false
    }

    /// 需要 isHidden 判断的 view 与 showAll 对应
    private func hidenAll() {
        containerWrapperView.backgroundColor = .clear
        containerWrapperView.layer.cornerRadius = 0
        containerWrapperView.clipsToBounds = false
        containerWrapperView.layer.borderWidth = 0

        containerView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
        containerView.spacing = 0

        permissionViews.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }

        loadingView.isHidden = true
        title.isHidden = true
        topTitleView.isHidden = true

        imageContainerView.isHidden = true
        bottomContainerView.isHidden = true
        imageAndBottomView.isHidden = true
        meetingNotesCreateView.isHidden = true
        bottomContainerView.backgroundColor = .clear
        permissionViews.subviews.forEach { $0.isHidden = true }

        templateContainerView.isHidden = true
    }

    /// 需要 isHidden 判断的 view 与 hideAll 对应
    private func showAll() {
        containerWrapperView.backgroundColor = UDColor.bgFloat
        containerWrapperView.layer.cornerRadius = 8
        containerWrapperView.clipsToBounds = true
        containerWrapperView.layer.borderWidth = 1
        let borderColor = UDColor.lineBorderCard & UDColor.lineBorderCard.withAlphaComponent(0.15)
        containerWrapperView.layer.ud.setBorderColor(borderColor)

        containerView.snp.remakeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }
        containerView.spacing = 8

        permissionViews.snp.remakeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.leading.trailing.equalTo(docImageView)
            $0.bottom.equalToSuperview()
        }
        imageAndBottomView.backgroundColor = .clear

        loadingView.isHidden = false
        title.isHidden = false
        imageContainerView.isHidden = false
        bottomContainerView.isHidden = false
        permissionViews.subviews.forEach { $0.isHidden = false }

        topTitleView.isHidden = false
        imageAndBottomView.isHidden = false
        templateContainerView.isHidden = false
        meetingNotesCreateView.isHidden = false
    }
}

// 将 TemplateListDelegate 转移到 MeetingNotesViewDelegate 上
extension MeetingNotesView: CalendarTemplateHorizontalListViewDelegate {
    /// 点击模板回调
    public func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, didClick templateId: String) -> Bool {
        return delegate?.templateHorizontalListView(listView, didClick: templateId) ?? false
    }

    /// 创建文档回调
    func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, onCreateDoc result: CalendarDocsTemplateCreateResult?, error: Error?) {
        delegate?.templateHorizontalListView(listView, onCreateDoc: result, error: error)
    }

    /// 选择模版回调
    func templateOnItemSelected(_ viewController: UIViewController, item: CalendarTemplateItem) {
        delegate?.templateOnItemSelected(viewController, item: item)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset
        print("Content offset: \(contentOffset)")
    }

    func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, onFailedStatus: Bool) {
        delegate?.templateHorizontalListView(listView, onFailedStatus: onFailedStatus)
    }
}

extension MeetingNotesView: MeetingNotesCreateViewDelegate {
    func clickAICreateView() {
        delegate?.onCreateAIDoc(self)
    }
    func clickAssociateDocView() {
        delegate?.onAssociateDoc(self)
    }
    func clickFakeListItemView() {
        delegate?.onCreateEmptyDoc(self)
    }
}

extension MeetingNotesView {
    /// 判断 meetingNotesView 当前状态是否可以展示GuideView
    private var canShowGuideView: Bool {
        guard let viewData = viewData else { return false }
        switch viewData {
        case .createEmpty, .createMeetingNotes, .templateList, .viewData:
            return true
        case .disabled, .failed, .loading, .hidden:
            return false
        default:
            return false
        }
    }

    /// GuideView 点击关闭按钮触发
    private func closeGuideView() {
        /// 消费 GuideKey
        newGuideManager?.didShowedGuide(guideKey: GuideService.GuideKey.eventEditMeetingNotesGuideKey.rawValue)
        /// 隐藏 GuideView
        setGuideView(isHidden: true)
    }

    /// 整体控制 GuideView show/hidden 的入口
    private func showOrHiddenGuideView() {
        guard needGuideView, let newGuideManager = self.newGuideManager else {
            setGuideView(isHidden: true)
            return
        }
        if canShowGuideView,
           GuideService.shouldShowGuideForMeetingNotes(newGuideManager: newGuideManager) {
            setGuideView(isHidden: false)
        } else {
            setGuideView(isHidden: true)
        }
    }

    private func setGuideView(isHidden: Bool) {
        guard guideView.isHidden != isHidden else { return }
        guideView.isHidden = isHidden
        adjustContentWrapperView()
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}
