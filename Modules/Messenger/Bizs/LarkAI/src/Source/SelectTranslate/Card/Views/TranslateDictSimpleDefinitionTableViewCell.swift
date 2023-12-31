//
//  TranslateDictSimpleDefinitionTableViewCell.swift
//  LarkAI
//
//  Created by ByteDance on 2022/8/3.
//
import Foundation
import UIKit
import LarkUIKit
private enum UI {
    /// 字体大小
    static let contentFontSize: CGFloat = 16
    /// 行间距
    static let contentLineSpace: CGFloat = 4
    /// cell之间间距
    static let simpleDefCellVerticalInset: CGFloat = 4
    /// 索引标签与后面的标签隔开一个空格
    static let indexLabelHorizontalInset: CGFloat = 4
}

/// 划词翻译卡片-释义
final class DictSimpleDefinitionTableViewCell: BaseSelectTranslateCardCell {
    lazy var partOfSpeechLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFont(ofSize: UI.contentFontSize, weight: .regular)
        label.textColor = UIColor.ud.textPlaceholder
        label.sizeToFit()
        return label
    }()
    lazy var wordMeaningView: ReplicableTextView = {
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
        guard let currItem = self.item as? DictSimpleDefinitionTextModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        wordMeaningView.copyConfig = currItem.copyConfig
        partOfSpeechLabel.text = currItem.partOfSpeech
        let style = NSMutableParagraphStyle()
        style.lineSpacing = UI.contentLineSpace
        wordMeaningView.attributedText = NSAttributedString(string: currItem.definitionText,
                                                     attributes: [.paragraphStyle: style,
                                                                  .foregroundColor: UIColor.ud.textTitle,
                                                                  .font: UIFont.systemFont(ofSize: UI.contentFontSize)])
    }
    private func setupSubViews() {
        contentView.backgroundColor = .ud.bgFloat
        partOfSpeechLabel.setContentHuggingPriority(.required, for: .horizontal)
        partOfSpeechLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(partOfSpeechLabel)
        partOfSpeechLabel.snp.makeConstraints { (make) in
            make.top.leading.equalToSuperview()
        }

        /// 在句子短比较空时优先拉伸释义label，在句子长比较满时优先压缩释义label.
        wordMeaningView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        wordMeaningView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentView.addSubview(wordMeaningView)
        wordMeaningView.snp.makeConstraints { (make) in
            make.top.trailing.equalToSuperview()
            make.leading.equalTo(partOfSpeechLabel.snp.trailing).offset(UI.indexLabelHorizontalInset)
            make.bottom.equalToSuperview().offset(-UI.simpleDefCellVerticalInset)
        }
    }
}
