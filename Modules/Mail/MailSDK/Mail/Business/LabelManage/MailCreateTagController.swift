//
//  MailCreateTagController.swift
//  MailSDK
//
//  Created by majx on 2019/10/28.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import LarkAlertController
import Homeric
import UniverseDesignColorPicker
import UniverseDesignFont
import UniverseDesignInput
import UniverseDesignIcon

protocol MailCreateLabelTagDelegate: AnyObject {
    func didCreateNewLabel(labelId: String)
    func didCreateLabelAndDismiss(_ toast: String, create: Bool)
}

protocol MailCreateFolderTagDelegate: AnyObject {
    func didCreateNewFolder(labelId: String)
    func didCreateFolderAndDismiss(_ toast: String, create: Bool, moveTo: Bool, folder: MailFilterLabelCellModel)
    func didEditFolderAndDismiss()
    func didEditFolder(labelId: String)
}

class MailCreateTagController: MailBaseViewController, UDTextFieldDelegate {
    enum Scene {
        case newLabel
        case newFolder
        case editLabel
        case editFolder
        case newFolderAndMoveTo
    }

    // MARK: - Property
    private let restrictedLabels: [String] = MailFilterLabelCellModel.restrictedLabels
    private var currentHeight = Display.height - Display.topSafeAreaHeight - 40
    private var disposeBag = DisposeBag()
    private let colorConfig = MailLabelDefultColorConfig()
    private var selectedColorPalette: MailLabelsColorPaletteItem? //UDPaletteItem
    weak var delegate: MailCreateLabelTagDelegate?
    weak var folderDelegate: MailCreateFolderTagDelegate?
    var scene: Scene = .newLabel
    var label: MailFilterLabelCellModel?
    var loadLabels: [MailFilterLabelCellModel] = []
    var showSuccessToast: Bool = true
    var parentID: String = Mail_FolderId_Root
    var userOrderIndex: Int64?
    var folderTree: FolderTree?

    private let labelMaxCharacters = 255
    private let folderMaxCharacters = 250

    var fromLabelId: String = ""
    var threadIds: [String] = []

    lazy var tipsView = MailEditTagTipView()
    var locationButton = UIButton()

    let accountContext: MailAccountContext

