//
//  WebinarStageVC.swift
//  ByteView
//
//  Created by liujianlong on 2023/3/10.
//

import UIKit
import ByteViewNetwork
import UniverseDesignColor
import RxSwift
import ByteViewSetting

final class WebinarStageVC: UIViewController {
    private let webinarManager: InMeetWebinarManager
    private weak var container: InMeetViewContainer?
    private let gridViewModel: InMeetGridViewModel
    private let activeSpeaker: InMeetActiveSpeakerViewModel
    private var gridDataBag = DisposeBag()

    var shareScene: InMeetShareScene = InMeetShareScene(shareSceneType: .none, shareScreenData: nil, magicShareData: nil, whiteboardData: nil, shareScreenToFollowData: nil, isLocalProjection: false) {
        didSet {
            guard self.shareScene != oldValue else {
                return
            }
            Logger.webinarStage.info("shareSceneChanged: \(self.shareScene)")
            self.computeShareVCType()
        }
    }
    var webinarStageInfo: WebinarStageInfo {
        didSet {
            guard self.webinarStageInfo != oldValue else {
                return
            }
            self.computeShareVCType()
            self.stageInfoDidChanged(oldValue: oldValue)
        }
    }

    private var shareRatio: CGFloat = 16.0/9.0 {
        didSet {
            guard abs(shareRatio - oldValue) > 0.01 else {
                return
            }
            self.view.setNeedsLayout()
        }
    }

    private var activeSpeakerUID: RtcUID? {
        didSet {
            guard self.activeSpeakerUID != oldValue else {
                return
            }
            self.view.setNeedsLayout()
        }
    }

    private var showFullVideoFrame: Bool {
        self.webinarStageInfo.showFullVideoFrame
    }

    private var stageBgPath: String? {
        didSet {
            guard self.stageBgPath != oldValue else {
                return
            }
            if let path = self.stageBgPath {
                let absPath = meeting.service.storage.getAbsPath(absolutePath: path)
                if absPath.fileExists(), let imageData = try? absPath.readData(options: .mappedIfSafe) {
                    stageBgView.image = UIImage(data: imageData)
                } else {
                    Logger.webinarStage.error("stageBg read error, fileExists: \(absPath.fileExists())")
                }
            } else {
                stageBgView.image = nil
            }
        }
    }

    private var stageBgView = UIImageView()

    private var shareVCType: InMeetShareSceneType = .none {
        didSet {
            guard shareVCType != oldValue else {
                return
            }
            updateShareVC()
        }
    }
    private var shareVC: UIViewController?

    private var guestViewDict = [ByteviewUser: InMeetingParticipantView]()

    // 用于圆角裁剪
    private lazy var guestsWrapper = UIView()
    // 用于绘制阴影、描边
    private lazy var guestsContainer = {
        let container = UIView()
        container.addSubview(guestsWrapper)
        guestsWrapper.frame = container.bounds
        guestsWrapper.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return container
    }()
    private var guestDivider: [CAShapeLayer] = []

    private var guestViews = [InMeetingParticipantView]() {
        didSet {
            guard self.guestViews.map(ObjectIdentifier.init) != oldValue.map(ObjectIdentifier.init) else {
                return
            }
            self.view.setNeedsLayout()
        }
    }


    let parentContainerGuide = UILayoutGuide()
    let contentLayoutGuide = UILayoutGuide()
    let bottomBarLayoutGuide = UILayoutGuide()
    var singleTapGestureRecognizer: UITapGestureRecognizer?
    let meeting: InMeetMeeting

    var isPhonePortrait: Bool {
        Display.phone && self.traitCollection.horizontalSizeClass == .compact && self.traitCollection.verticalSizeClass == .regular
    }

    private lazy var asBorderView = InMeetingParticipantActiveSpeakerView()

