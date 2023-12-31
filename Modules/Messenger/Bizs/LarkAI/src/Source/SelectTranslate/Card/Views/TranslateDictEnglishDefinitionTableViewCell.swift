//
//  TranslateDictEnglishDefinitionTableViewCell.swift
//  LarkAI
//
//  Created by ByteDance on 2022/8/3.
//
import Foundation
import LarkUIKit
import UIKit
private enum UI {
    /// 字体大小
    static let contentFontSize: CGFloat = 16
    /// 行间距
    static let contentLineSpace: CGFloat = 4
    /// cell之间间距
    static let cellVerticalInset: CGFloat = 12
    /// 索引标签与后面的标签隔开一个空格
    static let indexLabelHorizontalInset: CGFloat = 4
}

/// 划词翻译卡片-英英释义
final class DictEnglishDefinitionTableViewCell: BaseSelectTranslateCardCell {
    lazy var englishDefinitionIndexLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFont(ofSize: UI.contentFontSize, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        return label
    }()
    lazy var englishDefinitionView: ReplicableTextView = {
        let replicableTextView = ReplicableTextView()
        replicableTextView.font = UIFont.systemFont(ofSize: UI.contentFontSize, weight: .regular)
        replicableTextView.textColor = UIColor.ud.textTitle
        replicableTextView.sizeToFit()
        return replicableTextView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func setCellInfo() {
        guard let currItem = self.item as? DictEnglishDefinitionModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        englishDefinitionView.copyConfig = currItem.copyConfig
        englishDefinitionIndexLabel.text = String(currItem.englishDefinitionIndex) + "."
        let style = NSMutableParagraphStyle()
        style.lineSpacing = UI.contentLineSpace
        englishDefinitionView.attributedText = NSAttributedString(string: currItem.englishDefinitionText,
                                                     attributes: [.paragraphStyle: style,
                                                                  .foregroundColor: UIColor.ud.textTitle,
                                                                  .font: UIFont.systemFont(ofSize: UI.contentFontSize)])
    }

    private func setupSubViews() {

        contentView.backgroundColor = .ud.bgFloat
        englishDefinitionIndexLabel.setContentHuggingPriority(.required, for: .horizontal)
        englishDefinitionIndexLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(englishDefinitionIndexLabel)
        englishDefinitionIndexLabel.snp.makeConstraints { (make) in
            make.top.leading.equalToSuperview()
        }

        englishDefinitionView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        englishDefinitionView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentView.addSubview(englishDefinitionView)
        englishDefinitionView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalTo(englishDefinitionIndexLabel.snp.trailing).offset(UI.indexLabelHorizontalInset)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-UI.cellVerticalInset)
        }
    }
}
