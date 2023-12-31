//
//  BTConditionSelectCell.swift
//  SKBitable
//
//  Created by zoujie on 2022/6/13.
//  


import Foundation
import UIKit
import SKUIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import SKFoundation
import SKResource
import UniverseDesignFont
import HandyJSON

public protocol BTConditionSelectCellDelegate: AnyObject {
    func didClickDelete(cell: UITableViewCell)
    func didClickContainerButton(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?)
    func didClickRetry(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?)
}

public enum ConditionSelectionType: String {
    case selection
    case checkbox
    case loading
    case failed
    case unreadable
    case plainText
}

public struct BTConditionSelectButtonModel {
    var icon: UIImage?
    var showIconLighting: Bool
    var text: String
    var textColor: UIColor?
    var enable: Bool
    var hasRightIcon: Bool
    var type: ConditionSelectionType
    var typeValue: Any?
    var showLockIcon: Bool

    init(text: String,
         icon: UIImage? = nil,
         showIconLighting: Bool = false,
         enable: Bool = true,
         textColor: UIColor? = UDColor.textPlaceholder,
         hasRightIcon: Bool = true,
         type: ConditionSelectionType = .selection,
         typeValue: Any? = nil,
         showLockIcon: Bool = false) {
        self.icon = icon
        self.showIconLighting = showIconLighting
        self.text = text
        self.enable = enable
        self.hasRightIcon = hasRightIcon
        self.textColor = textColor
        self.type = type
        self.typeValue = typeValue
        self.showLockIcon = showLockIcon
    }
}

struct BTNewConditionSelectCellModel: Codable {
    struct Content: Codable {
        var text: String?
        var placeholder: String?
    }
    struct Title: Codable {
        var text: String?
    }
    struct Cell: Codable {
        var backgroudColor: String?
        var content: Content?
        var leftIcon: BTImageWidgetModel?
        var rightIcon: BTImageWidgetModel?
        var onClick: String?
        var checkBox: BTCheckBoxWidgetModel?
        var isSync: Bool?
    }

    struct Warning: Codable {
        var warningUDIcon: BTImageWidgetModel?
        var warningText: BTTextWidgetModel?
    }
    var warning: Warning?
    var conditionId: String
    var title: Title?
    var rightIcon: BTImageWidgetModel?
    var cells: [Cell]?
    var invalidType: BTFieldInvalidType?
    
    var originModel: BTConditionSelectCellModel {
        var originModel = BTConditionSelectCellModel()
        originModel.title = self.title?.text ?? ""
        originModel.conditionId = self.conditionId
        originModel.isShowDelete = !(self.rightIcon?.udToken.isEmpty ?? true)
        originModel.invalidType = self.invalidType
        if let warningText = warning?.warningText {
            originModel.isWarningVisible = true
            originModel.warningText = warningText.text ?? BundleI18n.SKResource.Bitable_Relation_FieldTypeChangedTip_Mobile
            // notSupport 优先级比invalidType高
            originModel.invalidType = .other
        }
        originModel.buttonModels = self.cells?.map({ item in
            if let checkBox = item.checkBox {
                return BTConditionSelectButtonModel(text: "", type: .checkbox, typeValue: checkBox.checked)
            } else if item.onClick.isEmpty {
                return BTConditionSelectButtonModel(text: item.content?.text ?? "", type: .plainText)
            }
            let hasContent = !(item.content?.text.isEmpty ?? true)
            let text = hasContent ? item.content?.text : item.content?.placeholder
            let textColor = hasContent ? UDColor.textTitle : UDOCColor.textPlaceholder
            return BTConditionSelectButtonModel(text: text ?? "",
                                                icon: item.leftIcon?.image,
                                                showIconLighting: item.isSync ?? false,
                                                textColor: textColor,
                                                hasRightIcon: !(item.rightIcon?.udToken.isEmpty ?? true))
        }) ?? []
        return originModel
    }
}

