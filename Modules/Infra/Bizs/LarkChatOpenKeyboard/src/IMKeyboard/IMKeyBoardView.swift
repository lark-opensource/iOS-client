//
//  IMKeyBoardView.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/3/9.
//

import UIKit
import LarkKeyboardView
import EditTextView
import RustPB
import LarkOpenKeyboard
import LarkModel

public protocol IMKeyboardDelegate: LKKeyboardViewDelegate {
    func clickExpandButton()
    func inputTextViewWillSend()
    func inputTextViewSend(attributedText: NSAttributedString, scheduleTime: Int64?)
}

open class IMKeyBoardView: OpenKeyboardView<KeyboardContext, IMKeyboardMetaModel> {
    public var imKeyboardDelegate: IMKeyboardDelegate? {
        return self.delegate as? IMKeyboardDelegate
    }
    /// 输入框的最大高度
    public var textFieldMaxHeight: CGFloat = 95

    /// showNewLine 该方法底层是对UIMenuController做操作，UIMenuController是个单例
    /// 所以需要进行清空和重设，防止其他页面设置后影响
    public var showNewLine: Bool = false {
        didSet {
            if showNewLine {
                self.inputTextView.supportNewLine = !self.keyboardNewStyleEnable
            } else {
                self.inputTextView.supportNewLine = false
            }
        }
    }

    /// inputHeaderView的最大高度, 默认不展示
    open var inputHeaderMaxHeight: CGFloat { 0 }

    public enum ChatInputExpandType {
        case show
        case hide
    }

    open var expandType: ChatInputExpandType = .show {
        didSet {
            self.updateExpandType()
        }
    }

    open func updateExpandType() {
        switch self.expandType {
        case .show:
            self.expandButton.isHidden = false
        case .hide:
            self.expandButton.isHidden = true
        }
        self.updateTextViewConstraints()
    }

    // 包装输入框和expand 按钮
    private lazy var inputContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    open fileprivate(set) lazy var expandButton: UIButton = {
       return KeyboardExpandButton(buttonTapped: { [weak self] btn in
            self?.expandButtonTapped()
        })
    }()

    /// 业务上添加的输入框的顶部区域，用来放置标题的输入框
    public let inputHeaderView = UIView()

    /// 给整个输入框添加一个上方扩展区域
    public let inputContainerInnerTopView: UIView = UIView()
    /// 给整个输入框添加一个下方扩展区域
    public let inputContainerInnerBottomView: UIView = UIView()

    public let controlContainerLeftContainerView: UIView = UIView()

    public let viewModel: IMKeyboardViewModel

    public init(frame: CGRect,
                viewModel: IMKeyboardViewModel,
                keyboardNewStyleEnable: Bool = false) {
        let config = KeyboardLayouConfig(phoneStyle: InputAreaStyle(inputWrapperMargin: 0,
                                                                        inputCanvasInset: .zero,
                                                                        inputStackInset: .zero),
                                             padStyle: InputAreaStyle(inputWrapperMargin: 8,
                                                                      inputCanvasInset: .zero,
                                                                        inputStackInset: .zero))
        self.viewModel = viewModel
        super.init(frame: frame,
                   config: config,
                   viewModel: viewModel,
                   keyboardNewStyleEnable: keyboardNewStyleEnable)
        self.updateTextViewConstraints()
        self.updateExpandType()
        showNewLine = true
    }

    public func setupKeyboardModule() {
        let model = IMKeyboardMetaModel(chat: viewModel.chat.value)
        self.viewModel.module.handler(model: model)
        self.viewModel.module.keyboardPanelInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 这里设置子View
    open override func configControlContainerSubViews() {
        controlContainer.addSubview(controlContainerLeftContainerView)
        controlContainer.addSubview(inputContainerView)
        inputContainerView.addSubview(inputContainerInnerTopView)
        inputContainerView.addSubview(inputContainerInnerBottomView)
        inputContainerView.addSubview(inputHeaderView)
        inputContainerView.addSubview(inputTextView)
        inputContainerView.addSubview(expandButton)

        controlContainerLeftContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(macInputStyle ? Cons.macStyleTextContainerMargin : Cons.textContainerMargin)
            make.bottom.equalToSuperview()
            make.top.equalTo(macInputStyle ? Cons.macStyleTextContainerTopMargin : Cons.textContainerMargin)
            make.width.equalTo(0)
        }

        inputContainerView.snp.makeConstraints({ make in
            make.left.equalTo(controlContainerLeftContainerView.snp.right)
            make.right.equalToSuperview().offset(macInputStyle ? Cons.macStyleTextContainerMargin : -Cons.textContainerMargin)
            make.bottom.equalToSuperview()
            make.top.equalTo(macInputStyle ? Cons.macStyleTextContainerTopMargin : Cons.textContainerMargin)
        })

        /// 这里设置为height 0，对用业务方进行更新
        inputContainerInnerTopView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(0)
        }

