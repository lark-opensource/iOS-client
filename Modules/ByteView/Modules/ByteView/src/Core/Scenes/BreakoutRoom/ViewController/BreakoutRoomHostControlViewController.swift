//
// Created by maozhixiang.lip on 2022/7/13.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewUI
import UniverseDesignIcon

class BreakoutRoomHostControlViewController: VMViewController<BreakoutRoomManager> {
    private let disposeBag = DisposeBag()

    private lazy var participantsView = BreakoutRoomParticipantsTableView()

    private lazy var endButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setAttributedTitle(NSAttributedString(string: I18n.View_MV_EndDiscussion, config: .h4), for: .normal)
        button.setTitleColor(.ud.functionDangerContentDefault, for: .normal)
        button.vc.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(.ud.udtokenBtnSeBgDangerHover, for: .highlighted)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.layer.ud.setBorderColor(.ud.functionDangerContentDefault)
        button.contentEdgeInsets = .init(top: 12, left: 16, bottom: 12, right: 16)
        button.addTarget(self, action: #selector(onTapEndButton), for: .touchUpInside)
        return button
    }()

    private lazy var endButtonContainer: UIView = {
        let view = UIView()
        view.addSubview(self.endButton)
        view.isHidden = true
        return view
    }()

    override func setupViews() {
        self.view.backgroundColor = .ud.bgFloat
        self.view.addSubview(participantsView)
        self.view.addSubview(endButtonContainer)
        self.updateLayout()
    }

    override func bindViewModel() {
        self.viewModel.hostControl.hostControlEnabled
            .drive(onNext: { [weak self] show in
                if !show { self?.dismiss(animated: true) }
            })
            .disposed(by: self.disposeBag)
        self.viewModel.hostControl.showEndButton
            .drive(onNext: { [weak self] show in
                self?.endButtonContainer.isHidden = !show
                self?.updateLayout()
            })
            .disposed(by: self.disposeBag)
        self.viewModel.hostControl.breakoutRooms
            .drive(onNext: { [weak self] rooms in
                self?.participantsView.breakoutRooms = rooms
                self?.participantsView.breakoutRoomManage = self?.viewModel
            })
            .disposed(by: self.disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = I18n.View_MV_RoomsTitle
        setNavigationBarBgColor(.ud.bgFloat)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }

    private func updateLayout() {
        if !self.endButtonContainer.isHidden {
            self.participantsView.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(VCScene.isRegular ? 0 : 8)
                make.left.right.equalToSuperview()
            }
            self.endButtonContainer.snp.remakeConstraints { make in
                make.top.equalTo(participantsView.snp.bottom)
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.view.safeAreaLayoutGuide)
            }
            self.endButton.snp.remakeConstraints { make in
                let insets: UIEdgeInsets = VCScene.isRegular
                    ? .init(top: 8, left: 147, bottom: 16, right: 147)
                    : .init(top: 8, left: 16, bottom: 8, right: 16)
                make.edges.equalToSuperview().inset(insets)
            }
        } else {
            self.endButtonContainer.snp.removeConstraints()
            self.endButton.snp.removeConstraints()
            self.participantsView.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(VCScene.isRegular ? 0 : 8)
                make.left.right.bottom.equalToSuperview()
            }
        }
    }

    @objc private func onTapEndButton() {
        let actionSheet = ActionSheetController(appearance: .init(
            backgroundColor: Display.pad ? UIColor.ud.bgFloat : UIColor.ud.bgBody,
            customTextHeight: 52,
            contentAlignment: .center
        ))
        actionSheet.addAction(SheetAction(
            title: I18n.View_G_CloseAllRoomsInfo,
            titleColor: UIColor.ud.textPlaceholder,
            titleFontConfig: .bodyAssist,
            handler: { _ in }
        ))
        actionSheet.addAction(SheetAction(
            title: I18n.View_MV_EndDiscussion,
            titleColor: UIColor.ud.functionDangerContentDefault,
            titleFontConfig: .h4,
            handler: { [weak self] _ in self?.viewModel.end() }
        ))
        actionSheet.addAction(SheetAction(
            title: I18n.View_G_CancelButton,
            sheetStyle: .cancel,
            handler: { _ in }
        ))
        actionSheet.modalPresentation = .popover
        let popoverConfig = DynamicModalPopoverConfig(sourceView: self.endButton,
                                                      sourceRect: self.endButton.bounds,
                                                      backgroundColor: UIColor.ud.bgBody,
                                                      popoverSize: actionSheet.padContentSize,
                                                      permittedArrowDirections: .down)
        let regularConfig = DynamicModalConfig(presentationStyle: .popover,
                                               popoverConfig: popoverConfig,
                                               backgroundColor: .clear)
        let compactConfig = DynamicModalConfig(presentationStyle: .pan)
        viewModel.meeting.router.presentDynamicModal(actionSheet, regularConfig: regularConfig, compactConfig: compactConfig)
        // TODO: @huangtao.ht C->R有概率tableView无法展示，autoLayout问题
    }
}