public struct BTConditionSelectCellModel {
    var conditionId: String = ""
    //标题
    var title: String = ""
    //按钮模型
    var buttonModels: [BTConditionSelectButtonModel] = []
    //是否展示删除按钮
    var isShowDelete: Bool = true
    //是否显示警告提示
    var isWarningVisible: Bool = false
    var warningText: String = ""
    var invalidType: BTFieldInvalidType? = .other
    var isDisable: Bool?
    
    static func titleWithIndex(_ index: Int) -> String {
        return BundleI18n.SKResource.Bitable_SingleOption_DefaultConditionName_Mobile(String(index))
    }
}

public final class BTConditionSelectCell: UITableViewCell {

    enum Const {
        static var conditionButtonInteritemSpacing: CGFloat = 8
        static var conditionButtonLineSpacing: CGFloat = 8
    }

    public var isFirstCell: Bool = true {
        didSet {
            containerView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(isFirstCell ? 0 : 10)
            }
        }
    }

    private lazy var containerView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFloat
        it.layer.cornerRadius = 10
    }

    private lazy var label = UILabel().construct { it in
        it.font = .systemFont(ofSize: 14)
        it.textColor = UDColor.textPlaceholder
    }

    private lazy var deleteButton = UIButton().construct { it in
        it.setImage(UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3), for: [.normal, .highlighted])
        it.addTarget(self, action: #selector(didClickDelete), for: .touchUpInside)
    }

    private lazy var warningLable = UILabel().construct { it in
        it.numberOfLines = 0
        it.lineBreakMode = .byWordWrapping
        it.textColor = UDColor.textPlaceholder
        it.font = .systemFont(ofSize: 14)
    }

    private lazy var warningView = UIView().construct { it in
        it.isHidden = true
        let warningIcon = UIImageView()
        warningIcon.image = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: 18, height: 18))

        it.addSubview(warningIcon)
        it.addSubview(warningLable)
        it.setContentHuggingPriority(.required, for: .vertical)

        warningIcon.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.top.left.equalToSuperview()
        }

        warningLable.snp.makeConstraints { make in
            make.top.equalTo(warningIcon).offset(2)
            make.bottom.equalToSuperview()
            make.left.equalTo(warningIcon.snp.right).offset(6)
            make.right.lessThanOrEqualToSuperview()
        }
    }
    
    private static var layoutConfig: BTConditiopnLayoutConfiguration {
        return BTConditiopnLayoutConfiguration(rowSpacing: 8, colSpacing: 8, lineHeight: 32)
    }

    private lazy var flowLayout = BTConditionCollectionViewLayout().construct { it in
        it.minimumLineSpacing = 8
        it.minimumInteritemSpacing = 8
        it.layoutConfig = Self.layoutConfig
    }

    private lazy var buttonCollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout).construct { it in
        it.delegate = self
        it.dataSource = self
        it.backgroundColor = .clear
        it.insetsLayoutMarginsFromSafeArea = false
        it.contentInsetAdjustmentBehavior = .never
        it.isScrollEnabled = false
        it.delaysContentTouches = false
        it.showsVerticalScrollIndicator = false
        it.showsHorizontalScrollIndicator = false
        it.register(BTConditionSelectButtonCell.self, forCellWithReuseIdentifier: ConditionSelectionType.selection.rawValue)
        it.register(BTConditionCheckBoxCell.self, forCellWithReuseIdentifier: ConditionSelectionType.checkbox.rawValue)
        it.register(BTConditionLoadingCell.self, forCellWithReuseIdentifier: ConditionSelectionType.loading.rawValue)
        it.register(BTConditionLoadingCell.self, forCellWithReuseIdentifier: ConditionSelectionType.failed.rawValue)
        it.register(BTConditionUnreadableCell.self, forCellWithReuseIdentifier: ConditionSelectionType.unreadable.rawValue)
        it.register(BTConditionPlainTextCell.self, forCellWithReuseIdentifier: ConditionSelectionType.plainText.rawValue)
    }

    private var model: BTConditionSelectCellModel = BTConditionSelectCellModel()
    private var newModel: BTNewConditionSelectCellModel?

    private var currentLineNumber = 1
    public weak var delegate: BTConditionSelectCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }

        containerView.addSubview(label)
        containerView.addSubview(deleteButton)
        containerView.addSubview(buttonCollectionView)
        containerView.addSubview(warningView)

        label.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(16)
            make.height.equalTo(20)
            make.right.lessThanOrEqualTo(deleteButton.snp.left)
        }

        deleteButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(label)
        }

        buttonCollectionView.snp.makeConstraints { make in
            make.height.equalTo(0)
            make.top.equalToSuperview().offset(44)
            make.left.right.equalToSuperview().inset(16)
        }
        
        warningView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview().inset(0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configModel(_ model: BTConditionSelectCellModel) {
        var model = model
        if model.invalidType == .fieldUnreadable {
            var invalidButton = BTConditionSelectButtonModel(text: BundleI18n.SKResource.Bitable_AdvancedPermission_NotAccessibleField)
            invalidButton.icon = nil
            invalidButton.type = .unreadable
            invalidButton.hasRightIcon = true
            model.buttonModels = [invalidButton]
            model.warningText = ""
            model.isWarningVisible = false
            model.isShowDelete = true
        }
        self.model = model
        
        label.text = model.title
        flowLayout.data = model.buttonModels
        buttonCollectionView.collectionViewLayout = flowLayout
        buttonCollectionView.reloadData()
        
        deleteButton.isHidden = !model.isShowDelete
        
        warningView.isHidden = !model.isWarningVisible
        warningLable.text = model.warningText

        warningView.snp.updateConstraints { make in
            make.left.right.bottom.equalToSuperview().inset(model.isWarningVisible ? 16 : 0)
        }
    }
    
    func setData(_ model: BTNewConditionSelectCellModel) {
        self.newModel = model
        self.configModel(model.originModel)
    }
    
    @objc
    private func didClickDelete() {
        delegate?.didClickDelete(cell: self)
    }
    

    /// 更新布局并且返回当前cell的高度
    /// - Returns: 高度9
    @discardableResult
    public func relayout() -> CGFloat {
        buttonCollectionView.layoutIfNeeded()
        //内部button高度+title高度和边距+底部留白
        let isEmpty = model.buttonModels.isEmpty
        let contentHeight = isEmpty ? 0 : buttonCollectionView.contentSize.height
        let contentBottomSpacing: CGFloat = isEmpty ? 0 : 16
        var fixedHeight = contentHeight + 44 + contentBottomSpacing
        fixedHeight += isFirstCell ? 0 : 10
        buttonCollectionView.snp.updateConstraints { make in
            make.height.equalTo(contentHeight)
        }
        fixedHeight += Self.calculateWarningHeight(with: model, limitWidth: buttonCollectionView.bounds.width - 22)
        debugPrint("filtertest relayoutHeight \(fixedHeight) contentHeight: \(contentHeight)")
        return fixedHeight
    }
    
    /// 计算高度
    static func calculateCellHeight(with model: BTConditionSelectCellModel, cellWith: CGFloat, hasTopSpacing: Bool) -> CGFloat {
        let width = cellWith - 32 - 32 //需要减去 containerView 外部的两边 16，再减去内部的两边 16
        let contentHeight: CGFloat
        let contentBottomSpacing: CGFloat
        if model.buttonModels.isEmpty {
            contentHeight = 0
            contentBottomSpacing = 0
        } else {
            contentHeight = BTConditionCollectionViewWaterfallHelper.calculate(with: model.buttonModels,
                                                                               maxLineLength: width,
                                                                               layoutConfig: Self.layoutConfig).0.height
            contentBottomSpacing = 16
        }
        var fixedHeight = contentHeight + 44 + contentBottomSpacing
        fixedHeight += hasTopSpacing ? 10 : 0
        fixedHeight += calculateWarningHeight(with: model, limitWidth: width - 22)
        debugPrint("filtertest calculateCellHeight \(fixedHeight)")
        return fixedHeight
    }
    
    /// 计算错误文案高度
    private static func calculateWarningHeight(with model: BTConditionSelectCellModel, limitWidth: CGFloat) -> CGFloat {
        if model.isWarningVisible {
            //展示cell警告信息，需要重新计算cell高度
            let warningLableHeight = model.warningText.getHeight(withConstrainedWidth: limitWidth, font: UIFont.systemFont(ofSize: 14))
            return warningLableHeight + 16
        }
        return 0
    }
}
protocol BTConditionNoPermissionCellDelegate: AnyObject {
    func didClickNoPermissionCellDelete(cell: UITableViewCell)
}
// 无权限条件cell
public final class BTConditionNoPermissionCell: UITableViewCell {
    weak var delegate: BTConditionNoPermissionCellDelegate?
    lazy var outView: UIView = {
        var view = UIView()
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.backgroundColor = UDColor.bgFloat
        return view
    }()
    lazy var label: UILabel = {
        let view = UILabel()
        view.font = UDFont.body1
        view.textColor = UDColor.textPlaceholder
        view.numberOfLines = 0
        return view
    }()
    lazy var deleteButton = UIButton().construct { it in
        it.setImage(UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3), for: [.normal, .highlighted])
        it.addTarget(self, action: #selector(didClickDelete), for: .touchUpInside)
    }
    @objc
    func didClickDelete() {
        guard let delegate = delegate else {
            DocsLogger.error("didClickDelete error delegate is nil")
            return
        }
        delegate.didClickNoPermissionCellDelete(cell: self)
    }
    var isFirstCell: Bool = true {
        didSet {
            // 保护逻辑，避免代码修改导致的outView没有被添加到视图层级，原则上不会进入else内
            guard outView.superview != nil else {
                DocsLogger.error("outView.superview is nil")
                return
            }
            outView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(isFirstCell ? 0 : 10)
            }
        }
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(outView)
        outView.addSubview(label)
        outView.addSubview(deleteButton)
        outView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.bottom.equalToSuperview()
        }
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(deleteButton.snp.left)
            make.centerY.equalToSuperview()
        }
        deleteButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(label)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func configText(_ text: String) {
        label.text = text
    }
}

