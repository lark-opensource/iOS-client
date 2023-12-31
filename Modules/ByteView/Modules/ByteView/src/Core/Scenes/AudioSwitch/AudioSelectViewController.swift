//
//  AudioSelectViewController.swift
//  ByteView
//
//  Created by wangpeiran on 2022/3/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewUI
import UniverseDesignIcon
import ByteViewNetwork
import UniverseDesignColor
import ByteViewTracker
import ByteViewMeeting

class AudioSelectViewSectionHeader: UIView {
    let close: UIButton = {
        let btn = UIButton()
        btn.setImage(UDIcon.getIconByKey(.closeSmallOutlined, iconColor: .ud.iconN1, size: .init(width: 24, height: 24)), for: .normal)
        return btn
    }()

    let label: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.textColor = UIColor.ud.textTitle
        view.font = .systemFont(ofSize: 17, weight: .medium)
        return view
    }()

    let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(close)
        addSubview(label)
        addSubview(lineView)
        close.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.left.equalToSuperview().inset(16)
            make.size.equalTo(24)
        }
        label.snp.makeConstraints { make in
            make.left.right.greaterThanOrEqualToSuperview().inset(50)
            make.height.equalTo(24)
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
        }
        lineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
    }

    func updateTitle(text: String) {
        label.text = text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct AudioSelectCellItem {
    var subTitle: String?
    var isSelect: Bool
    var pressHandler: () -> Void
    var isCalling: Bool
    let audioMode: ParticipantSettings.AudioMode
    var height: CGFloat

    init(subTitle: String? = nil, isSelect: Bool, isCalling: Bool = false, audioMode: ParticipantSettings.AudioMode, height: CGFloat, pressHandler: @escaping () -> Void) {
        self.subTitle = subTitle
        self.isSelect = isSelect
        self.pressHandler = pressHandler
        self.isCalling = isCalling
        self.audioMode = audioMode
        self.height = height
    }
}

protocol AudioSelectViewControllerDelegate: AnyObject {
    func didSelectedAudio(at type: PreviewAudioType)
    func viewWillAppear()
    func viewWillDisppear()
    func viewDidAppear()
    func viewDidDisappear()
}

extension AudioSelectViewControllerDelegate {
    func viewWillAppear() {}
    func viewWillDisppear() {}
    func viewDidAppear() {}
    func viewDidDisappear() {}
}

class AudioSelectViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    typealias AudioMode = ParticipantSettings.AudioMode

    enum Scene {
        case preview(String)
        case inMeet(InMeetMeeting)
    }

    struct Layout {
        static let commonMargin: CGFloat = 12.0
        static let commonCellHeight: CGFloat = 56
        static let phoneCellHeight: CGFloat = 60
        static let bottomPadding: CGFloat = Display.iPhoneXSeries ? 8 : 16
        static let headerHeight: CGFloat = 48
        static let tableLeftRightInset: CGFloat = 10
    }

    var isPadLandscapeRegular: Bool { return currentLayoutContext.layoutType.isRegular && view.isLandscape }
    var tableTopBottomInset: CGFloat { isPadLandscapeRegular ? 10 : 8 }

    var bgColor: UIColor { currentLayoutContext.layoutType.isRegular ? .ud.bgFloat : .ud.bgBody }
    var contentHeight: CGFloat { Layout.headerHeight + tableTopBottomInset * 2 + tableViewHeight }

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = bgColor
        return view
    }()

    lazy var headerView: AudioSelectViewSectionHeader = {
        let view = AudioSelectViewSectionHeader()
        view.backgroundColor = bgColor
        view.close.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        return view
    }()

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.register(AudioSelectCell.self, forCellReuseIdentifier: "AudioSelectCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        return tableView
    }()


    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    lazy var cancelView: UIView = {
        let view = UIView()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelAction)))
        return view
    }()

    weak var delegate: AudioSelectViewControllerDelegate?

    private var items: [AudioSelectCellItem] = []
    private var currentType: AudioMode?
    private var phoneNumber: String?
    private var isCalling: Bool
    private var tableViewHeight: CGFloat = 0
    private let isRoomConnected: Bool
    private let scene: Scene

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    init(scene: Scene, audioType: ParticipantSettings.AudioMode?, audioList: [ParticipantSettings.AudioMode], isRoomConnected: Bool = false) {
        self.scene = scene
        self.currentType = audioType
        self.isRoomConnected = isRoomConnected
        switch scene {
        case .preview(let phoneNumber):
            self.phoneNumber = phoneNumber
            self.isCalling = false
        case .inMeet(let meeting):
            self.phoneNumber = meeting.setting.callmePhoneNumber
            self.isCalling = meeting.audioModeManager.isPstnCalling
        }
        super.init(nibName: nil, bundle: nil)

        if case .inMeet(let meeting) = scene {
            meeting.audioModeManager.addListener(self)
        }

        createItemModel(by: audioList)
        tableViewHeight = items.reduce(0, { partialResult, item in
            partialResult + item.height
        })
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(containerView)
        view.addSubview(cancelView)
        containerView.addSubview(headerView)
        containerView.addSubview(tableView)

        updateBackgroundColor()
        headerView.updateTitle(text: isRoomConnected ? I18n.View_MV_SwitchAudioTo : I18n.View_G_AudioConnection_GreyText)
        layoutViews()
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if oldContext.layoutType != newContext.layoutType {
            headerView.close.isHidden = view.isLandscape && newContext.layoutType.isRegular
            updateBackgroundColor()
        }
        if case .inMeet = scene {
            layoutViews()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.viewWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.viewDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.viewWillDisppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.viewDidDisappear()
    }

    // disable-lint: duplicated code
    func layoutViews() {
        cancelView.snp.remakeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(headerView.snp.top)
        }
        headerView.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        if self.currentLayoutContext.layoutType.isPhoneLandscape {
            containerView.snp.remakeConstraints { make in
                make.centerX.bottom.equalToSuperview()
                make.width.equalTo(420)
            }
        } else {
            containerView.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
            }
        }
        tableView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.tableLeftRightInset)
            make.top.equalTo(headerView.snp.bottom).offset(tableTopBottomInset)
            make.height.equalTo(self.tableViewHeight)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide).offset(-tableTopBottomInset)
        }
    }

    private func updateBackgroundColor() {
        headerView.backgroundColor = VCScene.isRegular ? .clear : .ud.bgBody
        view.backgroundColor = VCScene.isRegular ? .clear : .ud.bgMask
        containerView.backgroundColor = bgColor
    }


    private func createItemModel(by audioList: [AudioMode]) {
        var hasPhone = false
        if let phone = phoneNumber, !phone.isEmpty {
            hasPhone = true
        }

        for item in audioList {
            if item == .internet {
                items.append(.init(isSelect: currentType == .internet,
                                   audioMode: .internet,
                                   height: Layout.commonCellHeight,
                                   pressHandler: { [weak self] in
                                        guard let self = self else {
                                            return
                                        }
                                        switch self.scene {
                                        case .preview:
                                            self.delegate?.didSelectedAudio(at: .system)
                                        case .inMeet(let meeting):
                                            self.pressAction(type: .internet)
                                            self.selectAudioMode(self.currentType ?? .internet, meeting: meeting)
                                        }
                                   }))
            }
            if item == .pstn {
                items.append(.init(subTitle: phoneNumber,
                                   isSelect: currentType == .pstn,
                                   isCalling: isCalling,
                                   audioMode: .pstn,
                                   height: hasPhone ? Layout.phoneCellHeight : Layout.commonCellHeight,
                                   pressHandler: { [weak self] in
                                        guard let self = self else {
                                            return
                                        }
                                        switch self.scene {
                                        case .preview:
                                            self.delegate?.didSelectedAudio(at: .pstn)
                                        case .inMeet(let meeting):
                                            self.pressAction(type: .pstn)
                                            self.selectAudioMode(self.currentType ?? .pstn, meeting: meeting)
                                        }
                                   }))
            }
            if item == .noConnect {
                items.append(.init(isSelect: currentType == .noConnect,
                                   audioMode: .noConnect,
                                   height: Layout.commonCellHeight,
                                   pressHandler: { [weak self] in
                                        guard let self = self else {
                                            return
                                        }
                                        switch self.scene {
                                        case .preview:
                                            self.delegate?.didSelectedAudio(at: .noConnect)
                                        case .inMeet(let meeting):
                                            self.pressAction(type: .noConnect)
                                            self.selectAudioMode(self.currentType ?? .noConnect, meeting: meeting)
                                        }
                                   }))
            }
        }
    }

    func pressAction(type: AudioMode) {
        currentType = type
        var click = ""
        switch type {
        case .unknown:
            click = ""
        case .internet:
            click = "system_audio"
        case .pstn:
            click = "call_me"
        case .noConnect:
            click = "unconnected_audio"
        }
        VCTracker.post(name: .vc_meeting_popup_click, params: [.click: click, .content: "change_audio"])
    }

    @objc
    func cancelAction() {
        VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "cancel", .content: "change_audio"])
        self.dismiss(animated: false, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AudioSelectCell",
                                                    for: indexPath) as? AudioSelectCell {
            cell.setModel(model: items[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row <= items.count {
            items[indexPath.row].pressHandler()  // 更新当前type
        }
        self.cancelAction()
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        cell.isHighlighted = true
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        cell.isHighlighted = false
    }
}

extension AudioSelectViewController: InMeetAudioModeListener {
    func beginPstnCalling() {
        changeCalling(true)
    }

    func closePstnCalling() {
        changeCalling(false)
    }

    private func changeCalling(_ isCalling: Bool) {
        items = items.map { item -> AudioSelectCellItem in
            var newItem: AudioSelectCellItem = item
            if item.audioMode == .pstn {
                newItem.isCalling = isCalling
            }
            return newItem
        }
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
        }
    }

    private func selectAudioMode(_ audioMode: ParticipantSettings.AudioMode, meeting: InMeetMeeting) {
        let oldAudioMode = meeting.audioMode
        let audioModeManager = meeting.audioModeManager
        if audioMode == oldAudioMode {
            return
        }

        if audioMode == .pstn && audioModeManager.isPstnCalling {  // 如果当前是pstn呼叫中，选择了pstn，则取消pstn
            audioModeManager.cancelPstnCall()
            return
        }

        Logger.callme.info("oldmode \(oldAudioMode) will——> newmode \(audioMode)")
        switch audioMode {
        case .internet:
            if oldAudioMode == .pstn {
                self.showCallmeAlert(content: I18n.View_MV_DeviceAudioHangUp_ConfirmPop, leftHandler: ({
                    VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "cancel", .content: "system_audio"])
                }), rightTitle: I18n.View_MV_DeviceAudioHangUp_PopContinue) { [weak audioModeManager] in
                    audioModeManager?.changeBizAudioMode(bizMode: .internet)
                    VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "confirm", .content: "system_audio"])
                }
            } else if oldAudioMode == .noConnect {
                if meeting.myself.settings.targetToJoinTogether != nil {
                    VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "room_to_mobile_mic"])
                    RoomAudioSelectViewModel.showAlert(for: .system, title: I18n.View_G_ConfirmSwitchSystemAudio, message: I18n.View_G_SwitchMayWhineCautionAnother,
                              rightTitle: I18n.View_MV_SwitchAudio_BarButton, rightHandler: { [weak audioModeManager] in
                        audioModeManager?.changeBizAudioMode(bizMode: .internet)
                    })
                } else {
                    ToolBarSwitchAudioItem.showSwitchAudioAlert(content: I18n.View_G_ConnectSystemAudioPop, message: I18n.View_G_ConnectSystemAudioPopExplain, leftHandler: {
                        VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "cancel", .content: "system_audio"])
                    }, rightTitle: I18n.View_G_ConnectSystemAudioButton, rightHandler: { [weak audioModeManager] in
                        VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "confirm", .content: "system_audio"])
                        audioModeManager?.changeBizAudioMode(bizMode: .internet)
                    })
                }
            } else {
                audioModeManager.changeBizAudioMode(bizMode: .internet)
            }
        case .pstn:
            if oldAudioMode == .noConnect && meeting.myself.settings.targetToJoinTogether != nil {
                VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "room_to_mobile_call"])
                RoomAudioSelectViewModel.showAlert(for: .callMe, title: I18n.View_G_ConfirmSwitchPhoneAudio, message: I18n.View_G_CallPhoneJoinDisconnectRoomAudio, rightTitle: I18n.View_MV_SwitchAudio_BarButton, rightHandler: { [weak audioModeManager] in
                    audioModeManager?.beginPstnCalling()
                })
            } else {
                audioModeManager.beginPstnCalling()
            }
        case .noConnect:
            self.showCallmeAlert(content: I18n.View_MV_DisconnectedCantHear_Pop, colorTheme: .redLight, leftHandler: ({
                VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "cancel", .content: "unconnected_audio"])
            }), rightTitle: I18n.View_MV_DisconnectedCantHear_PopDisconnect) { [weak audioModeManager] in
                audioModeManager?.changeBizAudioMode(bizMode: .noConnect)
                VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "confirm", .content: "unconnected_audio"])
            }
        default:
            break
        }
    }

    private func showCallmeAlert(content: String, colorTheme: ByteViewDialogConfig.ColorTheme = .defaultTheme, leftHandler: @escaping () -> Void, rightTitle: String, rightHandler: @escaping () -> Void) {
        ByteViewDialog.Builder()
            .id(.callme)
            .needAutoDismiss(true)
            .colorTheme(colorTheme)
            .title(content)
            .leftTitle(I18n.View_MV_CancelButtonTwo)
            .leftHandler({ _ in
                leftHandler()
            })
            .rightTitle(rightTitle)
            .rightHandler({ _ in
                rightHandler()
            })
            .show()
    }
}

extension AudioSelectViewController: PanChildViewControllerProtocol {

    var showBarView: Bool {
        false
    }

    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        return .contentHeight(contentHeight)
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone, axis == .landscape {
            return .maxWidth(width: 420)
        }
        return .fullWidth
    }
}