        inputContainerInnerBottomView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Cons.textFieldBottomMargin)
            make.height.equalTo(0).priority(.low)
        }

        expandButton.snp.makeConstraints { make in
            make.size.equalTo(Cons.buttonSize)
            make.right.equalToSuperview().offset(-12)
            make.top.equalTo(inputContainerInnerTopView.snp.bottom).offset(Cons.buttonTopMargin)
        }
        /// 默认header不展示
        inputHeaderView.snp.makeConstraints { make in
            make.left.right.equalTo(inputTextView)
            make.top.equalTo(inputContainerInnerTopView.snp.bottom).offset(Cons.inputHeaderTopMargin)
            make.height.lessThanOrEqualTo(inputHeaderMaxHeight)
        }
    }

    func expandButtonTapped() {
        self.imKeyboardDelegate?.clickExpandButton()
        self.endEditing(true)
    }

    private func updateTextViewConstraints() {
        inputTextView.snp.remakeConstraints { make in
            make.top.equalTo(inputHeaderView.snp.bottom)
            make.left.equalTo(Cons.textFieldLeftMargin)
            make.bottom.equalTo(inputContainerInnerBottomView.snp.top)
            make.height.greaterThanOrEqualTo(Cons.textFieldMinHeight)
            make.height.lessThanOrEqualTo(textFieldMaxHeight)
            switch self.expandType {
            case .show:
                make.right.equalTo(self.expandButton.snp.left).offset(-5)
            case .hide:
                make.right.equalToSuperview()
            }
        }
    }

    /// 当键盘设置为不可用的时候-> 禁止按钮的交互
    open override func setSubViewsEnable(enable: Bool) {
        self.expandButton.isEnabled = enable
        self.expandButton.isUserInteractionEnabled = enable
        super.setSubViewsEnable(enable: enable)
    }

    open func sendNewMessage(scheduleTime: Int64? = nil) {
        self.imKeyboardDelegate?.inputTextViewWillSend()
        let attributedText = getTrimTailSpacesAttributedString()
        self.imKeyboardDelegate?.inputTextViewSend(attributedText: attributedText, scheduleTime: scheduleTime)
    }

    open func getTrimTailSpacesAttributedString() -> NSAttributedString {
        return KeyboardStringTrimTool.trimTailAttributedString(attr: inputTextView.attributedText ?? NSAttributedString(), set: trimCharacterSetForAttributedString())
    }

    open func trimCharacterSetForAttributedString() -> CharacterSet {
        return .whitespaces
    }

}

extension IMKeyBoardView {
    public var inputKeyboardPanel: LarkKeyboardView.KeyboardPanel { self.keyboardPanel }
    public var inputProtocolSet: TextViewInputProtocolSet? { self.textViewInputProtocolSet }
}

public extension IMKeyBoardView {
    enum Cons {
        static var buttonSize: CGSize { .square(24) }
        static var macStyleTextContainerMargin: CGFloat { 0 }
        static var textFieldMinHeight: CGFloat { 22.auto() }
        static var textContainerMargin: CGFloat { 8 }
        static var macStyleTextContainerTopMargin: CGFloat { 8 }
        static var inputHeaderTopMargin: CGFloat { 12 }
        static var textFieldLeftMargin: CGFloat { 8 }
        static var textContainerMinHeight: CGFloat { 46 }
        static var textFieldBottomMargin: CGFloat { 12 }
        static var buttonTopMargin: CGFloat {
            (textContainerMinHeight - buttonSize.height) / 2
        }
    }
}

