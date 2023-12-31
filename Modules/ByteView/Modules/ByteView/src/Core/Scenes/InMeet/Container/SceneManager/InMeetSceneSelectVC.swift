//
// Created by liujianlong on 2022/8/23.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import ByteViewUI
import ByteViewNetwork

protocol InMeetSceneSelectViewControllerDelegate: AnyObject {
    func sceneSelectionViewWillDisappear()
    func sceneSelectionViewDidSelectSceneMode(_ mode: InMeetSceneManager.SceneMode)
    func sceneSelectionViewDidToggleHideSelf(_ enabled: Bool)
    func sceneSelectionViewDidToggleHideNonVideo(_ enabled: Bool)
    func sceneSelectionViewDidToggleSyncOrder(_ enabled: Bool)
    func sceneSelectionViewDidResetOrder()
    func sceneSelectionViewDidToggleShowSpeakerOnMainView(_ enabled: Bool)
}

private enum Layout {
    static let btnBgSize = CGSize(width: 56.0 + 3.0 * 2, height: 92.0)
    static let btnContentSize = CGSize(width: 56.0, height: 42.0)
}

class InMeetSceneSelectVC: UIViewController, MeetingSceneModeListener {
    weak var delegate: InMeetSceneSelectViewControllerDelegate?

    /// 数据源
    private var settingItems: [[PadSceneSettingItem]] = [[]]

    private let meeting: InMeetMeeting
    private let context: InMeetViewContext
    private let gridViewModel: InMeetGridViewModel
    private let hasWebinarStage: Bool

    // 是否为Webinar会议
    var isWebinar: Bool {
        meeting.subType == .webinar
    }

    init(meeting: InMeetMeeting,
         viewModel: InMeetViewModel,
         hasWebinarStage: Bool,
         context: InMeetViewContext) {
        self.meeting = meeting
        self.context = context
        self.gridViewModel = viewModel.resolver.resolve()!
        self.hasWebinarStage = hasWebinarStage
        super.init(nibName: nil, bundle: nil)
        updateSettingsData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.sceneSelectionViewWillDisappear()
    }

    var sceneButtons: [InMeetSceneManager.SceneMode: BVPositionedButton] {
        var btns: [InMeetSceneManager.SceneMode: BVPositionedButton] = [
            .gallery: galleryBtn,
            .thumbnailRow: thumbnailBtn,
            .speech: speechBtn,
            .webinarStage: stageBtn
        ]
        if self.hasWebinarStage {
            btns[.webinarStage] = stageBtn
        }
        return btns
    }
    lazy var galleryBtn = BVPositionedButton(type: .custom)
    lazy var thumbnailBtn = BVPositionedButton(type: .custom)
    lazy var speechBtn = BVPositionedButton(type: .custom)
    lazy var stageBtn = BVPositionedButton(type: .custom)


