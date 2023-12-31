//
//  NewMomentsProfileHeaderView.swift
//  Moment
//
//  Created by bytedance on 2021/9/16.
//

import Foundation
import UIKit
import SkeletonView
//字节特化——去掉关注（外部租户的设计不变）
final class NewMomentsProfileHeaderContentView: UIView {
    private lazy var skeletonView: UIView = {
        let view = UIView()
        view.addSkeletonBar(left: 17, topOffset: 16.5, width: 28, height: 17)
        view.addSkeletonBar(left: 79, topOffset: 16.5, width: 28, height: 17)
        view.addSkeletonBar(left: 141, topOffset: 16.5, width: 28, height: 17)
        view.addSkeletonBar(left: 17, topOffset: 39.5, width: 28, height: 17)
        view.addSkeletonBar(left: 79, topOffset: 39.5, width: 28, height: 17)
        view.addSkeletonBar(left: 141, topOffset: 39.5, width: 28, height: 17)
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

    private lazy var postView: ItemView = {
        let view = ItemView(title: BundleI18n.Moment.Lark_Community_Dynamic(0))
        return view
    }()

    private lazy var reactionView: ItemView = {
        let view = ItemView(title: BundleI18n.Moment.Lark_ProfilePage_ReationgNumber(0))
        return view
    }()

    //中间的分割竖线
    private lazy var dividerView: UIView = {
        let view = UIView()
        return view
    }()

    init() {
        super.init(frame: .zero)
        layer.cornerRadius = 8
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        dividerView.backgroundColor = UIColor.ud.lineDividerDefault
        backgroundColor = UIColor.ud.bgBody
    }
    func setupView() {
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.addSubview(postView)
        contentView.addSubview(dividerView)
        contentView.addSubview(reactionView)
        dividerView.snp.makeConstraints { make in
            make.left.equalTo(postView.snp.right).offset(22.75)
            make.right.equalTo(reactionView.snp.left).offset(-22.75)
            make.width.equalTo(0.5)
            make.height.equalTo(12)
            make.centerY.equalToSuperview()
        }
        addSubview(skeletonView)
        skeletonView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        updateUI()
    }

    func setupData(_ entity: RawData.UserProfileEntity) {
        postView.setValue(entity.userProfile.postsCount)
        postView.updateTitle(BundleI18n.Moment.Lark_Community_Dynamic(entity.userProfile.postsCount))
        reactionView.setValue(entity.userProfile.reactionsCount)
        reactionView.updateTitle(BundleI18n.Moment.Lark_ProfilePage_ReationgNumber(entity.userProfile.reactionsCount))
        contentView.isHidden = false
        skeletonView.isHidden = true
        updateUI()
    }

    func updateUI() {
        let postViewWidth = postView.calculateWidth()
        postView.snp.remakeConstraints { make in
            make.centerY.height.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(postViewWidth)
        }
        let reactionViewWidth = reactionView.calculateWidth()
        reactionView.snp.remakeConstraints { make in
            make.centerY.height.equalToSuperview()
            make.width.equalTo(reactionViewWidth)
        }
    }

    func updatePostCount(_ count: Int32) {
        postView.setValue(count)
        updateUI()
    }
    //header中每一块数字+标题的组合的view
    final class ItemView: UIView {
        lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.textColor = .ud.textPlaceholder
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
                make.height.equalTo(20)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview()
            }
            addSubview(valueLabel)
            valueLabel.snp.makeConstraints { make in
                make.height.equalTo(26)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview()
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
            let suggestWidth = getTitleLabelWidth() + getValueLabelWidth() + 6
            return suggestWidth
        }
    }
}
final class NewMomentsProfileHeaderView: MomentsProfileHeaderView {
    lazy var contentView: NewMomentsProfileHeaderContentView = {
        return NewMomentsProfileHeaderContentView()
    }()

    override init(viewModel: MomentsProfileHeaderViewModel) {
        super.init(viewModel: viewModel)
        setupView()
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
    }

    func setupView() {
        if viewModel.isCurrentUser {
            addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().offset(-12)
            }
            suggestHeight = 96
            configHeaderViewModel()
            viewModel.loadDataWithLocalPriority()
        } else {
            //只有12的间距，不展示任何内容
            suggestHeight = 12
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.ud.bgBase
    }
}
