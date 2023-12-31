//
//  LobbyToolBarItemView.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/6/14.
//

import Foundation

class LobbyToolBarItemView: UIView {

    struct PadLayout {
        static let iconSize: CGSize = CGSize(width: 20, height: 20)
        static let titleFont: UIFont = UIFont.systemFont(ofSize: 14)
        static let titleHeigt: CGFloat = 22
        static let expandSpacing: CGFloat = 6
        static let expandPadding: CGFloat = 12
        static let collapsePadding: CGFloat = 10

        static func textWidth(_ text: String) -> CGFloat {
            text.vc.boundingWidth(height: titleHeigt, font: titleFont)
        }
    }

    enum Style {
        case phone
        case padExpand
        case padCollapse
    }

    var style: Style = .phone {
        didSet {
            updateLayout()
        }
    }

    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    var titleColor: UIColor? {
        didSet {
            titleLabel.textColor = titleColor
        }
    }

    lazy var corner: MicCorner = {
        let corner = MicCorner()
        corner.attachToSuperView(imageView)
        return corner
    }()
    lazy var imageView = UIImageView()
    lazy var titleLabel = UILabel()
    lazy var button: UIButton = {
        let button = UIButton()
        button.isExclusiveTouch = true
        if Display.pad {
            button.vc.setBackgroundColor(UIColor.ud.vcTokenMeetingBtnBgToolbar, for: .normal)
            button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed, for: .highlighted)
        }
        return button
    }()

    private(set) lazy var warningImageView: UIImageView = {
        let image = UIImageView(frame: .zero)
        image.contentMode = .scaleAspectFill
        image.image = BundleResources.ByteView.ToolBar.disable_icon.vc.resized(to: CGSize(width: 16, height: 16))
        image.isHidden = true
        return image
    }()

    init() {
        super.init(frame: .zero)
        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.addSubview(imageView)
        self.addSubview(titleLabel)
        self.addSubview(warningImageView)

        updateLayout()
    }

    private func updateLayout() {
        self.layer.masksToBounds = true
        switch style {
        case .phone:
            self.layer.cornerRadius = 0
            imageView.snp.remakeConstraints { make in
                make.size.equalTo(22)
                make.top.equalToSuperview().inset(3.5)
                make.centerX.equalToSuperview()
            }
            titleLabel.isHidden = false
            titleLabel.font = .systemFont(ofSize: 10)
            titleLabel.snp.remakeConstraints { make in
                make.height.equalTo(13)
                make.top.equalTo(imageView.snp.bottom).offset(2)
                make.centerX.equalToSuperview()
            }
            warningImageView.snp.remakeConstraints { (make) in
                make.size.equalTo(16)
                make.left.equalTo(self.snp.centerX)
                make.top.equalToSuperview().offset(13.0)
            }
        case .padExpand:
            self.layer.cornerRadius = 8
            imageView.snp.remakeConstraints { make in
                make.size.equalTo(PadLayout.iconSize)
                make.left.equalToSuperview().inset(PadLayout.expandPadding)
                make.top.bottom.equalToSuperview().inset(10)
            }
            titleLabel.isHidden = false
            titleLabel.font = PadLayout.titleFont
            titleLabel.snp.remakeConstraints { make in
                make.height.equalTo(PadLayout.titleHeigt)
                make.left.equalTo(imageView.snp.right).offset(PadLayout.expandSpacing)
                make.right.equalToSuperview().inset(PadLayout.expandPadding)
                make.centerY.equalToSuperview()
            }
            warningImageView.snp.remakeConstraints { (make) in
                make.size.equalTo(14)
                make.right.equalTo(imageView).offset(4)
                make.bottom.equalTo(imageView)
            }
        case .padCollapse:
            self.layer.cornerRadius = 8
            imageView.snp.remakeConstraints { make in
                make.size.equalTo(PadLayout.iconSize)
                make.left.right.equalToSuperview().inset(PadLayout.collapsePadding)
                make.top.bottom.equalToSuperview().inset(10)
            }
            titleLabel.isHidden = true
            warningImageView.snp.remakeConstraints { (make) in
                make.size.equalTo(14)
                make.right.equalTo(imageView).offset(4)
                make.bottom.equalTo(imageView)
            }
        }
    }

    func calTotalWidth(_ style: Style) -> CGFloat {
        switch style {
        case .phone:
            return 0
        case .padExpand:
            let titleWidth = PadLayout.textWidth(title ?? "")
            return PadLayout.expandPadding + PadLayout.iconSize.width + PadLayout.expandSpacing + titleWidth + PadLayout.expandPadding
        case .padCollapse:
            return PadLayout.collapsePadding + PadLayout.iconSize.width + PadLayout.collapsePadding
        }
    }
}
