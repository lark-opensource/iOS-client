//
//  VariousAvatarEditController.swift
//  LarkChatSetting
//
//  Created by liluobin on 2023/2/9.
//

import LarkUIKit
import EditTextView
import RxSwift
import RxCocoa
import FigmaKit
import UniverseDesignTabs
import RustPB
import UniverseDesignColor
import LarkSDKInterface
import LKCommonsLogging
protocol ClearSeletedStatusProtocol: AnyObject {
    func clearSeletedStatus()
}

typealias AvatarTrackInfo = (isWord: Bool, isFill: Bool, isEnter: Bool, isTick: Bool, isImage: Bool)

final class VariousAvatarEditController: AvatarBaseSettingController,
                                         UDTabsViewDelegate,
                                         ColorPickerViewDelegate,
                                         ScrollViewVCAvoidKeyboardProtocol {
    let logger = Logger.log(VariousAvatarEditController.self, category: "LarkChatSetting.groupsetting.avatar")
    private let fillStyleIdx = 0
    private let borderStyleIdx = 1
    /// 选中颜色的idx
    private var colorSelectedIdx: Int?

    private var segmentedControlHadAction = false
    let disposeBag = DisposeBag()
    var actionScrollView: UIScrollView { self.scrollView }
    var keyboardAvoidKeySpace: CGFloat { 20 }
    var savedCallback: ((UIImage, RustPB.Basic_V1_AvatarMeta, UIViewController, UIView, AvatarTrackInfo) -> Void)?

    lazy var avatarEidtView: VariousAvatarView = {
        let avatarView = VariousAvatarView(defaultImage: self.viewModel.defaultCenterIcon)
        avatarView.cameraButtonClick = { [weak self] sender in
            self?.onCameraButtonClick(sender: sender)
        }
        return avatarView
    }()

    lazy var textAnalyzer: AvatarTextAnalyzer = {
        return AvatarTextAnalyzer { [weak self] text in
            self?.updateAvatarOnTextChange(text: text)
        } textColorCallBack: { [weak self] in
            guard let self = self else {
                return UIColor.ud.primaryOnPrimaryFill
            }
            guard let textColor = self.avatarEidtView.avatarType?.getTextColor() else {
                if let item = self.colorPikcer.getSeletedItem()?.0 {
                    return  self.segmentedControl.selectedIndex == self.fillStyleIdx ? UIColor.ud.primaryOnPrimaryFill :
                    ColorCalculator.middleColorForm(item.startColor, to: item.endColor)
                }
                return UIColor.ud.primaryOnPrimaryFill
            }
            return textColor
        }
    }()

    lazy var colorPikcer: ColorPickerView = {
        return ColorPickerView(delegate: self)
    }()

    private lazy var editView: AvatarTextEditView = {
        return AvatarTextEditView { [weak self] text in
            guard let self = self else { return }
            /// 头像还没初始化 不受文字影响
            if self.avatarEidtView.avatarType == nil { return }
            if self.colorPikcer.data.isEmpty {
                assertionFailure("error to have data \(self.viewModel.fillItems.count)")
                return
            }
            /// 头像没有指定背景色时候 需要至指定
            if self.avatarEidtView.avatarType?.getTextColor() == nil {
                let itemInfo = self.colorPikcer.getSeletedItem() ?? self.colorPikcer.pickerRandomColorItem()
                self.colorSelectedIdx = itemInfo.1
                self.updateAvatarEidtViewTypeForSelected(item: itemInfo.0)
                self.setRightButtonItemEnable(enable: true)
            } else {
                self.textAnalyzer.analysisText(text)
            }
        } textFilter: { [weak self] text in
            return self?.textAnalyzer.filterText(text)
        }
    }()

    private lazy var segmentedControl: UDSegmentedControl = {
        var configuration = UDSegmentedControl.Configuration()
        configuration.contentEdgeInset = 4
        configuration.preferredHeight = 36
        configuration.backgroundColor = UIColor.ud.N200
        configuration.indicatorColor = UDColor.N00 & UDColor.N500
        configuration.cornerStyle = .rounded
        let control = UDSegmentedControl(configuration: configuration)
        control.titles = [BundleI18n.LarkChatSetting.Lark_Core_GroupAvatarStyleFill_toggle,
                          BundleI18n.LarkChatSetting.Lark_Core_GroupAvatarStyleOutline_toggle]
        control.delegate = self
        return control
    }()

    private lazy var customTextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.LarkChatSetting.Lark_IM_EditGroupPhoto_Text_Title
        return label
    }()

    private lazy var customColorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.LarkChatSetting.Lark_IM_EditGroupPhoto_ColorsAndPatterns_Title
        return label
    }()

    lazy var tipsLabel: UILabel = {
        let tipsLabel = UILabel()
        tipsLabel.font = UIFont.systemFont(ofSize: 12)
        tipsLabel.text = BundleI18n.LarkChatSetting.Lark_IM_EditGroupPhoto_ColorsAndPattern_Hover
        tipsLabel.numberOfLines = 0
        tipsLabel.textColor = UIColor.ud.textPlaceholder
        tipsLabel.backgroundColor = UIColor.clear
        return tipsLabel
    }()

    let viewModel: VariousAvatarEditViewModel

    init(viewModel: VariousAvatarEditViewModel) {
        self.viewModel = viewModel
        super.init(userResolver: viewModel.userResolver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configBgScrollView()
        self.configSubView()
        self.configSubviewData()
    }

    func configBgScrollView() {
        self.contentView.backgroundColor = UIColor.ud.bgBody
        self.contentView.layer.cornerRadius = 8
        self.contentView.layer.masksToBounds = true

        self.contentView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(16)
            make.width.equalToSuperview()
        }

        self.scrollView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.top.equalToSuperview()
        }
    }

    func configSubView() {
        self.contentView.addSubview(avatarEidtView)
        self.contentView.addSubview(segmentedControl)
        self.contentView.addSubview(customTextLabel)
        self.contentView.addSubview(editView)
        self.contentView.addSubview(customColorLabel)
        self.contentView.addSubview(colorPikcer)
        self.scrollView.addSubview(tipsLabel)

        let size = avatarEidtView.avatarSize
        avatarEidtView.snp.makeConstraints { make in
            make.size.equalTo(size)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(40)
        }

        segmentedControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(avatarEidtView.snp.bottom).offset(24)
            make.height.equalTo(36)
        }

        customTextLabel.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.greaterThanOrEqualTo(24)
        }

        editView.snp.makeConstraints { make in
            make.left.right.equalTo(customTextLabel)
            make.top.equalTo(customTextLabel.snp.bottom).offset(8)
        }

        customColorLabel.snp.makeConstraints { make in
            make.left.right.equalTo(editView)
            make.top.equalTo(editView.snp.bottom).offset(24)
            make.height.greaterThanOrEqualTo(24)
        }

        colorPikcer.snp.makeConstraints { make in
            make.left.right.equalTo(customColorLabel)
            make.top.equalTo(customColorLabel.snp.bottom).offset(7)
            make.bottom.equalTo(self.contentView.snp.bottom).offset(-16)
        }

        tipsLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(self.contentView.snp.bottom).offset(12)
            make.bottom.equalTo(self.scrollView.snp.bottom).offset(-12)
        }
        observerKeyboardEvent()
    }

    func configSubviewData() {
        self.avatarEidtView.setAvatar(self.viewModel.avatarType)
        switch self.viewModel.drawStyle {
        case .transparent:
            self.segmentedControl.defaultSelectedIndex = self.borderStyleIdx
            self.colorPikcer.setData(items: self.viewModel.borderItems)
        case .soild:
            self.segmentedControl.defaultSelectedIndex = self.fillStyleIdx
            self.colorPikcer.setData(items: self.viewModel.fillItems)
        }
        self.viewModel.fetchRemoteData()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (texts, meta) in
                guard let `self` = self else { return }
                guard let meta = meta, meta.type != .upload else {
                    self.editView.addTags(texts)
                    return
                }

                var texts = texts
                var needSelectedColor = false
                switch meta.type {
                    // 用户自己上传的头像, 没有数据/错误数据/系统错误降级
                case .upload, .unknown: break
                    // 用户选了颜色未指定name或者选中推荐文字
                case .random:
                    needSelectedColor = true
                    // 用户选了颜色且指定name或者选中推荐文字
                case .words:
                    // 保证meta.text唯一texts中第一个
                    if !meta.text.isEmpty {
                        texts.lf_remove(object: meta.text)
                        if texts.isEmpty {
                            texts = [meta.text]
                        } else {
                            texts.insert(meta.text, at: 0)
                        }
                    }
                    needSelectedColor = true
                @unknown default: break
                }

                /// 接口返回之前，用户如果点击了 不做处理
                if !self.segmentedControlHadAction {
                    switch meta.styleType {
                    case .border:
                        self.segmentedControl.selectItemAt(index: self.borderStyleIdx)
                    case .fill:
                        self.segmentedControl.selectItemAt(index: self.fillStyleIdx)
                    case .unknownStyle:
                        self.segmentedControl.selectItemAt(index: self.fillStyleIdx)
                        needSelectedColor = false
                    @unknown default:
                        break
                    }

                    if needSelectedColor {
                        self.colorSelectedIdx = self.colorPikcer.setSelectedColor(startColorInt: meta.startColor, endColorInt: meta.endColor)?.row
                    }
                }

                // 填充推荐文字
                self.editView.addTags(texts)

                if meta.type == .words, !meta.text.isEmpty {
                    self.editView.selectedTitle(meta.text)
                }
            }).disposed(by: self.disposeBag)
    }

    override func saveGroupAvatar() {
        let isWord = self.avatarEidtView.displayText().length != 0
        let isFill = self.segmentedControl.selectedIndex == self.fillStyleIdx
        let isEnter = !(self.editView.textView.attributedText.length == 0)
        let isTick = self.editView.hadSelectedTag
        var isImage = false
        if case .upload(_) = self.avatarEidtView.avatarType {
            isImage = true
        }
        self.savedCallback?(self.avatarEidtView.getAvatarImage(),
                            self.avatarEidtView.avatarMeta(),
                            self,
                            self.editView,
                            (isWord, isFill, isEnter, isTick, isImage))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    private func onCameraButtonClick(sender: UIView) {
        self.view.endEditing(true)
        self.showSelectActionSheet(sender: sender, navigator: self.viewModel.navigator, finish: { [weak self] image in
            guard let `self` = self else { return }
            self.setRightButtonItemEnable(enable: true)
            let objs: [ClearSeletedStatusProtocol] = [self.editView, self.colorPikcer]
            objs.forEach { $0.clearSeletedStatus() }
            // 设置头像为选择的图片，清空颜色和文字
            self.avatarEidtView.setAvatar(.upload(image))
            self.colorSelectedIdx = nil
        })
    }

    func updateAvatarOnTextChange(text: NSAttributedString) {
        self.avatarEidtView.updateText(text)
        self.setRightButtonItemEnable(enable: true)
    }

    /// ColorPickItem
    func didSelectItemAt(indexPath: IndexPath, item: SolidColorPickItem) {
        self.colorSelectedIdx = indexPath.row
        updateAvatarEidtViewTypeForSelected(item: item)
    }

    func updateAvatarEidtViewTypeForSelected(item: SolidColorPickItem) {
        let attr = NSMutableAttributedString(attributedString: textAnalyzer.attrbuteStrForText(self.editView.selectedText))
        let color = self.segmentedControl.selectedIndex == fillStyleIdx ? UIColor.ud.primaryOnPrimaryFill :
        ColorCalculator.middleColorForm(item.startColor, to: item.endColor)
        attr.addAttributes([.foregroundColor: color], range: NSRange(location: 0, length: attr.length))
        if self.segmentedControl.selectedIndex == fillStyleIdx {
            self.avatarEidtView.setAvatar(.angularGradient(UInt32(item.startColorInt),
                                                           UInt32(item.endColorInt),
                                                           item.key,
                                                           attr,
                                                           self.viewModel.config.fsUnit))
            self.viewModel.resetBorderItems()
        } else {
            self.avatarEidtView.setAvatar(.border(UInt32(item.startColorInt),
                                                  UInt32(item.endColorInt),
                                                  attr))
            self.viewModel.resetFillItems()
        }
        self.setRightButtonItemEnable(enable: true)
    }

    /// UDTabsView
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        self.segmentedControlHadAction = true
        var item: SolidColorPickItem?
        if index == self.fillStyleIdx {
            self.viewModel.resetBorderItems()
            item = self.viewModel.selectedFillItem(self.colorSelectedIdx)
            self.colorPikcer.setData(items: viewModel.fillItems)
        } else {
            self.viewModel.resetFillItems()
            item = self.viewModel.selectedBorderItem(self.colorSelectedIdx)
            self.colorPikcer.setData(items: viewModel.borderItems)
        }
        if let item = item {
            self.updateAvatarEidtViewTypeForSelected(item: item)
        }
        self.view.endEditing(true)
    }
}
