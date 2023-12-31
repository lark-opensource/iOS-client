//
//  MeetingDetailHeaderView.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/21.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon

class MeetingDetailHeaderView: UIView {

    var LRInset: CGFloat {
        Util.rootTraitCollection?.horizontalSizeClass == .regular ? 28 : 16
    }

    lazy var titleComponents: [MeetingDetailComponent] = [
        MeetingDetailTitleHeaderComponent.self
    ].compactMap { resolver?.resolve($0) }

    lazy var infoComponents: [MeetingDetailComponent] = [
        MeetingDetailTimeHeaderComponent.self,
        MeetingDetailLoopHeaderComponent.self,
        MeetingDetailMeetingHeaderComponent.self,
        MeetingDetailPreviewHeaderComponent.self,
        MeetingDetailGuestHeaderComponent.self,
        MeetingDetailAudienceHeaderComponent.self,
        MeetingDetailJoinedDeviceHeaderComponent.self,
        MeetingDetailRedirectHeaderComponent.self
    ].compactMap { resolver?.resolve($0) }

    lazy var actionComponents: [MeetingDetailComponent] = [
        MeetingDetailJoinHeaderComponent.self,
        MeetingDetailCallHeaderComponent.self
    ].compactMap { resolver?.resolve($0) }

    var components: [MeetingDetailComponent] {
        titleComponents + infoComponents + actionComponents
    }

    // 整个视图的 container
    var contentView: UIStackView = {
        let contentView = UIStackView()
        contentView.axis = .vertical
        contentView.spacing = 24.0
        contentView.layer.masksToBounds = false
        return contentView
    }()

    // 标题、external 标签、头像（1v1）、日程 icon（日程会议）的 container
    lazy var titleView: UIView = UIView()

    // 时间信息和参会人信息的 container，在 1v1 呼叫中不显示
    lazy var infoView = UIView()

    lazy var infoStackView: UIStackView = {
        let infoStackView = UIStackView(arrangedSubviews: infoComponents)
        infoStackView.axis = .vertical
        infoStackView.spacing = 16
        infoStackView.alignment = .fill
        infoStackView.distribution = .fill
        return infoStackView
    }()

    private var resolver: MeetingDetailComponentResolver?
    convenience init(resolver: MeetingDetailComponentResolver) {
        self.init(frame: .zero)
        self.resolver = resolver
        setupViews()
    }

    func setupViews() {
        backgroundColor = UIColor.ud.N50.dynamicColor

        addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.left.right.equalToSuperview().inset(LRInset)
            $0.bottom.equalToSuperview().inset(24)
        }

        titleComponents.forEach {
            contentView.addArrangedSubview($0)
        }
        contentView.addArrangedSubview(infoView)
        actionComponents.forEach {
            contentView.addArrangedSubview($0)
        }

        infoView.addSubview(infoStackView)
        infoStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func updateLayout() {
        contentView.snp.updateConstraints {
            $0.left.right.equalToSuperview().inset(LRInset)
        }
    }
}
