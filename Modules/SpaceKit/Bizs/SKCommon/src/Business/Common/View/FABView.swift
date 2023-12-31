//
//  FABContainer.swift
//  SpaceKit
//
//  Created by Webster on 2019/7/10.
//

import UIKit
import SKFoundation
import HandyJSON
import SKResource
import SKUIKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignShadow

public enum FABIdentifier: String, HandyJSONEnum {
    // sheet:
    case search = "search" // 搜索按钮
    case keyboard = "input" // 键盘
    case cardMode = "cardMode" // 卡片模式
    case toolkit = "operation" // 快速操作面板

    // bitable:
    case bitableViewList = "bitableViewList"   // 视图管理
    case bitableGrid = "bitableGrid"       // 表格视图
    case bitableKanban = "bitableKanban"   // 看板试图
    case bitableGallery = "bitableGallery" // 画册视图
    case bitableGantt = "bitableGantt"     // 甘特图
    case zoomIn = "kanbanZoomIn"           // 放大，目前只有 grid 和 kanban 有这个能力，grid 表现为主键独立成行
    case zoomOut = "kanbanZoomOut"         // 缩小，目前只有 grid 和 kanban 有这个能力，grid 表现为所有字段放在同一行
    case createBitableRecord = "createRecord" // 创建卡片
    case bitableManager = "bitableManager" // bitable管理面板
    case shareForm = "shareForm" // bitable分享表单
    case shareDashboard = "shareDashboard" // bitable 通用分享接口

    var iconImage: UIImage {
        switch self {
        case .search: return UDIcon.findAndReplaceOutlined
        case .keyboard: return UDIcon.keyboardOutlined
        case .cardMode: return UDIcon.sheetCardmodelOutlined
        case .toolkit: return UDIcon.styleOutlined

        case .bitableViewList, .bitableManager: return UDIcon.viewListOutlined
        case .bitableGrid: return UDIcon.bitablegridOutlined
        case .bitableKanban: return UDIcon.bitablekanbanOutlined
        case .bitableGallery: return UDIcon.bitablegalleryOutlined
        case .bitableGantt: return UDIcon.bitableganttOutlined
        case .zoomIn: return UDIcon.zoomInOutlined
        case .zoomOut: return UDIcon.zoomOutOutlined
        case .createBitableRecord: return UDIcon.addOutlined
        case .shareForm: return UDIcon.shareOutlined
        case .shareDashboard: return UDIcon.shareOutlined
        }
    }

    var accessibilityID: String {
        switch self {
        case .toolkit:
            return "sheets.fab.button.toolkit"
        default:
            return "fab.button.\(rawValue)"
        }
    }

    var isPrimary: Bool {
        switch self {
        case .toolkit, .createBitableRecord, .shareForm:
            return true
        default:
            return false
        }
    }

    var canDisplayOnLanscapePhone: Bool {
        switch self {
        case .createBitableRecord: //手机横屏下不支持新建记录
            return false
        default:
            return true
        }
    }
}

public struct FABData: Equatable, HandyJSON, CustomStringConvertible {
    public var id: FABIdentifier = .keyboard
    public var disabled: Bool = false
    public var title: String?

    public init() {}
    
    public var description: String {
        return "id:\(id.rawValue),disabled:\(disabled) "
    }
}


public struct FABParams: Equatable, HandyJSON {
    public var data: [FABData] = []
    public var callback: String = ""

    public init() {}
}

public protocol FABContainerDelegate: AnyObject {
    func didClickFABButton(_ button: FABIdentifier, view: FABContainer)
}

public protocol FABCacheListener: AnyObject {
    func onFABButtonsChange()
}

public final class FABContainer: UIView {

    public weak var delegate: FABContainerDelegate?

    private lazy var stackView = UIStackView().construct { it in
        it.distribution = .equalSpacing
        it.axis = .horizontal
        it.alignment = .center
        it.spacing = 12
    }

    private var cache: [FABData] = []
    
    public let cacheListeners = ObserverContainer<FABCacheListener>()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.leading.bottom.equalToSuperview()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func orientationDidChange() {
        rearrangeButtons(cache)
    }

    public func updateButtons(_ data: [FABData]) {
        guard cache != data else { return }
        cache = data

        rearrangeButtons(data)
        
        self.cacheListeners.all.forEach { item in
            item.onFABButtonsChange()
        }
    }