    private lazy var settingsTableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgFloat
        tableView.delaysContentTouches = false
        tableView.isScrollEnabled = false
        tableView.register(PadSceneSettingSwitchCell.self, forCellReuseIdentifier: PadSceneSettingItem.CellType.switchCell.rawValue)
        tableView.register(PadSceneSettingDetailCell.self, forCellReuseIdentifier: PadSceneSettingItem.CellType.detailCell.rawValue)
        return tableView
    }()

    func containerDidChangeSceneMode(container: InMeetViewContainer, sceneMode: InMeetSceneManager.SceneMode) {
        self.loadViewIfNeeded()
        sceneButtons.forEach({ scene, btn in
            btn.isSelected = scene == sceneMode
        })
    }

    var hasHideNonVideoItem: Bool {
        meeting.participant.currentRoom.nonRingingCount > 1
    }

    var hasResetOrderItem: Bool {
        guard gridViewModel.isUsingCustomOrder else { return false }
        if gridViewModel.isGridOrderSyncing {
            return meeting.myself.isHost
        }
        return true
    }

    private var hasSyncOrderItem: Bool {
        return meeting.type == .meet &&
            gridViewModel.isUsingCustomOrder &&
            meeting.myself.isHost
    }

    var shouldShowMainViewSpeaker: Bool {
        context.showSpeakerOnMainScreenEnabled
    }

    var calculatedContentSize: CGSize {
        let sceneCount = self.hasWebinarStage ? 4 : 3
        let width: CGFloat = 56.0 * CGFloat(sceneCount) + 20.0 * CGFloat(sceneCount + 1)

        let baseHeight: CGFloat = 104
        var tableHeight: CGFloat = 0

        let maxWidth: CGFloat = width - 20.0 * 2 - 12.0 - 49.0
        for section in settingItems {
            tableHeight += 17.0
            for item in section {
                var textHeight: CGFloat = 22
                if item.cellType == .switchCell {
                    textHeight = min(2 * textHeight, max(textHeight, item.title.vc.boundingHeight(width: maxWidth, attributes: PadSceneSettingSwitchCell.attributes)))
                }
                tableHeight += 16 + textHeight
            }
        }

        let height = baseHeight + tableHeight
        return CGSize(width: width, height: height)
    }

    private func setupViews() {
        var sceneTitles: [(InMeetSceneManager.SceneMode, String, BVPositionedButton)] = [
            (.gallery, I18n.View_G_GalleryMini, galleryBtn),
            (.thumbnailRow, I18n.View_G_Thumbnail, thumbnailBtn),
            (.speech, I18n.View_G_Speaker, speechBtn)
        ]

        if hasWebinarStage {
            sceneTitles.append((.webinarStage, I18n.View_G_StageIcon, stageBtn))
        }

        for (scene, title, btn) in sceneTitles {
            btn.isExclusiveTouch = true
            btn.imagePosition = .top
            btn.spacing = 5.0
            btn.setTitle(title, for: .normal)
            btn.setAttributedTitle(NSAttributedString(string: title, config: .tinyAssist), for: .normal)
            btn.setTitleColor(UDColor.textTitle, for: .normal)
            btn.setTitleColor(UDColor.textDisabled, for: .disabled)
            let normalImg = Self.getOrCreateIcon(iconStatus: .normal, sceneMode: scene)
            btn.setImage(normalImg, for: .normal)
            let highlightImg = Self.getOrCreateIcon(iconStatus: .pressed, sceneMode: scene)
            btn.setImage(highlightImg, for: .highlighted)
            let selectImg = Self.getOrCreateIcon(iconStatus: .selected, sceneMode: scene)
            btn.setImage(selectImg, for: .selected)
            btn.setImage(selectImg, for: [.selected, .highlighted])
            let disableImg = Self.getOrCreateIcon(iconStatus: .disable, sceneMode: scene)
            btn.setImage(disableImg, for: .disabled)
//            btn.setBackgroundImage(Self.highlightBg, for: .highlighted)
            self.view.addSubview(btn)

            btn.addTarget(self,
                          action: #selector(sceneBtnTapped(sender:)),
                          for: .touchUpInside)
        }

        galleryBtn.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(17.0)
            make.left.equalToSuperview().offset(17.0)
            make.width.equalTo(Layout.btnBgSize.width)
        }

        thumbnailBtn.snp.makeConstraints { make in
            make.top.equalTo(galleryBtn)
            make.left.equalTo(galleryBtn.snp.right).offset(14.0)
            make.width.equalTo(Layout.btnBgSize.width)
        }

        speechBtn.snp.makeConstraints { make in
            make.top.equalTo(galleryBtn)
            make.left.equalTo(thumbnailBtn.snp.right).offset(14.0)
            make.width.equalTo(Layout.btnBgSize.width)
        }

        if hasWebinarStage {
            stageBtn.snp.makeConstraints { make in
                make.top.equalTo(galleryBtn)
                make.left.equalTo(speechBtn.snp.right).offset(14.0)
                make.width.equalTo(Layout.btnBgSize.width)
            }
        }

        if !settingItems.isEmpty {
            self.view.addSubview(settingsTableView)
            settingsTableView.snp.makeConstraints { make in
                make.top.equalTo(galleryBtn.snp.bottom).offset(7.0)
                make.left.right.equalToSuperview()
                make.bottom.greaterThanOrEqualToSuperview().inset(11)
            }
        }

    }

    @objc
    func sceneBtnTapped(sender: UIControl) {
        guard let mode = sceneButtons.first(where: { _, btn in btn === sender })?.key else {
            assertionFailure()
           return
        }
        delegate?.sceneSelectionViewDidSelectSceneMode(mode)
    }

    private func buildSections(builder: ((inout [[PadSceneSettingItem]]) -> Void)) -> [[PadSceneSettingItem]] {
        var sections: [[PadSceneSettingItem]] = []
        builder(&sections)
        return sections
    }

    private func updateSettingsData() {
        settingItems.removeAll()
        let isWebinarStage = context.sceneManager?.sceneMode == .webinarStage
        let participantsCount = meeting.participant.currentRoom.count
        if !isWebinarStage {
            let settings = buildSections {
                $0.section {
                    $0.row(hideSelfSetting(), if: context.hideSelfEnabled)
                    $0.row(hideNonVideoParticipantsSetting(), if: hasHideNonVideoItem)
                    $0.row(syncVideoOrderAllSetting(), if: hasSyncOrderItem)
                    $0.row(resetOrderItemSetting(), if: hasResetOrderItem)
                    if participantsCount == 1 {
                        // 单人会议异化
                        $0.row(showSpeakerOnMainScreenSetting(), if: shouldShowMainViewSpeaker && !context.isSettingHideSelf)
                    }
                }

                $0.section {
                    if participantsCount > 1 {
                        $0.row(showSpeakerOnMainScreenSetting(), if: shouldShowMainViewSpeaker)
                    }
                }
            }

            self.settingItems = settings
        }

        settingsTableView.reloadData()
    }
}

