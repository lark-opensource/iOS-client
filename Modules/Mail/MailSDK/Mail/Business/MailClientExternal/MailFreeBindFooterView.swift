//
//  MailFreeBindFooterView.swift
//  MailSDK
//
//  Created by ByteDance on 2023/8/9.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import SnapKit
import FigmaKit
import UniverseDesignCheckBox

/// 绑定入口底部协议视图
class MailFreeBindFooterView: UIView {
    /// footerview有两种模式
    /// normal: 正常模式
    /// gradient: 渐变
    enum Style {
        case normal
        case gradient
    }
    private let textView = UILabel(frame: .zero)
    private lazy var gradientView = LinearGradientView()
    private var style: Style = .normal
    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple)
        checkBox.isUserInteractionEnabled = false
        checkBox.isSelected = false
        return checkBox
    }()
    
    var checkboxSelected: Bool {
        set {
            checkBox.isSelected = true
        }
        get {
            return checkBox.isSelected
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        setup()
        setupTextViewContent()
        addTapGesture()
    }

    func changeStyle(_ style: Style) {
        guard self.style != style else { return }
        self.style = style
        if style == .gradient {
            setupGradient()
        } else {
            gradientView.removeFromSuperview()
            checkBox.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(14)
            }
            textView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(14)
            }
        }
    }

    private func setup() {
        backgroundColor = .clear
        if style == .gradient {
            setupGradient()
        }
        addSubview(checkBox)
        checkBox.snp.makeConstraints { make in
            make.width.height.equalTo(16.0)
            make.leading.equalToSuperview().offset(24)
            make.top.equalToSuperview().offset(14)
        }
        textView.backgroundColor = .clear
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.leading.equalTo(checkBox.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-24)
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        self.addGestureRecognizer(tap)
    }

    private func setupGradient() {
        gradientView.removeFromSuperview()
        gradientView.direction = .bottomToTop
        gradientView.colors = [UDColor.bgBody, UDColor.bgBody.withAlphaComponent(0.0)]
        gradientView.locations = [0.75, 1.0]
        addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        checkBox.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(24)
        }
        textView.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(24)
        }
        
        self.insertSubview(gradientView, belowSubview: checkBox)

    }

    private func setupTextViewContent() {
        let disclaimerString = BundleI18n.MailSDK.Mail_Login_DataBackupDisclaimer_Checkbox()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder,
                          NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let attributedString = NSMutableAttributedString(string: disclaimerString,
                                                         attributes: attributes)
        textView.attributedText = attributedString
        textView.textAlignment = .left
        textView.numberOfLines = 0
    }
    
    @objc
    func didTap() {
        checkBox.isSelected = !checkBox.isSelected
    }
}
