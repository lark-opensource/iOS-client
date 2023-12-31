//
//  File.swift
//  SKBitable
//
//  Created by zoujie on 2022/1/18.
//  
// swiftlint:disable all
import Foundation
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import SKResource
import UIKit
import UniverseDesignDialog
import UniverseDesignCheckBox
import SKFoundation
class BTFieldCustomButton: UIButton {
    private lazy var leftIconView = BTLightingIconView()
    private lazy var rightIconView = UIImageView()

    private(set) var enable: Bool = true

    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? UDColor.N900.withAlphaComponent(0.1) : UDColor.bgFloat
        }
    }

    private lazy var headLabel = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.setContentCompressionResistancePriority(.required, for: .horizontal)
        it.font = .systemFont(ofSize: 16)
    }

    private lazy var subTitleLabel = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = .systemFont(ofSize: 14)
        it.adjustsFontSizeToFitWidth = true
        it.minimumScaleFactor = 0.8
        it.numberOfLines = 2
    }

    private lazy var descriptionLabel = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = .systemFont(ofSize: 14)
    }

    private lazy var warningIcon = UIImageView().construct { it in
        it.isHidden = true
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            // 修改为🔒图标
            it.image = UDIcon.getIconByKey(.lockFilled, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.iconN3)
        } else {
        it.image = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: 18, height: 18))
        }
    }

    /// 引导view
    private lazy var onboardingView = UIButton().construct { it in
        it.setTitle("New",
                    withFontSize: 10,
                    fontWeight: .regular,
                    singleColor: UDColor.primaryOnPrimaryFill,
                    forAllStates: [.normal, .highlighted, .selected, [.highlighted, .selected]])
        it.isUserInteractionEnabled = false
        it.backgroundColor = UDColor.colorfulRed
        it.isHidden = true
        it.layer.cornerRadius = 7
    }

    public var identifier: String = ""

    init() {
        super.init(frame: .zero)
        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpUI() {
        addSubview(headLabel)
        addSubview(warningIcon)
        addSubview(subTitleLabel)
        addSubview(descriptionLabel)
        addSubview(leftIconView)
        addSubview(rightIconView)
        addSubview(onboardingView)

        backgroundColor = UDColor.bgFloat
        layer.cornerRadius = 10

        leftIconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        headLabel.snp.makeConstraints { make in
            make.height.equalTo(22)
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(44)
            make.right.lessThanOrEqualTo(subTitleLabel.snp.left).offset(-4)
        }

        onboardingView.snp.makeConstraints { make in
            make.height.equalTo(14)
            make.centerY.equalToSuperview()
            make.left.equalTo(headLabel.snp.right).offset(8)
        }

        warningIcon.snp.makeConstraints { make in
            make.width.height.equalTo(0)
            make.centerY.equalToSuperview()
            make.right.equalTo(subTitleLabel.snp.left).offset(-4)
            make.left.greaterThanOrEqualTo(headLabel.snp.right).offset(4)
        }

        subTitleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(rightIconView.snp.left).offset(-4)
            make.left.equalTo(warningIcon.snp.right).offset(4)
        }

        rightIconView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-15)
            make.left.equalToSuperview().offset(44)
            make.right.lessThanOrEqualTo(subTitleLabel.snp.left)
        }
    }

    func setTitleString(text: String) {
        headLabel.text = text
    }

    func setSubTitleString(text: String) {
        subTitleLabel.text = text
    }

    func setDescriptionString(text: String) {
        descriptionLabel.text = text
    }

    func setTitleColor(color: UIColor) {
        headLabel.textColor = color
    }

    func setLeftIcon(image: UIImage, showLighting: Bool = false) {
        leftIconView.update(image, showLighting: showLighting, tintColor: UDColor.iconN1)
    }
    
    private var headLabelLeftMargin: CGFloat?
    private func getHeadLabelLeftMargin() -> CGFloat {
        if let headLabelLeftMargin = headLabelLeftMargin {
            return headLabelLeftMargin
        }
        return leftIconView.isHidden ? 16 : 44
    }
    
    func setLeftIcon(view: UIView, size: CGSize? = nil, iconSpaceWithTitle: CGFloat? = nil) {
        view.removeFromSuperview()
        self.leftIconView.addSubview(view)
        view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        if let size = size {
            if let iconSpaceWithTitle = iconSpaceWithTitle {
                self.headLabelLeftMargin = 16 + size.width + iconSpaceWithTitle
            }
            self.leftIconView.snp.updateConstraints { make in
                make.size.equalTo(size)
            }
            self.headLabel.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(getHeadLabelLeftMargin())
            }
        }
    }

    func setRightIcon(image: UIImage) {
        self.rightIconView.image = image
    }

    func setLeftIconVisible(isVisible: Bool) {
        leftIconView.isHidden = !isVisible
        headLabel.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(getHeadLabelLeftMargin())
        }

        descriptionLabel.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(getHeadLabelLeftMargin())
        }
    }

    func setWaringIconVisible(isVisible: Bool) {
        warningIcon.isHidden = !isVisible
        warningIcon.snp.updateConstraints { make in
            make.width.height.equalTo(isVisible ? 18 : 0)
        }
    }

    func setButtonEnable(enable: Bool) {
        self.enable = enable
        leftIconView.updateTintColor(enable ? UDColor.iconN1 : UDColor.iconDisabled)
        headLabel.textColor = enable ? UDColor.textTitle : UDColor.textDisabled
        subTitleLabel.textColor = enable ? UDColor.textPlaceholder : UDColor.textDisabled
        descriptionLabel.textColor = enable ? UDColor.textPlaceholder : UDColor.textDisabled
    }

    func setOnboardingViewVisible(isVisible: Bool) {
        onboardingView.isHidden = !isVisible
    }
}