    init(meeting: InMeetMeeting,
         container: InMeetViewContainer,
         webinarManager: InMeetWebinarManager,
         stageInfo: WebinarStageInfo,
         gridViewModel: InMeetGridViewModel,
         activeSpeaker: InMeetActiveSpeakerViewModel) {
        self.meeting = meeting
        self.container = container
        self.webinarManager = webinarManager
        self.webinarStageInfo = stageInfo
        self.gridViewModel = gridViewModel
        self.activeSpeaker = activeSpeaker
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.clipsToBounds = true
        self.view.autoresizesSubviews = false
        self.view.addSubview(stageBgView)
        self.view.addLayoutGuide(parentContainerGuide)
        self.view.addLayoutGuide(contentLayoutGuide)
        self.view.addLayoutGuide(bottomBarLayoutGuide)
        self.view.addSubview(guestsContainer)
        self.view.addSubview(self.asBorderView)
        self.asBorderView.isHidden = true


        self.stageInfoDidChanged(oldValue: nil)
        self.updateShareVC()

        self.activeSpeaker.addListener(self)
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        Display.phone ? .allButUpsideDown : .all
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateStageLayout()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.updateStageLayout()
    }

    private var mobilePortraitLayoutStyle: Bool {
        isPhonePortrait
        || Display.pad && self.view.traitCollection.horizontalSizeClass == .compact
    }

