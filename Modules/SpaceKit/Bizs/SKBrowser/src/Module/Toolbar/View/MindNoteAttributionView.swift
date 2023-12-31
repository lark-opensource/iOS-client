//longweiwei

import UIKit
import SnapKit
import SKCommon
import SKUIKit
import EENavigator
import UniverseDesignColor

protocol MindNoteAttributionViewDelegate: AnyObject {
    func mindnoteAttributionView(view: MindNoteAttributionView, button: BarButtonIdentifier, update value: String?)
}

private typealias Const = DocsAttributionViewConst
private struct DocsAttributionViewConst {
    static let attributionHeight: CGFloat = 144
    static let separateLineHeight: CGFloat = 1
    static let colorWellHeight: CGFloat = 46
    static let colorWellItemLength: CGFloat = 40
    static let colorWellItemCornerRadius: CGFloat = 8
    static let attributeBottomMinusHeight: CGFloat = 18
}

class MindNoteAttributionView: SKSubToolBarPanel {
    weak var delegate: MindNoteAttributionViewDelegate?
    // MARK: Data
    private var itemStatus: [BarButtonIdentifier: ToolBarItemInfo]
    // MARK: UI Widget
    private var containerView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.showsVerticalScrollIndicator = false
        return view
    }()
    private let attributionView: TextAttributionView

    private lazy var colorWell = SKColorWell(delegate: self)

    init(status: [BarButtonIdentifier: ToolBarItemInfo], frame: CGRect) {
        let attributionFrame = CGRect(x: 0, y: 0, width: SKDisplay.activeWindowBounds.width, height: Const.attributionHeight)
        let layout = ToolBarLayoutMapping.mindnoteAttributeItems()
        attributionView = TextAttributionView(status: status, layouts: layout, frame: attributionFrame)
        attributionView.shouldCenteredDisplay = false
        itemStatus = status
        super.init(frame: frame)
        configure()
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateStatus(status: [BarButtonIdentifier: ToolBarItemInfo]) {
        itemStatus = status
        attributionView.updateStatus(status: status)
        for (statusKey, statusValue) in status where statusKey == .highlight {
            if let colorsArray = statusValue.valueList {
                colorWell.updateColors(colorsArray, currentSelectedColor: statusValue.value)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.contentSize = CGSize(width: frame.width,
                                           height: preferedHeight())
    }
    
    func reloadColorWell() {
        colorWell.reloadColorWell()
    }
    
    private func configure() {
        attributionView.disableScroll()
        attributionView.delegate = self
    }
    
    private func setupView() {
        let separator = UIView()
        separator.backgroundColor = UDColor.lineDividerDefault
        addSubview(separator)
        separator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.top.leading.trailing.equalToSuperview()
        }
        
        addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.top.equalTo(separator.snp.bottom)
            make.leading.bottom.trailing.equalToSuperview()
        }
        containerView.addSubview(attributionView)
        containerView.addSubview(colorWell)
        attributionView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Const.attributionHeight)
            make.width.equalToSuperview()
        }
        colorWell.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(attributionView.snp.bottom)
            make.height.equalTo(Const.colorWellHeight)
        }
        attributionView.backgroundColor = UDColor.bgBody
        containerView.backgroundColor = UDColor.bgBody
        colorWell.backgroundColor = UDColor.bgBody
        updateStatus(status: itemStatus)
    }

    private func preferedHeight() -> CGFloat {
        return Const.attributionHeight + Const.colorWellHeight
    }
}

extension MindNoteAttributionView: TextAttributionViewDelegate {
    func didClickTxtAttributionView(view: TextAttributionView, button: AttributeButton) {
        guard let sId = button.itemInfo?.identifier, let barId = BarButtonIdentifier(rawValue: sId) else {
            return
        }
        if let item = itemStatus[barId] {
            panelDelegate?.select(item: item, update: nil, view: self)
        }
    }
}

extension MindNoteAttributionView: SKColorWellDelegate {
    var appearance: SKColorWell.Appearance {
        (length: Const.colorWellItemLength, radius: Const.colorWellItemCornerRadius)
    }

    var layout: SKColorWell.Layout {
        .singleLine
    }

    func didSelectColor(string: String, index: Int) {
        if let highlightItem = itemStatus[.highlight] {
            panelDelegate?.select(item: highlightItem, update: string, view: self)
        }
    }
}
