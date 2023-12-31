//
//  AssignNewSharerCell.swift
//  ByteView
//
//  Created by liurundong.henry on 2019/10/30.
//

import Foundation
import UIKit
import UniverseDesignIcon
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI
import ByteViewSetting

class AssignNewSharerCell: UITableViewCell {

    private(set) weak var cellModel: AssignNewSharerCellModel?

    fileprivate enum Layout {
        static let horizontalEdgeOffset: CGFloat = 16.0
        static let avatarImageViewSize: CGFloat = 40.0
        static let iPadAvatarImageViewSize: CGFloat = 48.0
        static let avatarAndNameDistance: CGFloat = 12.0
        static let nameLabelHeight: CGFloat = 24.0
        static let deviceImageSize = CGSize(width: 16, height: 16)
        static let externalLabelHeight: CGFloat = 18.0
    }

    lazy var avatarImageView = AvatarView(style: .circle)

    /// 名字和外部标签，竖直左对齐
    private let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        stackView.spacing = 0
        return stackView
    }()

    /// 名字和设备图标
    private let horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 4.0
        return stackView
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.ud.textTitle
        label.attributedText = NSAttributedString(string: " ", config: .h4)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    lazy var deviceImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()

    // 展示 External 标签
    lazy var externalTagView: PaddingLabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 0.0,
                                        left: 4.0,
                                        bottom: 0.0,
                                        right: 4.0)
        label.attributedText = NSAttributedString(string: I18n.View_G_ExternalLabel, config: .assist)
        label.textColor = UIColor.ud.udtokenTagTextSBlue
        label.backgroundColor = UIColor.ud.udtokenTagBgBlue
        label.layer.cornerRadius = 4.0
        label.clipsToBounds = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    let saperatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundView = UIView()
        backgroundView?.backgroundColor = UIColor.ud.bgBody
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.ud.fillHover

        loadSubView()
        bindTraitChange()
    }

    func bindTraitChange() {
        self.handleRootTraitCollectionChanged(VCScene.rootTraitCollection ?? traitCollection)
        self.vc.windowSceneLayoutContextObservable.addObserver(self) { [weak self] _, context in
            self?.handleRootTraitCollectionChanged(context.traitCollection)
        }
    }

    private func handleRootTraitCollectionChanged(_ traitCollection: UITraitCollection) {
        let isRegular = traitCollection.horizontalSizeClass != .compact
        let avatarSize = isRegular ? Layout.iPadAvatarImageViewSize : Layout.avatarImageViewSize
        self.avatarImageView.snp.updateConstraints { make in
            make.size.equalTo(avatarSize)
        }
        self.avatarImageView.layer.cornerRadius = avatarSize / 2.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadSubView() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(verticalStackView)
        verticalStackView.addArrangedSubview(horizontalStackView)
        verticalStackView.addArrangedSubview(externalTagView)
        horizontalStackView.addArrangedSubview(nameLabel)
        horizontalStackView.addArrangedSubview(deviceImageView)
        contentView.addSubview(saperatorLine)

        avatarImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(Layout.avatarImageViewSize)
            make.left.equalToSuperview().offset(Layout.horizontalEdgeOffset).priority(999)
            make.left.greaterThanOrEqualTo(contentView.safeAreaLayoutGuide.snp.left).offset(Layout.horizontalEdgeOffset)
        }
        verticalStackView.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView.snp.right).offset(Layout.avatarAndNameDistance)
            make.right.lessThanOrEqualToSuperview().offset(-Layout.horizontalEdgeOffset)
            make.centerY.equalToSuperview()
        }
        horizontalStackView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview().priority(999)
            make.right.lessThanOrEqualTo(contentView.safeAreaLayoutGuide.snp.right).offset(-Layout.horizontalEdgeOffset)
            make.height.equalTo(Layout.nameLabelHeight)
        }
        nameLabel.snp.remakeConstraints { (make) in
            make.height.equalToSuperview()
        }
        deviceImageView.snp.makeConstraints { (make) in
            make.size.equalTo(Layout.deviceImageSize)
        }
        externalTagView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.height.equalTo(Layout.externalLabelHeight)
        }
        saperatorLine.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func update(with model: AssignNewSharerCellModel) {
        cellModel = model
        nameLabel.vc.justReplaceText(to: model.nameText)
        avatarImageView.setTinyAvatar(model.avatarInfo)
        deviceImageView.image = model.deviceImg
        deviceImageView.isHidden = model.deviceImg == nil
        if let externalStr = model.relationTag?.relationText {
            externalTagView.attributedText = NSAttributedString(string: externalStr, config: .assist)
            externalTagView.isHidden = false
        } else {
            if !model.service.setting.isRelationTagEnabled {
                externalTagView.isHidden = !model.isExternal
                externalTagView.attributedText = NSAttributedString(string: I18n.View_G_ExternalLabel, config: .assist)
            } else {
                externalTagView.isHidden = true
            }
        }

        requestRelationTagIfNeeded()
    }

    func requestRelationTagIfNeeded() {
        cellModel?.getRelationTag { [weak self] external in
            Util.runInMainThread {
                if let external = external {
                    self?.externalTagView.attributedText = NSAttributedString(string: external, config: .assist)
                    self?.externalTagView.isHidden = false
                } else {
                    self?.externalTagView.attributedText = NSAttributedString(string: I18n.View_G_ExternalLabel, config: .assist)
                    self?.externalTagView.isHidden = !(self?.cellModel?.isExternal ?? false)
                }
            }
        }
    }
}

