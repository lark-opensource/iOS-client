//
//  SearchErrorInfoView.swift
//  LarkSearch
//
//  Created by chenyanjie on 2023/8/31.
//

import Foundation
import RustPB
import UniverseDesignEmpty

public class SearchErrorInfoView: UIView, UITextViewDelegate {
    private var btnTappedAction: (() -> Void)?
    private let textView = UITextView()
    let icon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody

        addSubview(icon)
        icon.isHidden = true
        icon.snp.makeConstraints({ make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(100)
        })

        addSubview(textView)
        textView.backgroundColor = UIColor.ud.bgBody
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.delegate = self
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public func updateView(errorInfo: Search_V2_SearchCommonResponseHeader.ErrorInfo, isNeedShowIcon: Bool, btnTappedAction: (() -> Void)?) {

        if isNeedShowIcon {
            var image: UIImage
            if errorInfo.hasIcon, let iconImage = errorInfo.icon.udImage {
                image = iconImage
            } else {
                image = UDEmptyType.noAccess.defaultImage()
            }
            icon.image = image
            icon.isHidden = false
            textView.snp.makeConstraints({ make in
                make.top.equalTo(icon.snp.bottom).offset(12)
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalToSuperview()
            })
        } else {
            textView.snp.makeConstraints({ make in
                make.top.equalToSuperview()
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalToSuperview()
            })
        }

        var originStr: String = ""
        var hasExtraTapStr = false
        if errorInfo.hasMainText {
            originStr = errorInfo.mainText
        }
        let titleLength = originStr.count
        if !originStr.isEmpty, !errorInfo.ops.isEmpty, let op = errorInfo.ops.first {
            hasExtraTapStr = true
            if op.hasText {
                originStr.append(" " + op.text)
            }
        }
        let attributeStr = NSMutableAttributedString(string: originStr)
        attributeStr.addAttributes([.foregroundColor: UIColor.ud.textCaption], range: NSRange(location: 0, length: attributeStr.length))
        if hasExtraTapStr {
            let range = NSRange(location: titleLength, length: (originStr.count - titleLength))
            attributeStr.addAttributes([.foregroundColor: UIColor.ud.functionInfo600], range: range)
            if let btnTappedAction = btnTappedAction, let op = errorInfo.ops.first, case .ignoreQuotaSearch = op.opType {
                self.btnTappedAction = btnTappedAction
                attributeStr.addAttributes([.link: "more://"], range: range)
            }
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributeStr.addAttributes([.paragraphStyle: paragraphStyle, .font: UIFont.systemFont(ofSize: 14)], range: NSRange(location: 0, length: attributeStr.length))
        self.textView.attributedText = attributeStr
    }
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString == "more://", let btnTappedAction = self.btnTappedAction {
            btnTappedAction()
        }
        return false
    }
}
