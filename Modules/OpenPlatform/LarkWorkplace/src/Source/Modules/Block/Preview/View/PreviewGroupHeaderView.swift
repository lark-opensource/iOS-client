//
//  PreviewGroupHeaderView.swift
//  LarkWorkplace
//
//  Created by yinyuan on 2021/2/24.
//

import Foundation

/// Block 真机预览界面的 Group Header 控件，只有一个标题
final class PreviewGroupHeaderView: UICollectionReusableView {

    /// 分组标题
    private lazy var titleLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.font = .systemFont(ofSize: 17, weight: .medium)
        headerLabel.textColor = UIColor.ud.textTitle
        headerLabel.numberOfLines = 1
        headerLabel.textAlignment = .left
        return headerLabel
    }()

    // MARK: view initial
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(titleLabel)
        self.backgroundColor = UIColor.ud.bgBody
        setConstraint()
    }

    private func setConstraint() {
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.right.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    func updateData(groupTitle: String) {
        titleLabel.text = groupTitle
    }
}