    private func updateStageLayout() {
        guard self.view.bounds.width >= 1.0, self.view.bounds.height >= 1.0 else {
            return
        }
        let stageWidth: CGFloat
        let stageHeight: CGFloat
        let matchHeight: Bool
        if mobilePortraitLayoutStyle {
            // aspectFill
            matchHeight = self.view.bounds.height * 16.0 > self.view.bounds.width * 9.0
        } else {
            // aspectFit
            matchHeight = self.view.bounds.height * 16.0 < self.view.bounds.width * 9.0
        }
        if matchHeight {
            stageHeight = self.view.bounds.height
            stageWidth = stageHeight * 16.0 / 9.0
        } else {
            stageWidth = self.view.bounds.width
            stageHeight = stageWidth * 9.0 / 16.0
        }
        let stageFrame = CGRect(origin: CGPoint(x: (self.view.bounds.width - stageWidth) * 0.5,
                                                      y: (self.view.bounds.height - stageHeight) * 0.5),
                                size: CGSize(width: stageWidth, height: stageHeight))
            .integral
        self.stageBgView.frame = stageFrame

        let sharePosition: StageSharePosition

        let layout: StageLayout

        if self.shareVC == nil {
            sharePosition = .none
        } else if mobilePortraitLayoutStyle {
            sharePosition = .left
        } else {
            if webinarStageInfo.guestFloatingPos == .floatingBottom {
                sharePosition = .bottomFloating
            } else if webinarStageInfo.guestFloatingPos == .floatingTop {
                sharePosition = .topFloating
            } else if webinarStageInfo.sharingPosition == .shareRight {
                sharePosition = .right
            } else {
                sharePosition = .left
            }
        }

        let insets: UIEdgeInsets
        if let window = self.view.window,
            self.view.bounds == window.bounds {
            insets = window.safeAreaInsets
        } else {
            insets = self.view.safeAreaInsets
        }
        if mobilePortraitLayoutStyle {
            // NOTE: iPhone14Pro 在小窗切换到大窗时，获取的 self.view.safeAreaInsets 不正确
            let stageSafeArea = self.view.bounds.inset(by: insets)
            if stageSafeArea.width < 1.0 || stageSafeArea.height < 1.0 {
                return
            }
            layout = WebinarStageMobilePortraitLayout(stageSafeArea: stageSafeArea, showFullVideoFrame: self.showFullVideoFrame)
        } else {
            if sharePosition == .topFloating || sharePosition == .bottomFloating {
                layout = WebinarStageMobileLandscapeLayout(stageArea: self.view.bounds.inset(by: insets),  // 悬浮视图下舞台区域没有 16:9 约束
                                                           isPhone: Display.phone,
                                                           shareRatio: self.shareRatio,
                                                           showFullVideoFrame: self.showFullVideoFrame)
            } else {
                layout = WebinarStageMobileLandscapeLayout(stageArea: stageFrame,
                                                           isPhone: Display.phone,
                                                           shareRatio: self.shareRatio,
                                                           showFullVideoFrame: self.showFullVideoFrame)
            }
        }
        if let shareVC = self.shareVC {
            shareVC.view.layer.cornerRadius = 8.0
            shareVC.view.clipsToBounds = true
            let (shareArea, guestAreas) = layout.computeShareLayouts(guestCount: guestViews.count,
                                                                     draggedLayoutInfo: self.webinarStageInfo.draggedLayoutInfo,
                                                                     sharePosition: sharePosition)
            shareVC.view.frame = shareArea.rect

            if !guestAreas.isEmpty,
               sharePosition == .bottomFloating || sharePosition == .topFloating {
                let origin = guestAreas.first?.rect.origin ?? self.view.bounds.origin
                let size = CGSize(width: (guestAreas.last?.rect.maxX ?? self.view.bounds.maxX) - origin.x,
                                  height: (guestAreas.last?.rect.maxY ?? self.view.bounds.maxY) - origin.y)
                updateGuestContainerStyle(customFrame: CGRect(origin: origin, size: size),
                                          guestCount: guestViews.count,
                                          isVertical: sharePosition == .topFloating)
            } else {
                updateGuestContainerStyle(customFrame: nil, guestCount: guestViews.count, isVertical: false)
            }

            for guestArea in guestAreas.enumerated() {
                let guestView = guestViews[guestArea.offset]
                guestView.frame = guestsContainer.convert(guestArea.element.rect, from: self.view)
                let bottomFrame = guestView.convert(self.bottomBarLayoutGuide.layoutFrame, from: self.bottomBarLayoutGuide.owningView)
                configureGuestViewStyle(guestView: guestView,
                                        renderMode: guestArea.element.renderMode,
                                        bottomBarFrame: bottomFrame,
                                        guestCount: guestViews.count,
                                        sharePosition: sharePosition)
            }
        } else {
            updateGuestContainerStyle(customFrame: nil, guestCount: guestViews.count, isVertical: false)
            let guestAreas = layout.computeLayouts(guestCount: guestViews.count)
            for rect in guestAreas.enumerated() {
                let guestView = guestViews[rect.offset]
                guestView.frame = rect.element.rect
                guestView.translatesAutoresizingMaskIntoConstraints = true
                let bottomFrame = guestView.convert(self.bottomBarLayoutGuide.layoutFrame, from: self.bottomBarLayoutGuide.owningView)
                configureGuestViewStyle(guestView: guestView,
                                        renderMode: rect.element.renderMode,
                                        bottomBarFrame: bottomFrame,
                                        guestCount: guestViews.count,
                                        sharePosition: sharePosition)
            }
        }
        if (webinarStageInfo.guestFloatingPos == .floatingBottom || webinarStageInfo.guestFloatingPos == .floatingTop) && self.shareVC != nil {
            stageBgView.isHidden = true
        } else {
            stageBgView.isHidden = false
        }
        updateASBorder(sharePosition: sharePosition)
    }

    private func createGuestView() -> InMeetingParticipantView {
        let view = InMeetingParticipantView()
        view.moreSelectionButton.removeFromSuperview()
        view.didTapUserName = { [weak self] p in
            self?.tapUserName(participant: p)
        }
        return view
    }

