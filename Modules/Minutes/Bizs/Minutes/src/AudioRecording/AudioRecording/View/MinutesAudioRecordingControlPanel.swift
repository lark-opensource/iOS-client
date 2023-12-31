//
//  MinutesAudioRecordingControlPanel.swift
//  Minutes
//
//  Created by lvdaqian on 2021/3/11.
//

import UIKit
import LarkUIKit
import LarkLocalizations
import MinutesFoundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignShadow

class MinutesAudioRecordingControlPanel: UIView {
    lazy var waveContainer: MinutesAudioWaveContainer = {
        let view = MinutesAudioWaveContainer(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 0))
        return view
    }()

    lazy var recordTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont(name: "DINAlternate-Bold", size: 24) ?? .systemFont(ofSize: 24)
        return label
    }()

    lazy var languageButton: MinutesChooseLanguageButton = {
        let button = MinutesChooseLanguageButton()
        button.leftImageView.image = BundleResources.Minutes.minutes_speak_language
        button.addTarget(self, action: #selector(selectLanguage), for: .touchUpInside)
        button.rightImageView.transform = button.rightImageView.transform.rotated(by: CGFloat.pi)
        return button
    }()

    lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.shareOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 24, height: 24)), for: .normal)
        button.backgroundColor = UIColor.ud.N100
        button.layer.cornerRadius = 26
        button.addTarget(self, action: #selector(shareAction), for: .touchUpInside)
        button.isHidden = Display.pad
        return button
    }()

    private lazy var translationButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.translateOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 24, height: 24)), for: .normal)
        button.backgroundColor = UIColor.ud.N100
        button.layer.cornerRadius = 26
        button.addTarget(self, action: #selector(translationAction), for: .touchUpInside)
        button.isHidden = Display.pad
        return button
    }()

    private lazy var buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.isHidden = Display.pad
        stack.addArrangedSubview(shareButton)
        shareButton.snp.makeConstraints { make in
            make.width.height.equalTo(52)
        }
        stack.setCustomSpacing(44, after: shareButton)
        stack.addArrangedSubview(translationButton)
        translationButton.snp.makeConstraints { make in
            make.width.height.equalTo(52)
        }
        return stack
    }()

    lazy var pauseContinueButton: MinutesRecordPauseContinueButton = {
        let button = MinutesRecordPauseContinueButton()
        button.pressCallback = { [weak self] in
            guard let self = self else { return }
            self.pausingContinueRecordBlock?()
        }
        return button
    }()

    private lazy var stopRecordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(BundleI18n.Minutes.MMWeb_G_DoneClick, for: .normal)
        button.setTitleColor(UIColor.ud.functionInfoContentDefault, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(onBtnStopRecord), for: .touchUpInside)
        return button
    }()

    var isPausing: Bool = false {
        didSet {
            pauseContinueButton.isPausing = isPausing
            if isPausing {
                waveContainer.stopWave()
            } else {
                waveContainer.startWave()
            }
        }
    }

    var pausingContinueRecordBlock: (() -> Void)?
    var stopRecordBlock: (() -> Void)?
    var selectLanguageBlock: ((CGPoint) -> Void)?
    var shareBlock: (() -> Void)?
    var translationBlock: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(waveContainer)
        addSubview(recordTimeLabel)
        addSubview(buttonStack)
        addSubview(languageButton)
        addSubview(pauseContinueButton)
        addSubview(stopRecordButton)

        waveContainer.snp.makeConstraints { (maker) in
            maker.left.top.right.equalToSuperview()
            maker.height.equalTo(76)
        }
        languageButton.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.right.lessThanOrEqualTo(pauseContinueButton.snp.left).offset(-3)
            maker.centerY.equalTo(pauseContinueButton)
        }
        pauseContinueButton.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalToSuperview().offset(-44)
        }
        stopRecordButton.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-24)
            maker.centerY.equalTo(pauseContinueButton)
            maker.height.equalTo(48)
            maker.width.lessThanOrEqualTo(100)
        }
        buttonStack.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(pauseContinueButton.snp.top).offset(-24)
        }

        recordTimeLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(buttonStack.snp.top).offset(-20)
            maker.top.equalTo(waveContainer.snp.bottom).offset(12)
        }
        self.layer.ud.setShadow(type: .s1Up)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var maskPath: UIBezierPath?
    override func layoutSubviews() {
        super.layoutSubviews()

        if maskPath == nil {
            let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 16, height: 16))
            self.maskPath = maskPath
            let maskLayer = CAShapeLayer()
            layer.insertSublayer(maskLayer, at: 0)
            maskLayer.ud.setFillColor(UIColor.ud.bgBody)
            maskLayer.path = maskPath.cgPath
        }
    }

    func loadWave() {
        waveContainer.loadWave()
    }

    @objc func selectLanguage() {
        let point = convert(CGPoint(x: languageButton.frame.minX, y: languageButton.frame.minY), to: nil)
        selectLanguageBlock?(point)
    }

    @objc func onBtnStopRecord() {
        waveContainer.stopWave()
        waveContainer.clearData()
        stopRecordBlock?()
    }

    func rotateArrow() {
        languageButton.rightImageView.transform = languageButton.rightImageView.transform.rotated(by: CGFloat.pi)
    }

    @objc func shareAction() {
        shareBlock?()
    }

    @objc func translationAction() {
        translationBlock?()
    }

    func updateTranslationButton(isTranslation: Bool) {
        let img = isTranslation ? UIImage.dynamicIcon(.iconTranslateCancelThin, size: CGSize(width: 24, height: 24), color: UIColor.ud.iconN2) : UIImage.dynamicIcon(.iconTranslateOutlined, size: CGSize(width: 24, height: 24), color: UIColor.ud.iconN2)
        
        translationButton.setImage(img, for: .normal)
    }
}
