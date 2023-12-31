//
//  BTCardRichTextValueView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/30.
//

import Foundation
import UniverseDesignFont

final class BTCardRichTextValueView: UIView {
    
    private struct Const {
        static let textDefaultFont = UDFont.body2
    }
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setInternal(_ model: BTCardFieldCellModel,
                              font: UIFont = Const.textDefaultFont,
                              numberOfLines: Int = 1) {
        if let data = model.getFieldData(type: BTRichTextData.self).first,
            let segments = data.segments  {
            textLabel.numberOfLines = numberOfLines
            textLabel.attributedText = BTUtil.convert(segments, font: font, lineBreakMode: .byTruncatingTail)
        } else {
            textLabel.attributedText = nil
        }
    }
    
}

extension BTCardRichTextValueView: BTTextCellValueViewProtocol {
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        setInternal(model)
    }
    
    func set(_ model: BTCardFieldCellModel, with font: UIFont, numberOfLines: Int) {
        setInternal(model, font: font, numberOfLines: numberOfLines)
    }
}

class BTCardTitleTextCalculaor {
    
    static let label = UILabel()
    // 是否是单行
    static func isSingleLine(_ model: BTCardFieldCellModel, font: UIFont, containerWidth: CGFloat) -> Bool {
        if model.isRichText,
           let richText = model.getFieldData(type: BTRichTextData.self).first {
            if let segments = richText.segments {
                label.attributedText = BTUtil.convert(segments, font: font, lineBreakMode: .byTruncatingTail)
                return label.intrinsicContentSize.width / containerWidth <= 1.0
            } else {
                return true
            }
        } else if model.isSimpleText,
                  let simpleText = model.getFieldData(type: BTSimpleTextData.self).first {
            let text = simpleText.text
            label.text = text
            label.font = font
            return label.intrinsicContentSize.width / containerWidth <= 1.0
        } else if model.isDate,
                  let dateText = model.getFieldData(type: BTSimpleTextData.self).first {
            let text = dateText.text
            label.text = text
            label.font = font
            return label.intrinsicContentSize.width / containerWidth <= 1.0
        }
        return true
    }
    
    static func caculateTextWidth(text: String, font: UIFont, inset: UIEdgeInsets) -> CGFloat {
        self.label.text = text
        self.label.font = font
        return self.label.intrinsicContentSize.width + inset.left + inset.right
    }
}
