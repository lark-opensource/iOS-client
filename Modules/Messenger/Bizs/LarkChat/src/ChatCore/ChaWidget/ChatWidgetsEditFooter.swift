//
//  ChatWidgetsEditFooter.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/4/4.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon

final class ChatWidgetsEditFooter: UIView {
    static var footerHeight: CGFloat { return 66 }
    private let onTap: () -> Void

    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: Self.footerHeight))
        self.backgroundColor = UIColor.clear
        self.addSubview(editButton)
        editButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
            make.top.equalToSuperview().inset(16)
        }
        editButton.addTarget(self, action: #selector(clickEdit), for: .touchUpInside)
    }

    lazy var editButton: ChatWidgetsEditButton = ChatWidgetsEditButton()

    @objc
    private func clickEdit() {
        self.onTap()
    }

    func setEnable(_ enbale: Bool) {
        self.editButton.enable = enbale
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ChatWidgetsEditButton: UIControl {
    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkChat.Lark_Group_EditWidget_Button
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    private let imageView: UIImageView = UIImageView(image: UDIcon.getIconByKey(.editOutlined, renderingMode: .alwaysTemplate, size: CGSize(width: 16, height: 16)))

    override var isHighlighted: Bool {
        didSet {
            self.reload()
        }
    }

    var enable: Bool = true {
        didSet {
            self.reload()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(label)
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
            make.left.equalToSuperview().inset(16)
        }
        label.snp.makeConstraints { (make) in
            make.left.equalTo(imageView.snp.right).offset(4)
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        layer.cornerRadius = 18
        layer.borderWidth = 1
        layer.masksToBounds = true
        reload()
    }

    override func draw(_ rect: CGRect) {
        reload()
    }

    private func reload() {
        if !enable {
            self.backgroundColor = UIColor.ud.rgb(0xFFFFFF).withAlphaComponent(0.1)
            let tintColor = UIColor.ud.rgb(0xFFFFFF).withAlphaComponent(0.5) & UIColor.ud.rgb(0xFFFFFF).withAlphaComponent(0.2)
            self.layer.borderColor = tintColor.cgColor
            imageView.tintColor = tintColor
            label.textColor = tintColor
        } else if isHighlighted {
            self.backgroundColor = UIColor.ud.rgb(0xFFFFFF).withAlphaComponent(0.2)
            let tintColor = UIColor.ud.rgb(0xF8F9FA)
            self.layer.borderColor = UIColor.ud.rgb(0xF8F9FA).withAlphaComponent(0.5).cgColor
            imageView.tintColor = tintColor
            label.textColor = tintColor
        } else {
            self.backgroundColor = UIColor.clear
            let tintColor = UIColor.ud.rgb(0xF8F9FA)
            self.layer.borderColor = UIColor.ud.rgb(0xF8F9FA).withAlphaComponent(0.5).cgColor
            imageView.tintColor = tintColor
            label.textColor = tintColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ChatWidgetsBottomGestureView: UIView {
    weak var targetView: UIView?
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let targetView = targetView {
            let targetPoint = self.convert(point, to: targetView)
            if targetView.bounds.contains(targetPoint) {
                return false
            }
        }
        return super.point(inside: point, with: event)
    }
}
