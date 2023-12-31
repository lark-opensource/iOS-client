//
//  SubtitleSearchView.swift
//  ByteView
//
//  Created by kiri on 2020/6/15.
//

import UIKit
import RxSwift
import ByteViewTracker
import UniverseDesignIcon

class SubtitleSearchView: UIView {
    private var contentView = UIView()
    private var searchImageView = UIImageView()
    private var buttonMaskView = UIView()
    private var textField = UITextField()

    var filterBlock: ((SubtitlesFilterViewController) -> Void)?
    var clearBlock: (() -> Void)?
    private lazy var indexLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.isHidden = true
        label.text = "0/0"
        return label
    }()
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        view.isHidden = true
        return view
    }()
    private var clearButton = UIButton(type: .custom)
    private var filterButton = UIButton(type: .custom)

    private let disposeBag = DisposeBag()

    var viewModel: SubtitlesViewModel? {
        didSet {
            updateViewModel()
        }
    }

    var transctiptViewModel: TranscriptViewModel? {
        didSet {
            transctiptViewModel?.addListener(self)
            textField.attributedPlaceholder = NSAttributedString(string: I18n.View_M_Search,
                                                                 attributes: [.foregroundColor: UIColor.ud.textPlaceholder,
                                                                              .font: UIFont.systemFont(ofSize: 16)])
        }
    }

    var isFilterButtonSelected: Bool = false {
        didSet {
            updateFilterButton(isSelected: isFilterButtonSelected)
        }
    }

    var filterSelectedBackgroundColor: UIColor {
        UIColor.ud.N900.withAlphaComponent(0.05)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        configAppear()

        contentView.snp.remakeConstraints { (maker) in
            maker.height.equalTo(36)
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(16)
            maker.right.equalTo(filterButton.snp.left).offset(-8)
        }
    }

    func configAppear() {
        self.backgroundColor = UIColor.ud.bgBody

        filterButton.layer.cornerRadius = 6

        filterButton.layer.masksToBounds = true

        contentView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    private func setup() {
        configAppear()

        contentView.layer.cornerRadius = 6
        contentView.layer.masksToBounds = true

        searchImageView.contentMode = .scaleAspectFill
        searchImageView.clipsToBounds = true
        searchImageView.image = UDIcon.getIconByKey(.searchOutlined, iconColor: .ud.iconN2, size: CGSize(width: 18, height: 18))

        textField.borderStyle = .none
        textField.returnKeyType = .search
        textField.backgroundColor = .clear
        textField.textColor = UIColor.ud.textTitle
        textField.clearButtonMode = .never
        textField.contentVerticalAlignment = .center
        textField.attributedPlaceholder = NSAttributedString(string: I18n.View_G_SearchSubtitles,
                                                             attributes: [.foregroundColor: UIColor.ud.textPlaceholder,
                                                                          .font: UIFont.systemFont(ofSize: 16)])
        clearButton.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN2, size: CGSize(width: 16, height: 16)), for: .normal)
        clearButton.isHidden = true
        filterButton.setImage(UDIcon.getIconByKey(.filterOutlined, iconColor: .ud.iconN1, size: CGSize(width: 16, height: 16)), for: .normal)
        filterButton.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.05), for: .normal)
        filterButton.vc.setBackgroundColor(UIColor.ud.fillPressed.withAlphaComponent(0.12), for: .highlighted)
        buttonMaskView.isHidden = false

        self.addSubview(contentView)
        self.addSubview(filterButton)

        filterButton.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(36)
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-16)
        }

        contentView.snp.makeConstraints { (maker) in
            maker.height.equalTo(36)
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(16)
            maker.right.equalTo(filterButton.snp.left).offset(-8)
        }
        contentView.addSubview(searchImageView)
        contentView.addSubview(textField)
        contentView.addSubview(indexLabel)
        contentView.addSubview(separatorView)
        contentView.addSubview(clearButton)
        contentView.addSubview(buttonMaskView)
        searchImageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(18)
            maker.left.equalToSuperview().offset(12)
            maker.centerY.equalToSuperview()
        }
        textField.snp.makeConstraints { (maker) in
            maker.left.equalTo(searchImageView.snp.right).offset(10)
            maker.centerY.equalToSuperview()
        }
        indexLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(textField.snp.right)
            maker.centerY.equalToSuperview()
        }
        separatorView.snp.makeConstraints { (maker) in
            maker.left.equalTo(indexLabel.snp.right).offset(10)
            maker.width.equalTo(1)
            maker.height.equalTo(16)
            maker.centerY.equalTo(indexLabel)
        }
        clearButton.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(16)
            maker.centerY.equalToSuperview()
            maker.left.equalTo(separatorView.snp.right).offset(10)
            maker.right.equalToSuperview().offset(-10)
        }
        buttonMaskView.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalTo(indexLabel)
            maker.right.equalTo(clearButton)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didClickButtonMask(_:)))
        buttonMaskView.isUserInteractionEnabled = true
        buttonMaskView.addGestureRecognizer(tap)
        clearButton.addTarget(self, action: #selector(didClickClear(_:)), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(didClickFilter(_:)), for: .touchUpInside)

        bind()
    }

    func bind() {
        //监听文本框内容的改变

        textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)

        textField.rx.controlEvent([.editingDidEndOnExit])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let text = self.textField.text, !text.isEmpty {
                    self.viewModel?.startSearch(text: text)
                    self.transctiptViewModel?.startSearch(text: text)
                    self.indexLabel.isHidden = false
                    self.separatorView.isHidden = false
                    SubtitleTracksV2.trackEditingDidBegin()
                }
            }).disposed(by: rx.disposeBag)

        textField.rx.controlEvent([.editingDidBegin])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                VCTracker.post(name: .vc_meeting_subtitle_page, params: [.action_name: "search"])
            }).disposed(by: rx.disposeBag)

        textField.rx.controlEvent([.touchDown])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                SubtitleTracksV2.trackClickSearch()
            }).disposed(by: rx.disposeBag)

    }

    @objc func textFieldEditingChanged(_ textField: UITextField) {
        if textField.text?.isEmpty == true {
            self.viewModel?.clearSearchMode()
            self.transctiptViewModel?.clearSearchMode()
            self.buttonMaskView.isHidden = false
            self.clearButton.isHidden = true
            self.indexLabel.isHidden = true
            self.separatorView.isHidden = true
            self.setSearchImageHighlighted(false)
            DispatchQueue.main.async {
                self.clearBlock?()
            }
        } else {
            self.buttonMaskView.isHidden = true
            self.clearButton.isHidden = false
            self.setSearchImageHighlighted(true)
        }
    }

    // 两个条件满足之一就可以高亮：textfileld 成为第一响应者，或者输入框有文字
    private func setSearchImageHighlighted(_ isHighlighted: Bool) {
        let color = isHighlighted ? UIColor.ud.iconN3 : UIColor.ud.iconN3
        searchImageView.image = UDIcon.getIconByKey(.searchOutlined, iconColor: color, size: CGSize(width: 16, height: 16))
    }

    private func updateFilterButton(isSelected: Bool) {
        let color = isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.iconN1
        filterButton.setImage(UDIcon.getIconByKey(.filterOutlined, iconColor: color, size: CGSize(width: 16, height: 16)), for: .normal)
    }

    private func updateViewModel() {
        guard let vm = viewModel else {
            return
        }

        vm.filterObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] isSelected in
            guard let `self` = self else { return }
            self.updateFilterButton(isSelected: isSelected)
        }).disposed(by: disposeBag)

        let o1 = vm.jumpObservable.startWith(0)
        let o2 = vm.subtitleViewDatasObservable.map { _ in 0 }.startWith(0)
        Observable.combineLatest(o1, o2)
            .map { (_, _) -> String in
                guard vm.isSearchMode == true,
                      let idx = vm.indexOfSearchData,
                      let length = vm.numOfSearchData else { return "0/0" }
                return "\(idx + 1)/\(length)"
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(indexLabel.rx.text)
            .disposed(by: rx.disposeBag)

        Observable.combineLatest(o1, o2)
            .map { (_, _) -> Bool in
                guard vm.isSearchMode == true, vm.indexOfSearchData != nil, vm.numOfSearchData != nil else { return true }
                return false
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: true)
            .drive(indexLabel.rx.isHidden)
            .disposed(by: rx.disposeBag)

        Observable.combineLatest(o1, o2)
            .map { (_, _) -> Bool in
                guard vm.isSearchMode == true, vm.indexOfSearchData != nil, vm.numOfSearchData != nil else { return true }
                return false
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: true)
            .drive(separatorView.rx.isHidden)
            .disposed(by: rx.disposeBag)
    }

    @objc func didClickButtonMask(_ sender: Any?) {
        textField.becomeFirstResponder()
    }

    @objc func didClickFilter(_ sender: UIButton) {
        VCTracker.post(name: .vc_meeting_subtitle_page, params: [.action_name: "filter"])
        SubtitleTracksV2.trackClickFilter()
        endEditing(true)

        if let filterVC = self.viewModel?.filterAction(sender, text: textField.text) {
            filterBlock?(filterVC)
        }

        if let vc = transctiptViewModel?.filterAction(sender, text: textField.text) {
            filterBlock?(vc)
        }
    }

    @objc func didClickClear(_ sender: Any) {
        VCTracker.post(name: .vc_meeting_subtitle_page, params: [.action_name: "search_clear"])
        textField.text = nil
        indexLabel.text = "0/0"
        textFieldEditingChanged(textField)
    }

    func clearInput() {
        if viewModel?.isSearchMode == false || transctiptViewModel?.isSearchMode == false {
            textField.text = nil
            clearButton.isHidden = true
            indexLabel.text = "0/0"
        }
    }
}

extension SubtitleSearchView: TranscriptViewModelDelegate {

    func searchEnabledDidChanged() {
    }

    func filterModeDidChanged() {
        isFilterButtonSelected = transctiptViewModel?.isFilterMode ?? false
    }

    func searchModeDidChanged() {
        updateIndexLabel()
        clearInput()
    }

    func selectedSearchResultDidChangeTo(row: Int) {
        updateIndexLabel()
    }

    func updateIndexLabel() {
        if let model = transctiptViewModel, model.isSearchMode {
            let index = model.indexOfSearchData ?? -1
            let count = model.numOfSearchData ?? 0
            indexLabel.isHidden = false
            separatorView.isHidden = false
            indexLabel.text = "\(index + 1)/\(count)"
        } else {
            indexLabel.isHidden = true
            separatorView.isHidden = true
        }
    }
}
