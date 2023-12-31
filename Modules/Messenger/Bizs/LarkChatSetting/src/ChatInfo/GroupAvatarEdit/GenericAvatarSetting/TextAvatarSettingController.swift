//
//  TextAvatarSettingController.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/10/7.
//

import LarkUIKit
import UniverseDesignIcon
import LarkContainer
import UniverseDesignToast
import EENavigator
import LKCommonsLogging
import RxSwift
import RustPB
import LarkBaseKeyboard

class TextAvatarSettingController: BaseUIViewController,
                                   ColorPickerViewDelegate,
                                   ScrollViewVCAvoidKeyboardProtocol,
                                   AvatarTypePickerDelegate {
    let logger = Logger.log(TextAvatarSettingController.self, category: "LarkChatSetting.groupsetting.textavatar")
    /// 右导航保存按钮
    lazy var saveButtonItem: LKBarButtonItem = {
        let item = LKBarButtonItem(image: nil, title: BundleI18n.LarkChatSetting.Lark_GroupPhoto_EditText_Done_Button, fontStyle: .medium)
        item.addTarget(self, action: #selector(saveItemTapped), for: .touchUpInside)
        item.setBtnColor(color: UIColor.ud.primaryContentDefault)
        return item
    }()

    lazy var backButtonItem: LKBarButtonItem = {
        let item = LKBarButtonItem(image: UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault), title: nil)
        item.button.addTarget(self, action: #selector(backItemTapped), for: .touchUpInside)
        return item
    }()

    let contentView = UIView()
    let scrollView = UIScrollView()

    lazy var avatarEditView: GenericAvatarView = {
        let avatarView = GenericAvatarView(defaultImage: viewModel.defaultCenterIcon)
        avatarView.isUserInteractionEnabled = false
        return avatarView
    }()

    lazy var textAnalyzer: AvatarAttributedTextAnalyzer = {
        return AvatarAttributedTextAnalyzer { [weak self] in
            guard let self = self, self.avatarTypePicker.currentAvatarType != .unknownStyle else {
                return UIColor.ud.primaryOnPrimaryFill
            }
            guard let textColor = self.avatarEditView.avatarType?.getTextColor() else {
                if let item = self.colorPicker.getSeletedItem()?.0 {
                    return self.avatarTypePicker.currentAvatarType == .fill ? UIColor.ud.primaryOnPrimaryFill :
                    ColorCalculator.middleColorForm(item.startColor, to: item.endColor)
                }
                return UIColor.ud.primaryOnPrimaryFill
            }
            return textColor
        }
    }()

    lazy var colorPicker: GenericColorPickerView = {
        return GenericColorPickerView(delegate: self)
    }()

    lazy var avatarTypePicker: GenericAvatarTypePickerView = {
        return GenericAvatarTypePickerView(delegate: self)
    }()
    private lazy var editView: AvatarAttributedTextEditView = {
        return AvatarAttributedTextEditView(userResolver: viewModel.userResolver, fromVC: self) { [weak self] text in
            guard let self = self else { return }
            /// 头像还没初始化
            if self.avatarEditView.avatarType == nil {
                self.logger.info("avatarView have not init yet!")
            }
            if self.colorPicker.data.isEmpty {
                assertionFailure("error to have data")
                return
            }
            if self.avatarEditView.avatarType?.getTextColor() == nil {
                self.logger.info("avatarView get wrong type! type - \(String(describing: self.avatarEditView.avatarType))")
                return
            }
            self.updateAvatarOnTextChange(text: self.textAnalyzer.attrbuteStrForText(text))
        }
    }()

    private lazy var customTextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.LarkChatSetting.Lark_Core_custmoized_groupavatar
        return label
    }()

    private lazy var customColorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.LarkChatSetting.Lark_IM_EditGroupPhoto_ColorsAndPatterns_Title
        return label
    }()

    private lazy var customAvatarTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.LarkChatSetting.Lark_GroupPhoto_SelectStyle_Title
        return label
    }()
    /// 选中颜色的idx
    private var colorSelectedIdx: Int?
    var actionScrollView: UIScrollView { self.scrollView }
    var keyboardAvoidKeySpace: CGFloat { 20 }
    var disposeBag: DisposeBag = DisposeBag()
    var saveTextAvatarCallBack: ((VariousAvatarType?) -> Void)?
    let viewModel: TextAvatarSettingViewModel
    weak var fromVC: UIViewController?

    init(viewModel: TextAvatarSettingViewModel,
         fromVC: UIViewController) {
        self.viewModel = viewModel
        self.fromVC = fromVC
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkChatSetting.Lark_GroupPhoto_Type_Text_Mobile_Title
        self.navigationItem.rightBarButtonItem = self.saveButtonItem
        self.navigationItem.leftBarButtonItem = self.backButtonItem

        self.view.backgroundColor = UIColor.ud.bgBody
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.contentInsetAdjustmentBehavior = .never
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(self.viewTopConstraint)
        }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            // 设置width.equalToSuperview()，可以上下滚动
            make.edges.width.equalToSuperview()
        }
        configSubView()
        configSubviewData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarTypePicker.refreshView()
    }

    func configSubView() {
        self.contentView.addSubview(avatarEditView)
        self.contentView.addSubview(customTextLabel)
        self.contentView.addSubview(editView)
        self.contentView.addSubview(customAvatarTypeLabel)
        self.contentView.addSubview(avatarTypePicker)
        self.contentView.addSubview(customColorLabel)
        self.contentView.addSubview(colorPicker)

        let size = avatarEditView.avatarSize
        avatarEditView.snp.makeConstraints { make in
            make.size.equalTo(size)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(40)
        }

        customTextLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarEditView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.greaterThanOrEqualTo(24)
        }

        editView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(customTextLabel)
            make.top.equalTo(customTextLabel.snp.bottom).offset(8)
        }

        customAvatarTypeLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(editView)
            make.top.equalTo(editView.snp.bottom).offset(36)
            make.height.greaterThanOrEqualTo(24)
        }

        avatarTypePicker.snp.makeConstraints { make in
            make.leading.trailing.equalTo(customAvatarTypeLabel)
            make.top.equalTo(customAvatarTypeLabel.snp.bottom).offset(8)
        }

        customColorLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(editView)
            make.top.equalTo(avatarTypePicker.snp.bottom).offset(24)
            make.height.greaterThanOrEqualTo(24)
        }

        colorPicker.snp.makeConstraints { make in
            make.leading.trailing.equalTo(customColorLabel)
            make.top.equalTo(customColorLabel.snp.bottom).offset(7)
            make.bottom.equalTo(self.contentView.snp.bottom).offset(-16)
        }

        observerKeyboardEvent()
    }

    func configSubviewData() {
        // 刷新UI放在主线程
        refreshView(meta: viewModel.avatarMeta)
    }

    func refreshView(meta: RustPB.Basic_V1_AvatarMeta) {
        if (meta.type == .words || meta.type == .random), meta.styleType != .unknownStyle {
            let attr = RichTextTransformKit.transformRichTextToStr(richText: meta.richText, attributes: [:], attachmentResult: [:])
            self.editView.setAttributedText(attr)
            self.avatarTypePicker.currentAvatarType = meta.styleType
            let itemInfo = self.colorPicker.setSelectedColor(startColorInt: meta.startColor, endColorInt: meta.endColor) ?? self.colorPicker.pickerFirstColorItem()
            self.colorSelectedIdx = itemInfo.1
            self.updateavatarEditViewTypeForSelected(item: itemInfo.0)
            return
        }
        /// meta.styleType == .unknownStyle表示旧版头像信息
        /// 使用兜底头像
        switch viewModel.drawStyle {
        case .transparent:
            self.avatarTypePicker.currentAvatarType = .border
        case .soild:
            self.avatarTypePicker.currentAvatarType = .fill
        }
        let itemInfo = self.colorPicker.getSeletedItem() ?? self.colorPicker.pickerFirstColorItem()
        self.colorSelectedIdx = itemInfo.1
        self.updateavatarEditViewTypeForSelected(item: itemInfo.0)

    }

    /// 保存用户定制的群头像
    @objc
    func saveItemTapped() {
        saveTextAvatarCallBack?(self.avatarEditView.avatarType)
        self.navigationController?.popViewController(animated: true)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.editView.endEditing(true)
    }

    func updateAvatarOnTextChange(text: NSAttributedString) {
        self.avatarEditView.updateText(text)
    }

    /// ColorPickItem
    func didSelectItemAt(indexPath: IndexPath, item: SolidColorPickItem) {
        self.colorSelectedIdx = indexPath.row
        updateavatarEditViewTypeForSelected(item: item)
    }

    func updateavatarEditViewTypeForSelected(item: SolidColorPickItem) {
        let attr = NSMutableAttributedString(attributedString: textAnalyzer.attrbuteStrForText(self.editView.selectedText))
        let color = self.avatarTypePicker.currentAvatarType == .fill ? UIColor.ud.primaryOnPrimaryFill :
        ColorCalculator.middleColorForm(item.startColor, to: item.endColor)

        attr.addAttributes([.foregroundColor: color], range: NSRange(location: 0, length: attr.length))
        if self.avatarTypePicker.currentAvatarType == .fill {
            self.avatarEditView.setAvatar(.angularGradient(UInt32(item.startColorInt),
                                                           UInt32(item.endColorInt),
                                                           item.key,
                                                           attr,
                                                           self.viewModel.config.fsUnit))
            self.viewModel.resetBorderItems()
        } else if self.avatarTypePicker.currentAvatarType == .border {
            self.avatarEditView.setAvatar(.border(UInt32(item.startColorInt),
                                                  UInt32(item.endColorInt),
                                                  attr))
            self.viewModel.resetFillItems()
        }
    }

    func chooseAvatarType(avatarType: Basic_V1_AvatarMeta.AvatarStyleType) {
        var item: SolidColorPickItem?
        if avatarType == .fill {
            self.viewModel.resetBorderItems()
            item = self.viewModel.selectedFillItem(self.colorSelectedIdx)
            self.colorPicker.setData(items: viewModel.fillItems)
        } else {
            self.viewModel.resetFillItems()
            item = self.viewModel.selectedBorderItem(self.colorSelectedIdx)
            self.colorPicker.setData(items: viewModel.borderItems)
        }
        if let item = item {
            self.updateavatarEditViewTypeForSelected(item: item)
        }
        self.view.endEditing(true)
    }
}
