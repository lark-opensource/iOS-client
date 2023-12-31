//
//  ChatMessageEditView.swift
//  ByteView
//
//  Created by wulv on 2020/12/15.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import ByteViewUI

extension ChatMessageEditView {

    enum Layout {
        fileprivate static var MarginRight: CGFloat {
            max(VCScene.safeAreaInsets.right, 20)
        }
        fileprivate static var MarginLeft: CGFloat {
            max(VCScene.safeAreaInsets.left, 20)
        }
        fileprivate static let MarginVertical: CGFloat = 11
        fileprivate static let LineViewHeight: CGFloat = 0.5
        fileprivate static let FontSize: CGFloat = 16
        fileprivate static let FontHeight: CGFloat = 22
        static let MinHeight: CGFloat = FontHeight + 2 * MarginVertical
    }
}

class ChatMessageEditView: UIView {

    var maxLine: Int = 7
    var sendClosure: ((String?) -> Void)?
    var beforeEdit: (() -> Void)?
    var allowInput: Bool = true

    private lazy var topLine: UIView = {
        let line = UIView(frame: .zero)
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    private lazy var textView: UITextView = {
        let view = UITextView(frame: .zero)
        view.backgroundColor = UIColor.ud.bgBody
        view.textColor = UIColor.ud.textTitle
        view.keyboardAppearance = .default
        view.keyboardType = .default
        view.returnKeyType = .send
        view.isEditable = true
        view.isSelectable = true
        view.textAlignment = .left
        view.layoutManager.allowsNonContiguousLayout = false
        view.enablesReturnKeyAutomatically = true
        view.dataDetectorTypes = UIDataDetectorTypes.all
        view.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        view.alwaysBounceHorizontal = false
        view.delegate = self

        let style = NSMutableParagraphStyle()
        let lineHeight: CGFloat = Layout.FontHeight
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.lineBreakMode = .byWordWrapping
        let font = UIFont.systemFont(ofSize: Layout.FontSize, weight: .regular)
        let offset = (lineHeight - font.lineHeight) / 4.0
        view.typingAttributes = [.paragraphStyle: style, .baselineOffset: offset, .font: font, .foregroundColor: UIColor.ud.textTitle]
        return view
    }()

    private(set) lazy var placeHolderLabel: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.ud.textPlaceholder
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBody
        loadSubviews()
        bindTextView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadSubviews() {
        addSubview(topLine)
        topLine.snp.makeConstraints { (maker) in
            maker.left.right.top.equalToSuperview()
            maker.height.equalTo(Layout.LineViewHeight)
        }

        addSubview(textView)
        textView.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview().inset(Layout.MarginVertical)
            maker.left.equalToSuperview().inset(Layout.MarginLeft)
            maker.right.equalToSuperview().inset(Layout.MarginRight)
        }

        textView.addSubview(placeHolderLabel)
        placeHolderLabel.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(3)
            maker.center.equalToSuperview()
        }
    }

    func remakeTextViewLayout() {
        textView.snp.remakeConstraints { (maker) in
            maker.top.bottom.equalToSuperview().inset(Layout.MarginVertical)
            maker.left.equalToSuperview().inset(Layout.MarginLeft)
            maker.right.equalToSuperview().inset(Layout.MarginRight)
        }
    }
}

// MARK: TextView
extension ChatMessageEditView {

    private func bindTextView() {

        textView.rx.text
            .map { $0?.isEmpty == false }
            .bind(to: placeHolderLabel.rx.isHidden)
            .disposed(by: rx.disposeBag)

        textView.rx.didChange
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                // 动态高度
                let textHeight = self.textView.contentSize.height

                let maxHeight = Layout.FontHeight * CGFloat(self.maxLine)
                var newHeight: CGFloat = 0
                if textHeight <= Layout.FontHeight {
                    newHeight = self.getTextViewHeight()
                } else {
                    newHeight = max(textHeight, Layout.FontHeight)
                }

                if newHeight <= maxHeight {
                    self.textView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                    self.snp.updateConstraints { (maker) in
                        maker.height.equalTo(newHeight + 2 * Layout.MarginVertical)
                    }
                } else if self.textView.frame.size.height != maxHeight {
                    // 固定最大高度
                    self.snp.updateConstraints { (maker) in
                        maker.height.equalTo(maxHeight + 2 * Layout.MarginVertical)
                    }
                }
            })
            .disposed(by: rx.disposeBag)

    }

    private func getTextViewHeight() -> CGFloat {
        let font = UIFont.systemFont(ofSize: Layout.FontSize, weight: .regular)
        let width = (VCScene.rootTraitCollection?.isRegular ?? false ? 540 : VCScene.bounds.width) - textView.textContainer.lineFragmentPadding * 2 - Layout.MarginLeft - Layout.MarginRight - 4
        let textHeight = self.textView.text.vc.boundingHeight(width: width, font: font) / font.lineHeight * Layout.FontHeight
        return max(textHeight, Layout.FontHeight)
    }

    func getEditViewHeight() -> CGFloat {
        let textHeight = getTextViewHeight()
        let editViewHeight = min(textHeight, Layout.FontHeight * CGFloat(self.maxLine)) + Layout.MarginVertical * 2
        return editViewHeight
    }

    func clearText() {
        textView.text = nil // 不会触发didChange回调, 需要额外处理高度更新
        snp.updateConstraints { (maker) in
            maker.height.equalTo(Layout.MinHeight)
        }
    }

    func getText() -> String {
        return textView.text
    }

    func setText(_ text: String) {
        textView.text = text
    }

    func endEditing() {
        textView.resignFirstResponder()
    }
}

extension ChatMessageEditView: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let sendClosure = sendClosure {
                sendClosure(textView.text)
            }
            return false
        }
        return true
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        guard allowInput else { return false }
        if let closure = beforeEdit {
            closure()
        }
        return true
    }
}
