//
//  SheetFilterHelpView.swift
//  SpaceKit
//
//  Created by Webster on 2019/10/14.
//

import Foundation
import LarkUIKit
import SKCommon
import SKBrowser
import SKResource
import RxSwift
import UniverseDesignCheckBox
import UniverseDesignIcon

protocol SheetFilterSearchViewDelegate: AnyObject {
    func textFieldWillBeginEdit(_ view: SheetFilterSearchView)
    func textFieldWillEndEdit(_ view: SheetFilterSearchView)
    func textFieldChangeText(_ text: String, view: SheetFilterSearchView)
}

class SheetFilterSearchView: UIView {
    weak var delegate: SheetFilterSearchViewDelegate?
    lazy var textField: LarkUIKit.SearchUITextField = {
        let view = LarkUIKit.SearchUITextField()
        view.backgroundColor = UIColor.ud.N100
        view.textColor = UIColor.ud.N900
        view.font = UIFont.systemFont(ofSize: 14)
        view.returnKeyType = .done
        view.addTarget(self, action: #selector(searchEditingExitByTappingReturnKey), for: .editingDidEndOnExit)
        view.addTarget(self, action: #selector(searchEditingBegin), for: .editingDidBegin)
        view.addTarget(self, action: #selector(textFieldTextChange), for: .editingChanged)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.clipsToBounds = true
        addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(36)
            make.centerY.equalToSuperview()
        }
    }

    func cleanInput() {
        textField.text = ""
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func searchEditingBegin() {
        delegate?.textFieldWillBeginEdit(self)
    }

    @objc
    func searchEditingExitByTappingReturnKey() {
        delegate?.textFieldWillEndEdit(self)
    }

    @objc
    func textFieldTextChange() {
        let realTimeTxt = textField.text ?? ""
        delegate?.textFieldChangeText(realTimeTxt, view: self)
    }
}

protocol SheetFilterSelectAllViewDelegate: AnyObject {
    func hasAllSelect(selected: Bool, view: SheetFilterSelectAllView)
    func requestFocusSearch(view: SheetFilterSelectAllView)
}

class SheetFilterSelectAllView: UIView {
    weak var delegate: SheetFilterSelectAllViewDelegate?

    private var isItemSelected: Bool = false {
        didSet {
            detailView.isItemSelected = isItemSelected
        }
    }

    lazy var detailView = SheetFilterNormalValueCell(frame: .zero)

    lazy var searchButton: UIButton = {
        let button = UIButton(frame: .zero)
        let image = UDIcon.getIconByKey(.searchOutlined, size: CGSize(width: 20, height: 20))
        button.setImage(image.ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        button.setImage(image.ud.withTintColor(UIColor.ud.iconDisabled), for: .disabled)
        button.addTarget(self, action: #selector(didClickSearchButton), for: .touchUpInside)
        button.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        //detail view
        addSubview(detailView)
        detailView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(didReceiveTapAtView))
        addGestureRecognizer(tap)
        //search button
        addSubview(searchButton)
        searchButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func didReceiveTapAtView() {
        reverseModel()
        delegate?.hasAllSelect(selected: isItemSelected, view: self)
    }

    @objc
    func didClickSearchButton() {
        delegate?.requestFocusSearch(view: self)
    }

    func configure(by info: SheetFilterInfo.FilterValueItem) {
        isItemSelected = info.selected
        let isEmpty = info.count == 0
        searchButton.isEnabled = !isEmpty
        let textColor = isEmpty ? UIColor.ud.N400: UIColor.ud.N900
        detailView.configure(by: info)
        detailView.titleLabel.textColor = textColor
        detailView.countLabel.textColor = textColor
    }

    private func reverseModel() {
        guard var model = detailView.model else { return }
        let nextStatus = !isItemSelected
        model.selected = nextStatus
        model.value = BundleI18n.SKResource.Doc_Sheet_SelectAll
        isItemSelected = nextStatus
        configure(by: model)
    }
}

class SheetFilterNormalValueCell: UICollectionViewCell {

    var model: SheetFilterInfo.FilterValueItem?

    lazy var checkBox: UDCheckBox = {
        let config = UDCheckBoxUIConfig(style: .circle)
        let checkbox = UDCheckBox(boxType: .multiple, config: config, tapCallBack: { (_) in })
        checkbox.isUserInteractionEnabled = false
        return checkbox
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.text = "(0)"
        label.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        return label
    }()

    var isItemSelected: Bool = false {
        didSet {
            checkBox.isSelected = isItemSelected
        }
    }
    
    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        addSubview(checkBox)
        addSubview(titleLabel)
        addSubview(countLabel)
        
        checkBox.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(48)
            make.centerY.equalToSuperview()
        }

        countLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right).offset(2)
            make.right.lessThanOrEqualToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        //重置背景色，避免addHover残留
        self.backgroundColor = nil
    }

    func configure(by info: SheetFilterInfo.FilterValueItem) {
        model = info
        titleLabel.text = info.value
        countLabel.text = "(\(info.count))"
        isItemSelected = info.selected
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