    private func rearrangeButtons(_ data: [FABData]) {
        var newData = data
        if SKDisplay.phone && UIApplication.shared.statusBarOrientation.isLandscape {
            newData = data.filter { $0.id.canDisplayOnLanscapePhone }
        }

        stackView.subviews.forEach { $0.removeFromSuperview() }

        for item in newData {
            if let title = item.title {
                if item.id == .shareForm {
                    attachShareFormButton(text: title, disabled: item.disabled)
                } else if item.id == .toolkit {
                    attachToolkitButton(text: title, disabled: item.disabled)
                } else if item.id == .shareDashboard {
                    attachShareBitableButton(text: title, disabled: item.disabled)
                }
            } else {
                attachFloatButton(id: item.id, disabled: item.disabled)
            }
        }
    }

    private func attachShareFormButton(text: String, disabled: Bool) {
        let button = TextOnlyPrimaryButton(text: text)
        button.isDisabled = disabled
        button.accessibilityIdentifier = FABIdentifier.shareForm.accessibilityID
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(didClickShareFormButton(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }
    
    /// Bitable 通用分享按钮
    private func attachShareBitableButton(text: String, disabled: Bool) {
        let button = TextOnlyPrimaryButton(text: text)
        button.isDisabled = disabled
        button.accessibilityIdentifier = FABIdentifier.shareForm.accessibilityID
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(didClickShareBitableButton(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }

    private func attachToolkitButton(text: String, disabled: Bool) {
        let button = PrimaryButtonWithText(text)
        button.isDisabled = disabled
        button.setImage(UDIcon.styleOutlined.ud.withTintColor(UDColor.primaryOnPrimaryFill), for: .normal)
        button.isAccessibilityElement = true
        button.accessibilityIdentifier = FABIdentifier.toolkit.accessibilityID
        button.addTarget(self, action: #selector(didClickSheetToolkitButton(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }

    private func attachFloatButton(id: FABIdentifier, disabled: Bool) {
        let button = id.isPrimary ? FloatPrimaryButton(id: id) : FloatSecondaryButton(id: id)
        button.isDisabled = disabled
        button.isAccessibilityElement = true
        button.accessibilityIdentifier = id.accessibilityID
        button.addTarget(self, action: #selector(didClickFloatButton(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }

    @objc
    private func didClickFloatButton(_ sender: FloatButton) {
        delegate?.didClickFABButton(sender.buttonIdentifier, view: self)
    }

    @objc
    private func didClickSheetToolkitButton(_ sender: UIButton) {
        delegate?.didClickFABButton(.toolkit, view: self)
    }

    @objc
    private func didClickShareFormButton(_ sender: UIButton) {
        delegate?.didClickFABButton(.shareForm, view: self)
    }
    
    @objc
    private func didClickShareBitableButton(_ sender: UIButton) {
        delegate?.didClickFABButton(.shareDashboard, view: self)
    }
    
    public func hasFABItem(_ fabID: FABIdentifier) -> Bool {
        return cache.contains { $0.id == fabID && !$0.disabled }
    }
}

/// 没有文字，只有图标的浮动按钮
public class FloatButton: UIButton {

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: 40, height: 40)
    }

    public var buttonIdentifier: FABIdentifier

    public var foregroundColor: UIColor { .clear }

    public var normalBackgroundColor: UIColor { .clear }

    public var highlightedBackgroundColor: UIColor { .clear }

    public var disabledBackgroundColor: UIColor { .clear }

    public override var isHighlighted: Bool {
        didSet {
            guard !isDisabled else { return }
            if isHighlighted {
                backgroundColor = highlightedBackgroundColor
            } else {
                backgroundColor = normalBackgroundColor
            }
        }
    }

    public var isDisabled: Bool = false

    public init(id: FABIdentifier) {
        buttonIdentifier = id
        super.init(frame: .zero)
        backgroundColor = normalBackgroundColor
        contentEdgeInsets = UIEdgeInsets(edges: 8)
        setImage(id.iconImage.ud.withTintColor(foregroundColor), for: .normal)
        adjustsImageWhenHighlighted = false
        adjustsImageWhenDisabled = false
        layer.cornerRadius = 20
        docs.addStandardLift()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


public final class FloatPrimaryButton: FloatButton {

    public override var foregroundColor: UIColor { UDColor.primaryOnPrimaryFill }

    public override var normalBackgroundColor: UIColor { UDColor.primaryContentDefault }

    public override var highlightedBackgroundColor: UIColor { UDColor.primaryContentPressed }

    public override var isDisabled: Bool {
        didSet {
            if isDisabled {
                backgroundColor = UDColor.fillDisabled
                layer.ud.setShadow(type: .s4Down)
            } else {
                backgroundColor = normalBackgroundColor
                layer.ud.setShadow(type: .s4DownPri)
            }
        }
    }

    public override init(id: FABIdentifier) {
        super.init(id: id)
        layer.ud.setShadow(type: .s4DownPri)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class FloatSecondaryButton: FloatButton {

    public override var foregroundColor: UIColor { UDColor.primaryContentDefault }

    public override var normalBackgroundColor: UIColor { UDColor.bgFloat }

    public override var highlightedBackgroundColor: UIColor { UDColor.primaryFillSolid02 }

    public override var isDisabled: Bool {
        didSet {
            if isDisabled {
                backgroundColor = UDColor.fillDisabled
            } else {
                backgroundColor = normalBackgroundColor
            }
        }
    }

    public override init(id: FABIdentifier) {
        super.init(id: id)
        layer.borderWidth = 0.5
        layer.ud.setBorderColor(UDColor.lineBorderCard)
        layer.ud.setShadow(type: .s4Down)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 左边图标、右边文字
public final class PrimaryButtonWithText: UIButton {

    public override var intrinsicContentSize: CGSize {
        let textWidth: CGFloat = titleLabel?.intrinsicContentSize.width ?? 0
        return CGSize(width: 20 + 24 + 4 + textWidth + 20, height: 40)
    }

    public override var isHighlighted: Bool {
        didSet {
            guard !isDisabled else { return }
            if isHighlighted {
                backgroundColor = UDColor.primaryContentPressed
            } else {
                backgroundColor = UDColor.primaryContentDefault
            }
        }
    }

    public var isDisabled: Bool = false {
        didSet {
            if isDisabled {
                backgroundColor = UDColor.fillDisabled
                layer.ud.setShadow(type: .s4Down)
            } else {
                backgroundColor = UDColor.primaryContentDefault
                layer.ud.setShadow(type: .s4DownPri)
            }
        }
    }

    public init(_ text: String) {
        super.init(frame: .zero)
        backgroundColor = UDColor.primaryContentDefault
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        adjustsImageWhenHighlighted = false
        adjustsImageWhenDisabled = false
        layer.cornerRadius = 20
        setTitle(text, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 17)
        titleLabel?.adjustsFontForContentSizeCategory = false
        titleLabel?.adjustsFontSizeToFitWidth = false
        titleLabel?.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        layer.ud.setShadow(type: .s4DownPri)
        docs.addStandardLift()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// 没有图标，只有文字
public final class TextOnlyPrimaryButton: UIButton {

    public override var intrinsicContentSize: CGSize {
        let textWidth: CGFloat = titleLabel?.intrinsicContentSize.width ?? 0
        return CGSize(width: 20 + textWidth + 20, height: 40)
    }

    public override var isHighlighted: Bool {
        didSet {
            guard !isDisabled else { return }
            if isHighlighted {
                backgroundColor = UDColor.primaryContentPressed
            } else {
                backgroundColor = UDColor.primaryContentDefault
            }
        }
    }

    public var isDisabled: Bool = false {
        didSet {
            if isDisabled {
                backgroundColor = UDColor.fillDisabled
                layer.ud.setShadow(type: .s4Down)
            } else {
                backgroundColor = UDColor.primaryContentDefault
                layer.ud.setShadow(type: .s4DownPri)
            }
        }
    }

    public init(text: String) {
        super.init(frame: .zero)
        backgroundColor = UDColor.primaryContentDefault
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        setTitle(text, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 17)
        titleLabel?.adjustsFontForContentSizeCategory = false
        titleLabel?.adjustsFontSizeToFitWidth = false
        titleLabel?.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        layer.cornerRadius = 20
        layer.ud.setShadow(type: .s4DownPri)
        docs.addStandardLift()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