class BreakoutRoomParticipantsTableView: BaseTableView, UITableViewDataSource, UITableViewDelegate {
    typealias RoomModel = BreakoutRoomHostControlViewModel.BreakoutRoomModel
    typealias ParticipantModel = BreakoutRoomHostControlViewModel.BreakoutRoomParticipantModel

    var breakoutRoomManage: BreakoutRoomManager?
    var breakoutRooms: [RoomModel] = [] {
        didSet {
            self.reloadData()
        }
    }

    init() {
        super.init(frame: .zero, style: .grouped)
        self.delegate = self
        self.dataSource = self
        self.register(cellType: TableCell.self)
        self.register(viewType: TableSectionHeader.self)
        self.rowHeight = 64
        self.sectionHeaderHeight = 40
        self.sectionFooterHeight = 8
        self.separatorStyle = .none
        self.backgroundColor = UIColor.ud.bgFloat
        self.delaysContentTouches = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        self.breakoutRooms.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.breakoutRooms[section].visibleParticipants.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.deselectRow(at: indexPath, animated: false)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let meeting = self.breakoutRoomManage?.meeting else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withType: TableCell.self, for: indexPath)
        let participant = self.breakoutRooms[indexPath.section].visibleParticipants[indexPath.row]
        cell.configure(participant, meeting)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withType: TableSectionHeader.self) else { return nil }
        guard let roomManager = self.breakoutRoomManage else { return nil }
        header.configure(roomManager, self.breakoutRooms[section], onToggleExpand: { [weak self] in
            guard let self = self else { return }
            self.breakoutRooms[section].expanded.toggle()
            UIView.performWithoutAnimation {
                self.reloadSections(IndexSet(integer: section), with: .none)
            }
        })
        return header
    }

    private class TableCell: InMeetParticipantCell {
        private lazy var needHelpView: UIView = {
            let container = UIView()
            let needHelpView = NeedHelpLabelView()
            container.addSubview(needHelpView)
            needHelpView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(8)
            }
            return container
        }()

        private lazy var notInRoomTag: UIView = {
            let label = PaddingLabel()
            label.textInsets = .init(top: 0, left: 4, bottom: 0, right: 0)
            label.attributedText = .init(string: I18n.View_G_NotJoined_Status, config: .h4)
            label.textColor = UIColor.ud.textPlaceholder
            return label
        }()

        override func loadSubViews() {
            super.loadSubViews()
            statusStack(add: [needHelpView])
            nameStack(add: [notInRoomTag])
        }

        func configure(_ participant: ParticipantModel, _ meeting: InMeetMeeting) {
            super.configure(with: participant.toInMeetParticipantCellModel(meeting))
            super.rightStackView.isHidden = true
            self.needHelpView.isHidden = !participant.needHelp
            self.notInRoomTag.isHidden = !participant.isNotInRoom
        }
    }

    private class TableSectionHeader: UITableViewHeaderFooterView {
        private static let expandIconSize = CGSize(width: 12, height: 12)
        private lazy var iconExpandDown = UDIcon.getIconByKey(.expandDownFilled, iconColor: UIColor.ud.iconN2, size: .init(width: 12, height: 12))
        private lazy var iconExpandRight = UDIcon.getIconByKey(.expandRightFilled, iconColor: UIColor.ud.iconN2, size: .init(width: 12, height: 12))

        private lazy var iconView: UIImageView = {
            let image = UIImageView()
            return image
        }()

        private lazy var topicLabel: UILabel = {
            let label = UILabel()
            label.attributedText = NSAttributedString(string: "", config: .boldBodyAssist)
            label.textColor = UIColor.ud.textCaption
            return label
        }()

        private lazy var participantsNumLabel: UILabel = {
            let label = UILabel()
            label.attributedText = NSAttributedString(string: "", config: .bodyAssist)
            label.textColor = UIColor.ud.textCaption
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            return label
        }()

        private lazy var needHelpLabel = NeedHelpLabelView()

        private lazy var actionButton: ParticipantButton = {
            let b = ParticipantButton(style: .none)
            b.touchUpInsideAction = { [weak self] in
                self?.didTapActionButton()
            }
            return b
        }()

        private lazy var leftContainer: UIView = {
            let container = UIView()
            container.addSubview(self.iconView)
            container.addSubview(self.topicLabel)
            container.addSubview(self.participantsNumLabel)
            container.addSubview(self.needHelpLabel)
            self.iconView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview()
            }
            self.topicLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(self.iconView.snp.right).offset(8)
            }
            self.updateNeedHelpLabelLayout()
            let tapGesture = UITapGestureRecognizer()
            tapGesture.addTarget(self, action: #selector(toggleExpand))
            container.addGestureRecognizer(tapGesture)
            return container
        }()

        private lazy var rightContainer: UIView = {
            let container = UIView()
            container.addSubview(self.actionButton)
            self.actionButton.snp.makeConstraints { make in
                make.left.right.centerY.equalToSuperview()
            }
            return container
        }()

        private lazy var contentContainer: UIView = {
            let container = UIView()
            container.addSubview(self.leftContainer)
            container.addSubview(self.rightContainer)
            self.leftContainer.snp.makeConstraints { make in
                make.top.bottom.left.equalToSuperview()
            }
            self.rightContainer.snp.makeConstraints { make in
                make.top.bottom.right.equalToSuperview()
                make.left.equalTo(self.leftContainer.snp.right).offset(8)
            }
            return container
        }()

        private func updateNeedHelpLabelLayout() {
            if self.needHelpLabel.isHidden {
                self.participantsNumLabel.snp.remakeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.left.equalTo(self.topicLabel.snp.right).offset(4)
                    make.right.lessThanOrEqualToSuperview()
                }
                self.needHelpLabel.snp.removeConstraints()
            } else {
                self.participantsNumLabel.snp.remakeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.left.equalTo(self.topicLabel.snp.right).offset(4)
                }
                self.needHelpLabel.snp.remakeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.left.equalTo(self.participantsNumLabel.snp.right).offset(8)
                    make.right.lessThanOrEqualToSuperview()
                }
            }
        }

        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)
            self.contentView.addSubview(self.contentContainer)
            self.contentContainer.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(40)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private var onToggleExpand: (() -> Void)?
        private var onTapActionButton: (() -> Void)?
        private var isNeedHelpLabelHidden = false {
            didSet {
                guard isNeedHelpLabelHidden != oldValue else { return }
                self.needHelpLabel.isHidden = isNeedHelpLabelHidden
                self.updateNeedHelpLabelLayout()
            }
        }

        func configure(_ manager: BreakoutRoomManager, _ room: RoomModel, onToggleExpand: (() -> Void)?) {
            let myself = manager.meeting.myself
            self.iconView.image = room.expanded ? self.iconExpandDown : self.iconExpandRight
            self.topicLabel.text = room.topic
            self.participantsNumLabel.text = "(\(room.participantCount))"
            self.isNeedHelpLabelHidden = room.expanded || !room.needHelp
            self.onToggleExpand = onToggleExpand
            self.actionButton.isHidden = !room.isOnTheCall
            if room.isOnTheCall {
                if myself.breakoutRoomId == room.id {
                    self.updateActionButton(.leave) {
                        manager.leave()
                        BreakoutRoomTracksV2.trackHostControlClick(manager.meeting, .leaveRoom)
                    }
                } else {
                    self.updateActionButton(.join) {
                        manager.join(breakoutRoomID: room.id)
                        BreakoutRoomTracksV2.trackHostControlClick(manager.meeting, .joinRoom)
                    }
                }
            }
        }

        private func updateActionButton(_ style: ParticipantButton.Style, action: @escaping () -> Void) {
            self.onTapActionButton = action
            self.actionButton.style = style
        }

        @objc private func toggleExpand() {
            self.onToggleExpand?()
        }

        private func didTapActionButton() {
            self.onTapActionButton?()
        }
    }

    private class NeedHelpLabelView: UIView {
        private var iconView: UIImageView = {
            let icon = UIImageView()
            icon.image = UDIcon.getIconByKey(.maybeOutlined, iconColor: UIColor.ud.iconN3, size: .init(width: 16, height: 16))
            return icon
        }()

        private var textLabel: UILabel = {
            let label = UILabel()
            label.attributedText = NSAttributedString(string: I18n.View_G_AskForHelp_Tag, config: .bodyAssist)
            label.textColor = UIColor.ud.textPlaceholder
            return label
        }()

        init() {
            super.init(frame: .zero)
            self.addSubview(iconView)
            self.addSubview(textLabel)
            self.iconView.snp.makeConstraints { make in
                make.left.centerY.equalToSuperview()
            }
            self.textLabel.snp.makeConstraints { make in
                make.top.bottom.right.equalToSuperview()
                make.left.equalTo(self.iconView.snp.right).offset(2)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
