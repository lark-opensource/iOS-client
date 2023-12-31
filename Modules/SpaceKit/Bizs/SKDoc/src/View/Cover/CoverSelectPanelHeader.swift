//
//  CoverSelectPanelHeader.swift
//  SKDoc
//
//  Created by lizechuang on 2021/1/27.
//

import SKCommon
import SKFoundation
import SKResource
import RxSwift
import RxRelay
import RxCocoa
import SKUIKit
import UniverseDesignIcon
import UniverseDesignColor

class CoverSelectPanelHeader: UIView {
    private lazy var randomView: CoverSelectRandomView = {
        let randomView = CoverSelectRandomView()
        randomView.isHidden = true
        randomView.layer.cornerRadius = 4.0
        return randomView
    }()

    private lazy var pickerView: SpaceMultiListPickerView = {
        let pickerView = SpaceMultiListPickerView()
        return pickerView
    }()

    private var sectionChangedRelay = PublishRelay<Int>()
    var sectionChangedSignal: Signal<Int> { sectionChangedRelay.asSignal() }
    let randomOptionSelect = PublishSubject<()>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        self.addSubview(randomView)
        self.addSubview(pickerView)
        self.setupShadow()
        self.randomView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
            make.height.equalTo(25)
        }
        self.pickerView.snp.makeConstraints { (make) in
            make.top.bottom.left.equalToSuperview()
            make.right.equalTo(randomView.snp.left).offset(-16)
        }
        self.randomView.addTarget(self, action: #selector(didClickRandomView), for: .touchUpInside)
        self.randomView.addTarget(self, action: #selector(touchDownRandomView), for: .touchDown)
        self.randomView.addTarget(self, action: #selector(touchCancelRandomView), for: .touchCancel)
        self.randomView.addTarget(self, action: #selector(touchCancelRandomView), for: .touchDragExit)
        self.randomView.setContentHuggingPriority(.required, for: .horizontal)
        self.randomView.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.pickerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        self.pickerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func setupShadow() {
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 1
        layer.ud.setShadowColor(UDColor.shadowDefaultMd)
    }

    func update(items: [SpaceMultiListPickerItem], currentIndex: Int) {
        pickerView.update(items: items, currentIndex: currentIndex)
        pickerView.clickHandler = { [weak self] index in
            self?.sectionChangedRelay.accept(index)
        }
    }

    func updateRandomViewShowStatus(_ isShow: Bool) {
        self.randomView.isHidden = !isShow
    }

    @objc
    private func didClickRandomView() {
        randomOptionSelect.onNext(())
    }

    @objc
    private func touchDownRandomView() {
        randomView.backgroundColor = UDColor.udtokenBtnTextBgNeutralHover
    }

    @objc
    private func touchCancelRandomView() {
        randomView.backgroundColor = .clear
    }
    
}

class CoverSelectRandomView: UIControl {

    private lazy var iconView: UIImageView = {
        let icon = UIImageView()
        return icon
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textCaption
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        self.iconView.image = UDIcon.driveloadOutlined.ud.withTintColor(UDColor.iconN2)
        self.titleLabel.text = BundleI18n.SKResource.CreationMobile_Docs_DocCover_Random_Tab
        self.addSubview(iconView)
        self.addSubview(titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        self.iconView.snp.makeConstraints { (make) in
            make.left.centerY.equalToSuperview()
            make.right.equalTo(titleLabel.snp.left).offset(-4)
            make.height.width.equalTo(14)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