extension BTConditionSelectCell: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < model.buttonModels.count, model.invalidType != .fieldUnreadable else {
            return
        }

        let cell = collectionView.cellForItem(at: indexPath)
        delegate?.didClickContainerButton(index: indexPath.row, cell: self, subCell: cell)
    }
}

extension BTConditionSelectCell: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
         return model.buttonModels.count
     }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.row < model.buttonModels.count else { return BTConditionSelectButtonCell() }
        var buttonModel = model.buttonModels[indexPath.row]
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: buttonModel.type.rawValue, for: indexPath)
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if model.isDisable == true {
                buttonModel.enable = false
            } else {
                buttonModel.enable = true
            }
        }
        switch buttonModel.type {
        case .unreadable:
            guard let cell = collectionViewCell as? BTConditionUnreadableCell else {
                return collectionViewCell
            }
            cell.update(model: buttonModel)
        case .selection:
            guard let cell = collectionViewCell as? BTConditionSelectButtonCell else {
                return collectionViewCell
            }
            cell.update(model: buttonModel)
            cell.didTapItem = { [weak self] in
                self?.collectionView(collectionView, didSelectItemAt: indexPath)
            }
        case .checkbox:
            guard let cell = collectionViewCell as? BTConditionCheckBoxCell else {
                return collectionViewCell
            }
            let isSelected = buttonModel.typeValue as? Bool ?? false
            cell.updateCheckBox(isSelected: isSelected, text: buttonModel.text)
        case .loading, .failed:
            guard let cell = collectionViewCell as? BTConditionLoadingCell else {
                return collectionViewCell
            }
            
            if buttonModel.type == .failed {
                cell.didTapRetry = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.didClickRetry(index: indexPath.row, cell: self, subCell: cell)
                }
            }

            cell.updateText(buttonModel.text)
        case .plainText:
            guard let cell = collectionViewCell as? BTConditionPlainTextCell else {
                return collectionViewCell
            }
            cell.updateText(text: buttonModel.text)
        }
        return collectionViewCell
     }
}
