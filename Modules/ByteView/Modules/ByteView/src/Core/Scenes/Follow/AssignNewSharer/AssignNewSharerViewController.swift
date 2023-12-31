//
//  AssignNewSharerViewController.swift
//  ByteView
//
//  Created by liurundong.henry on 2019/10/29.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewUI
import RxDataSources
import ByteViewNetwork
import UniverseDesignIcon

class AssignNewSharerViewController: PuppetPresentedViewController {

    var isIPadLayout: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    // 使用私有的串行队列执行所有宽度计算，防止参会人频繁变动时size设置发生时序问题
    private let widthCalculationScheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
    // 记录participants到达的顺序，当频繁更新时使用sequenceID来避免不必要的size计算和UI更新
    private var sequenceID: Int = 0

    struct Layout {
        static let rowHeight: CGFloat = 66.0
        static let iPadRowHeight: CGFloat = 68.0
        static let minPopoverWidth: CGFloat = 200.0
        static let maxPopoverWidth: CGFloat = 375.0
        static let emptyPopoverWidth: CGFloat = 263.0
        static let emptyPopoverHeight: CGFloat = rowHeight
        static let emptyLabelHeight: CGFloat = 20.0
        static let emptyLabelLeftOffset: CGFloat = 16.0
        static let emptyLabelBottomOffset: CGFloat = 18.0
        static let phoneLandscapeMaxWidth: CGFloat = 420.0
    }

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_VM_PassOnSharing
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    let saperateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    lazy var participantsTableView: BaseTableView = {
        let tableView = BaseTableView(frame: CGRect.zero, style: .plain)
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = Layout.rowHeight
        tableView.register(AssignNewSharerCell.self,
                           forCellReuseIdentifier: String(describing: AssignNewSharerCell.self))
        return tableView
    }()