    private func updateASBorder(sharePosition: StageSharePosition) {

        if let activeSpeakerUID = self.activeSpeakerUID,
           self.guestViews.count > 1,
           let guestView = self.guestViews.first(where: { view in
               guard let participant = view.cellViewModel?.participant.value else {
                   return false
               }
               return InMeetGridCellViewModel.calActiveSpeaker(speakerSDKUID: activeSpeakerUID, participant: participant)
           }) {
            self.asBorderView.isHidden = false
            let guestIndex = self.guestViews.firstIndex(of: guestView) ?? 0
            let guestFrame = self.view.convert(guestView.frame, from: guestView.superview)

            self.asBorderView.roundedRadius = 8.0
            if sharePosition == .topFloating || sharePosition == .bottomFloating {
                // Floating 样式 AS 使用内部描边
                self.asBorderView.asStrokeOutside = false
                self.asBorderView.frame = guestFrame.insetBy(dx: 1.0, dy: 1.0)
            } else {
                // AS 默认使用外部描边
                self.asBorderView.asStrokeOutside = true
                self.asBorderView.frame = guestFrame.insetBy(dx: -2.0, dy: -2.0)
            }
            if (sharePosition == .topFloating || sharePosition == .bottomFloating) && guestViews.count == 1 {
                self.asBorderView.corners = .allCorners
            } else if sharePosition == .topFloating {
                if guestIndex == 0 {
                    self.asBorderView.corners = [.topLeft, .topRight]
                } else if guestIndex == self.guestViews.count - 1 {
                    self.asBorderView.corners = [.bottomLeft, .bottomRight]
                } else {
                    self.asBorderView.corners = []
                }
            } else if sharePosition == .bottomFloating {
                if guestIndex == 0 {
                self.asBorderView.corners = [.topLeft, .bottomLeft]
                } else if guestIndex == self.guestViews.count - 1 {
                    self.asBorderView.corners = [.topRight, .bottomRight]
                } else {
                    self.asBorderView.corners = []
                }
            } else {
                self.asBorderView.corners = .allCorners
            }
        } else {
            self.asBorderView.isHidden = true
        }
    }

    private func updateGuestContainerStyle(customFrame: CGRect?, guestCount: Int, isVertical: Bool) {
        if let frame = customFrame {
            guestsContainer.frame = frame
            guestsContainer.layer.cornerRadius = 8.0
            guestsContainer.layer.borderWidth = 1.0
            guestsContainer.layer.borderColor = UDColor.staticWhite.withAlphaComponent(0.2).cgColor
            guestsContainer.layer.ud.setShadow(type: .s4Down)

            guestsWrapper.layer.cornerRadius = 8.0
            guestsWrapper.layer.masksToBounds = true
        } else {
            guestsContainer.frame = self.view.bounds
            guestsContainer.layer.cornerRadius = 0.0
            guestsContainer.layer.borderWidth = 0.0
            guestsContainer.layer.borderColor = nil
            guestsContainer.layer.shadowColor = nil
            guestsContainer.layer.shadowOpacity = 0.0

            guestsWrapper.layer.cornerRadius = 0.0
            guestsWrapper.layer.masksToBounds = false
        }

        let dividerCount = customFrame != nil && guestCount > 0 ?  guestCount - 1 : 0

        if self.guestDivider.count > dividerCount {
            self.guestDivider.suffix(self.guestDivider.count - dividerCount).forEach { $0.removeFromSuperlayer() }
            self.guestDivider.removeLast(self.guestDivider.count - dividerCount)
        } else {
            for _ in 0..<dividerCount - self.guestDivider.count {
                let layer = CAShapeLayer()
                layer.lineWidth = 1.0
                layer.ud.setStrokeColor(UDColor.lineBorderCard, bindTo: self.guestsContainer)
                self.guestsContainer.layer.addSublayer(layer)
                self.guestDivider.append(layer)
            }
        }

        if dividerCount > 0 {
            let path = CGMutablePath()
            if isVertical {
                path.addLines(between: [CGPoint(x: 1, y: 0), CGPoint(x: guestsContainer.bounds.width - 1.0, y: 0.0)])
            } else {
                path.addLines(between: [CGPoint(x: 0, y: 1), CGPoint(x: 0.0, y: guestsContainer.bounds.height - 1.0)])
            }
            let offset = CGPoint(x: isVertical ? 0.0 : guestsContainer.bounds.width / CGFloat(guestCount),
                                 y: isVertical ? guestsContainer.bounds.height / CGFloat(guestCount) : 0.0)
            let size = CGSize(width: isVertical ? guestsContainer.bounds.width : 1.0,
                              height: isVertical ? 1.0 : guestsContainer.bounds.height)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            for (idx, divider) in guestDivider.enumerated() {
                divider.path = path
                divider.frame = CGRect(x: CGFloat(idx + 1) * offset.x,
                                       y: CGFloat(idx + 1) * offset.y,
                                       width: size.width,
                                       height: size.height)
            }
            CATransaction.commit()
        }
    }

