//
//  ItemStateCell.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/7/21.
//

import UIKit

final class ItemStateCell: WorkPlaceIconCell {
    /// 重试回调
    var retryCallback: (() -> Void)?
    private lazy var stateView: WPCategoryPageStateView = {
        let view = WPCategoryPageStateView(
            frame: self.bounds,
            state: .loading,
            retryCallback: nil
        )
        view.retryCallback = { [weak self] in
            self?.retryClick()
        }
        return view
    }()
    // MARK: cell initial
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContentView() // 这里只初始化外部样式，widgetView通过refresh实现
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupContentView() {
        contentView.addSubview(stateView)
        stateView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(100)
        }
        setupTitleConstraints(state: .success)
    }
    private func setupTitleConstraints(state: SubSectionState) {
        titleLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            if state == .loading {
                make.width.equalTo(60)
            } else {
                make.width.equalToSuperview()
            }
            make.height.equalTo(14)
        }
    }
    /// 刷新状态
    func refreshItemModel(model: StateItemModel) {
        stateView.isHidden = false
        iconView.isHidden = model.state != .loading
        titleLabel.isHidden = model.state != .loading
        iconView.layer.borderWidth = 1.0 / UIScreen.main.scale
        titleLabel.layer.cornerRadius = 0
        titleLabel.layer.masksToBounds = false
        setupTitleConstraints(state: .success)
        switch model.state {
        case .loading:
            stateView.state = .loading
            stateView.isHidden = true
            iconView.backgroundColor = UIColor.ud.bgFiller
            titleLabel.backgroundColor = UIColor.ud.bgFiller
            iconView.layer.borderWidth = 0
            titleLabel.layer.cornerRadius = 2
            titleLabel.layer.masksToBounds = true
            setupTitleConstraints(state: .loading)
        case .success:
            stateView.state = .success
            stateView.isHidden = true
        case .fail:
            stateView.state = .fail
        case .empty:
            stateView.state = .empty
        }
    }
    func retryClick() {
        retryCallback?()
        WorkPlaceIconCell.logger.info("retryClick")
    }
}