class AssignNewSharerCellModel {
    let nameText: String
    let avatarInfo: AvatarInfo
    let deviceImg: UIImage?
    let isExternal: Bool
    let participant: Participant
    let service: MeetingBasicService
    var httpClient: HttpClient { service.httpClient }
    /// 关联标签
    private(set) var relationTag: VCRelationTag?

    init(nameText: String,
         avatarInfo: AvatarInfo,
         deviceImg: UIImage?,
         isExternal: Bool,
         participant: Participant,
         service: MeetingBasicService) {
        self.nameText = nameText
        self.avatarInfo = avatarInfo
        self.deviceImg = deviceImg
        self.isExternal = isExternal
        self.participant = participant
        self.service = service
    }

    static func construct(with participant: Participant, userInfo: ParticipantUserInfo, isDuplicated: Bool,
                          isExternal: Bool, service: MeetingBasicService, meetingSource: VideoChatInfo.MeetingSource) -> AssignNewSharerCellModel {
        var nameText = userInfo.name
        if participant.isLarkGuest {
            if meetingSource == .vcFromInterview {
                nameText += I18n.View_G_CandidateBracket
            } else {
                nameText += I18n.View_M_GuestParentheses
            }
        }
        let avatarInfo = userInfo.avatarInfo
        var deviceImg: UIImage?
        if let pstnInfo = participant.pstnInfo, ConveniencePSTN.isConvenience(pstnInfo) {
            deviceImg = ParticipantImageView.PstnDeviceImg
        } else if isDuplicated {
            switch participant.deviceType {
            case .mobile:
                deviceImg = UDIcon.getIconByKey(.cellphoneFilled, iconColor: .ud.iconN3, size: AssignNewSharerCell.Layout.deviceImageSize)
            case .web:
                deviceImg = BundleResources.ByteView.Meet.iconMobileWindow.ud.withTintColor(.ud.iconN3)
            default: break
            }
        }

        let model = AssignNewSharerCellModel(nameText: nameText, avatarInfo: avatarInfo, deviceImg: deviceImg,
                                             isExternal: isExternal, participant: participant, service: service)
        return model
    }
}

extension AssignNewSharerCellModel {
    func getRelationTag(_ completion: @escaping ((String?) -> Void)) {
        guard isExternal, self.service.setting.isRelationTagEnabled else {
            completion(nil)
            return
        }
        if let externalStr = relationTag?.relationText {
            completion(externalStr)
            return
        }

        httpClient.participantRelationTagService.relationTagsByUsers([participant.relationTagUser]) { [weak self] tags in
            let relationTag = tags.first
            guard relationTag?.userID == self?.participant.user.id else {
                completion(nil)
                return
            }
            self?.relationTag = relationTag
            completion(relationTag?.relationText)
        }
    }
}