extension InMeetSceneSelectVC {
    func hideSelfSetting() -> PadSceneSettingItem {
        PadSceneSettingItem(cellType: .switchCell,
                            title: I18n.View_G_HideMe,
                            status: context.isSettingHideSelf,
                            switchHandler: { [weak self] enabled in
            self?.delegate?.sceneSelectionViewDidToggleHideSelf(enabled)
        })
    }

    func hideNonVideoParticipantsSetting () -> PadSceneSettingItem {
        var displayMode: VCSwitchDisplayMode = .normal
        var status = context.isSettingHideNonVideoParticipants
        if gridViewModel.isSyncingOthers {
            displayMode = .disable
            status = false
        }
        return PadSceneSettingItem(cellType: .switchCell,
                                   title: I18n.View_G_HideNonVideoParticipants,
                                   status: status,
                                   displayMode: displayMode,
                                   switchHandler: { [weak self] enabled in
            self?.delegate?.sceneSelectionViewDidToggleHideNonVideo(enabled)
        })
    }

    func syncVideoOrderAllSetting() -> PadSceneSettingItem {
        var status = gridViewModel.isGridOrderSyncing
        var displayMode: VCSwitchDisplayMode = .normal
        if meeting.data.inMeetingInfo?.focusingUser != nil || meeting.data.isOpenBreakoutRoom {
            displayMode = .disable
            status = false
        }

        let title = isWebinar ? I18n.View_G_SyncVideoOrderAttendee : I18n.View_G_SyncVideoOrderAll
        return PadSceneSettingItem(cellType: .switchCell,
                                   title: title,
                                   status: status,
                                   displayMode: displayMode,
                                   switchHandler: { [weak self] enabled in
            self?.delegate?.sceneSelectionViewDidToggleSyncOrder(enabled)
        })
    }

    func resetOrderItemSetting() -> PadSceneSettingItem {
        PadSceneSettingItem(cellType: .detailCell,
                            title: I18n.View_G_ResetVideoOrder,
                            detailAction: { [weak self] _ in
            self?.delegate?.sceneSelectionViewDidResetOrder()
        })
    }

    func showSpeakerOnMainScreenSetting () -> PadSceneSettingItem {
        PadSceneSettingItem(cellType: .switchCell,
                            title: I18n.View_G_ShowSpeakerOnMain,
                            status: context.isShowSpeakerOnMainScreen,
                            switchHandler: { [weak self] enabled in
            self?.delegate?.sceneSelectionViewDidToggleShowSpeakerOnMainView(enabled)
        })
    }
}

extension InMeetSceneSelectVC {
    private static var imageCache: [String: UIImage] = [:]

