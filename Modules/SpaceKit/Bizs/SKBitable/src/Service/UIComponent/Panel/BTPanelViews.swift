//
// Created by duanxiaochen.7 on 2021/3/14.
// Affiliated with SKBitable.
//
// Description:


import UIKit
import SnapKit
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import RxSwift
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignBadge

class BTPanelBottomView: UIView {
    
    enum LayoutMode {
        case single // 单按钮模式
        case multi  // 多按钮模式
    }
    
    private lazy var topSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private(set) lazy var button: SKHighlightButton = {
        let button = SKHighlightButton()
        button.normalBackgroundColor = .clear
        button.highlightBackgroundColor = UDColor.udtokenBtnSeBgNeutralHover
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        button.layer.cornerRadius = 6
        return button
    }()
    
    lazy var rightBadge: UDBadge = {
        let badge = UDBadge(config: .text)
        return badge
    }()
    

    private lazy var centerView = UIView().construct { view in
        view.isUserInteractionEnabled = false
    }

    private(set) lazy var buttonTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()

    private(set) lazy var buttonIconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let layoutMode: LayoutMode

    init(layoutMode: LayoutMode = .single) {
        self.layoutMode = layoutMode
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        if layoutMode == .single {
            addSubview(topSeperatorView)
            topSeperatorView.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }

        addSubview(button)
        button.snp.makeConstraints { make in
            let inset = layoutMode == .single ? 16 : 0
            make.top.bottom.equalToSuperview().inset(inset)
            make.left.equalToSuperview().offset(self.safeAreaInsets.left).inset(inset)
            make.right.equalToSuperview().offset(self.safeAreaInsets.right).inset(inset)
        }

        centerView.addSubview(buttonIconView)
        buttonIconView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }

        centerView.addSubview(buttonTitleLabel)
        buttonTitleLabel.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.height.equalTo(24)
            make.left.equalTo(buttonIconView.snp.right).offset(4)
        }

        button.addSubview(centerView)
        centerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(16)
        }
        
        button.addSubview(rightBadge)
        rightBadge.snp.makeConstraints { make in
            make.left.equalTo(centerView.snp.right).offset(8)
            make.centerY.equalToSuperview()
        }
    }

    func update(info: BTCommonItem) {
        if let image = info.leftIconImage {
            buttonIconView.image = image
            buttonIconView.snp.updateConstraints { make in
                make.width.equalTo(20)
            }
            buttonTitleLabel.snp.makeConstraints { make in
                make.left.equalTo(buttonIconView.snp.right).offset(4)
            }
        } else {
            buttonIconView.image = nil
            buttonIconView.snp.updateConstraints { make in
                make.width.equalTo(0)
            }
            buttonTitleLabel.snp.makeConstraints { make in
                make.left.equalTo(buttonIconView.snp.right)
            }
        }
        buttonTitleLabel.text = info.leftText
        buttonTitleLabel.textColor = info.leftTextColor
    }
    
    func updateTopLine(hidden: Bool) {
        topSeperatorView.isHidden = hidden
    }
    
    func updateButtonConstrains(letfMargin: CGFloat, rightMargin: CGFloat) {
        if button.superview != nil {
            button.snp.remakeConstraints { make in
                let inset = layoutMode == .single ? 16 : 0
                make.top.bottom.equalToSuperview().inset(inset)
                make.left.equalToSuperview().offset(self.safeAreaInsets.left).inset(letfMargin)
                make.right.equalToSuperview().offset(self.safeAreaInsets.left).inset(rightMargin)
            }
        }
    }

    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }
}

class PanelSectionHeader: UIView {
    
    var text: String
    
    lazy var label: UILabel = {
        let view = UILabel()
        view.text = text
        view.font = .systemFont(ofSize: 14)
        view.textColor = UDColor.textCaption
        return view
    }()
    
    init(text: String) {
        self.text = text
        super.init(frame: .zero)
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview().offset(-2)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(20)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
