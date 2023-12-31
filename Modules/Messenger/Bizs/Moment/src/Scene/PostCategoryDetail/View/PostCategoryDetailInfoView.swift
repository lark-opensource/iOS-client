//
//  PostCategoryHeaderView.swift
//  Moment
//
//  Created by liluobin on 2021/4/27.
//

import Foundation
import UIKit
import SnapKit
import RichLabel
import LKCommonsLogging
import LarkBizAvatar
import AvatarComponent
import LarkFeatureGating
import FigmaKit

final class InfoTapView: UIView, UIGestureRecognizerDelegate {
    var tapHandler: (() -> Void)?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.tapHandler == nil {
            super.touchesBegan(touches, with: event)
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.tapHandler == nil {
            super.touchesMoved(touches, with: event)
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.tapHandler == nil {
            super.touchesCancelled(touches, with: event)
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let handler = self.tapHandler {
            handler()
        } else {
            super.touchesEnded(touches, with: event)
        }
    }
}

final class PostCategoryDetailInfoView: UIView {
    static let logger = Logger.log(PostCategoryDetailInfoView.self, category: "Module.Moments.PostCategoryDetailInfoView")

    var tracker: MomentsCommonTracker?
    var firstLoadTrackerItem: MomentsPolymerizationItem?

    public lazy var iconView: BizAvatar = {
        let view = SmoothingBizAvatar()
        view.setSmoothCorner(radius: 8, smoothness: .max)
        view.avatar.clipsToBounds = true
        view.backgroundColor = UIColor.ud.N300
        let config = AvatarComponentUIConfig(style: .square)
        view.setAvatarUIConfig(config)
        view.lu.addTapGestureRecognizer(action: #selector(iconTap), target: self)
        return view
    }()
    let containerView = UIView()
    private let titleLabel = UILabel()
    private let subTitleLabel = UILabel()
    private let iconWidth: CGFloat = 68
    lazy var iconMaxY: CGFloat = iconWidth + iconTopDistance
    let iconTopDistance: CGFloat = 18

    var hostWidth: CGFloat {
        didSet {
            categoryInfoLabel.preferredMaxLayoutWidth = hostWidth - 40
            let height = recalculationContentHeight()
            if self.categoryInfoLabel.numberOfLines == 2 {
                contentHeight = height <= 20 ? 20 : 40
            } else {
                contentHeight = height
            }
            self.heightChangeCallBack?(false)
        }
    }

    // 默认两行的宽度
    private var contentHeight: CGFloat = 40
    private var avatarKey: String = ""
    private var entityId: String = ""

    //当categoryInfoLabel有信息时，TapView距离底部距离为24（距离头像/管理员信息12）；
    //当categoryInfoLabel为空时，头像/管理员信息 距离底部24，即TapView距离上下各12
    private var spaceBetweenTapViewAndBottom: CGFloat = 24 {
        didSet {
            tapView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(-spaceBetweenTapViewAndBottom)
            }
        }
    }
    var suggestHeight: CGFloat {
        if adminInfoView.superview == containerView {
            return max(iconMaxY, containerView.frame.minY + adminInfoView.frame.maxY) + 12 + spaceBetweenTapViewAndBottom + contentHeight
        }
        return iconMaxY + 12 + spaceBetweenTapViewAndBottom + contentHeight
    }
    var hadShowMoreBtn = false

    private lazy var categoryInfoLabel: LKLabel = {
        let label = LKLabel()
        label.delegate = self
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = .clear
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textCheckingDetecotor = RegularManager.linkRegular()
        label.autoDetectLinks = true
        label.linkAttributes = [
            LKLineAttributeName: LKLineStyle(color: UIColor.ud.primaryOnPrimaryFill, style: .line),
            NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.ud.primaryOnPrimaryFill
        ]
        label.activeLinkAttributes = [:]
        label.lineSpacing = 2
        label.numberOfLines = 2
        var tempAtt = attributes
        tempAtt[.foregroundColor] = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.7)
        label.outOfRangeText = NSAttributedString(string: "... " + "\(BundleI18n.Moment.Lark_Community_More)", attributes: tempAtt)
        return label
    }()

    private lazy var adminInfoView: CategoryAdminInfoContainerView = {
        let view = CategoryAdminInfoContainerView(frame: .zero) { [weak self] item in
            guard let self = self else { return }
            self.adminAvatarTapCallBack?(item)
        }
        view.layoutChangeCallBack = {
            [weak self] in
            guard let self = self else { return }
            self.heightChangeCallBack?(false)
        }
        return view
    }()

    private lazy var attributes: [NSAttributedString.Key: Any] = {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        return [
            .foregroundColor: UIColor.ud.primaryOnPrimaryFill,
            .font: UIFont.systemFont(ofSize: 14),
            .paragraphStyle: paragraph
        ]
    }()

    private lazy var tapView: InfoTapView = {
        let view = InfoTapView()
        view.tapHandler = { [weak self] in
            self?.onContentTap()
        }
        return view
    }()

    var headerDetailInfoCallback: ((_ entityId: String, _ imageKey: String, _ title: String) -> Void)?
    var headerImageSetFinishCallback: ((UIImage, _ key: String, _ entityId: String) -> Void)?
    var heightChangeCallBack: ((Bool) -> Void)?
    var iconTapCallBack: ((String, String) -> Void)?
    var adminAvatarTapCallBack: ((MomentUser) -> Void)?
    var didTapUrl: ((URL) -> Void)?
    let viewModel: PostCategoryHeaderViewModel

    init(viewModel: PostCategoryHeaderViewModel, hostWidth: CGFloat, heightChangeCallBack: ((Bool) -> Void)?, detailInfoCallback: ((String, String, String) -> Void)?) {
        self.viewModel = viewModel
        self.headerDetailInfoCallback = detailInfoCallback
        self.heightChangeCallBack = heightChangeCallBack
        self.hostWidth = hostWidth
        super.init(frame: .zero)
        setupView()
        refreshData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshData() {
        let item = self.getTrackerItem()
        item?.startheaderDataCost()
        self.viewModel.getCategoryDetailWithRefreshBlock { [weak self] (info) in
            guard let self = self else { return }
            item?.endheaderDataCost()
            item?.startHeaderRender()
            if let info = info,
               let category = info.category {
                self.titleLabel.text = category.name
                self.subTitleLabel.text = self.subTitleWithCategoryStats(info.categoryStats)
                self.categoryInfoLabel.attributedText = NSAttributedString(string: category.description_p, attributes: self.attributes)
                if category.showAdminInfo == true,
                   info.adminUsers?.count ?? 0 > 0 {
                    self.showAdminInfoView(info: info)
                }
                self.adjustCurrentContentHeightIfNeedForText(category.description_p)
                Self.logger.info("refreshData \(category.iconKey)")
                self.updateDataWithImageKey(category.iconKey, title: category.name, entityId: category.categoryID)
            } else {
                /// 没有获取到信息的话 展会为空
                self.adjustCurrentContentHeightIfNeedForText(nil)
            }
            item?.endHeaderRender()
            self.tracker?.endTrackFeedUpdateItemForExtra(item)
        }
    }
    private func showAdminInfoView(info: RawData.CategoryInfoEntity) {
        self.containerView.addSubview(self.adminInfoView)
        self.adminInfoView.data = info.adminUsers
        self.adminInfoView.snp.makeConstraints { make in
            make.top.equalTo(subTitleLabel.snp.bottom).offset(2)
            make.left.equalTo(titleLabel)
            make.right.equalToSuperview()
            if let lastView = adminInfoView.adminInfoViews.last {
                make.bottom.equalTo(lastView.snp.bottom)
            } else {
                make.bottom.equalTo(adminInfoView.label.snp.bottom)
            }
        }
        containerView.snp.remakeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalTo(iconView).priority(.low)
            make.top.greaterThanOrEqualTo(iconView).priority(.high)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(adminInfoView)
        }
        subTitleLabel.snp.updateConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }
    }
    private func updateDataWithImageKey(_ imageKey: String, title: String, entityId: String) {
        self.headerDetailInfoCallback?(entityId, imageKey, title)
        self.avatarKey = imageKey
        self.entityId = entityId
        self.iconView.setAvatarByIdentifier(entityId,
                                            avatarKey: imageKey,
                                            scene: .Moments,
                                            avatarViewParams: .init(sizeType: .size(iconWidth)),
                                            backgroundColorWhenError: UIColor.ud.N300,
                                            completion: { [weak self] result in
                                                switch result {
                                                case .success(let imageResult):
                                                    if let image = imageResult.image {
                                                        self?.headerImageSetFinishCallback?(image, imageKey, entityId)
                                                    }
                                                case .failure(let error):
                                                    Self.logger.error("refreshData error \(imageKey) error: \(error)")
                                                }
                                            })
    }