    private enum IconStatus {
        case normal
        case pressed
        case selected
        case disable
    }
    private static func getOrCreateIcon(iconStatus: IconStatus, sceneMode: InMeetSceneManager.SceneMode) -> UIImage? {
        let key = "\(iconStatus)_\(sceneMode)"
        if let img = imageCache[key] {
            return img
        }
        let img = UIImage.dynamic(light: makeGalleryIcon(iconStatus: iconStatus, sceneMode: sceneMode, isDark: false),
                                  dark: makeGalleryIcon(iconStatus: iconStatus, sceneMode: sceneMode, isDark: true))
        imageCache[key] = img
        return img
    }


    private static func iconForegroundColor(_ iconStatus: IconStatus) -> UIColor {
        switch iconStatus {
        case .normal:
            return UIColor.ud.N300
        case .pressed:
            return UIColor.ud.N900.withAlphaComponent(0.15)
        case .selected:
            return UIColor.ud.colorfulBlue.withAlphaComponent(0.2)
        case .disable:
            return UIColor.ud.N900.withAlphaComponent(0.15)
        }
    }

    // disable-lint: long function
    private static func makeGalleryIcon(iconStatus: IconStatus, sceneMode: InMeetSceneManager.SceneMode, isDark: Bool) -> UIImage {
        let contentSize = Layout.btnContentSize
        let contentOffset = CGPoint(x: 3.0, y: 3.0)

        let borderOffset: CGPoint = .zero
        let borderSize = CGSize(width: 62.0, height: 48.0)

        var foregroundColor = iconForegroundColor(iconStatus)
        var selectStrokeColor = UIColor.ud.B400
        if #available(iOS 13.0, *) {
            if isDark {
                foregroundColor = foregroundColor.alwaysDark
                selectStrokeColor = selectStrokeColor.alwaysDark
            } else {
                foregroundColor = foregroundColor.alwaysLight
                selectStrokeColor = selectStrokeColor.alwaysLight
            }
        }

