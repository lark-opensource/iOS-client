//
//  PasswordCheckerView.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/2/8.
//

import UIKit
import UniverseDesignTheme
import UniverseDesignColor
import SnapKit

enum PasswordStrength {
    case invalid(String)
    case weak(String)
    case middle(String)
    case strong(String)
    
    var color: UIColor {
        switch self {
        case .invalid:
            return UIColor.ud.functionDangerContentDefault
        case .weak:
            return UIColor.ud.functionWarningContentDefault
        case .middle:
            return UIColor.ud.functionInfoContentDefault
        case .strong:
            return UIColor.ud.functionSuccessContentPressed
        }
    }
}

class PasswordStrengthIndicator: UIView {
    var strength: PasswordStrength = .middle("") {
        didSet {
            for bar in [weakBar, middleBar, strongBar] {
                bar.backgroundColor = strength.color
            }
            let grey = UDColor.rgb(0xc4c4c4)
            switch strength {
            case .invalid(_):
                weakBar.backgroundColor = grey
                middleBar.backgroundColor = grey
                strongBar.backgroundColor = grey
            case .weak(_):
                weakBar.backgroundColor = strength.color
                middleBar.backgroundColor = grey
                strongBar.backgroundColor = grey
            case .middle(_):
                weakBar.backgroundColor = strength.color
                middleBar.backgroundColor = strength.color
                strongBar.backgroundColor = grey
            case .strong(_):
                weakBar.backgroundColor = strength.color
                middleBar.backgroundColor = strength.color
                strongBar.backgroundColor = strength.color
            }
        }
    }
    
    private lazy var weakBar: UIView = {
        return makeBar()
    }()
    
    private lazy var middleBar: UIView = {
        return makeBar()
    }()
    
    private lazy var strongBar: UIView = {
        return makeBar()
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let stackView = UIStackView(arrangedSubviews: [weakBar, middleBar, strongBar])
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func makeBar() -> UIView {
        let view = UIView()
        view.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 21, height: 4))
        }
        return view
    }
}

class PasswordCheckerView: UIView {
    var strengthDescription: String = "" {
        didSet {
            strengthLabel.text = strengthDescription
        }
    }
    
    var strength: PasswordStrength = .middle("") {
        didSet {
            func show(strength: PasswordStrength, result: String) {
                errorLabel.text = ""
                errorLabel.isHidden = true
                strengthView.isHidden = false
                resultLabel.text = result
                resultLabel.textColor = strength.color
                indicator.strength = strength
            }
            
            switch strength {
            case .invalid(let errorMessage):
                errorLabel.isHidden = false
                strengthView.isHidden = true
                errorLabel.text = errorMessage
            case .weak(let result):
                show(strength: strength, result: result)
            case .middle(let result):
                show(strength: strength, result: result)
            case .strong(let result):
                show(strength: strength, result: result)
            }
        }
    }
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = PasswordStrength.invalid("").color
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var strengthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()
    
    private lazy var resultLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private lazy var indicator: PasswordStrengthIndicator = {
        let indicator = PasswordStrengthIndicator()
        return indicator
    }()
    
    private lazy var strengthView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [strengthLabel, resultLabel, indicator])
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        addSubview(errorLabel)
        errorLabel.isHidden = true
        errorLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualTo(self.snp.right)
        }
        
        addSubview(strengthView)
        strengthView.isHidden = true
        strengthView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualTo(self.snp.right)
        }
    }
}
