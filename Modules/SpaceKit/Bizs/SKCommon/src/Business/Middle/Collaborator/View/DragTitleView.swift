//
//  DragTitleView.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/11.
//  


import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon


// 5.0从FeedTableComponentView迁移出来

public final class DragTitleView: UIView {
    
    public var clickClose: (() -> Void)?
    
    private var leftTitleLabel: UILabel?
    private lazy var commentPanView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgFloatOverlay
        view.layer.cornerRadius = 3
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        return button
    }()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        let titleLine = UIView()
        titleLine.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(titleLine)
        
        addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(18)
            make.top.equalToSuperview().inset(14)
            make.width.height.equalTo(24)
        }
        
        titleLine.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        let titleLabel = UILabel().construct { it in
            it.isAccessibilityElement = true
            it.accessibilityIdentifier = "docs.feed.panel.title.label"
            it.accessibilityLabel = "docs.feed.panel.title.label"
            it.text = BundleI18n.SKResource.Doc_Normal_DocMessage
            it.textColor = UIColor.ud.N900
            it.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        leftTitleLabel = titleLabel
        // 滑动条块
        addSubview(commentPanView)
        commentPanView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(8)
            make.width.equalTo(40)
            make.height.equalTo(4)
        }
    }

    public func removeDragLine() {
        commentPanView.removeFromSuperview()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateTitle(title: String) {
        leftTitleLabel?.text = title
    }

    public func updateTitleFontSize(fontSize: UIFont) {
        leftTitleLabel?.font = fontSize
    }
    
    @objc
    func closeAction() {
        clickClose?()
    }
}