        let render = UIGraphicsImageRenderer(bounds: .init(origin: .zero, size: borderSize))
        let img = render.image { context in
            let ctx = context.cgContext
            // draw foreground
            ctx.saveGState()
            ctx.setFillColor(foregroundColor.cgColor)
            if sceneMode == .gallery {
                let blockSize = CGSize(width: 27.0, height: 20.0)
                for col in 0..<2 {
                    for row in 0..<2 {
                        let pos = CGPoint(x: contentOffset.x + CGFloat(col) * (blockSize.width + 2.0),
                                          y: contentOffset.y + CGFloat(row) * (blockSize.height + 2.0))
                        let topLeftCorner = col == 0 && row == 0 ? 4.0 : 1.0
                        let topRightCorner = col == 1 && row == 0 ? 4.0 : 1.0
                        let bottomLeftCorner = col == 0 && row == 1 ? 4.0 : 1.0
                        let bottomRightCorner = col == 1 && row == 1 ? 4.0 : 1.0
                        let path = CGPath.createSpecializedCornerRadiusPath(bounds: CGRect(origin: pos, size: blockSize),
                                                                            topLeft: topLeftCorner,
                                                                            topRight: topRightCorner,
                                                                            bottomLeft: bottomLeftCorner,
                                                                            bottomRight: bottomRightCorner)
                        ctx.addPath(path)
                    }
                }
                ctx.fillPath(using: .winding)
            } else if sceneMode == .thumbnailRow {
                let smallBlockSize = CGSize(width: 17.0, height: 10.0)
                let bigBlockSize = CGSize(width: 56.0, height: 30.0)
                for col in 0..<3 {
                    let pos = CGPoint(x: contentOffset.x + CGFloat(col) * (smallBlockSize.width + 2.5),
                                      y: contentOffset.y)
                    let topLeftCorner = col == 0 ? 4.0 : 1.0
                    let topRightCorner = col == 2 ? 4.0 : 1.0
                    let path = CGPath.createSpecializedCornerRadiusPath(bounds: CGRect(origin: pos, size: smallBlockSize),
                                                                        topLeft: topLeftCorner,
                                                                        topRight: topRightCorner,
                                                                        bottomLeft: 1.0,
                                                                        bottomRight: 1.0)
                    ctx.addPath(path)
                }
                let pos = CGPoint(x: contentOffset.x,
                                  y: contentOffset.y + smallBlockSize.height + 2.0)
                let path = CGPath.createSpecializedCornerRadiusPath(bounds: CGRect(origin: pos, size: bigBlockSize),
                                                                    topLeft: 1.0,
                                                                    topRight: 1.0,
                                                                    bottomLeft: 4.0,
                                                                    bottomRight: 4.0)
                ctx.addPath(path)
                ctx.fillPath(using: .winding)
            } else if sceneMode == .speech {
                let outerSize = CGSize(width: 56.0, height: 42.0)
                let innerSize = CGSize(width: 15.0, height: 12.0)
                let outerPath = UIBezierPath(roundedRect: CGRect(origin: contentOffset, size: outerSize),
                                             cornerRadius: 4.0)
                let innerPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: contentOffset.x + outerSize.width - innerSize.width - 3.0,
                                                                                 y: contentOffset.y + 3.0),
                                                                 size: innerSize),
                                             cornerRadius: 2.0)
                ctx.addPath(outerPath.cgPath)
                ctx.addPath(innerPath.reversing().cgPath)
                ctx.fillPath(using: .winding)
            } else if sceneMode == .webinarStage {
                let imgSize = CGSize(width: 24.0, height: 24.0)
                let offset = CGPoint(x: 0.5 * (borderSize.width - imgSize.width), y: 0.5 * (borderSize.height - imgSize.height))
                let img = UDIcon.getIconByKey(.livestreamHybridFilled,
                                              iconColor: .black,
                                              size: imgSize)
                ctx.saveGState()
                let rectPath = UIBezierPath(roundedRect: CGRect(origin: contentOffset,
                                                                size: contentSize),
                                            cornerRadius: 5.0)
                ctx.addPath(rectPath.cgPath)
                ctx.fillPath()
                ctx.setBlendMode(.destinationOut)
                if let img = img.cgImage {
                    let flip = CGAffineTransform(1.0, 0.0,
                                                 0.0, -1.0,
                                                 0.0, 2 * offset.y + imgSize.height)
                    ctx.concatenate(flip)
                    ctx.draw(img, in: CGRect(origin: offset, size: imgSize))
                }
                ctx.restoreGState()
            }
            ctx.restoreGState()
            if iconStatus == .selected {
                // disable-lint: magic number
                ctx.saveGState()
                // draw selected border
                ctx.setStrokeColor(selectStrokeColor.cgColor)
                ctx.setLineWidth(1.5)
                let borderRect = CGRect(origin: borderOffset, size: borderSize)
                let selectedPath = UIBezierPath(roundedRect: borderRect.insetBy(dx: 0.75, dy: 0.75),
                                                cornerRadius: 6.0 - 0.75)
                ctx.addPath(selectedPath.cgPath)
                ctx.strokePath()
                ctx.restoreGState()
                // enable-lint: magic number
            }
        }
        return img
    }
    // enable-lint: long function
}

extension InMeetSceneSelectVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingItems[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < settingItems.count,
              indexPath.row < settingItems[indexPath.section].count else {
            return UITableViewCell()
        }
        let item = settingItems[indexPath.section][indexPath.row]
        let identifier = item.cellType.rawValue
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PadSceneSettingBaseCell {
            cell.item = item
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < settingItems.count,
              indexPath.row < settingItems[indexPath.section].count else {
            return
        }
        let item = settingItems[indexPath.section][indexPath.row]
        if item.cellType == .detailCell {
            item.detailAction?(self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 17.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }

    private func headView() -> UIView {
        let headView = UIView()
        headView.backgroundColor = UIColor.clear

        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault

        headView.addSubview(view)
        view.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8.0)
            make.height.equalTo(1.0)
            make.right.left.equalToSuperview()
        }

        return headView
    }
}

private extension Array where Element == [PadSceneSettingItem] {
    mutating func section(_ buildingBlock: ((inout [PadSceneSettingItem]) -> Void)) {
        var rows: [PadSceneSettingItem] = []
        buildingBlock(&rows)
        if !rows.isEmpty {
            append(rows)
        }
    }
}

private extension Array where Element == PadSceneSettingItem {
    mutating func row(_ model: PadSceneSettingItem, if condition: Bool = true) {
        if condition {
            append(model)
        }
    }
}
