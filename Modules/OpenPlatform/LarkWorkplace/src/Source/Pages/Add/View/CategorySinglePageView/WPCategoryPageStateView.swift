//
//  WPCategoryPageStateView.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/6/22.
//

import UIKit
import LarkUIKit
import UniverseDesignLoading

final class WPCategoryPageStateView: UIView, UIGestureRecognizerDelegate {
    /// 页面状态
    var state: AppCategoryPageState {
        didSet {
            updatePageStateView()
        }
    }
    /// 重试回调
    var retryCallback: (() -> Void)?
    /// 默认加载view的cell数量
    let defaultLoadingCell: Int = 10

    /// 加载态视图
    lazy var loadingTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(WPCategoryLoadingCell.self, forCellReuseIdentifier: WPCategoryLoadingCell.cellID)
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
        tableView.isSkeletonable = true
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return tableView
    }()
    /// 空态页
    lazy var emptyView: WPPageStateView = {
        WPPageStateView()
    }()

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    // MARK: 初始化
    init(frame: CGRect, state: AppCategoryPageState, retryCallback: (() -> Void)?) {
        self.state = state
        self.retryCallback = retryCallback
        super.init(frame: frame)
        setupViews()
        setConstraint()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// MARK: 视图相关
extension WPCategoryPageStateView {
    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(loadingTableView)
        addSubview(emptyView)
    }

    private func setConstraint() {
        loadingTableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    /// 更新状态
    private func updatePageStateView() {
        loadingTableView.hideUDSkeleton()
        loadingTableView.isHidden = true
        emptyView.state = .hidden
        switch state {
        case .loading:
            loadingTableView.isHidden = false
            loadingTableView.showUDSkeleton()
        case .empty:
            emptyView.state = .noApp(.create(action: nil))
        case .fail:
            emptyView.state = .loadFail(
                .create { [weak self] in
                    self?.retryCallback?()
                }
            )
        case .success: break
        }
    }
}

extension WPCategoryPageStateView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return defaultLoadingCell
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let dequeueCell = tableView.dequeueReusableCell(
            withIdentifier: WPCategoryLoadingCell.cellID
        ) as? WPCategoryLoadingCell {
            return dequeueCell
        }
        return WPCategoryPageViewCell(
            style: .default,
            reuseIdentifier: WPCategoryLoadingCell.cellID
        )
    }
}

extension WPCategoryPageStateView: UITableViewDelegate {
    /// cell高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return WPCategoryPageViewCell.CellConfig.cellHeight
    }
}

final class WPCategoryLoadingCell: UITableViewCell {

    static let cellID: String = "WPCategoryLoadingCell"

    /// Item的图标
    private lazy var logoView: WPMaskImageView = {
        let logoView = WPMaskImageView()
        logoView.backgroundColor = UIColor.ud.bgFiller
        logoView.sqRadius = WPUIConst.AvatarRadius.middle
        return logoView
    }()
    /// Cell的标题
    private lazy var titleLabel: UIImageView = {
        let titleImage = UIImageView()
        titleImage.backgroundColor = UIColor.ud.bgFiller
        titleImage.layer.cornerRadius = 4
        titleImage.layer.masksToBounds = true
        return titleImage
    }()
    /// Cell的描述
    private lazy var descLabel: UIImageView = {
        let descImage = UIImageView()
        descImage.backgroundColor = UIColor.ud.bgFiller
        descImage.layer.cornerRadius = 4
        descImage.layer.masksToBounds = true
        return descImage
    }()
    /// 分割线
    private lazy var dividerLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.bgFiller
        return line
    }()
    // 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(logoView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descLabel)
        contentView.addSubview(dividerLine)

        dividerLine.isHidden = true
        isSkeletonable = true
        logoView.isSkeletonable = true
        titleLabel.isSkeletonable = true
        descLabel.isSkeletonable = true
    }

    private func setConstraints() {
        logoView.snp.makeConstraints { (make) in
            make.size.equalTo(WPUIConst.AvatarSize.middle)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(17)
            make.width.equalTo(120)
            make.top.equalTo(logoView.snp.top).offset(6)
            make.left.equalTo(logoView.snp.right).offset(12)
        }
        descLabel.snp.makeConstraints { (make) in
            make.height.equalTo(12)
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom).offset(7)
            make.right.equalToSuperview().inset(16)
        }
        dividerLine.snp.makeConstraints { (make) in
            make.height.equalTo(0.8)
            make.bottom.right.equalToSuperview()
            make.left.equalTo(descLabel.snp.left)
        }
    }
}
