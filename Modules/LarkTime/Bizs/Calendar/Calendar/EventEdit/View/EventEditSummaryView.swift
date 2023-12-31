//
//  EventEditSummaryView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/18.
//

import UniverseDesignIcon
import UniverseDesignColor
import UIKit
import SnapKit
import RxSwift
import LarkInteraction
import CalendarFoundation
import LarkAIInfra

protocol EventEditSummaryViewDataType {
    var title: String { get }
    var isEditable: Bool { get }
    var inset: UIEdgeInsets { get }
    var shouldShowAIStyle: Bool { get }
    var canShowAIEntrance: Bool { get }
    var myAIName: String { get }
}

final class EventEditSummaryView: UIView, ViewDataConvertible {
    static let edgeInset = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
    var viewData: EventEditSummaryViewDataType? {
        didSet {
            let editable = viewData?.isEditable ?? false
            let title = viewData?.title ?? ""
            canShowAIEntrance = viewData?.canShowAIEntrance ?? false
            if let newInset = viewData?.inset, newInset != self.inset {
                textView.snp.remakeConstraints {
                    $0.edges.equalToSuperview().inset(newInset)
                    $0.height.greaterThanOrEqualTo(28)
                }
                self.inset = newInset
            }

            inlineAIPlaceHolderView.configAILabel(myAiNickName: viewData?.myAIName ?? "")

            guard editable != textView.isEditable || (title != textView.text ?? "") || shouldShowAIStyle != viewData?.shouldShowAIStyle else {
                return
            }
            textView.text = title
            textView.isEditable = editable
            textView.textColor = editable ? UIColor.ud.textTitle : UIColor.ud.textDisabled
            if !editable && title.isEmpty {
                // 不可编辑状态 且 标题为空情况下，placeHolder颜色也要置灰
                textView.placeholderColor = UIColor.ud.textDisabled
            }
            
            if !title.isEmpty {
                inlineAIPlaceHolderView.isHidden = true
            }
            shouldShowAIStyle = viewData?.shouldShowAIStyle ?? false
            updateAIBgAndLayout(shouldShowAIStyle: shouldShowAIStyle)
        }
    }
    // 上一个inset
    private var inset: UIEdgeInsets = .zero
    
    private var canShowAIEntrance: Bool = false
    
    private var shouldShowAIStyle: Bool = false
    
    var inlineClickHandler: (() -> Void)?

    lazy var textView: KMPlaceholderTextView = {
        let textView = KMPlaceholderTextView()
        textView.returnKeyType = .default
        textView.backgroundColor = .ud.bgFloat
        textView.isScrollEnabled = false
        textView.font = EventEditUIStyle.Font.titleText
        textView.placeholder = BundleI18n.Calendar.Calendar_Edit_AddTitle
        textView.placeholderColor = EventEditUIStyle.Color.dynamicGrayText
        return textView
    }()
    
    lazy var inlineAIPlaceHolderView: EventEditInlineAIEntraceView = {
        let view = EventEditInlineAIEntraceView()
        view.isUserInteractionEnabled = true
        view.isHidden = true
        return view
    }()
    
    lazy var inlineAISummaryBgView: UIView = {
        let view = UIView()
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutInlineAIBg()
        addSubview(textView)
        textView.delegate = self
        textView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Self.edgeInset)
        }
        
        layoutInlineAIPlaceHolder()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutInlineAIPlaceHolder() {
        addSubview(inlineAIPlaceHolderView)
        inlineAIPlaceHolderView.snp.makeConstraints { make in
            make.left.right.top.equalTo(textView)
        }
        inlineAIPlaceHolderView.onClickAIAction = { [weak self] in
            self?.inlineClickHandler?()
        }
    }
    
    private func layoutInlineAIBg() {
        addSubview(inlineAISummaryBgView)
        inlineAISummaryBgView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Self.edgeInset)
            make.left.equalToSuperview().offset(9)
            make.right.equalToSuperview().inset(7)
        }
        inlineAISummaryBgView.layer.cornerRadius = 8
    }
    
    private func updateAIBgAndLayout(shouldShowAIStyle: Bool) {
        inlineAISummaryBgView.backgroundColor = shouldShowAIStyle ? UDColor.AIPrimaryFillTransparent01(ofSize: inlineAISummaryBgView.bounds.size) : .clear
        textView.backgroundColor = shouldShowAIStyle ? .clear : .ud.bgFloat
    }
}

extension EventEditSummaryView: UITextViewDelegate {
    var summaryMaxLength: Int {
        400
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text) as NSString
        inlineAIPlaceHolderView.isHidden = !(canShowAIEntrance && newText.length == 0)
        if newText.length > summaryMaxLength {
            textView.text = newText.substring(to: summaryMaxLength)
            return false
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        inlineAIPlaceHolderView.isHidden = true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        let isTextEmpty: Bool = textView.text.isEmpty
        inlineAIPlaceHolderView.isHidden = !(isTextEmpty && canShowAIEntrance)
    }
}
