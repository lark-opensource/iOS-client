//
//  TranslateDictExampleSentenceTableViewCell.swift
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
    static let cellVerticalInset: CGFloat = 12
    /// 索引标签与后面的标签隔开一个空格
    static let indexLabelHorizontalInset: CGFloat = 4
}

/// 划词翻译卡片-双语例句
final class DictExampleSentenceTableViewCell: BaseSelectTranslateCardCell {
    lazy var exampleSentenceIndexLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFont(ofSize: UI.contentFontSize, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var originSentenceView: ReplicableTextView = {
        let replicableTextView = ReplicableTextView()
        replicableTextView.font = UIFont.systemFont(ofSize: UI.contentFontSize, weight: .regular)
        replicableTextView.textColor = UIColor.ud.textTitle
        replicableTextView.sizeToFit()
        return replicableTextView
    }()
    lazy var translateSentenceView: ReplicableTextView = {
        let replicableTextView = ReplicableTextView()
        replicableTextView.font = UIFont.systemFont(ofSize: UI.contentFontSize, weight: .regular)
        replicableTextView.textColor = UIColor.ud.textPlaceholder
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
        guard let currItem = self.item as? DictExampleSentenceModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        originSentenceView.copyConfig = currItem.copyConfig
        translateSentenceView.copyConfig = currItem.copyConfig
        exampleSentenceIndexLabel.text = String(currItem.exampleSentenceIndex) + "."
        let style = NSMutableParagraphStyle()
        style.lineSpacing = UI.contentLineSpace
        translateSentenceView.attributedText = NSAttributedString(string: currItem.translationText,
                                                     attributes: [.paragraphStyle: style,
                                                                  .foregroundColor: UIColor.ud.textPlaceholder,
                                                                  .font: UIFont.systemFont(ofSize: UI.contentFontSize)])
        originSentenceView.attributedText = NSAttributedString(string: currItem.originText,
                                                     attributes: [.paragraphStyle: style,
                                                                  .foregroundColor: UIColor.ud.textTitle,
                                                                  .font: UIFont.systemFont(ofSize: UI.contentFontSize)])
    }

    private func setupSubViews() {
        contentView.backgroundColor = .ud.bgFloat
        exampleSentenceIndexLabel.setContentHuggingPriority(.required, for: .horizontal)
        exampleSentenceIndexLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(exampleSentenceIndexLabel)
        exampleSentenceIndexLabel.snp.makeConstraints { (make) in
            make.top.leading.equalToSuperview()
        }

        originSentenceView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        originSentenceView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentView.addSubview(originSentenceView)
        originSentenceView.snp.makeConstraints { (make) in
            make.top.trailing.equalToSuperview()
            make.leading.equalTo(exampleSentenceIndexLabel.snp.trailing).offset(UI.indexLabelHorizontalInset)
        }

        translateSentenceView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        translateSentenceView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentView.addSubview(translateSentenceView)
        translateSentenceView.snp.makeConstraints { (make) in
            make.top.equalTo(originSentenceView.snp.bottom).offset(UI.contentLineSpace)
            make.leading.equalTo(originSentenceView.snp.leading)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-UI.cellVerticalInset)
        }
    }
}
