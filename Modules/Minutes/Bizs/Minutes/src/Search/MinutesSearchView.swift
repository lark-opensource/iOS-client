//
//  MinutesSearchView.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/12.
//  Copyright © 2021年 wangcong. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import MinutesNetwork
import UniverseDesignColor
import UniverseDesignIcon
import LarkUIKit

protocol MinutesSearchViewDelegate: AnyObject {
    func searchViewClearSearching(_ view: MinutesSearchView)
    func searchViewExitKeywordSearching(_ view: MinutesSearchView)
    func searchViewFinishSearching(_ view: MinutesSearchView)
    func searchView(_ view: MinutesSearchView, shouldSearch text: String, type: Int, callback:(() -> Void)?)
    func searchViewPreSearching(_ view: MinutesSearchView)
    func searchViewNextSearching(_ view: MinutesSearchView)
}

protocol MinutesSearchViewDataProvider: AnyObject {
    func searchViewTotalCount(_ view: MinutesSearchView) -> Int
    func searchViewCurrentIndex(_ view: MinutesSearchView) -> Int
}

class MinutesSearchView: UIView {
    public weak var delegate: MinutesSearchViewDelegate?
    public weak var dataProvider: MinutesSearchViewDataProvider?

    var isKeywordSearch: Bool = false {
        didSet(old) {
            if isKeywordSearch != old && isKeywordSearch == false {
                self.delegate?.searchViewExitKeywordSearching(self)
            }
        }
    }
    var originSearchValue: String?

    lazy var textField: MinutesSearchTextField = {
        let tf = MinutesSearchTextField()
        tf.addTarget(self, action: #selector(textFieldChanged(textFiled:)), for: .editingChanged)
        tf.delegate = self
        tf.returnKeyType = .search
        tf.enablesReturnKeyAutomatically = true
        tf.backgroundColor = UIColor.ud.N200
        tf.attributedPlaceholder = NSAttributedString(string: BundleI18n.Minutes.MMWeb_G_SearchKeywords, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder])
        tf.addSubview(searchResultLabel)
        searchResultLabel.snp.makeConstraints { make in
            make.right.equalTo(-10)
            make.centerY.equalToSuperview()
        }
        tf.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.right.equalTo(-10)
            make.centerY.equalToSuperview()
        }
        return tf
    }()

    lazy var searchResultLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 14)
        label.isHidden = true
        return label
    }()

    lazy var indicator: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView()
        indicatorView.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
        indicatorView.isHidden = true
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                indicatorView.style = .white
            } else {
                indicatorView.style = .gray
            }
        } else {
            indicatorView.style = .gray
        }
        return indicatorView
    }()

    lazy var doneButton: UIButton = {
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle(BundleI18n.Minutes.MMWeb_G_Done, for: .normal)
        cancelButton.setTitleColor(UIColor.ud.N900, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelButton.setContentHuggingPriority(UILayoutPriority(rawValue: 1000.0), for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000.0), for: .horizontal)
        cancelButton.addTarget(self, action: #selector(finishSearching), for: .touchUpInside)
        return cancelButton
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.addArrangedSubview(textField)
        textField.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
        stackView.setCustomSpacing(16, after: textField)
        stackView.addArrangedSubview(buttonView)
        stackView.setCustomSpacing(16, after: buttonView)
        stackView.addArrangedSubview(doneButton)
        return stackView
    }()

    private lazy var buttonView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.addSubview(preButton)
        preButton.snp.makeConstraints { make in
            make.left.equalTo(6)
            make.top.bottom.equalToSuperview()
            make.size.equalTo(22)
        }
        v.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.left.equalTo(preButton.snp.right).offset(16)
            make.top.bottom.equalToSuperview()
            make.size.equalTo(22)
            make.right.equalTo(-6)
        }
        return v
    }()

    private lazy var preButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UDIcon.getIconByKey(.avSetUpOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(preSearchResult), for: .touchUpInside)
        return button
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UDIcon.getIconByKey(.avSetDownOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(nextSearchResult), for: .touchUpInside)
        return button
    }()

    var originFrame = CGRect.zero
    private let standardHeight: CGFloat = 40

    private var isKeyboardShow = false
    private var isRequestSearch = false

    var isVideo = true

    let minutes: Minutes

    var detailBottomInset: CGFloat = 0

    private lazy var tracker: MinutesTracker = {
        return MinutesTracker(minutes: minutes)
    }()

    init(frame: CGRect, minutes: Minutes) {
        self.minutes = minutes
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N300
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(5)
            make.right.equalTo(-16)
            make.height.equalTo(30)
        }

        observeKeyBoard()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func viewWillShow() {
        self.textField.becomeFirstResponder()
    }

    func observeKeyBoard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIApplication.keyboardWillHideNotification, object: nil)
    }

    @objc func keyBoardWillShow(notification: Notification) {
        isKeyboardShow = true
        isRequestSearch = false
        if let keyBoardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let y = Display.pad ? originFrame.maxY - keyBoardFrame.height - standardHeight + detailBottomInset : keyBoardFrame.minY - standardHeight
            let targetFrame = CGRect(x: originFrame.minX, y: y, width: originFrame.width, height: standardHeight)
            if isVideo {
                let keyBoardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
                UIView.animate(withDuration: keyBoardAnimationDuration, animations: {
                    self.frame = targetFrame
                })
            } else {
                UIView.animate(withDuration: 0.2, delay: 0.05, options: .curveEaseOut) {
                    self.frame = targetFrame
                } completion: { _ in
                }
                if self.isHidden {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self.isHidden = false
                    }
                }
            }
            
            let totalCount = self.dataProvider?.searchViewTotalCount(self) ?? 0
            if totalCount > 0 {
                preButton.isEnabled = true
                nextButton.isEnabled = true
                searchResultLabel.isHidden = false
            } else {
                preButton.isEnabled = false
                nextButton.isEnabled = false
                searchResultLabel.isHidden = true
            }
        }
    }

    @objc func keyBoardWillHide(notification: Notification) {
        isKeyboardShow = false
        var keyBoardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        if !isVideo { keyBoardAnimationDuration = 0.2 }
        UIView.animate(withDuration: keyBoardAnimationDuration) {
            self.frame = self.originFrame
        } completion: { _ in
            self.isRequestSearch = false
        }
        if isRequestSearch { return }
        let totalCount = self.dataProvider?.searchViewTotalCount(self) ?? 0
        if totalCount > 0 {
            preButton.isEnabled = true
            nextButton.isEnabled = true
            searchResultLabel.isHidden = false
        } else {
            preButton.isEnabled = false
            nextButton.isEnabled = false
            searchResultLabel.isHidden = true
        }
    }
}

