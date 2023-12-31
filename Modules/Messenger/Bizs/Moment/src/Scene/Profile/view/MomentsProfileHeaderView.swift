//
//  ProfileHeaderView.swift
//  Moment
//
//  Created by liluobin on 2021/8/3.
//

import Foundation
import UIKit
import RxSwift
import SkeletonView
import LarkFeatureGating
import LKCommonsLogging

final class OldMomentsProfileHeaderContentView: UIView {
    private let maxWidth: CGFloat
    private let isCurrentUser: Bool
    private let followable: Bool

    var followButtonCallBack: ((Bool) -> Void)?
    var followerViewClickedCallBack: (() -> Void)?
    var followingViewClickedCallBack: (() -> Void)?

    private lazy var skeletonView: UIView = {
        let view = UIView()
        view.addSkeletonBar(left: 17, topOffset: 16.5, width: 28, height: 17)
        view.addSkeletonBar(left: 79, topOffset: 16.5, width: 28, height: 17)
        view.addSkeletonBar(left: 17, topOffset: 39.5, width: 28, height: 17)
        view.addSkeletonBar(left: 79, topOffset: 39.5, width: 28, height: 17)
        if shouldShowPostView() {
            view.addSkeletonBar(left: 141, topOffset: 16.5, width: 28, height: 17)
            view.addSkeletonBar(left: 141, topOffset: 39.5, width: 28, height: 17)
        }
        view.addSkeletonBar(right: 16, topOffset: 22, width: 70, height: 28)
        view.isSkeletonable = true
        view.layoutIfNeeded()
        let gradient = SkeletonGradient(baseColor: UIColor.ud.N200.withAlphaComponent(0.5),
                                                secondaryColor: UIColor.ud.N200)
        view.showAnimatedGradientSkeleton(usingGradient: gradient)
        view.startSkeletonAnimation()
        return view
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private lazy var followButton = MomentsFollowButton(isFollowed: false) {[weak self] isFollowed in
        guard let callBack = self?.followButtonCallBack else {
            return
        }
        callBack(isFollowed)
    }

    private lazy var postView: ItemView = {
        let view = ItemView(title: BundleI18n.Moment.Lark_Community_Dynamic(0))
        return view
    }()

    var followerCount: Int32 = 0 //记录被关注数，以便点击关注/取消关注时 对数量做乐观更新
    private lazy var followerView: ItemView = {
        let view = ItemView(title: BundleI18n.Moment.Lark_Community_Followers(0))
        view.lu.addTapGestureRecognizer(action: #selector(onFollowerViewClicked), target: self)
        return view
    }()

    private lazy var followingView: ItemView = {
        let view = ItemView(title: BundleI18n.Moment.Lark_Community_Following(0))
        view.lu.addTapGestureRecognizer(action: #selector(onFollowingViewClicked), target: self)
        return view
    }()

    init(isCurrentUser: Bool, width: CGFloat, followable: Bool) {
        self.maxWidth = width
        self.isCurrentUser = isCurrentUser
        self.followable = followable
        super.init(frame: .zero)
        layer.cornerRadius = 8
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.ud.bgBody
    }
    func setupView() {
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if shouldShowPostView() {
            contentView.addSubview(postView)
        }

        contentView.addSubview(followerView)

        contentView.addSubview(followingView)

        contentView.addSubview(followButton)
        followButton.isHidden = isCurrentUser || !followable
        addSubview(skeletonView)
        skeletonView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setupData(_ entity: RawData.UserProfileEntity) {
        if shouldShowPostView() {
            postView.setValue(entity.userProfile.postsCount)
            postView.updateTitle(BundleI18n.Moment.Lark_Community_Dynamic(entity.userProfile.postsCount))
        }

        followerCount = entity.userProfile.followerCount
        followerView.setValue(entity.userProfile.followerCount)
        followerView.updateTitle(BundleI18n.Moment.Lark_Community_Followers(entity.userProfile.followerCount))

        followingView.setValue(entity.userProfile.followingCount)
        followingView.updateTitle(BundleI18n.Moment.Lark_Community_Following(entity.userProfile.followingCount))

        updateFollowed(entity.user?.isCurrentUserFollowing ?? false)
        contentView.isHidden = false
        skeletonView.isHidden = true
        updateUI()
    }

    //新规则：当板块权限fg是开的时，不显示他人的动态数
    private func shouldShowPostView() -> Bool {
        return isCurrentUser
    }

    func updateUI() {
        let postViewWidth: CGFloat = shouldShowPostView() ? postView.calculateWidth() : 0
        let followerViewWith = followerView.calculateWidth()
        let followingViewWidth = followingView.calculateWidth()
        let followBtnWidth = isCurrentUser ? 0 : followButton.suggestWidth
        /**
                     当isCurrentUser == true时，有4个Item
                        postView｜- space  -｜followerView ｜- space -｜followingView ｜ - space - ｜ followButton
         有3个space。反之当isCurrentUser == false时，有2个space
         */
        var itemSpaceCount: CGFloat = isCurrentUser ? 2 : 3
        if !shouldShowPostView() {
            //如果不展示postview 则itemspace又会少1个
            itemSpaceCount -= 1
        }
        let itemsWidth = postViewWidth + followingViewWidth + followerViewWith + followBtnWidth
        let leftAndRightMargin: CGFloat = 16
        let totalWidth = itemsWidth + leftAndRightMargin * 2 + 32 * itemSpaceCount
        if totalWidth > maxWidth {
            if itemsWidth + leftAndRightMargin * 2 + 8 * itemSpaceCount > maxWidth {
                let lastViewWidth = followingViewWidth - ((itemsWidth + leftAndRightMargin * 2 + 8 * itemSpaceCount) - maxWidth)
                updateItemsLayout(8, lastViewWidth: max(lastViewWidth, 0))
            } else {
                let itemSpace = (maxWidth - itemsWidth - leftAndRightMargin * 2) / itemSpaceCount
                updateItemsLayout(itemSpace)
            }
        } else {
            updateItemsLayout()
        }
    }

    func updateItemsLayout(_ space: CGFloat = 32, lastViewWidth: CGFloat? = nil) {
        if shouldShowPostView() {
            let postViewWidth = postView.suggestWidth
            postView.snp.remakeConstraints { make in
                make.top.equalTo(13.5)
                make.bottom.equalTo(-12.5)
                make.left.equalTo(16)
                make.width.equalTo(postViewWidth)
            }
            let followerViewWidth = followerView.suggestWidth
            followerView.snp.remakeConstraints { make in
                make.top.bottom.equalTo(postView)
                make.left.equalTo(postView.snp.right).offset(space)
                make.width.equalTo(followerViewWidth)
            }
        } else {
            let followerViewWidth = followerView.suggestWidth
            followerView.snp.remakeConstraints { make in
                make.top.equalTo(13.5)
                make.bottom.equalTo(-12.5)
                make.left.equalTo(16)
                make.width.equalTo(followerViewWidth)
            }
        }

        let followingViewWidth = followingView.suggestWidth
        followingView.snp.remakeConstraints { make in
            make.top.bottom.equalTo(followerView)
            make.left.equalTo(followerView.snp.right).offset(space)
            if let lastViewWidth = lastViewWidth {
                make.width.equalTo(lastViewWidth)
            } else {
                make.width.equalTo(followingViewWidth)
            }
        }
        followButton.snp.remakeConstraints { make in
            make.height.equalTo(28)
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
    }

    func updatePostCount(_ count: Int32) {
        postView.setValue(count)
        updateUI()
    }

    func updateFollowedAndFollowerCount(_ isFollowed: Bool) {
        guard followButton.isFollowed != isFollowed else {
            return
        }
        if isFollowed {
            followerCount += 1
        } else {
            guard followerCount > 0 else {
                assertionFailure("点击取消关注时，当前关注数应大于0 当前followerCount:\(followerCount)")
                return
            }
            followerCount -= 1
        }
        followButton.reloadUIForIsFollowed(isFollowed)
        followerView.setValue(followerCount)
        followerView.updateTitle(BundleI18n.Moment.Lark_Community_Followers(followerView))
        updateUI()
    }

    private func updateFollowed(_ isFollowed: Bool) {
        guard followButton.isFollowed != isFollowed else {
            return
        }
        followButton.reloadUIForIsFollowed(isFollowed)
        updateUI()
    }

    @objc
    func onFollowerViewClicked() {
        guard let callBack = followerViewClickedCallBack else {
            return
        }
        callBack()
    }

    @objc
    func onFollowingViewClicked() {
        guard let callBack = followingViewClickedCallBack else {
            return
        }
        callBack()
    }

    //header中每一块数字+标题的组合的view
    final class ItemView: UIView {
        var suggestWidth: CGFloat = 0
        lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.textColor = .ud.N500
            label.font = .systemFont(ofSize: 12)
            label.textAlignment = .center
            return label
        }()

        lazy var valueLabel: UILabel = {
            let label = UILabel()
            label.textColor = .ud.N900
            label.font = MomentsFontTool.dinBoldFont(ofSize: 22)
            label.textAlignment = .center
            return label
        }()

        init(title: String) {
            super.init(frame: .zero)
            titleLabel.text = title
            setupView()
        }

        private func setupView() {
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.height.equalTo(18)
                make.bottom.equalToSuperview()
                make.left.right.equalToSuperview()
            }
            addSubview(valueLabel)
            valueLabel.snp.makeConstraints { make in
                make.height.equalTo(26)
                make.top.equalToSuperview()
                make.left.right.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setValue(_ value: String) {
            valueLabel.text = value
        }

        func setValue(_ value: Int32) {
            setValue("\(value)")
        }

        func updateTitle(_ title: String) {
            titleLabel.text = title
        }

        func getTitleLabelWidth() -> CGFloat {
            return MomentsDataConverter.widthForString(titleLabel.text ?? "", font: titleLabel.font)
        }

        func getValueLabelWidth() -> CGFloat {
            return MomentsDataConverter.widthForString(valueLabel.text ?? "", font: valueLabel.font)
        }

        func calculateWidth() -> CGFloat {
            suggestWidth = max(getTitleLabelWidth(), getValueLabelWidth())
            return suggestWidth
        }
    }
}
final class OldMomentsProfileHeaderView: MomentsProfileHeaderView {
    private static let logger = Logger.log(OldMomentsProfileHeaderView.self, category: "Moment.OldMomentsProfileHeaderView")
    let contentView: OldMomentsProfileHeaderContentView

    init(viewModel: MomentsProfileHeaderViewModel, followable: Bool) {
        contentView = OldMomentsProfileHeaderContentView(isCurrentUser: viewModel.isCurrentUser,
                                                         width: UIScreen.main.bounds.width - CGFloat(24),
                                                         followable: followable)
        super.init(viewModel: viewModel)
        setupView()
        configHeaderViewModel()
        viewModel.loadDataWithLocalPriority()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configHeaderViewModel() {
        viewModel.refreshDataCallBack = {[weak self] (data) in
            self?.contentView.setupData(data)
        }
        viewModel.refreshPostCountCallBack = {[weak self] (count) in
            self?.contentView.updatePostCount(count)
        }
        viewModel.followingChangedNotiCallBack = { [weak self] isFollowed in
            Self.logger.info("followingChangedNotiCallBack isFollowed: \(isFollowed)")
            self?.contentView.updateFollowedAndFollowerCount(isFollowed)
        }
        contentView.followButtonCallBack = {[weak self] isCurrentUserFollowing in
            self?.viewModel.followerUserWithFinish(isCurrentUserFollowing: isCurrentUserFollowing) {[weak self] isFollowed in
                Self.logger.info("followerUserWithFinish isCurrentUserFollowingBeforeClickButton:\(isCurrentUserFollowing) isFollowedAfterClickButton:\(isFollowed)")
                self?.contentView.updateFollowedAndFollowerCount(isFollowed)
                //isFollowed返回true说明点之前是未关注，所以isFollow参数传入!isFollowed
                self?.trackFeedPageViewClick(isFollowed ? .follow : .follow_cancel,
                                             isFollow: !isFollowed)
            }
        }
        contentView.followerViewClickedCallBack = { [weak self] in
            self?.viewModel.jumpToFollowVCWithType(.followers)
            self?.trackFeedPageViewClick(.followed_page)
        }
        contentView.followingViewClickedCallBack = { [weak self] in
            self?.viewModel.jumpToFollowVCWithType(.followings)
            self?.trackFeedPageViewClick(.follow_page)
        }
    }

    func trackFeedPageViewClick(_ clickType: MomentsTracer.FeedPageViewClickType, isFollow: Bool? = nil) {
        let isFollow = isFollow ?? viewModel.profileEntity?.user?.isCurrentUserFollowing
        MomentsTracer.trackFeedPageViewClick(clickType,
                                             circleId: viewModel.context.circleId,
                                             type: .moments_profile,
                                             detail: nil,
                                             profileInfo: MomentsTracer.ProfileInfo(profileUserId: viewModel.userID,
                                                                                    isFollow: isFollow,
                                                                                    isNickName: false,
                                                                                    isNickNameInfoTab: false))
    }

    func setupView() {
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.ud.bgBase
    }
}
class MomentsProfileHeaderView: UIView {
    let viewModel: MomentsProfileHeaderViewModel
    var suggestHeight: CGFloat = 96
    init(viewModel: MomentsProfileHeaderViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