    lazy var barCloseButton: UIButton = {
        let button = UIButton(type: .custom)
        let size = CGSize(width: 18, height: 18)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN1, size: size),
                        for: .normal)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN3, size: size),
                        for: .highlighted)
        button.addTarget(
            self,
            action: #selector(dismissNavigationViewController),
            for: .touchUpInside
        )
        return button
    }()

    let viewModel: AssignNewSharerViewModel
    init(viewModel: AssignNewSharerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgBody
        setNavigationBar()
        setupViews()
        bindViewModel()
    }

    private func setNavigationBar() {
        title = I18n.View_VM_PassOnSharing
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.leftBarButtonItem = nil
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // disable-lint: duplicated code
    func setupViews() {
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16.0)
            make.top.equalToSuperview()
            make.height.equalTo(44.0)
        }

        view.addSubview(saperateLine)
        saperateLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom)
            make.height.equalTo(0.5)
        }

        view.addSubview(barCloseButton)
        barCloseButton.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16.0)
            maker.top.equalToSuperview().offset(21.0)
            maker.size.equalTo(18.0)
        }

        view.addSubview(participantsTableView)
        participantsTableView.snp.makeConstraints { (make) in
            make.top.equalTo(saperateLine.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    // enable-lint: duplicated code

    func bindViewModel() {
        viewModel.cellModels
            .bind(to: participantsTableView.rx
                .items(cellIdentifier: String(describing: AssignNewSharerCell.self))) { _, model, cell in
                    if let participantCell = cell as? AssignNewSharerCell {
                        participantCell.update(with: model)
                    }
                }.disposed(by: rx.disposeBag)

        viewModel.isSelfSharingObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isSharing) in
                if !isSharing {
                    self?.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            }).disposed(by: rx.disposeBag)

        participantsTableView.rx.modelSelected(AssignNewSharerCellModel.self)
            .subscribe(onNext: { [weak self] cellModel in
                guard let self = self else { return }
                let beFollowPresenter = cellModel.participant.capabilities.followPresenter
                let userProduceStgIds = cellModel.participant.capabilities.followProduceStrategyIds
                let documentStgs = self.viewModel.remoteDocument.strategies
                var documentStgIds: [String] = []
                for docStg in documentStgs {
                    documentStgIds.append(docStg.id)
                }
                let isStgContain = documentStgIds.allSatisfy { userProduceStgIds.contains($0) }
                let isDoc = self.viewModel.remoteDocument.shareSubType == .ccmDoc
                InMeetFollowViewModel.logger.debug("""
                    beFollowPresenter: \(beFollowPresenter)
                    isStgContain: \(isStgContain)
                    userProduceStgIds: \(userProduceStgIds)
                    documentStgIds: \(documentStgIds)
                    """)
                if beFollowPresenter && (isStgContain || isDoc) {
                    self.showAlert(with: cellModel.participant)
                } else {
                    Toast.show(I18n.View_VM_UserCannotShare)
                }
            }).disposed(by: rx.disposeBag)

        participantsTableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.participantsTableView.deselectRow(at: indexPath, animated: true)
            }).disposed(by: rx.disposeBag)

        // ipad和iphone布局模式有一些区别，在转换时需要remake layout
        isIPadLayout
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.remakeLayout()
            }).disposed(by: rx.disposeBag)
    }

    func remakeLayout() {
        if isIPadLayout.value {
            titleLabel.textAlignment = .center
            saperateLine.isHidden = true
            barCloseButton.isHidden = false
            titleLabel.snp.updateConstraints { (maker) in
                maker.height.equalTo(62.0)
            }
            participantsTableView.rowHeight = Layout.iPadRowHeight
        } else {
            titleLabel.textAlignment = .left
            saperateLine.isHidden = false
            barCloseButton.isHidden = true
            titleLabel.snp.updateConstraints { (maker) in
                maker.height.equalTo(44.0)
            }
            participantsTableView.rowHeight = Layout.rowHeight
        }
        participantsTableView.reloadData()
    }

    func showAlert(with participant: Participant) {
        let meeting = self.viewModel.meeting
        let cancelText = I18n.View_G_CancelButton
        let confirmText = I18n.View_G_ConfirmButton
        weak var assignNewSharerConfirmAlertController: ByteViewDialog?
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pid: participant, meetingId: meeting.meetingId) { [weak self] ap in
            guard let self = self else { return }
            let userName = ap.name
            let titleText = I18n.View_VM_AssignToShareQuestionNameBraces(userName)
            ByteViewDialog.Builder()
                .id(.assignOtherToShare)
                .title(titleText)
                .message(nil)
                .leftTitle(cancelText)
                .rightTitle(confirmText)
                .rightHandler({ [weak self] _ in
                    guard let strongSelf = self else { return }
                    let document = strongSelf.viewModel.remoteDocument
                    MagicShareTracks.trackAssignPresent(to: participant.user,
                                                        subType: document.shareSubType.rawValue,
                                                        followType: document.shareType.rawValue,
                                                        shareId: document.shareID,
                                                        token: document.token)
                    MagicShareTracksV2.trackAssignPresenter(user: participant.user, isSharer: true)
                    strongSelf.viewModel.meeting.httpClient.follow.transferSharer(
                        strongSelf.viewModel.currentDocumentURL,
                        meetingId: meeting.meetingId,
                        sharer: participant,
                        breakoutRoomId: meeting.data.breakoutRoomId) { result in
                            switch result {
                            case .success:
                                Util.runInMainThread {
                                    self?.presentingViewController?.dismiss(animated: true, completion: nil)
                                }
                            case .failure:
                                Self.logger.debug("assign new sharer failed")
                            }
                        }
                })
                .show { alert in
                    assignNewSharerConfirmAlertController = alert
                }
            Disposables.create {
                DispatchQueue.main.async {
                    assignNewSharerConfirmAlertController?.dismiss()
                    assignNewSharerConfirmAlertController = nil
                }
            }
            .disposed(by: self.rx.disposeBag)
        }
    }

    @objc private func dismissNavigationViewController() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

extension AssignNewSharerViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        self.isIPadLayout.accept(isRegular)
    }
}

extension AssignNewSharerViewController: PanChildViewControllerProtocol {

    func height(
        _ axis: RoadAxis,
        layout: RoadLayout
    ) -> PanHeight {
        let maxHeight = VCScene.bounds.height - VCScene.safeAreaInsets.top - 60
        let itemHeight = 56 + CGFloat(66 * viewModel.participantCountRelay.value) + VCScene.safeAreaInsets.bottom
        return .contentHeight(min(maxHeight, itemHeight))
    }

    var defaultLayout: RoadLayout {
        return .shrink
    }

    var panScrollable: UIScrollView? {
        return participantsTableView
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone, axis == .landscape {
            return .maxWidth(width: Layout.phoneLandscapeMaxWidth)
        }
        return .fullWidth
    }

}