    private func subTitleWithCategoryStats(_ stats: RawData.CategoryStats) -> String {
        var text = BundleI18n.Moment.Lark_Community_NumberMomentsInCategory(stats.postCount)
        text += " · "
        text += BundleI18n.Moment.Lark_Community_NumberPeopleInCategory(stats.participantCount)
        return text
    }

    private func setupView() {
        self.addSubview(iconView)
        self.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subTitleLabel)
        self.addSubview(tapView)
        tapView.addSubview(categoryInfoLabel)
        iconView.clipsToBounds = true
        iconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(CGSize(width: iconWidth, height: iconWidth))
            make.top.equalToSuperview().offset(iconTopDistance)
        }
        containerView.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalTo(iconView).priority(.low)
            make.top.greaterThanOrEqualTo(iconView).priority(.high)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(subTitleLabel)
        }
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        if let category = viewModel.catgegoryEntity {
            titleLabel.text = category.category.name
            updateDataWithImageKey(category.category.iconKey, title: category.category.name, entityId: category.category.categoryID)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }
        subTitleLabel.font = UIFont.systemFont(ofSize: 12)
        subTitleLabel.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        subTitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.right.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.height.greaterThanOrEqualTo(20)
        }
        categoryInfoLabel.preferredMaxLayoutWidth = hostWidth - 40
        tapView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.greaterThanOrEqualTo(iconView.snp.bottom).offset(12)
            make.top.greaterThanOrEqualTo(containerView.snp.bottom).offset(12)
            make.bottom.equalToSuperview().offset(-spaceBetweenTapViewAndBottom)
        }
        categoryInfoLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func recalculationContentHeight() -> CGFloat {
        let size = CGSize(width: hostWidth - 40, height: CGFloat(MAXFLOAT))
        return categoryInfoLabel.systemLayoutSizeFitting(size).height.rounded(.up)
    }

    private func onContentTap() {
        if self.hadShowMoreBtn {
            relayoutInfoLabel()
        }
    }

    private func adjustCurrentContentHeightIfNeedForText(_ text: String?) {
        /// 这里原来有数据 失败后不刷新
        if  text?.count ?? 0 == 0, self.categoryInfoLabel.attributedText?.length ?? 0 == 0 {
            contentHeight = 0.0
            spaceBetweenTapViewAndBottom = 12
            categoryInfoLabel.snp.remakeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.height.equalTo(0)
            }
            self.heightChangeCallBack?(false)
            return
        }
        spaceBetweenTapViewAndBottom = 24
        /// 刷新后更新UI
        let height = recalculationContentHeight()
        categoryInfoLabel.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        if self.categoryInfoLabel.numberOfLines == 2 {
            contentHeight = height <= 20 ? 20 : 40
            self.heightChangeCallBack?(false)
        }
    }

    private func relayoutInfoLabel() {
        /// 重新赋值触发布局
        self.categoryInfoLabel.numberOfLines = 0
        self.categoryInfoLabel.attributedText = self.categoryInfoLabel.attributedText
        contentHeight = recalculationContentHeight()
        self.heightChangeCallBack?(true)
    }

    @objc
    private func iconTap() {
        iconTapCallBack?(avatarKey, entityId)
    }

    func getTrackerItem() -> MomentsFeedUpdateItem? {
        if firstLoadTrackerItem == nil {
            firstLoadTrackerItem = MomentsPolymerizationItem(detail: .category_recommend)
            return firstLoadTrackerItem
        } else {
            return self.tracker?.getItemWithEvent(.refreshFeed) as? MomentsFeedUpdateItem
        }
    }
}

extension PostCategoryDetailInfoView: LKLabelDelegate {

    func attributedLabel(_ label: RichLabel.LKLabel, didSelectLink url: URL) {
    }

    func shouldShowMore(_ label: LKLabel, isShowMore: Bool) {
        self.hadShowMoreBtn = isShowMore
    }

    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        if let url = URL(string: text) {
            didTapUrl?(url)
        } else {
            Self.logger.error("String转URL失败 --- string count \(text.count)")
        }
        return false
    }

    func tapShowMore(_ label: RichLabel.LKLabel) {
        relayoutInfoLabel()
    }
}