    override var navigationBarTintColor: UIColor {
        return ModelViewHelper.navColor()
    }

    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shouldRecordMailState = false
        setupViews()
        loadData()
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedKeyboardWillHideNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedKeyboardDidShowNotification), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedKeyboardFrameDidChangeNotification(_:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedKeyboardFrameDidChangeNotification(_:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
    }

    @objc
    func didReceivedKeyboardWillHideNotification() {
        bgMask.removeFromSuperview()
    }

    @objc
    func didReceivedKeyboardDidShowNotification() {
        view.addSubview(bgMask)
        bgMask.snp.makeConstraints { make in
            make.top.equalTo(labelTextField.snp.bottom)
            make.width.bottom.equalToSuperview()
        }
    }

    @objc
    func didReceivedKeyboardFrameDidChangeNotification(_ notify: Notification) {
        guard let userinfo = notify.userInfo else {
            return
        }

        if notify.name == UIResponder.keyboardWillShowNotification {
            guard let keyboardFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
//            view.addSubview(bgMask)
//            bgMask.snp.makeConstraints { make in
//                make.left.equalToSuperview()
//                make.bottom.eq
//            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        focus()
        if Store.settingData.mailClient && scene == .editFolder {
            if abnormalCharacter((labelTextField.input.text ?? "").removeAllSpaceAndNewlines) {
                self.setSaveBtnEnable(false)
                self.updateTipViewText(BundleI18n.MailSDK.Mail_Folder_SpecialCharactersNotSupported)
             }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MailRoundedHUD.remove(on: self.view)
        blur()
    }

    func loadData() {
        if scene == .newLabel {
            selectedColorAtIndex(0)
            selectedColorPalette = makeColorPaltte(colorConfig.colorItems.first ?? .clear)
        } else if scene == .editLabel, let label = label {
            /// if matched color, selected in the color picker
            if let labelColorIndex = colorConfig.bgColorHexItems
                .firstIndex(where: { $0.uppercased() == label.bgColorHex?.uppercased() }) {
                selectedColorAtIndex(labelColorIndex)
                selectedColorPalette = makeColorPaltte(colorConfig.colorItems[labelColorIndex])
            }
            /// convert old version2 colors config to current colors
            else if let labelColorIndex = MailLabelColorOldVersion2Config().paletteItems
                .firstIndex(where: { $0.fontColor.hex6?.uppercased() == label.fontColorHex?.uppercased() }) {
                selectedColorAtIndex(labelColorIndex)
                selectedColorPalette = makeColorPaltte(colorConfig.colorItems[labelColorIndex])
            }
            /// convert old version colors config to current colors
            else if let labelColorIndex = MailLabelColorOldVersionConfig().paletteItems
                .firstIndex(where: { $0.fontColor.hex6?.uppercased() == label.fontColorHex?.uppercased() }) {
                selectedColorAtIndex(labelColorIndex)
                selectedColorPalette = makeColorPaltte(colorConfig.colorItems[labelColorIndex])
            } else {
                /// if can't match color, use label's custom color
                selectedColorPalette = MailLabelsColorPaletteItem(name: .custom,
                                                                  bgColor: label.bgColor ?? UIColor.ud.udtokenTagBgBlue.alwaysLight,
                                                                  fontColor: label.fontColor ?? UIColor.ud.udtokenTagTextSBlue.alwaysLight)
            }
            labelTextField.text = label.text
        } else if scene == .editFolder, let folder = label {
            labelTextField.text = folder.text
        }
    }

    func makeColorPaltte(_ fontColor: UIColor?) -> MailLabelsColorPaletteItem {
        let fontColor = fontColor ?? UIColor.ud.udtokenTagBgBlue.alwaysLight
        return MailLabelsColorPaletteItem(name: .custom, bgColor: colorConfig.pickerMapToBgColor(fontColor),
                                          fontColor: fontColor)
    }

    func setupViews() {
        if scene == .editLabel {
            self.title = BundleI18n.MailSDK.__Mail_Folder_EditTabNameMobile.toTagName(.label)
        } else if scene == .newLabel {
            self.title = BundleI18n.MailSDK.Mail_Label_NewLabel_title
        } else if scene == .editFolder {
            self.title = BundleI18n.MailSDK.__Mail_Folder_EditTabNameMobile.toTagName(.folder)
        } else if scene == .newFolder || scene == .newFolderAndMoveTo {
            self.title = BundleI18n.MailSDK.Mail_NewFolder_Title
        }
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.text = BundleI18n.MailSDK.Mail_Manage_FolderLabelName
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(20)
            make.trailing.equalTo(-16)
            make.top.equalTo(16)
            make.height.equalTo(18)
        }

        view.backgroundColor = ModelViewHelper.bgColor()
        view.addSubview(labelTextField)
        view.addSubview(tipsView)
        let saveBtn = UIButton(type: .custom)
        saveBtn.addTarget(self, action: #selector(saveLabel), for: .touchUpInside)
        var buttonStr = BundleI18n.MailSDK.Mail_CustomLabels_Save
        if self.scene == .newFolder || scene == .newFolderAndMoveTo {
            buttonStr = BundleI18n.MailSDK.Mail_NewFolder_Create_button
        } else if self.scene == .newLabel {
            buttonStr = BundleI18n.MailSDK.Mail_NewLabel_Create_button
        }
        saveBtn.setTitle(buttonStr, for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        saveBtn.setTitleColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        saveBtn.setTitleColor(UIColor.ud.primaryFillSolid03, for: .disabled)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveBtn)

        let cancelBtn = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_Common_Cancel)
        cancelBtn.button.tintColor = UIColor.ud.textTitle
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        navigationItem.leftBarButtonItem = cancelBtn

        labelTextField.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.height.equalTo(32)
        }
        tipsView.isHidden = true
        tipsView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(0)
            make.top.equalTo(labelTextField.snp.bottom)
            make.height.equalTo(0)
        }
        configFolderLocation()
        configTextField()
        configColorPicker()
    }

    func configColorPicker() {
        if !(scene == .editLabel || scene == .newLabel) {
            return
        }
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.text = BundleI18n.MailSDK.Mail_Label_LabelColor
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(20)
            make.trailing.equalTo(-16)
            make.top.equalTo(locationButton.snp.bottom).offset(16)
            make.height.equalTo(20)
        }
        let bgView = UIView()
        bgView.backgroundColor = ModelViewHelper.listColor()
        bgView.layer.cornerRadius = 10
        bgView.layer.masksToBounds = true
        view.addSubview(bgView)

        let colorHeight = calColorPickerHeight()
        bgView.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.height.equalTo(colorHeight + 32)
        }
        view.addSubview(colorPicker)
        colorPicker.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.center.equalTo(bgView)
            make.height.equalTo(colorHeight)
        }
    }

    func calColorPickerHeight() -> CGFloat {
        let leftRightMargin: CGFloat = 14
        let itemSize: CGFloat = 48
        let count: CGFloat = CGFloat(colorConfig.colorItems.count)
        let vcWidth = view.bounds.width - 32
        let lineCount = (vcWidth + leftRightMargin) / (itemSize + leftRightMargin)
        let lines = count / lineCount
        return (ceil(lines) * 48) + max(0, (ceil(lines) - 1)) * 8
    }

    func configFolderLocation() {
        let titleLabel = UILabel()
        var title = ""
        if scene == .editFolder || scene == .newFolder || scene == .newFolderAndMoveTo {
            title = BundleI18n.MailSDK.Mail_Folder_MyFoldersMobile
            titleLabel.text = BundleI18n.MailSDK.__Mail_Manage_FolderLabelLocation.toTagName(.folder)
        } else {
            title = BundleI18n.MailSDK.Mail_Label_MyLabels
            titleLabel.text = BundleI18n.MailSDK.__Mail_Manage_FolderLabelLocation.toTagName(.label)
        }
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(20)
            make.trailing.equalTo(-16)
            make.top.equalTo(tipsView.snp.bottom).offset(16)
            make.height.equalTo(18)
        }

        locationButton.addTarget(self, action: #selector(locationButtonHandler), for: .touchUpInside)
        locationButton.backgroundColor = ModelViewHelper.listColor()
        locationButton.layer.cornerRadius = 10
        locationButton.layer.masksToBounds = true
        locationButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        locationButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        locationButton.titleLabel?.textAlignment = .left
        locationButton.titleLabel?.lineBreakMode = .byTruncatingTail
        if let label = label, !label.parentID.isEmpty, !label.parentID.isRoot() {
            for loadLabel in loadLabels where loadLabel.labelId == label.parentID {
                title = loadLabel.text
                parentID = loadLabel.labelId
            }
        }
        locationButton.setTitle(title, for: .normal)
        locationButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 32)
        locationButton.contentHorizontalAlignment = .left
        view.addSubview(locationButton)
        locationButton.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.height.equalTo(48)
        }

        let arrowIcon = UIImageView(image: UDIcon.hideToolbarOutlined.withRenderingMode(.alwaysTemplate))
        arrowIcon.tintColor = UIColor.ud.iconN3
        arrowIcon.isUserInteractionEnabled = false
        locationButton.addSubview(arrowIcon)
        arrowIcon.snp.makeConstraints { (make) in
            make.width.height.equalTo(12)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    @objc
    func locationButtonHandler() {
        var parentId = (labelScene() && parentID == Mail_FolderId_Root) ? nil : parentID
        let locationVC = MailTagLocationViewController(fromLabel: label,
                                                       defaultParentId: parentId,
                                                       accountContext: accountContext)
        locationVC.delegate = self
        if labelScene() {
            locationVC.scene = .label
        }
        if folderScene() {
            MailTracker.log(event: "email_folder_editPosition", params: [MailTracker.sourceParamKey(): MailTracker.source(type: .folderManage)])
            locationVC.scene = .folder
        }
        navigator?.push(locationVC, from: self)
    }

    func folderScene() -> Bool {
        return scene == .newFolder || scene == .editFolder || scene == .newFolderAndMoveTo
    }

    func labelScene() -> Bool {
        return scene == .newLabel || scene == .editLabel
    }

    func configTextField() {
        labelTextField.backgroundColor = ModelViewHelper.listColor()
        if labelScene() {
            labelTextField.placeholder = BundleI18n.MailSDK.__Mail_Folder_PleaseEnterFolderName.toTagName(.label)
        } else {
            labelTextField.placeholder = BundleI18n.MailSDK.__Mail_Folder_PleaseEnterFolderName.toTagName(.folder)
        }
        labelTextField.snp.remakeConstraints { (make) in
            make.leading.equalTo(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(40)
            make.height.equalTo(48)
        }
    }

    func dismissSelf(animated: Bool = true, compltion: @escaping () -> Void) {
        if #available(iOS 13.0, *) {
            self.dismiss(animated: animated, completion: compltion)
        } else {
            navigator?.pop(from: self, animated: animated, completion: compltion)
        }
    }

    func updateTipViewText(_ text: String) {
        tipsView.text = text
        tipsView.backgroundColor = .clear
        tipsView.isHidden = text.isEmpty
        tipsView.snp.updateConstraints { (make) in
            make.height.equalTo(text.isEmpty ? 0 : 32)
        }
    }

    func longTextDetect(_ content: String) -> Bool {
        if labelScene() {
            var parentPathStr = ""
            if let parentLabel = loadLabels.first(where: { $0.labelId == parentID }) {
                parentPathStr = parentLabel.textNames.joined(separator: "/")
            }
            return parentPathStr.utf8.count + content.utf8.count > labelMaxCharacters
        }
        if folderScene() {
            return content.count > folderMaxCharacters
        }
        return false
    }

    func abnormalCharacter(_ content: String) -> Bool {
        if folderScene() && Store.settingData.mailClient {
            let abnormalStr = "~!@#$%^&*()_+{}|:\"<>? ~！@#￥%……&*（）——+{}|：“”《》？·-=[]\\;',./·-=【】、；‘  ’，。、"
            for contentChar in content {
                if abnormalStr.contains(contentChar) {
                    return true
                }
            }
        }
        return false
    }

    func containsTag(_ trimmedContent: String) -> Bool {
        if scene == .newLabel || scene == .editLabel {
            var parentStr = ""
            if !parentID.isRoot(), let parentLabel = loadLabels.first(where: { $0.labelId == parentID }) {
                for i in 0...parentLabel.textNames.count - 1 {
                    parentStr = parentStr + parentLabel.textNames[i] + "/"
                }
            }
            return self.loadLabels.filter({ $0.tagType == .label }).contains(where: { [weak self] (model) -> Bool in
                guard let `self` = self else { return false }
                return self.checkDuplicate(model: model, content: trimmedContent.trimmingCharacters(in: .whitespacesAndNewlines),
                                           parentStr: parentStr)
            })
        } else {
            return checkDuplicate(model: label, content: trimmedContent.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    // 检查label是否有重名
    private func checkDuplicate(model: MailFilterLabelCellModel?, content: String, parentStr: String = "") -> Bool {
        if content.isEmpty {
            return false
        }
        if labelScene() {
            guard let model = model else { return false }
            // 检查没有父亲的label
            if parentID.isRoot() {
                if model.parentID.isEmpty || model.parentID.isRoot() {
                    return model.text.caseInsensitiveCompare(content) == ComparisonResult.orderedSame
                }
            } else {
                let labelStr = parentStr + content
                let tem = model.textNames.joined(separator: "/")
                if tem.caseInsensitiveCompare(labelStr) == ComparisonResult.orderedSame {
                    return true
                }
                return false
            }
            return false
        } else if folderScene() {
            if let editFolder = model {
                if content == editFolder.text {
                    return false // 编辑场景下重名不提示
                }
            }
            for child in folderTree?.findChildsInSameParent(parentID).filter({ $0.tagType == .folder }) ?? [] where child.text == content {
                return true
            }

            for systemTag in loadLabels.filter({ $0.isSystem })
            where systemTag.text == content && parentID == Mail_FolderId_Root {
                return true
            }

            return false
        } else {
            return false
        }
    }

    // MARK: - Views
    lazy var labelTextField: UDTextField = {
        var config = UDTextFieldUIConfig(isShowBorder: false,
                                         clearButtonMode: .whileEditing,
                                         textColor: UIColor.ud.textTitle,
                                         font: UIFont.systemFont(ofSize: 16.0, weight: .regular))

        config.contentMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 12)
        let textField = UDTextField(config: config)
        textField.tintColor = UIColor.ud.functionInfoContentDefault
        textField.input.clearButtonMode = .whileEditing
        textField.accessibilityIdentifier = MailAccessibilityIdentifierKey.FieldCreateLabelKey
        textField.input.addTarget(self, action: #selector(handleEdtingChange(sender:)), for: .editingChanged)
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        textField.delegate = self
        return textField
     }()

    lazy var separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor.ud.lineDividerDefault
        return separator
    }()

    lazy var colorPicker: UDColorPickerPanel = {
        let picker = UDColorPickerPanel(config: colorConfig.defaultConfig())
        picker.delegate = self
        picker.layer.cornerRadius = 10
        picker.layer.masksToBounds = true
        picker.backgroundColor = .clear
        return picker
    }()

    lazy var bgMask: UIButton = {
        let bgMask = UIButton()
        bgMask.addTarget(self, action: #selector(bgMaskClicked), for: .touchUpInside)
        return bgMask
    }()

    @objc
    func bgMaskClicked() {
        // 兼容小屏机的色板选择
        blur()
    }

    // MARK: - Actions
    func focus() {
        labelTextField.becomeFirstResponder()
    }

    func blur() {
        view.endEditing(true)
    }

    func notInSubTree() -> Bool {
        if folderScene() {
            return parentID == Mail_FolderId_Root
        }
        return true
    }

    @objc
    func handleEdtingChange(sender: UITextField) {
        let content = sender.text ?? ""
        detectInputTagName(content)
    }

    func detectInputTagName(_ content: String) {
        self.setSaveBtnEnable(true)
        let trimmedContent = self.labelScene() ? content.trimmingCharacters(in: .whitespacesAndNewlines) : content.removeAllSpaceAndNewlines
        if content.isEmpty {
            self.updateTipViewText("")
        } else if self.abnormalCharacter(trimmedContent) {
            self.setSaveBtnEnable(false)
            self.updateTipViewText(BundleI18n.MailSDK.Mail_Folder_SpecialCharactersNotSupported)
        } else if self.containsTag(trimmedContent) {
            self.setSaveBtnEnable(false)
            if self.labelScene() {
                self.updateTipViewText(BundleI18n.MailSDK.__Mail_Folder_NameExists.toTagName(.label))
            }
            if self.folderScene() {
                self.updateTipViewText(BundleI18n.MailSDK.__Mail_Folder_NameExists.toTagName(.folder))
            }
        } else if self.restrictedLabels.contains(where: { restrictedLabel in
            return restrictedLabel.caseInsensitiveCompare(trimmedContent) == ComparisonResult.orderedSame && notInSubTree()
        }) {
            self.setSaveBtnEnable(false)
            self.updateTipViewText(BundleI18n.MailSDK.Mail_CustomLabels_InvalidSystemName)
        } else if self.longTextDetect(content) {
            self.setSaveBtnEnable(false)
            if self.labelScene() {
                self.updateTipViewText(BundleI18n.MailSDK.Mail_Inbox_TooLongTips)
            }
            if self.folderScene() {
                self.updateTipViewText(BundleI18n.MailSDK.Mail_AddSubFolder_MaximumCharacter_Toast(num: self.folderMaxCharacters))
            }
        } else {
            self.updateTipViewText("")
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        labelTextField.text = nil
        return true
    }

    @objc
    func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc
    func saveLabel() {
        guard let text = labelTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty else {
            var tagType = ""
            if labelScene() {
                MailRoundedHUD.showTips(with: BundleI18n.MailSDK.__Mail_Folder_PleaseEnterFolderName.toTagName(.label), on: self.view,
                                        event: ToastErrorEvent(event: .label_create_empty_name, userCause: true))
            } else {
                MailRoundedHUD.showTips(with: BundleI18n.MailSDK.__Mail_Folder_PleaseEnterFolderName.toTagName(.folder), on: self.view,
                                        event: ToastErrorEvent(event: .label_create_empty_name, userCause: true))
            }
            return
        }
        labelTextField.resignFirstResponder()
        disposeBag = DisposeBag()
        if scene == .newLabel {
            guard let color = selectedColorPalette else {
                return
            }
            MailTracker.log(event: Homeric.EMAIL_LABEL_CREATE, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction)])
            var newParentID: String? = parentID
            if parentID == Mail_FolderId_Root || parentID.isEmpty {
                newParentID = nil
            }
            createNewLabel(name: text,
                           bgColor: color.bgColor,
                           fontColor: color.fontColor,
                           parentID: newParentID)
        } else if scene == .editLabel, let label = label {
            guard let color = selectedColorPalette else {
                return
            }
            updateLabel(labelId: label.labelId,
                        name: text,
                        bgColor: color.bgColor,
                        fontColor: color.fontColor,
                        parentID: parentID == Mail_FolderId_Root ? label.parentID : parentID,
                        applyToAll: false)
        } else if scene == .newFolder || scene == .newFolderAndMoveTo {
            createNewFolder(name: text, parentID: parentID)
        } else if scene == .editFolder, let folder = label {
            updateFolder(folderID: folder.labelId, name: text, parentID: parentID,
                         orderIndex: userOrderIndex)
        }
    }

    func createNewFolder(name: String, parentID: String?) {
        let folderName = name
        setSaveBtnEnable(false)
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Normal_Loading, on: self.view, disableUserInteraction: false)
        MailLogger.debug("[mail_folder] createNewFolder parentID: \(parentID ?? "")")
        let event = MailAPMEvent.LabelManageAction()
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.action_type("create"))
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.mailbox_type("folder"))
        event.markPostStart()
        MailManageFolderDataSource.default.addFolder(name: name, parentID: parentID)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                if response.hasFolder {
                    self.folderDelegate?.didCreateNewFolder(labelId: response.folder.id)
                    let folder = MailFilterLabelCellModel.init(pbModel: response.folder)
                    if self.scene == .newFolderAndMoveTo {
                        if let msgList = (self.navigator?.navigation?.viewControllers ?? []).last(where: { $0 is MailMessageListController}) as? MailMessageListController {
                            self.navigator?.pop(from: msgList, animated: false, completion: {
                                self.dismissSelf {
                                    self.folderDelegate?.didCreateFolderAndDismiss(BundleI18n.MailSDK.Mail_MovedToTheNewFolder_Toast(folderName), create: true, moveTo: true, folder: folder)
                                    event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                                }
                            })
                        } else {
                            self.dismissSelf {
                                self.folderDelegate?.didCreateFolderAndDismiss(BundleI18n.MailSDK.Mail_MovedToTheNewFolder_Toast(folderName), create: true, moveTo: true, folder: folder)
                                event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                            }
                        }
                    } else {
                        MailRoundedHUD.remove(on: self.view)
                        self.dismissSelf {
                            self.folderDelegate?.didCreateFolderAndDismiss(BundleI18n.MailSDK.Mail_Folder_CreatedSuccessfully(folderName), create: true, moveTo: false, folder: folder)
                            event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                        }
                    }
                } else {
                    MailRoundedHUD.remove(on: self.view)
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Manage_FailedToCreateFolder, on: self.view,
                                               event: ToastErrorEvent(event: .folder_create_custom_fail))
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                }
                event.postEnd()
                self.setSaveBtnEnable(true)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                MailRoundedHUD.remove(on: self.view)
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Manage_FailedToCreateFolder, on: self.view,
                                           event: ToastErrorEvent(event: .folder_create_custom_fail))
                event.endParams.appendError(error: error)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                event.postEnd()
                self.setSaveBtnEnable(true)
            }).disposed(by: disposeBag)
    }

    func updateFolder(folderID: String, name: String, parentID: String?, orderIndex: Int64?) {
        MailLogger.debug("[mail_folder] folderID: \(folderID) parentID: \(parentID ?? "") orderIndex: \(orderIndex ?? -1)")
        MailTracker.log(event: "email_folder_editSave", params: nil)
        let folderName = name
        setSaveBtnEnable(false)
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Normal_Loading, on: self.view, disableUserInteraction: false)
        let event = MailAPMEvent.LabelManageAction()
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.action_type("edit"))
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.mailbox_type("folder"))
        event.markPostStart()
        MailManageFolderDataSource.default.updateFolder(folderID: folderID, name: name, parentID: parentID, orderIndex: orderIndex)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                MailRoundedHUD.remove(on: self.view)
                let folder = MailFilterLabelCellModel.init(pbModel: response.folder)
                if response.hasFolder {
                    self.folderDelegate?.didEditFolder(labelId: response.folder.id)
                    self.dismissSelf {
                        self.folderDelegate?.didCreateFolderAndDismiss(
                            BundleI18n.MailSDK.Mail_Mange_FolderEdited_Toast(folderName),
                            create: false, moveTo: false, folder: folder)
                        event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                        event.postEnd()
                    }
                } else {
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.__Mail_Manage_FolderLabelModifyFailed.toTagName(.folder, tagName: folderName), on: self.view,
                                               event: ToastErrorEvent(event: .folder_modify_custom_fail))
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                    event.postEnd()
                }
                self.setSaveBtnEnable(true)
            }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                MailRoundedHUD.remove(on: self.view)
                if Store.settingData.mailClient {
                    self.dismissSelf { [weak self] in
                        self?.folderDelegate?.didEditFolderAndDismiss()
                    }
                } else {
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.__Mail_Manage_FolderLabelModifyFailed.toTagName(.folder, tagName: folderName), on: self.view,
                                           event: ToastErrorEvent(event: .folder_modify_custom_fail))
                }

                event.endParams.appendError(error: error)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                event.postEnd()
                self.setSaveBtnEnable(true)
            }).disposed(by: disposeBag)
    }

    func createNewLabel(name: String,
                        bgColor: UIColor,
                        fontColor: UIColor,
                        parentID: String?) {
        let labelName = name
        setSaveBtnEnable(false)
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Normal_Loading, on: self.view, disableUserInteraction: false)
        MailLogger.debug("[mail_folder] createNewLabel parentID: \(parentID ?? "")")
        let event = MailAPMEvent.LabelManageAction()
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.action_type("create"))
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.mailbox_type("label"))
        event.markPostStart()
        let colorType = colorConfig.findColorTypeWithPickerColor(fontColor)
        MailManageLabelsDataSource.default.addLabel(name: labelName,
                                                    bgColor: colorType.bgColorValue() ?? "",
                                                    fontColor: colorType.fontColorValue() ?? "",
                                                    parentID: parentID)
            .subscribe(onNext: { [weak self](response) in
                guard let `self` = self else { return }
                if response.hasLabel {
                    self.delegate?.didCreateNewLabel(labelId: response.label.id)
                    self.dismissSelf {
                        self.delegate?.didCreateLabelAndDismiss(BundleI18n.MailSDK.Mail_CustomLabels_Add_Label_Notification(labelName), create: true)
                    }
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                    event.postEnd()
                } else {
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_CustomLabels_FailedToast, on: self.view,
                                               event: ToastErrorEvent(event: .label_create_custom_fail))
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                    event.postEnd()
                }
                self.setSaveBtnEnable(true)
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_CustomLabels_FailedToast, on: self.view,
                                           event: ToastErrorEvent(event: .label_create_custom_fail))
                event.endParams.appendError(error: error)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                event.postEnd()
                self.setSaveBtnEnable(true)
            }).disposed(by: disposeBag)
    }

    func updateLabel(labelId: String,
                     name: String,
                     bgColor: UIColor,
                     fontColor: UIColor,
                     parentID: String,
                     applyToAll: Bool) {
        let labelName = name
        setSaveBtnEnable(false)
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Normal_Loading, on: self.view, disableUserInteraction: false)
        MailLogger.debug("[mail_folder] updateLabel labelId: \(labelId) parentID: \(parentID)")
        let event = MailAPMEvent.LabelManageAction()
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.action_type("edit"))
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.mailbox_type("label"))
        event.markPostStart()
        let colorType = colorConfig.findColorTypeWithPickerColor(fontColor)
        MailManageLabelsDataSource.default.updateLabel(labelId: labelId,
                                                       name: labelName,
                                                       bgColor: colorType.bgColorValue(),
                                                       fontColor: colorType.fontColorValue(),
                                                       parentID: parentID, applyToAll: applyToAll)
            .subscribe(onNext: { [weak self](response) in
                guard let `self` = self else { return }
                MailRoundedHUD.remove(on: self.view)
                if response.hasLabel {
                    self.dismissSelf {
                        self.delegate?.didCreateLabelAndDismiss(BundleI18n.MailSDK.Mail_Mange_LabelEdited_Toast(labelName), create: false)
                    }
                } else {
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.__Mail_Manage_FolderLabelModifyFailed.toTagName(.label, tagName: labelName),
                                               on: self.view,
                                               event: ToastErrorEvent(event: .label_modify_custom_fail))
                }
                self.setSaveBtnEnable(true)
            }, onError: { [weak self] (_) in
                    guard let `self` = self else { return }
                    MailRoundedHUD.remove(on: self.view)
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.__Mail_Manage_FolderLabelModifyFailed.toTagName(.label, tagName: labelName), on: self.view,
                                       event: ToastErrorEvent(event: .label_modify_custom_fail))
                self.setSaveBtnEnable(true)
            }).disposed(by: disposeBag)
    }

    private func setSaveBtnEnable(_ isEnabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = isEnabled
    }

    private func selectedColorAtIndex(_ index: Int) {
        if index < self.colorConfig.colorItems.count {
            let newConfig = UDColorPickerConfig(models: [UDPaletteModel(category: .basic, title: "",
                                                                        items: colorConfig.colorItems.map({ UDPaletteItem(color: $0) }),
                                                                        selectedIndex: index)],
                                                backgroudColor: ModelViewHelper.listColor())
            self.colorPicker.update(newConfig)
        }
    }
}