    private func configureGuestViewStyle(guestView: InMeetingParticipantView,
                                         renderMode: ByteViewRenderMode,
                                         bottomBarFrame: CGRect,
                                         guestCount: Int,
                                         sharePosition: StageSharePosition) {
        var cfg: ParticipantViewStyleConfig
        let hasShare = sharePosition != .none
        if mobilePortraitLayoutStyle {
            if hasShare {
                cfg = Self.phonePortraitShareGuestStyle
            } else if guestCount <= 2 {
                cfg = Self.phonePortraitNoShareGuestStyle2
            } else {
                cfg = Self.phonePortraitNoShareGuestStyle4
            }
        } else if Display.phone {
            if hasShare {
                cfg = Self.phoneLandscapeShareGuestStyle
            } else if guestCount <= 2 {
                cfg = Self.phoneLandscapeNoShareGuestStyle2
            } else {
                cfg = Self.phoneLandscapeNoShareGuestStyle4
            }
        } else {
            if hasShare {
                cfg = Self.padShareGuestStyle
            } else if guestCount <= 2 {
                cfg = Self.padNoShareGuestStyle2
            } else {
                cfg = Self.padNoShareGuestStyle4
            }
        }

        if mobilePortraitLayoutStyle {
            cfg.hasTopBottomBarInset = true
        } else {
            cfg.hasTopBottomBarInset = false
        }
        if bottomBarFrame.minY < guestView.bounds.maxY {
            cfg.bottomBarInset = guestView.bounds.maxY - bottomBarFrame.minY
        } else {
            cfg.bottomBarInset = 0
        }
        switch sharePosition {
        case .topFloating, .bottomFloating:
            cfg.showBorderLines = false
            cfg.showVideoBorderLines = false
            cfg.cornerRadius = 0
        default:
            break
        }
        cfg.userInfoViewStyle.components = [.name, .nameDesc]
        cfg.renderMode = renderMode
        guestView.styleConfig = cfg
        let viewSizeScale = meeting.setting.multiResolutionConfig.viewSizeScale

        let multiResolutionConfig = meeting.setting.multiResolutionConfig
        // https://bytedance.feishu.cn/docx/CYCod2hw3oIeGJxRj7Nc0aEPnaf
        if mobilePortraitLayoutStyle {
            if hasShare {
                guestView.streamRenderView.multiResSubscribeConfig = matchGalleryRules(rules: multiResolutionConfig.phone.subscribe.stageShareGuest, viewSizeScale: viewSizeScale, viewCount: guestCount)
            } else {
                guestView.streamRenderView.multiResSubscribeConfig = InMeetingCollectionViewSquareGridFlowLayout.makeMultiResSubConfig(cfgs: multiResolutionConfig, viewCount: guestCount)
            }
        } else if Display.phone {
            if hasShare {
                guestView.streamRenderView.multiResSubscribeConfig = matchGalleryRules(rules: multiResolutionConfig.phone.subscribe.stageShareGuest, viewSizeScale: viewSizeScale, viewCount: guestCount)
            } else {
                guestView.streamRenderView.multiResSubscribeConfig = matchGalleryRules(rules: multiResolutionConfig.phone.subscribe.stageGuest, viewSizeScale: viewSizeScale, viewCount: guestCount)
            }
        } else {
            if hasShare {
                guestView.streamRenderView.multiResSubscribeConfig = matchGalleryRules(rules: multiResolutionConfig.pad.subscribe.stageShareGuest, viewSizeScale: viewSizeScale, viewCount: guestCount)
            } else {
                guestView.streamRenderView.multiResSubscribeConfig = matchGalleryRules(rules: multiResolutionConfig.pad.subscribe.stageGuest, viewSizeScale: viewSizeScale, viewCount: guestCount)
            }
        }
    }