final class BTAddButton: UIButton {
    var icon = UIImageView()

    var label = UILabel().construct { it in
        it.textColor = UDColor.primaryContentDefault
        it.font = .systemFont(ofSize: 16)
    }

    override var isHighlighted: Bool {
        didSet {
            guard buttonIsEnabled else { return }
            self.backgroundColor = isHighlighted ? UDColor.N900.withAlphaComponent(0.1) : UDColor.bgFloat
        }
    }

    var buttonIsEnabled: Bool = true {
        didSet {
            self.label.textColor = buttonIsEnabled ? UDColor.primaryContentDefault : UDColor.textDisabled
            self.icon.image = self.icon.image?.ud.withTintColor(buttonIsEnabled ? UDColor.primaryContentDefault : UDColor.iconDisabled)
        }
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = UDColor.bgFloat
        layer.cornerRadius = 10

        addSubview(icon)
        addSubview(label)

        icon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        label.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
            make.right.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(text: String) {
        label.text = text
    }
}

final class BTAutoNumberPreviewView: UIView {
    var label = UILabel().construct { it in
        it.textColor = UDColor.textCaption
        it.font = .systemFont(ofSize: 16)
        it.text = BundleI18n.SKResource.Bitable_Field_AutoIdPreviewMobileVer
    }

    var previewTextLabel = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.numberOfLines = 0
        it.lineBreakMode = .byWordWrapping
        it.font = .systemFont(ofSize: 16)
    }

    var fakeTextLabel = UILabel().construct { it in
        it.numberOfLines = 1
        it.isHidden = true
        it.font = .systemFont(ofSize: 16)
    }

    init() {
        super.init(frame: .zero)
        layer.cornerRadius = 10
        clipsToBounds = true
        backgroundColor = UDColor.bgFloat

        addSubview(previewTextLabel)
        addSubview(fakeTextLabel)
        addSubview(label)

        previewTextLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.left.equalTo(label.snp.right).offset(12)
        }

        label.sizeToFit()
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalTo(fakeTextLabel)
            make.width.equalTo(label.bounds.width)
            make.right.equalTo(previewTextLabel.snp.left).offset(-12)
        }

        fakeTextLabel.snp.makeConstraints { make in
            make.top.left.right.equalTo(previewTextLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(text: String, viewWidth: CGFloat) -> CGFloat {
        previewTextLabel.text = text
        fakeTextLabel.text = text
        label.sizeToFit()
        let previewTextLabelWidth = viewWidth - label.bounds.width - 36
        return previewTextLabel.sizeThatFits(CGSize(width: previewTextLabelWidth, height: CGFloat.greatestFiniteMagnitude)).height
    }
}
/// figma：https://www.figma.com/file/orGCA6jqOvyBXIMKYcfE7f/%E8%BD%AC%E6%8D%A2%E4%B8%BA%E4%BA%BA%E5%91%98%E5%AD%97%E6%AE%B5?node-id=0%3A1
final class ConvertUserAlertContentView: UIView {
    let msg: UILabel = {
        let lab = UILabel()
        lab.text = BundleI18n.SKResource.Bitable_PeopleField_Conversion_Description
        lab.font = .systemFont(ofSize: 16)
        lab.textColor = UDColor.textTitle
        lab.numberOfLines = 0
        return lab
    }()
    let check: UDCheckBox = {
        let che = UDCheckBox(boxType: .multiple) { box in
            box.isSelected = !box.isSelected
        }
        che.isEnabled = true
        che.isSelected = true
        return che
    }()
    let actMsg: UILabel = {
        let lab = UILabel()
        lab.text = BundleI18n.SKResource.Bitable_PeopleField_Conversion_Checkbox
        lab.font = UIFont.systemFont(ofSize: 14)
        lab.textColor = UDColor.textTitle
        lab.numberOfLines = 0
        return lab
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(msg)
        addSubview(check)
        addSubview(actMsg)
        msg.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(UDDialog.Layout.dialogWidth - 40)
        }
        check.snp.makeConstraints { make in
            make.centerY.equalTo(actMsg.snp.centerY)
            make.left.equalToSuperview()
            make.width.height.equalTo(18)
        }
        actMsg.snp.makeConstraints { make in
            make.top.equalTo(msg.snp.bottom).offset(12)
            make.left.equalTo(check.snp.right).offset(8)
            make.right.bottom.equalToSuperview().offset(-4)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BTFieldColorButton: BTFieldCustomButton {
    
    private let iconSize = CGSize(width: 22, height: 22)
    
    lazy var colorView: BTColorView = {
        let colorView = BTColorView()
        colorView.layer.cornerRadius = iconSize.width / 2
        colorView.layer.masksToBounds = true
        
        return colorView
    }()
    
    override func setUpUI() {
        super.setUpUI()
        
        self.setLeftIcon(view: colorView, size: iconSize, iconSpaceWithTitle: 12)
        self.setLeftIconVisible(isVisible: true)
    }
}
