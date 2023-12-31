//  Created by Songwen Ding on 2018/5/14.

import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignIcon

// MARK: - Search textfield
public final class CollaboratorSearchTextField: UIView {

    public var inputField = UDTextField()

    public var placeholder: String? {
        didSet {
            self.inputField.input.attributedPlaceholder = NSAttributedString(
                string: self.placeholder ?? "",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.ud.N500
                ]
            )
        }
    }

    private lazy var left: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 18, height: 18))
        imageView.image = UDIcon.getIconByKey(.searchOutlineOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UDColor.iconN3)
        return imageView
    }()

    private lazy var right: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 18, height: 18))
        let icon = UDIcon.getIconByKey(.closeFilled, size: CGSize(width: 18, height: 18))
            .ud.withTintColor(UDColor.iconN3)
        button.setImage(icon, for: .normal)
        button.addTarget(self, action: #selector(clearTextField), for: .touchUpInside)
        return button
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.text = nil
        self.layer.cornerRadius = 6
        self.backgroundColor = UDColor.bgFiller

        var config = UDTextFieldUIConfig()
        config.backgroundColor = .clear
        config.textColor = UIColor.ud.N900
        config.font = UIFont.systemFont(ofSize: 16)

        inputField.config = config
        inputField.placeholder = BundleI18n.SKResource.Doc_Facade_CollaboratorsSearchHint()
        inputField.input.returnKeyType = .search
        inputField.setLeftView(self.left)
        inputField.setRightView(self.right)
        inputField.input.addTarget(self, action: #selector(editingChangedAction(sender:)), for: .editingChanged)

        self.addSubview(inputField)

        inputField.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(6)
            make.right.equalToSuperview().offset(-8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func clearTextField() {
        self.text = nil
        self.inputField.input.sendActions(for: .editingChanged)
    }

    @objc
    private func editingChangedAction(sender: UITextField) {
        // 有内容的时候显示
        self.right.isHidden = self.inputField.text?.isEmpty == true
    }

    public var text: String? {
        get { return self.inputField.text }
        set {
            self.inputField.text = newValue
            self.right.isHidden = self.inputField.text?.isEmpty == true
        }
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return self.inputField.becomeFirstResponder()
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        return self.inputField.resignFirstResponder()
    }
}