    private func stageInfoDidChanged(oldValue: WebinarStageInfo?) {
        guard self.isViewLoaded else {
            return
        }
        self.view.setNeedsLayout()
        if oldValue?.backgroundURL != self.webinarStageInfo.backgroundURL
            || oldValue?.backgroundToken != self.webinarStageInfo.backgroundToken {
            let url = self.webinarStageInfo.backgroundURL
            let token = self.webinarStageInfo.backgroundToken
            self.webinarManager.loadStageBackground(webinarStageInfo: self.webinarStageInfo) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self,
                          case .success(let path) = result,
                          token == self.webinarStageInfo.backgroundToken && url == self.webinarStageInfo.backgroundURL else {
                        return
                    }
                    self.stageBgPath = path
                }
            }
        }

        self.gridDataBag = DisposeBag()
        self.gridViewModel.allGridViewModels
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] allGridViewModels in
                guard let self = self else {
                    return
                }
                if self.updateStageGuestViews(webinarStageInfo: self.webinarStageInfo, allGridViewModels: allGridViewModels) {
                    self.gridDataBag = DisposeBag()
                }
            })
            .disposed(by: self.gridDataBag)
    }

    private func updateStageGuestViews(webinarStageInfo: WebinarStageInfo, allGridViewModels: [ByteviewUser: InMeetGridCellViewModel]) -> Bool {
        var isSynced = true
        var newGuestViewDict = [ByteviewUser: InMeetingParticipantView]()
        var newGuestViews = [InMeetingParticipantView]()
        for p in self.webinarStageInfo.guests {
            if newGuestViewDict.index(forKey: p) != nil {
                continue
            }
            if let v = self.guestViewDict.removeValue(forKey: p) {
                newGuestViewDict[p] = v
                newGuestViews.append(v)
            } else if let vm = allGridViewModels[p] {
                let v = self.createGuestView()
                v.bind(viewModel: vm, enableConditionEmoji: false, layoutType: "webinar_stage_guest")
                newGuestViewDict[p] = v
                newGuestViews.append(v)
                self.guestsWrapper.addSubview(v)
            } else {
                Logger.webinarStage.error("missing webinar stage guest")
                isSynced = false
            }
        }

        for kv in self.guestViewDict {
            kv.value.removeFromSuperview()
        }
        self.guestViewDict = newGuestViewDict
        self.guestViews = newGuestViews
        return isSynced
    }

    private func updateShareVC() {
        guard self.isViewLoaded else {
            return
        }
        self.shareRatio = 16.0/9.0
        if let shareVC = self.shareVC {
            shareVC.willMove(toParent: nil)
            shareVC.view.removeFromSuperview()
            shareVC.removeFromParent()
            self.shareVC = nil
        }
        if shareVCType == .othersSharingScreen {
            if let vm = self.container?.shareComponent?.shareScreenVM {
                let vc = InMeetShareScreenVideoVC(viewModel: vm, showHighDefinitionIndicator: false)
                vc.view.isUserInteractionEnabled = false
                self.addChild(vc)
                self.view.insertSubview(vc.view, belowSubview: guestsContainer)
                vc.didMove(toParent: self)
                self.shareVC = vc
                vc.streamRenderView.addListener(self)
            }
        } else if shareVCType == .selfSharingScreen {
            if let vc = self.container?.shareComponent?.makeVCWithContent(.selfShareScreen) {
                self.addChild(vc)
                self.view.insertSubview(vc.view, belowSubview: guestsContainer)
                vc.didMove(toParent: self)
                self.shareVC = vc
            }
        }
        self.view.setNeedsLayout()
    }

    private func tapUserName(participant: Participant) {
        self.container?.flowComponent?.didTapUserName(participant: participant)
    }
}

