//
//  EnterpriseCallViewController.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/7/1.
//

import UIKit
import UniverseDesignIcon
import ByteViewTracker
import ByteViewMeeting
import UniverseDesignColor
import ByteViewUI
import ByteViewCommon
import LarkMedia

class EnterpriseCallViewController: VMViewController<EnterpriseCallViewModel>, UICollectionViewDataSource, UICollectionViewDelegate {

    private static let cellID = "PhoneCallCellID"
    private static let buttonSize: CGFloat = Display.iPhoneMaxSeries ? 82 : 76

    lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 24, height: 24)), for: .highlighted)
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        return button
    }()

    let usernameLabel: FloatingLabel = {
        let label = FloatingLabel()
        label.textColor = UIColor.ud.textTitle
        label.waitInterval = 3.0
        label.loggingDist = 40
        label.shadowLength = 4
        label.animationSpd = 40
        return label
    }()

    let avatarView = AvatarView()

    let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: EnterpriseCallItemCell.Layout.itemWidth, height: EnterpriseCallItemCell.Layout.itemHeight)
        layout.minimumInteritemSpacing = 32
        layout.minimumLineSpacing = 2
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(EnterpriseCallItemCell.self, forCellWithReuseIdentifier: Self.cellID)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    lazy var hangupButton: UIButton = {
        let button = UIButton()
        button.vc.setBackgroundColor(UIColor.ud.functionDangerContentDefault, for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 36
        let size = Display.iPhoneMaxSeries ? 36 : 32
        button.setImage(UDIcon.getIconByKey(.callEndFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: size, height: size)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.callEndFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: size, height: size)), for: .disabled)
        button.addTarget(self, action: #selector(hangup), for: .touchUpInside)
        return button
    }()

    lazy var hideDialButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_VM_Hide, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed, for: .highlighted)
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(hideDiaPad), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    lazy var directDialView: EnterpriseCallDialView = {
        let view = EnterpriseCallDialView(viewModel: viewModel)
        view.isHidden = true
        return view
    }()

    var tapNumberBlock: ((String, String) -> Void)?

    // MARK: - Overrides

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ProximityMonitor.updateAudioOutput(route: viewModel.session.audioDevice?.output.currentOutput ?? LarkAudioSession.shared.currentOutput, isMuted: false)
        ProximityMonitor.start(isPortrait: !VCScene.isLandscape)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ProximityMonitor.stop()
    }

    deinit {
        ProximityMonitor.stop()
        Logger.enterpriseCall.info("EnterpriseCallViewController deinit")
        viewModel.meeting?.syncChecker.unregisterMicrophone(self)
    }

    override func setupViews() {
        super.setupViews()
        view.backgroundColor = UIColor.ud.bgBody

        let infoViewTopOffset: CGFloat
        let collectionViewTopOffset: CGFloat
        let hangupButtonTopOffset: CGFloat
        let buttonSize: CGFloat
        let dialBottomMargin: CGFloat

        let displayType = Display.typeIsLike
        if displayType < Display.DisplayType.iPhone6 {
            infoViewTopOffset = 10
            collectionViewTopOffset = 48
            hangupButtonTopOffset = 22
            buttonSize = 64
            dialBottomMargin = 8
        } else if displayType < Display.DisplayType.iPhoneX {
            infoViewTopOffset = 14
            collectionViewTopOffset = 58
            hangupButtonTopOffset = 80
            buttonSize = 72
            dialBottomMargin = 20
        } else if Display.iPhoneMaxSeries {
            infoViewTopOffset = Display.typeIsLike == .iPhoneXR ? 46 : 36
            collectionViewTopOffset = 129
            hangupButtonTopOffset = Display.typeIsLike == .iPhoneXR ? 92 : 102
            buttonSize = 82
            dialBottomMargin = Display.typeIsLike == .iPhoneXR ? 24 : 34
        } else {
            infoViewTopOffset = 26
            collectionViewTopOffset = 110
            hangupButtonTopOffset = 80
            buttonSize = 72
            dialBottomMargin = 20
        }
        avatarView.setAvatarInfo(viewModel.avatarInfo)
        hangupButton.layer.cornerRadius = buttonSize / 2

        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.size.equalTo(24)
        }

        // autolayout auto sizing
        let callingInfoView = UIView()
        view.addSubview(callingInfoView)
        callingInfoView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(52)
            make.top.equalTo(backButton.snp.bottom).offset(infoViewTopOffset)
        }


        avatarView.layer.masksToBounds = true
        avatarView.layer.cornerRadius = 30
        callingInfoView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.size.equalTo(60)
        }

        callingInfoView.addSubview(usernameLabel)

        callingInfoView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.left.right.equalTo(usernameLabel)
            make.top.equalTo(usernameLabel.snp.bottom).offset(8)
            make.height.equalTo(22)
            make.bottom.equalToSuperview()
        }

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(callingInfoView.snp.bottom).offset(collectionViewTopOffset)
            make.width.equalTo(Display.iPhoneMaxSeries ? 310 : 280)
            make.height.equalTo(Display.iPhoneMaxSeries ? 270 : 248)
        }

        view.addSubview(hangupButton)
        hangupButton.snp.makeConstraints { make in
            make.size.equalTo(buttonSize)
            make.centerX.equalToSuperview()
            make.top.equalTo(collectionView.snp.bottom).offset(hangupButtonTopOffset)
        }

        view.addSubview(directDialView)
        directDialView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(hangupButton.snp.top).offset(-dialBottomMargin)
            make.height.equalTo(directDialView.viewHeight)
            make.width.equalToSuperview()
        }

        view.addSubview(hideDialButton)
        hideDialButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 64, height: 24))
            make.centerY.equalTo(hangupButton)
            make.left.equalTo(hangupButton.snp.right).offset(36)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        directDialView.tapBlock = { [weak self] (_: String, totalNum: String) in
            guard let self = self else { return }
            self.showDialNumber(totalNum: totalNum)
        }
        viewModel.delegate = self
        viewModel.updateInfo = { [weak self] in
            self?.updateCallingInfoView()
            if let avatarInfo = self?.viewModel.avatarInfo {
                self?.avatarView.setAvatarInfo(avatarInfo)
            }
        }
        statusTextDidChange(viewModel.statusText)
        updateCallingInfoView()
        collectionView.reloadData()
        viewModel.meeting?.syncChecker.registerMicrophone(self)

        viewModel.speakerItem.action = { [weak self] in
            self?.didClickSpeaker()
        }
    }

    private func updateCallingInfoView() {
        guard hideDialButton.isHidden else { return }
        switch viewModel.handle {
        case .userID, .ipPhoneBindLark:
            avatarView.isHidden = false
            statusLabel.textAlignment = .left
            usernameLabel.attributedText = NSAttributedString(string: viewModel.userName ?? "", config: VCFontConfig(fontSize: 32, lineHeight: 34, fontWeight: .medium), alignment: .left)
            usernameLabel.textAlignment = .left
            usernameLabel.snp.remakeConstraints { make in
                make.left.equalTo(avatarView.snp.right).offset(10)
                make.width.equalTo(208)
                make.top.equalToSuperview()
                make.height.equalTo(34)
            }
        case .enterprisePhoneNumber(let phoneNumber), .recruitmentPhoneNumber(let phoneNumber), .ipPhone(let phoneNumber):
            avatarView.isHidden = true
            statusLabel.textAlignment = .center
            let formatted = PhoneNumberUtil.format(phoneNumber) ?? phoneNumber
            usernameLabel.attributedText = NSAttributedString(string: formatted, config: VCFontConfig(fontSize: 32, lineHeight: 34, fontWeight: .semibold), alignment: .center)
            usernameLabel.textAlignment = .center
            usernameLabel.policy = .ellision
            usernameLabel.snp.remakeConstraints { make in
                make.left.equalToSuperview()
                make.width.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(34)
            }
        case .candidateID:
            avatarView.isHidden = false
            statusLabel.textAlignment = .left
            let userId = viewModel.session.userId
            let p = viewModel.session.videoChatInfo?.participants.first(where: { $0.user.id != userId })
            usernameLabel.attributedText = NSAttributedString(string: p?.settings.nickname ?? "", config: VCFontConfig(fontSize: 32, lineHeight: 34, fontWeight: .semibold), alignment: .left)
            usernameLabel.textAlignment = .left
            usernameLabel.snp.remakeConstraints { make in
                make.left.equalTo(avatarView.snp.right).offset(10)
                make.right.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(34)
            }
        }
    }

    private func showDialNumber(totalNum: String) {
        self.usernameLabel.attributedText = NSAttributedString(string: totalNum, config: VCFontConfig(fontSize: 32, lineHeight: 34, fontWeight: .semibold), alignment: .center, lineBreakMode: .byTruncatingHead)
        self.avatarView.isHidden = true
        self.statusLabel.isHidden = true
        self.usernameLabel.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(34)
        }
    }

    private func updateDialData() {
        if let identifier = viewModel.calledParticpant?.identifier {
            viewModel.meeting?.participantDialData.saveData.updateValue(directDialView.dialTotalNumber, forKey: identifier)
        }
    }

    // MARK: - Actions
    @objc private func handleBack() {
        updateDialData()
        viewModel.service.router.setWindowFloating(true)
        let callParams = getCallParamsTrack()
        VCTracker.post(name: .vc_office_phone_calling_click,
                       params: [.click: "return", "status": viewModel.trackParam().0, "is_link_bluetooth": viewModel.trackParam().1, "user_type": callParams.0, "call_source": callParams.1 ])
    }

    @objc private func hangup() {
        viewModel.hangup()
        let callParams = getCallParamsTrack()
        VCTracker.post(name: .vc_office_phone_calling_click,
                       params: [.click: "hang_up", "status": viewModel.trackParam().0, "is_link_bluetooth": viewModel.trackParam().1, "user_type": callParams.0, "call_source": callParams.1 ])
    }

    @objc private func hideDiaPad() {
        collectionView.isHidden = false
        directDialView.isHidden = true
        hideDialButton.isHidden = true
        statusLabel.isHidden = false
        updateCallingInfoView()
    }

    @objc private func didClickSpeaker() {
        viewModel.shouldChangeSpeakerIcon = true
        viewModel.session.audioDevice?.output.showPicker(scene: .phoneCall, from: self)
    }

    private func getCallParamsTrack() -> (String, String) {
        let userType = viewModel.session.videoChatInfo?.inviterId == viewModel.session.userId ? "caller" : "callee"
        switch viewModel.handle {
        case .enterprisePhoneNumber, .recruitmentPhoneNumber, .userID, .candidateID:
            return (userType, "office_call")
        case .ipPhone, .ipPhoneBindLark:
            return (userType, "ip_phone")
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellID, for: indexPath) as? EnterpriseCallItemCell else {
            return UICollectionViewCell()
        }
        cell.update(with: viewModel.items[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        viewModel.items[indexPath.row].throttledAction(())
    }
}

extension EnterpriseCallViewController: EnterpriseCallViewModelDelegate {
    func statusTextDidChange(_ text: String) {
        let alignment: NSTextAlignment
        switch viewModel.handle {
        case .enterprisePhoneNumber, .ipPhone, .recruitmentPhoneNumber: alignment = .center
        case .userID, .candidateID, .ipPhoneBindLark: alignment = .left
        }
        statusLabel.attributedText = NSAttributedString.init(string: text, config: .body, alignment: alignment)
    }

    func meetingStateDidChange(_ state: MeetingState) {
        collectionView.reloadData()
        updateCallingInfoView()
    }

    func directItemsDidChange() {
        collectionView.reloadData()
    }

    func didTapDiaPad() {
        self.collectionView.isHidden = true
        self.directDialView.isHidden = false
        self.hideDialButton.isHidden = false
    }

    func didUpdateMeeting() {
        updateDialData()
    }

    func didChangeMuteBeforeOntheCall(isMute: Bool) {
        Toast.showOnVCScene(isMute ? I18n.View_VM_MicOff : I18n.View_VM_MicOn)
    }

    func didChangeAudioput(audioOutput: AudioOutput) {
        Toast.showOnVCScene(audioOutput.i18nText)
    }
}

extension EnterpriseCallViewController: MicrophoneStateRepresentable {
    var isMicMuted: Bool? {
        // 保证监控直接取自 UI 层，避免 viewModel 内状态变更未同步到 UI 导致隐私问题且监控不到
        if let micCell = collectionView.visibleCells.compactMap({ $0 as? EnterpriseCallItemCell }).first(where: { $0.item === viewModel.micItem }) {
            return micCell.iconType != EnterpriseCallViewModel.micOnIcon
        }
        return nil
    }

    var micIdentifier: String {
        "PhoneCallMic"
    }
}
