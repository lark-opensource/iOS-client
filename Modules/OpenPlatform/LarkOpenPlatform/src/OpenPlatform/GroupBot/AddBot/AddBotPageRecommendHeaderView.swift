//
//  AddBotPageRecommendHeaderView.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/10.
//

import LarkUIKit
import SnapKit

/// 「添加机器人」推荐headerView
class AddBotPageRecommendHeaderView: UITableViewHeaderFooterView {
    /// reuse id
    static let headerReuseID = "AddBotPageRecommendHeaderViewReuseID"

    /// 分割线
    private lazy var splitLine: UIView = {
        let splitView = UIView()
        splitView.backgroundColor = UIColor.ud.bgBase
        return splitView
    }()

    /// header标题
    private lazy var tipTitle: UILabel = {
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 14.0)
        title.textColor = UIColor.ud.textPlaceholder
        title.numberOfLines = 1
        return title
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //布局，支持多次调用
    private func setupViews() {
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(splitLine)
        splitLine.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        let mainView = UIView()
        contentView.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(41)
            make.top.equalTo(splitLine.snp.bottom)
        }

        mainView.addSubview(tipTitle)
        tipTitle.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-6)
            make.left.equalToSuperview().offset(16)
        }
    }

    /// 更新视图。针对是否包含已经安装的机器人，展示不同文案
    func updateViews(hasNoInstalledBots: Bool) {
        let title = hasNoInstalledBots ? BundleI18n.GroupBot.Lark_GroupBot_NoBots : BundleI18n.GroupBot.Lark_GroupBot_Recommend
        tipTitle.text = title
        tipTitle.textColor = hasNoInstalledBots ? UIColor.ud.textTitle : UIColor.ud.textPlaceholder

        splitLine.isHidden = hasNoInstalledBots
    }
}
