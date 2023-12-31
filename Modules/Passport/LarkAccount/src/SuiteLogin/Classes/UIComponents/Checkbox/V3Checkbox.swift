//
//  V3Checkbox.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/12/12.
//

protocol V3CheckboxDelegate: AnyObject {
    func didTapV3Checkbox(_ checkbox: V3Checkbox)
}

class V3Checkbox: UIControl {
    public private(set) var on: Bool = false
    var iconView: UIImageView = UIImageView()
    private var iconSize: CGSize?
    public weak var delegate: V3CheckboxDelegate?
    private(set) var style: Style = .default

    public override var isSelected: Bool {
        didSet {
            self.refreshIcon()
        }
    }

    public init(iconSize: CGSize? = nil) {
        super.init(frame: .zero)
        self.iconSize = iconSize
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    func commonInit() {
        self.backgroundColor = UIColor.clear
        self.addTarget(self, action: #selector(handleTapCheckBox), for: .touchUpInside)
        addSubview(iconView)
        iconView.snp.makeConstraints({ make in
            if let iconSize = iconSize {
                make.size.equalTo(iconSize)
            }
            make.edges.equalToSuperview()
        })
        refreshIcon()
    }

    @objc
    func handleTapCheckBox(sender: UIControl) {
        if style == .stayChecked { return }
        self.isSelected = !self.isSelected
        self.delegate?.didTapV3Checkbox(self)
        self.sendActions(for: .valueChanged)
    }

    func refreshIcon() {
        switch style {
        case .default:
            let image = self.isSelected ? DynamicResource.checkbox_selected : Resource.V3.checkbox.ud.withTintColor(UIColor.ud.textPlaceholder)
            iconView.image = image
        case .stayChecked:
            iconView.image = Resource.V3.checkbox_disable
        }
    }

    enum Style {
        /// Default CheckBox Behavior
        case `default`
        /// Always stay checked
        case stayChecked
    }

    /// 避免与 superview 上的 tap gesture 冲突
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UITapGestureRecognizer.self) {
            return false
        } else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
    }
    
}