extension WebinarStageVC {
    private func computeShareVCType() {
        if webinarStageInfo.hideSharing {
            shareVCType = .none
        } else if shareScene.shareSceneType == .othersSharingScreen {
            shareVCType = .othersSharingScreen
        } else if shareScene.shareSceneType == .selfSharingScreen && Display.pad {
            shareVCType = .selfSharingScreen
        } else {
            shareVCType = .none
        }
    }
}

extension WebinarStageVC: InMeetFlowAndShareProtocol {
    var shareBottomView: UIView? {
        nil
    }

    var shareBottomBackgroundView: UIView? {
        nil
    }


    var shareVideoView: UIView? {
        nil
    }
}

extension WebinarStageVC {
    static let padNoShareGuestStyle2: ParticipantViewStyleConfig = {
        var style = ParticipantViewStyleConfig.webinarStage
        style.systemCallingStatusInfoSyle = .systemCallingBigPad
        style.userInfoViewStyle = .inMeetingGrid
        return style
    }()
    static let padNoShareGuestStyle4: ParticipantViewStyleConfig = {
        var style = ParticipantViewStyleConfig.webinarStage
        style.systemCallingStatusInfoSyle = .systemCallingMidPad
        style.userInfoViewStyle = .inMeetingGrid
        return style
    }()
    static let padShareGuestStyle: ParticipantViewStyleConfig = {
        var style = ParticipantViewStyleConfig.webinarStage
        style.systemCallingStatusInfoSyle = .systemCallingMidPad
        style.userInfoViewStyle = .inMeetingGrid
        return style
    }()

    static let phonePortraitNoShareGuestStyle2: ParticipantViewStyleConfig = {
        var style = ParticipantViewStyleConfig.webinarStage
        style.systemCallingStatusInfoSyle = .systemCallingBigPhone
        style.userInfoViewStyle = .inMeetingGrid
        return style
    }()

    static let phonePortraitNoShareGuestStyle4: ParticipantViewStyleConfig = {
        var style = ParticipantViewStyleConfig.webinarStage
        style.systemCallingStatusInfoSyle = .systemCallingMidPhone
        style.userInfoViewStyle = .inMeetingGrid
        return style
    }()

    static let phonePortraitShareGuestStyle: ParticipantViewStyleConfig = phonePortraitNoShareGuestStyle4

    static let phoneLandscapeNoShareGuestStyle2: ParticipantViewStyleConfig = {
        var style = ParticipantViewStyleConfig.webinarStage
        style.systemCallingStatusInfoSyle = .systemCallingMidPhone
        style.userInfoViewStyle = .inMeetingGrid
        return style
    }()

    static let phoneLandscapeNoShareGuestStyle4: ParticipantViewStyleConfig = {
        var style = ParticipantViewStyleConfig.webinarStage
        style.systemCallingStatusInfoSyle = .systemCallingSmallPhone
        style.userInfoViewStyle = .inMeetingGrid
        return style
    }()

    static let phoneLandscapeShareGuestStyle: ParticipantViewStyleConfig = {
        var style = ParticipantViewStyleConfig.webinarStage
        style.systemCallingStatusInfoSyle = .systemCallingSmallPhone
        style.userInfoViewStyle = .floating
        style.cornerRadius = 8.0
        return style
    }()
}

extension WebinarStageVC: InMeetActiveSpeakerListener {
    func didChangeActiveSpeaker(_ rtcUid: RtcUID?, oldValue: RtcUID?) {
        Util.runInMainThread {
            self.activeSpeakerUID = rtcUid
        }
    }
}

extension WebinarStageVC: StreamRenderViewListener {
    func streamRenderViewDidChangeVideoFrameSize(_ renderView: StreamRenderView, size: CGSize?) {
        var ratio: CGFloat = 16.0/9.0
        if let size = size,
           size.height >= 1.0 && size.width >= 1.0 {
            ratio = size.width / size.height
        }
        Util.runInMainThread {
            self.shareRatio = ratio
        }
    }
}
