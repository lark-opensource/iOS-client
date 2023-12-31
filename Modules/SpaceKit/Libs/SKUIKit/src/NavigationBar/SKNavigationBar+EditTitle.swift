//
//  SKNavigationBar+EditTitle.swift
//  SKUIKit
//
//  Created by JiayiGuo on 2021/4/30.
// swiftlint:disable line_length


import SKFoundation
import SKResource
import UniverseDesignColor

extension SKNavigationBar: TitleEditorDelegate {
    public func didSaveEditing(_ titleContent: String) {
        title = titleContent
        if maskUIView.superview == nil {
            window?.addSubview(maskUIView)
        }
        maskUIView.snp.remakeConstraints { make in
            make.edges.equalTo(self)
        }   //退出编辑态 maskUIView缩小
        NotificationCenter.default.removeObserver(self)
        keyboard?.stop()
        isEditingTitle = false
        if let title = title {
            renameDelegate?.renameSheet(title, nodeToken: nil, completion: nil)
        }
    }
}

extension SKNavigationBar {

    func addMaskUIView() {
        //增加一个全局的uiview,用来监听编辑标题过程中是否点击了其他区域以及鼠标移开标题
        guard maskUIView.superview == nil else { return }
        window?.addSubview(maskUIView)
        maskUIView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        maskUIView.backgroundColor = .clear
        maskUIView.editTitleDelegate = self
    }
    
    @objc
    func editorViewDidChange(_ notification: Notification) {
        guard let currentTextField = (notification.object as? UITextField) else { return }
        guard var changedTitle = currentTextField.text else { return }
        if changedTitle.count > 255 {
            changedTitle = changedTitle.mySubString(to: 255)  //输入标题长度限制255
            title = changedTitle
            
        } else if changedTitle.isEmpty {
            title = BundleI18n.SKResource.Doc_More_RenameSheetPlaceholder
            titleEditorView.placeholder = BundleI18n.SKResource.Doc_More_RenameSheetPlaceholder
        } else {
            title = changedTitle
        }
    }
    
    func handleKeyboardWillHide() {
        if shouldBeginEditingTitleAfterKeyboardDidHide {
            titleEditorView.becomeFirstResponder()
            isEditingTitle = true
            shouldBeginEditingTitleAfterKeyboardDidHide = false
        } else if isEditingTitle {
            titleEditorView.removeFromSuperview()
            if let currentTitle = titleEditorView.text {
                didSaveEditing(currentTitle)
            } else {
                didSaveEditing(BundleI18n.SKResource.Doc_Facade_UntitledSheet)
            }
        }
    }

    func beginEditingTitle() {
        guard titleCanRename == true && titleShouldRename == true && SKDisplay.pad else { return }

        guard !isEditingTitle else { return }

        if maskUIView.superview == nil {
            window?.addSubview(maskUIView)
        }
        maskUIView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        keyboard?.start()

        if let titleInfo = titleInfo {
            if titleInfo.title == BundleI18n.SKResource.Doc_Facade_UntitledSheet {
                titleEditorView.placeholder = BundleI18n.SKResource.Doc_More_RenameSheetPlaceholder
            } else {
                titleEditorView.text = titleInfo.title
            }
            titleEditorView.originalTitleValue = titleInfo.title
        } else {
            titleEditorView.placeholder = BundleI18n.SKResource.Doc_More_RenameSheetPlaceholder
            titleEditorView.originalTitleValue = nil
        }

        if renameDelegate?.beginRenamingSheet() == true {
            // 说明是从 sheet 编辑态切换过来的，要等键盘下去之后再成为第一响应者，否则键盘的消失事件会被捕捉到，误触发 handleKeyboardHide()
            shouldBeginEditingTitleAfterKeyboardDidHide = true
        } else {
            titleEditorView.becomeFirstResponder()
            isEditingTitle = true
        }

    }
}

protocol TitleEditorDelegate: AnyObject {
    func didSaveEditing(_ titleContent: String)
}

class TitleEditorView: UITextField, UITextFieldDelegate {
    var originalTitleValue: String? //编辑修改之前的原始标题值
    weak var titleDelegate: TitleEditorDelegate?
    
    var sidePadding: CGFloat = 0
    var topPadding: CGFloat = 0

