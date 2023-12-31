//
//  AudioActionButton.swift
//  LarkAudio
//
//  Created by kangkang on 2023/11/15.
//

import Foundation
import UniverseDesignFont

final class AudioActionButton: UIButton {
    struct AudioActionButtonConfig {
        let name: String
        let icon: UIImage
        let iconColor: UIColor
        let textColor: UIColor
        let loadingColor: UIColor
        let labelLines: Int
        let iconSideLength: CGFloat
        let spacing: CGFloat
        let labelBaseHeight: CGFloat
        let titleFont: UIFont

        init(name: String, icon: UIImage,
             iconColor: UIColor, textColor: UIColor, loadingColor: UIColor,
             spacing: CGFloat = 8, labelLines: Int = 2,
             iconSideLength: CGFloat = 24, labelBaseHeight: CGFloat = 22,
             titleFont: UIFont = UDFont.body2) {
            self.name = name
            self.icon = icon
            self.iconColor = iconColor
            self.textColor = textColor
            self.loadingColor = loadingColor
            self.spacing = spacing
            self.labelLines = labelLines
            self.iconSideLength = iconSideLength
            self.labelBaseHeight = labelBaseHeight
            self.titleFont = titleFont
        }
    }

    var tapHandler: (() -> Void)?
    private var stackView = UIStackView()
    private let config: AudioActionButtonConfig
    private let icon = UIImageView()
    private let textLabel = UILabel()
    private let loadingView = LoadingView(frame: .zero)

    private lazy var paragraphStyle: NSMutableParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = config.titleFont.figmaHeight
        paragraphStyle.maximumLineHeight = config.titleFont.figmaHeight
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center
        return paragraphStyle
    }()

    init(config: AudioActionButtonConfig) {
        self.config = config
        super.init(frame: .zero)
        setupSubviews()
    }

    private func setupSubviews() {
        // add
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = config.spacing
        self.addSubview(stackView)
        icon.isUserInteractionEnabled = false
        stackView.addArrangedSubview(icon)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = config.labelLines
        stackView.addArrangedSubview(textLabel)
        loadingView.backgroundColor = UIColor.ud.bgBodyOverlay
        loadingView.fillColor = UIColor.ud.bgBodyOverlay
        loadingView.radius = 10
        // 布局
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        icon.snp.makeConstraints { make in
            make.size.equalTo(config.iconSideLength)
        }
        textLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(config.labelBaseHeight)
        }

        let divider: CGFloat = if #available(iOS 17.0, *) {
            2
        } else {
            2 * 2
        }
        let baselineOffset = (config.titleFont.figmaHeight - config.titleFont.lineHeight) / divider
        // 赋值
        self.textLabel.attributedText = NSAttributedString(
            string: config.name,
            attributes: [
                .baselineOffset: baselineOffset,
                .font: config.titleFont,
                .paragraphStyle: paragraphStyle
            ])

        self.icon.image = config.icon
        self.setNormalColor()
        loadingView.strokeColor = config.loadingColor

        self.lu.addTapGestureRecognizer(action: #selector(tapGesture), target: self)
    }

    @objc
    private func tapGesture() {
        tapHandler?()
    }

    private func setNormalColor() {
        guard isEnabled else { return }
        textLabel.textColor = config.textColor
        icon.image = icon.image?.ud.withTintColor(config.iconColor)
    }

    private func setDisableColor() {
        guard !isEnabled else { return }
        textLabel.textColor = UIColor.ud.textDisabled
        icon.image = icon.image?.ud.withTintColor(UIColor.ud.textDisabled)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            if isEnabled {
                self.setNormalColor()
            } else {
                self.setDisableColor()
            }
        }
    }

    func loadingHandler(show: Bool) {
        if show {
            if loadingView.superview == nil {
                self.addSubview(self.loadingView)
                self.loadingView.snp.makeConstraints { make in
                    make.size.equalTo(self.config.iconSideLength)
                    make.centerX.equalToSuperview()
                    make.top.equalToSuperview()
                }
            }
        } else {
            loadingView.removeFromSuperview()
        }
    }
}
