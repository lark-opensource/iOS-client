//
//  InMeetSecurityUserFlagLabel.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/9.
//

import Foundation
import ByteViewUI
import UniverseDesignColor
import ByteViewCommon
import ByteViewNetwork

/// 用户标签(外部/请假)
final class InMeetSecurityUserFlagLabel: PaddingLabel {
    struct FlagInfo: Equatable {
        let isRelationTagEnabled: Bool
        let isNewStatusEnabled: Bool
        let isExternal: Bool
        let user: VCRelationTag.User
        var workStatus: User.WorkStatus?
        var relationTag: CollaborationRelationTag?
    }

    /// 用户标签类型
    enum UserFlagType: Equatable {
        /// 无
        case none
        /// 外部
        case external
        /// 请假
        case onLeave
        /// 关联标签
        case relationTag(String)
    }

    var type: UserFlagType = .none {
        didSet {
            if oldValue != type {
                update(type: type)
            }
        }
    }

    var onUpdateFlagType: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        textInsets = UIEdgeInsets(top: 0.0, left: 4.0, bottom: 0.0, right: 4.0)
        font = .systemFont(ofSize: 12, weight: .medium)
        lineBreakMode = .byTruncatingTail
        textAlignment = .center
        contentMode = .center
        baselineAdjustment = .alignCenters
        layer.cornerRadius = 4.0
        clipsToBounds = true
        isHidden = true
        updateLabelWidth()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(type: UserFlagType) {
        switch type {
        case .none:
            isHidden = true
        case .external:
            isHidden = false
            configureToExternal()
        case .onLeave:
            isHidden = false
            configureToOnLeave()
        case .relationTag(let tag):
            isHidden = false
            configureToRelationTag(tag)
        }
        updateLabelWidth()
        self.onUpdateFlagType?()
    }

    private func updateLabelWidth() {
        snp.remakeConstraints { make in
            make.width.greaterThanOrEqualTo(30)
            make.height.equalTo(18)
        }
    }

    private func configureToExternal() {
        text = I18n.View_G_ExternalLabel
        textColor = UIColor.ud.udtokenTagTextSBlue
        backgroundColor = UIColor.ud.udtokenTagBgBlue
        setContentCompressionResistancePriority(.init(400), for: .horizontal)
    }

    private func configureToOnLeave() {
        text = I18n.View_G_OnLeave
        textColor = UIColor.ud.R600
        backgroundColor = UIColor.ud.R100
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func configureToRelationTag(_ tag: String) {
        text = tag
        textColor = UIColor.ud.udtokenTagTextSBlue
        backgroundColor = UIColor.ud.udtokenTagBgBlue
        setContentCompressionResistancePriority(.init(400), for: .horizontal)
    }

    private var flagInfo: FlagInfo?
    private var relationTagUser: VCRelationTag.User?
    private var relationTagCache: VCRelationTag?
    private var service: ParticipantRelationTagService?
    func setFlagInfo(_ flagInfo: FlagInfo?, service: ParticipantRelationTagService?) {
        self.flagInfo = flagInfo
        self.service = service
        self.relationTagUser = nil
        if let flagInfo = flagInfo {
            self.updateFlag(shouldFetchRelationTag: flagInfo.isRelationTagEnabled)
        } else {
            self.type = .none
        }
    }

    private func updateFlag(shouldFetchRelationTag: Bool) {
        guard let flagInfo = self.flagInfo else {
            self.type = .none
            return
        }
        self.relationTagUser = nil
        if flagInfo.isExternal {
            if let text = flagInfo.relationTag?.meetingTagText {
                self.type = .relationTag(text)
            } else if shouldFetchRelationTag {
                fetchRelationTagIfNeeded(flagInfo.user)
            } else {
                self.type = .external
            }
        } else if flagInfo.workStatus == .leave && !flagInfo.isNewStatusEnabled {
            // 新的个人状态组件包含了请假状态，因此不需要重复展示自定义请假标签
            self.type = .onLeave
        } else {
            self.type = .none
        }
    }

    private func fetchRelationTagIfNeeded(_ user: VCRelationTag.User) {
        assert(Thread.isMainThread, "fetchRelationTagIfNeeded must invoked in main thread")
        if let cache = self.relationTagCache, cache.user == user {
            updateRelationTag(cache)
            return
        }
        if user == self.relationTagUser { return }
        self.relationTagUser = user
        self.relationTagCache = nil
        guard let service = self.service else {
            updateRelationTag(nil)
            return
        }
        service.relationTagsByUsers([user]) { [weak self] tags in
            Util.runInMainThread {
                guard let self = self, self.relationTagUser == user else { return }
                if let tag = tags.first, tag.user == self.relationTagUser {
                    self.relationTagCache = tag
                    self.updateRelationTag(tag)
                } else {
                    self.updateRelationTag(nil)
                }
            }
        }
        if self.relationTagCache == nil {
            /// clear before requesting new tag
            self.type = .none
        }
    }

    private func updateRelationTag(_ tag: VCRelationTag?) {
        if let text = tag?.relationText {
            self.type = .relationTag(text)
        } else {
            self.updateFlag(shouldFetchRelationTag: false)
        }
    }
}
