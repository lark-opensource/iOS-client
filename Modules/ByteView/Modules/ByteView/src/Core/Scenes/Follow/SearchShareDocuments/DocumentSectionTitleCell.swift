//
//  DocumentSectionTitleCell.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/9/22.
//

import Foundation

class DocumentSectionTitleCell: UITableViewCell {

    private enum Layout {
        static let infoLabelFontSize: CGFloat = 14.0
        static let cellHeight: CGFloat = 22.0
        static let horizontalEdgeInsets: CGFloat = 16.0
        static let selectedHorizontalEdgeInsets: CGFloat = 6.0
    }

    let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: Layout.infoLabelFontSize)
        label.numberOfLines = 1
        label.backgroundColor = .clear
        label.textColor = .ud.textCaption
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        layoutViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        setBackgroundViewColor(UIColor.ud.bgFloat)
        setSelectedBackgroundColor(UIColor.ud.bgFloat)
        self.backgroundColor = UIColor.ud.bgFloat
        addSubview(infoLabel)
    }

    private func layoutViews() {
        infoLabel.snp.remakeConstraints {
            $0.height.equalTo(Layout.cellHeight)
            $0.bottom.equalToSuperview()
            $0.left.right.equalToSuperview().inset(Layout.horizontalEdgeInsets)
        }
    }

    func setTitle(_ title: String) {
        infoLabel.text = title
    }

    /// 设置背景View颜色
    /// - Parameter backgroundViewColor: 背景View颜色
    func setBackgroundViewColor(_ backgroundViewColor: UIColor) {
        let backgroundView = UIView()
        backgroundView.backgroundColor = backgroundViewColor
        self.backgroundView = backgroundView
    }

    /// 设置按压选中状态背景色
    /// - Parameter selectedColor: 按压选中状态背景色
    func setSelectedBackgroundColor(_ selectedColor: UIColor) {
        let selectedBackgroundView = UIView()
        let subView = UIView()
        subView.layer.cornerRadius = 6
        subView.layer.masksToBounds = true
        subView.backgroundColor = selectedColor
        selectedBackgroundView.addSubview(subView)
        subView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.selectedHorizontalEdgeInsets)
            make.top.bottom.equalToSuperview()
        }
        self.selectedBackgroundView = selectedBackgroundView
    }

}
