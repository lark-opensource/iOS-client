//
//  InMeetingParticipantGridCell.swift
//  ByteView
//
//  Created by Prontera on 2020/11/3.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import RichLabel
import RxSwift
import UniverseDesignShadow
import ByteViewCommon
import ByteViewNetwork

protocol InMeetingParticipantGridCellDelegate: AnyObject {
    func didSingleTapContent(cellVM: InMeetGridCellViewModel, isSingleVideoEnabled: Bool, cell: UICollectionViewCell)

    func didDoubleTapContent(participant: Participant, isSingleVideoEnabled: Bool, from view: UIView, avatarView: UIView)

    func didTapCancelInvite(participant: Participant)

    func didTapMoreSelection(cellVM: InMeetGridCellViewModel, isFullscreen: Bool, isSingleVideoEnabled: Bool, from view: UIView, avatarView: UIView)

    func didTapUserName(participant: Participant)
}


class InMeetingParticipantGridCell: UICollectionViewCell {
    static var instanceCount = 0
    static var instanceCountErrorTracked = false

    private static let logger = Logger.ui

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    weak var delegate: InMeetingParticipantGridCellDelegate?

    var disposeBag = DisposeBag()

    let participantView: InMeetingParticipantView = {
        let view = InMeetingParticipantView()
        view.shouldShowSwitchCamera = true
        return view
    }()

    lazy var activeSpeakerBorder: InMeetingParticipantActiveSpeakerView = {
        let view = InMeetingParticipantActiveSpeakerView()
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        Self.instanceCount += 1
        if Self.instanceCount > 30 && !Self.instanceCountErrorTracked {
            Self.instanceCountErrorTracked = true
            let msg = "ParticipantGridCell instance count \(Self.instanceCount)"
            Self.logger.error(msg)
            BizErrorTracker.trackBizError(key: .gridCellCount, msg)
        }
        setUpUI()
        bindActions()
    }

    deinit {
        Self.instanceCount -= 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isTalking: Bool = false {
        didSet {
            guard oldValue != isTalking else {
                return
            }
            updateASBorderVisibility()
        }
    }

    var activeSpeakerAlwaysHidden = false {
        didSet {
            guard oldValue != activeSpeakerAlwaysHidden else {
                return
            }
            updateASBorderVisibility()
        }
    }
    func updateASBorderVisibility() {
        activeSpeakerBorder.isHidden = !isTalking || activeSpeakerAlwaysHidden
    }

    private func setUpUI() {
        contentView.backgroundColor = UIColor.clear
        contentView.addSubview(participantView)
        contentView.addSubview(activeSpeakerBorder)

        let doubleTapGesture = UIShortTapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        self.participantView.streamRenderView.addGestureRecognizer(doubleTapGesture)
        self.participantView.isCellVisible = false
        let singleTapGesture = UIFullScreenGestureRecognizer(target: self, action: #selector(singleTap))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        contentView.addGestureRecognizer(singleTapGesture)
        singleTapGesture.require(toFail: doubleTapGesture)
        makeConstraints()
    }

    private func makeConstraints() {

        activeSpeakerBorder.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(-2.0)
        }

        participantView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func bindActions() {

        participantView.didTapCancelButton = { [weak self] participant in
            self?.delegate?.didTapCancelInvite(participant: participant)
        }

        participantView.didTapMoreSelectionButton = { [weak self] (cellVM, isFullscreen) in
            guard let self = self else {
                return
            }
            self.delegate?.didTapMoreSelection(cellVM: cellVM,
                                               isFullscreen: isFullscreen,
                                               isSingleVideoEnabled: self.isSingleVideoEnabled,
                                               from: self.participantView,
                                               avatarView: self.participantView.avatar)
        }

        participantView.didTapUserName = { [weak self] participant in
            self?.delegate?.didTapUserName(participant: participant)
        }
    }

    var cellViewModel: InMeetGridCellViewModel? {
        return participantView.cellViewModel
    }

    var rtcUid: RtcUID? {
        return cellViewModel?.participant.value.rtcUid
    }

    var deviceId: String? {
        return cellViewModel?.pid.deviceId
    }

    var moreButtonPoint: CGPoint {
        let frame = participantView.moreSelectionButton.frame
        return participantView.convert(CGPoint(x: frame.midX, y: frame.midY), to: nil)
    }

    func reloadImageInfo() {
        participantView.reloadImageInfo()
    }

    @objc private func singleTap() {
        if let cellVM = self.cellViewModel {
            self.delegate?.didSingleTapContent(cellVM: cellVM, isSingleVideoEnabled: self.isSingleVideoEnabled, cell: self)
        }
    }

    @objc private func doubleTap() {
        if let participant = self.cellViewModel?.participant.value {
            self.delegate?.didDoubleTapContent(participant: participant,
                                               isSingleVideoEnabled: self.isSingleVideoEnabled,
                                               from: participantView,
                                               avatarView: participantView.avatar)
        }
    }

    var isSingleVideoEnabled: Bool {
        guard let participant = self.cellViewModel?.participant.value else {
            return false
        }
        return self.participantView.styleConfig.isSingleVideoEnabled && participant.status == .onTheCall
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {

        super.apply(layoutAttributes)
        self.layer.shadowColor = nil
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 0
        self.layer.shadowOpacity = 0

        participantView.viewSize = layoutAttributes.size

        // Pad 沉浸态下存在透明度，无法使用离屏渲染优化
        if Display.pad,
           cellViewModel?.context.meetingLayoutStyle != .tiled {
            participantView.offscreenOptimiseEnable = false
        } else {
            participantView.offscreenOptimiseEnable = true
        }

        if let layout = layoutAttributes as? InMeetingCollectionViewLayoutAttributes {
            participantView.streamRenderView.viewCount = layout.viewCount
            participantView.styleConfig = layout.styleConfig
            assert(layout.multiResSubscribeConfig.isValid, "MultiResolutionConfig is not initialized")
            participantView.streamRenderView.multiResSubscribeConfig = layout.multiResSubscribeConfig
            activeSpeakerBorder.roundedRadius = 8
            switch layout.style {
            case .fill:
                participantView.streamRenderView.isMini = false
            case .fillSquare:
                participantView.streamRenderView.isMini = false
            case .half:
                participantView.streamRenderView.isMini = false
            case .newHalf:
                participantView.streamRenderView.isMini = false
            case .quarter:
                participantView.streamRenderView.isMini = true
            case .third:
                participantView.streamRenderView.isMini = true
            case .sixth:
                participantView.streamRenderView.isMini = true
            case .singleRow, .singleRowSquare:
                participantView.streamRenderView.layoutType = "share_screen"
                participantView.streamRenderView.isMini = true
            }
            if layout.style == .fill, isPhoneLandscape {
                activeSpeakerAlwaysHidden = true
            } else {
                activeSpeakerAlwaysHidden = false
            }
        }
    }
}

extension InMeetingParticipantGridCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let view = touch.view
        if view is UIButton {
            return false
        } else if view is LKLabel {
            return false
        }
        return true
    }
}