extension MailCreateTagController: MailTagLocationDelegate {
    func updateTagLocation(_ model: MailFilterLabelCellModel, userOrderIndex: Int64?) {
        self.parentID = model.labelId
        self.userOrderIndex = userOrderIndex
        locationButton.setTitle(model.text, for: .normal)
        detectInputTagName(labelTextField.text ?? "")
    }
}

extension String {
    func toTagName(_ tagType: MailTagType) -> String {
        switch tagType {
        case .label:
            return self.replacingOccurrences(of: "{{TabName}}", with: BundleI18n.MailSDK.Mail_Manage_ManageLabelMobile)
                .replacingOccurrences(of: "{{Folder_Label}}", with: BundleI18n.MailSDK.Mail_Label_Label)
        case .folder:
            return self.replacingOccurrences(of: "{{TabName}}", with: BundleI18n.MailSDK.Mail_Folder_FolderTab)
                .replacingOccurrences(of: "{{Folder_Label}}", with: BundleI18n.MailSDK.Mail_Folder_Folder)
        }
    }

    func toTagName(_ tagType: MailTagType, tagName: String) -> String {
        let tempString = self.toTagName(tagType)
        return tempString.replacingOccurrences(of: "{{name}}", with: tagName)
    }
}

// MARK: - MailLabelColorPickerDelegate
extension MailCreateTagController: UDColorPickerPanelDelegate {
//    func didSelectedColorPaletteItem(_ colorPalette: MailLabelsColorPaletteItem) {
//        self.selectedColorPalette = colorPalette
//    }
    func didSelected(color: UIColor?, category: UDPaletteItemsCategory, in panel: UDColorPickerPanel) {
        let pickerColor = color ?? UIColor.ud.udtokenTagBgBlue.alwaysLight
        self.selectedColorPalette = MailLabelsColorPaletteItem(name: .custom, bgColor: colorConfig.pickerMapToBgColor(pickerColor), fontColor: pickerColor)
    }
}

class MailEditTagTipView: UIView {
    var text: String = "" {
        didSet {
            tipsLabel.text = text
        }
    }

    lazy private var tipsLabel: UILabel = {
        let tipsLabel = UILabel()
        tipsLabel.textColor = UIColor.ud.functionDangerContentDefault
        tipsLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return tipsLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(32)
            make.trailing.equalTo(0)
            make.top.equalToSuperview()
            make.height.equalTo(22)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
