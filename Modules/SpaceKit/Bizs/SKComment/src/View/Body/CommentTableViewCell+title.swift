//
//  CommentTableViewCell+title.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/9/30.
//


import SnapKit
import Foundation
import SKResource

extension CommentTableViewCell {
    
    final class TitleView: UIView {
        
        private lazy var nameLabel: UILabel = {
            let view = UILabel()
            view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            view.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
            return view
        }()
        
        private lazy var timeLabel: UILabel = {
            let view = UILabel()
            view.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
            view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            return view
        }()
        
        private lazy var editLabel: UILabel = {
            let view = UILabel()
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            view.setContentHuggingPriority(.defaultLow, for: .horizontal)
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(nameLabel)
            addSubview(timeLabel)
            addSubview(editLabel)

            nameLabel.snp.makeConstraints {
                $0.leading.top.bottom.equalToSuperview()
                $0.trailing.equalTo(timeLabel.snp.leading).offset(-2)
            }
            
            timeLabel.snp.makeConstraints {
                $0.top.bottom.equalToSuperview()
                $0.trailing.equalTo(editLabel.snp.leading).offset(-2)
            }
            
            editLabel.snp.makeConstraints {
                $0.trailing.top.bottom.equalToSuperview()
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setFont(font: UIFont, nameColor: UIColor, extraInfoColor: UIColor) {
            _update(label: nameLabel, font: font, textColor: nameColor)
            _update(label: timeLabel, font: font, textColor: extraInfoColor)
            _update(label: editLabel, font: font, textColor: extraInfoColor)
        }
        
        private func _update(label: UILabel, font: UIFont, textColor: UIColor) {
            label.font = font
            label.textColor = textColor
        }
        
        func config(displayName: String?, timeString: String?, editted: Bool) {
            nameLabel.text = displayName
            timeLabel.text = timeString
            editLabel.text = editted ? BundleI18n.SKResource.Doc_Comment_Edited : ""
        }
    }
}