    override var selectedTextRange: UITextRange? {
        willSet {
            DocsLogger.debug("will set text range")
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        delegate = self
        textAlignment = .center
        font = UIFont.systemFont(ofSize: 17, weight: .medium)
        borderStyle = .roundedRect
        layer.ud.setBorderColor(UIColor.ud.colorfulBlue)
        textColor = UIColor.ud.textTitle
        layer.masksToBounds = true
        layer.cornerRadius = 4
        layer.borderWidth = 1.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width <= sidePadding * 2 || bounds.height <= topPadding * 2 {
            quitEditing()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.origin.x + sidePadding,
            y: bounds.origin.y + topPadding,
            width: bounds.size.width - sidePadding * 2,
            height: bounds.size.height - topPadding * 2
        )
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return self.textRect(forBounds: bounds)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        let startPosition = position(from: beginningOfDocument, offset: 0)
        let endPosition = position(from: endOfDocument, offset: 0)
        if let startPos = startPosition, let endPos = endPosition {
            selectedTextRange = textRange(from: startPos, to: endPos)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        return updatedText.count <= 255
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveEditing()
        resignFirstResponder()
        
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(quitEditing), discoverabilityTitle: BundleI18n.SKResource.CreationMobile_Sheets_ShortCutKey_EditCancel),
                UIKeyCommand(input: UIKeyCommand.inputReturn, modifierFlags: [], action: #selector(saveEditing), discoverabilityTitle: BundleI18n.SKResource.CreationMobile_Sheets_ShortCutKey_EditFinished) ]
    }
    
    @objc
    func quitEditing() {
        removeFromSuperview()
        if let originalTitleValue = originalTitleValue {
            titleDelegate?.didSaveEditing(originalTitleValue)
        } else {
            titleDelegate?.didSaveEditing(BundleI18n.SKResource.Doc_Facade_UntitledSheet) //取消的时候原本的标题名就为空
            return
        }
    }
    
    @objc
    func saveEditing() {
        removeFromSuperview()
        if let currentTitleValue = text {
            if currentTitleValue .isEmpty {
                titleDelegate?.didSaveEditing(BundleI18n.SKResource.Doc_Facade_UntitledSheet) //保存的时候标题名为空
            } else {
                titleDelegate?.didSaveEditing(currentTitleValue)
            }
        }
    }
}


protocol EditTitleDelegate: AnyObject {
    var titleEditorView: TitleEditorView { get }
    var isEditingTitle: Bool { get }
    var titleFieldRect: CGRect { get }
    func addEditorView(beginEditing: Bool)
    func removeEditorView()
    func saveCurrentTitle()
}

public protocol SheetRenameRequest: AnyObject {
    func beginRenamingSheet() -> Bool
    func renameSheet(_ newTitle: String, nodeToken: String?, completion: ((_ error: Error?) -> Void)?)
}

//editorTitleView委托NavBar
extension SKNavigationBar: EditTitleDelegate {

    var titleFieldRect: CGRect {
        if maskUIView.bounds == .zero || titleView.bounds == .zero {
            return .zero
        } else {
            return titleView.convert(titleView.bounds, to: maskUIView)
        }
    }

    func addEditorView(beginEditing: Bool) {
        guard titleView.frame != .zero else { return }
        if titleEditorView.superview == nil {
            titleEditorView.sidePadding = layoutAttributes.textFieldSidePadding
            titleEditorView.topPadding = layoutAttributes.textFieldVerticalPadding
            addSubview(titleEditorView)
            titleEditorView.snp.makeConstraints { (make) in
                make.left.equalTo(titleLabel.snp.left).offset(-layoutAttributes.textFieldSidePadding)
                make.right.equalTo(titleLabel.snp.right).offset(layoutAttributes.textFieldSidePadding)
                make.top.equalTo(titleLabel.snp.top).offset(-layoutAttributes.textFieldVerticalPadding)
                make.bottom.equalTo(titleLabel.snp.bottom).offset(layoutAttributes.textFieldVerticalPadding)
            }
        }

        titleEditorView.text = titleInfo?.title
        if beginEditing {
            beginEditingTitle()
        }
    }

    func removeEditorView() {
        guard titleEditorView.superview != nil else { return }
        titleEditorView.resignFirstResponder()
        titleEditorView.removeFromSuperview()
    }

    func saveCurrentTitle() {
        if isEditingTitle {
            titleEditorView.saveEditing()
        }
    }
}

class MaskUIView: UIView {
    weak var editTitleDelegate: EditTitleDelegate?
    var lastTouchTimestamp: TimeInterval?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if #available(iOS 13.4, *) {
            if event?.type == .hover || event == nil {
                if editTitleDelegate?.titleFieldRect.contains(point) == true { // hover 到标题栏
                    if editTitleDelegate?.titleEditorView.superview == nil {
                        editTitleDelegate?.addEditorView(beginEditing: false)
                    }
                } else if editTitleDelegate?.isEditingTitle == false { // hover 移开标题栏
                    editTitleDelegate?.removeEditorView()
                }
                return nil
            }
        }
        // MaskUIView在titleEditor上面 通过判断点的坐标决定是否屏蔽
        if editTitleDelegate?.titleFieldRect.contains(point) == true {
            if editTitleDelegate?.isEditingTitle == false {
                editTitleDelegate?.addEditorView(beginEditing: true)
                lastTouchTimestamp = event?.timestamp
                return self
            } else if event?.timestamp == lastTouchTimestamp {
                return self
            } else {
                lastTouchTimestamp = nil
                return nil
            }
        }

        if self.frame.contains(point) != true {
            return nil
        }
        
        editTitleDelegate?.saveCurrentTitle()
        return nil
    }
}