extension MinutesSearchView {
    @objc
    func finishSearching() {
        self.textField.text = nil
        self.originSearchValue = nil
        
        self.searchResultLabel.isHidden = true
        self.textField.resignFirstResponder()
        self.delegate?.searchViewFinishSearching(self)
    }

    func clearSearching() {
        self.textField.text = ""
        self.originSearchValue = ""
        
        self.searchResultLabel.isHidden = true
        self.delegate?.searchViewFinishSearching(self)
    }

    @objc
    func textFieldChanged(textFiled: UITextField) {
        if isKeywordSearch {
            isKeywordSearch = false
            self.delegate?.searchViewExitKeywordSearching(self)
        }

        if textFiled.text?.isEmpty == true {
            delegate?.searchViewClearSearching(self)
        } else if let searchText = textFiled.text, searchText.isEmpty == false {
            isRequestSearch = true
            //delegate?.searchViewClearSearching(self)
            self.doSearch(text: searchText, type: 1)
        }
    }
}

extension MinutesSearchView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textField.resignFirstResponder()
        return true
        
        isRequestSearch = true
        delegate?.searchViewClearSearching(self)
        self.textField.resignFirstResponder()
        // 使用原始值，避免引号影响
        if let text = originSearchValue {
            if !text.isEmpty {
                self.doSearch(text: text, type: 1)
                return true
            }
        }
        return false
    }
}

extension MinutesSearchView {
    @objc
    func preSearchResult() {
        self.delegate?.searchViewPreSearching(self)
        refreshResultLabel()
    }

    @objc
    func nextSearchResult() {
        self.delegate?.searchViewNextSearching(self)
        refreshResultLabel()
    }

    func refreshResultLabel() {
        let totalCount = self.dataProvider?.searchViewTotalCount(self) ?? 0
        let currentIndex = self.dataProvider?.searchViewCurrentIndex(self) ?? 0
        if totalCount > 0 {
            searchResultLabel.text = "\(currentIndex)/\(totalCount)"
        } else {
            searchResultLabel.text = "\(totalCount)"
        }
    }

    func refreshSearchView() {

        let totalCount = self.dataProvider?.searchViewTotalCount(self) ?? 0
        if totalCount > 0 {
            preButton.isEnabled = true
            nextButton.isEnabled = true
            self.searchResultLabel.isHidden = false
        } else {
            preButton.isEnabled = false
            nextButton.isEnabled = false
            self.searchResultLabel.isHidden = true
        }
        UIView.animate(withDuration: 0.2) {
            self.stackView.layoutIfNeeded()
        }
        refreshResultLabel()
    }

    func keyWordSearch(text: String) {
        isRequestSearch = true
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
        let newText = "\"" + text + "\""
        self.textField.text = newText
        self.originSearchValue = text
        
        self.doSearch(text: text, type: 1)
    }

    func doSearch(text: String, type: Int) {
        searchResultLabel.isHidden = true
        indicator.isHidden = false
        indicator.startAnimating()
        self.delegate?.searchView(self, shouldSearch: text, type: type, callback: { [weak self] in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.indicator.isHidden = true
                self.indicator.stopAnimating()
                self.refreshSearchView()
                let total = self.dataProvider?.searchViewTotalCount(self) ?? 0
                if total <= 0 {
                    self.tracker.tracker(name: .popupView, params: ["popup_name": "no_search_content"])
                }
            }
        })
    }

}

// MARK: -
class MinutesSearchTextField: UITextField {
    
    lazy var left: UIImageView = {
        let iv = UIImageView(image: UDIcon.getIconByKey(.searchOutlineOutlined, iconColor: UIColor.ud.textPlaceholder, size: CGSize(width: 16, height: 16)))
        iv.contentMode = .center
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBodyOverlay
        layer.cornerRadius = 6
        leftView = left
        leftViewMode = .always
        rightView = nil
        rightViewMode = .whileEditing
        textColor = UIColor.ud.textTitle
        font = UIFont.systemFont(ofSize: 14)
        attributedPlaceholder = NSAttributedString(string: BundleI18n.Minutes.MMWeb_G_Search, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 0, y: 0, width: 36, height: bounds.height)
    }
}
