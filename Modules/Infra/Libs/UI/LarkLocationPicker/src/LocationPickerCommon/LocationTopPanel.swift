//
//  LarkLocationTopPanel.swift
//  LarkRxLocationPicker
//
//  Created by Fangzhou Liu on 2019/7/9.
//  日历，地点选择页面顶部panel
//

import Foundation
import UIKit
import SnapKit
import MapKit
import LarkUIKit
import RxSwift
import RxCocoa
import RxDataSources
import UniverseDesignToast
import Reachability
import LKCommonsLogging

public final class LocationTopPanel: UIView {
    private static let logger = Logger.log(LocationTopPanel.self, category: "LocationPicker.LocationTopPanel")
    private var type: MapType = .amap
    private let disposeBag = DisposeBag()
    /* UI component */
    private let searchTextField = ContentTextField(inset: 16)
    private let separatorLine = UIView()
    private let searchTableView = UITableView()
    private let searchTipTableView = UITableView()
    /* 没有结果 */
    private let emptyImageIcon = NoSearchResultIconView(frame: .zero)
    /* 没有更多结果 */
    private let noMoreResultIcon = UILabel(frame: .zero)
    /* 顶部加载 */
    private var loadingHeader = LoadingProgressView(frame: .zero)
    /* 底部加载 */
    private var loadingFooter = LoadingProgressView(frame: .zero)
    private var searchTableViewHeightConstraint: Constraint?
    private var searchTipTableViewHeightConstraint: Constraint?
    private let viewModel: LocationTopPanelViewModel
    private var dataSource: [UILocationData] = []
    /* 用户当前位置 */
    private var userCoordinate: CLLocationCoordinate2D?
    private var allowCustomLocation = true
    /* 防止多次刷新 */
    private var isRefreshing: Bool = false
    /* 点击搜索框回调 */
    var locationSearchTappedBlock: (() -> Void)?
    /* 选中地点的回调 */
    var locationPanelDidSelectLocationBlock: ((UILocationData) -> Void)?

    public init(location: String, allowCustomLocation: Bool, useWGS84: Bool = false) {
        viewModel = LocationTopPanelViewModel(allowCustomLocation: allowCustomLocation)
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.clear
        self.allowCustomLocation = allowCustomLocation

        addSubview(searchTextField)
        addSubview(separatorLine)
        addSubview(searchTableView)
        addSubview(searchTipTableView)

        searchTextFieldSetup(defaultString: location)
        searchTextField.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(52)
        }
        searchTextField.delegate = self

        separatorLine.backgroundColor = UIColor.ud.N300
        separatorLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.top.equalTo(searchTextField.snp.bottom)
        }

        initLoadingHeader()

        searchTableView.delegate = self
        searchTableView.backgroundColor = UIColor.ud.N00
        searchTableView.keyboardDismissMode = .onDrag
        searchTableView.separatorStyle = .none
        searchTableView.register(LarkLocationCell.self, forCellReuseIdentifier: LarkLocationPickerUtils.locationCellID)
        searchTableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(separatorLine.snp.bottom)
            searchTableViewHeightConstraint = make.height.equalTo(0).constraint
        }

        searchTipTableView.delegate = self
        searchTipTableView.backgroundColor = UIColor.ud.N00
        searchTipTableView.keyboardDismissMode = .onDrag
        searchTipTableView.separatorStyle = .none
        searchTipTableView.register(LarkLocationCell.self, forCellReuseIdentifier: LarkLocationPickerUtils.locationCellID)
        searchTipTableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(separatorLine.snp.bottom)
            searchTipTableViewHeightConstraint = make.height.equalTo(0).constraint
        }

        initLoadingFooter()

        addSubview(emptyImageIcon)
        emptyImageIcon.snp.makeConstraints { (make) in
            make.top.equalTo(separatorLine.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(searchTableView.snp.bottom)
        }
        viewModel.setCoordinateSystem(useWGS84: useWGS84)
        bindToViewModel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let resultView = super.hitTest(point, with: event)
        if resultView === self {
            return nil
        }
        return resultView
    }

    deinit {
        #if DEBUG
        print("LocationTopPanel deinit")
        #endif
    }

    private func searchTextFieldSetup(defaultString: String) {
        let attributedString = NSMutableAttributedString(
            string: BundleI18n.LarkLocationPicker.Lark_Chat_MapsSearchInputLocation,
            attributes: [.kern: 0.0])
        attributedString.addAttribute(
            .foregroundColor,
            value: UIColor.ud.N500,
            range: NSRange(location: 0, length: BundleI18n.LarkLocationPicker.Lark_Chat_MapsSearchInputLocation.count)
        )
        searchTextField.backgroundColor = UIColor.ud.bgBody
        searchTextField.text = defaultString
        searchTextField.attributedPlaceholder = attributedString
        searchTextField.textColor = UIColor.ud.N900
        searchTextField.font = UIFont.systemFont(ofSize: 22)
        searchTextField.tintColor = UIColor.ud.colorfulBlue
        searchTextField.clearButtonMode = .never
        searchTextField.returnKeyType = .done
        searchTextField.addSearchIcon()
        searchTextField.addClearIcon()
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
    }

    @objc
    private func searchTextChanged() {
        if searchTextField.markedTextRange == nil {
            self.viewModel.reset()
            self.loadingHeader.showLoadingProgressLayer()
            self.viewModel.matchInputText(center: self.userCoordinate ?? CLLocationCoordinate2D(), text: searchTextField.text ?? "")
        }
    }

    private func initLoadingHeader() {
        addSubview(loadingHeader)
        loadingHeader.snp.makeConstraints { (make) in
            make.top.equalTo(separatorLine.snp.bottom)
            make.centerX.equalToSuperview()
        }
    }

    private func initLoadingFooter() {
        let view = UIView(
            frame: CGRect(x: 0, y: 0, width: 0, height: LarkLocationPickerUtils.footerHeight)
        )
        view.addSubview(loadingFooter)
        view.addSubview(noMoreResultIcon)
        loadingFooter.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
        }
        noMoreResultIcon.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        noMoreResultIcon.text = BundleI18n.LarkLocationPicker.Lark_Legacy_SearchNoMoreResult
        noMoreResultIcon.textColor = UIColor.ud.N500
        noMoreResultIcon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        searchTableView.tableFooterView = view
    }

    private func bindToViewModel() {
        /* 开始编辑 */
        self.searchTextField.rx.controlEvent(.editingDidBegin).asObservable()
            .subscribe(onNext: { [weak self] _ in
                guard let frameHeight = self?.frame.height, let textFieldHeight = self?.searchTextField.frame.height else {
                    return
                }
                self?.searchTableViewHeightConstraint?.update(offset: frameHeight - textFieldHeight)
                self?.searchTipTableViewHeightConstraint?.update(offset: frameHeight - textFieldHeight)
                self?.searchTableView.contentOffset = CGPoint.zero
                self?.locationSearchTappedBlock?()
            })
            .disposed(by: disposeBag)

        viewModel.state.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.updateUI(state: state)
            }, onError: { (error) in
                print(String(describing: error))
            }).disposed(by: disposeBag)

        /* 搜索提示结果变化后更新列表 */
        viewModel.searchInputTipResult
            .bind(to: searchTipTableView.rx.items) { [weak self] (tableView, _, location) in
                let cell = tableView.dequeueReusableCell(withIdentifier: LarkLocationPickerUtils.locationCellID)
                if let cell = cell as? LarkLocationCell, let `self` = self {
                    cell.setHighLightContent(location: location.0, distance: LarkLocationPickerUtils.calculateDistance(
                        from: self.userCoordinate,
                        to: location.0.location), keyword: self.searchTextField.text ?? "")
                    return cell
                }
                return LarkLocationCell()
            }.disposed(by: disposeBag)

        /* 搜索结果变化后更新列表 */
        viewModel.searchResult
            .bind(to: searchTableView.rx.items) { [weak self] (tableView, _, location) in
                let cell = tableView.dequeueReusableCell(withIdentifier: LarkLocationPickerUtils.locationCellID)
                if let cell = cell as? LarkLocationCell, let `self` = self {
                    cell.setContent(location: location, distance: LarkLocationPickerUtils.calculateDistance(
                        from: self.userCoordinate,
                        to: location.location)
                    )
                    return cell
                }
                return LarkLocationCell()
            }.disposed(by: disposeBag)

        /*  绑定点击事件 */
        searchTableView.rx
            .itemSelected
            .map { [weak self] indexPath in
                return (indexPath, self?.viewModel.searchResultDataSource[indexPath.row])
            }
            .subscribe(onNext: { [weak self] (_, model) in
                guard let model = model, let `self` = self else {
                    return
                }
                self.hideFromSuperview()
                self.searchTextField.resignFirstResponder()
                self.locationPanelDidSelectLocationBlock?(model)
            }).disposed(by: disposeBag)

        searchTipTableView.rx
            .itemSelected
            .map { [weak self] indexPath in
                return (indexPath, self?.viewModel.searchInputTipDataSource[indexPath.row])
            }
            .subscribe(onNext: { [weak self] (_, model) in
                guard let model = model, let `self` = self else {
                    return
                }
                // 如果选择的内容不为POI信息，则进行关键词搜索
                if !model.1 {
                    // 只隐藏搜索提示列表
                    Self.logger.info("Again Search Not POI Input Tip")
                    self.searchTipTableViewHeightConstraint?.update(inset: 0)
                    self.viewModel.reset()
                    self.searchTextField.text = model.0.name
                    self.viewModel.matchInputText(center: self.userCoordinate ?? CLLocationCoordinate2D(), text: model.0.name)
                } else {
                    // 直接在地图上显示，此时两个列表都应该隐藏
                    Self.logger.info("Show Input Tip Or POI For Map")
                    self.hideFromSuperview()
                    self.searchTextField.resignFirstResponder()
                    self.locationPanelDidSelectLocationBlock?(model.0)
                }
                self.viewModel.clearInputTipResult()
            }).disposed(by: disposeBag)

    }

    /// 根据状态刷新UI
    ///
    /// - Parameter state: 当前view model的状态
    private func updateUI(state: StateWrapper) {
        switch state.state {
        case .initial:
            emptyImageIcon.isHidden = true
            noMoreResultIcon.isHidden = true
            loadingHeader.hideLoadingPorgressLayer()
            footerEndRefreshing()
        case .hint:
            emptyImageIcon.isHidden = true
            noMoreResultIcon.isHidden = true
            loadingHeader.showLoadingProgressLayer()
        case .search:
            searchTipTableViewHeightConstraint?.update(inset: 0)
            emptyImageIcon.isHidden = true
            noMoreResultIcon.isHidden = true
            loadingHeader.showLoadingProgressLayer()
        case .result, .hintResult:
            emptyImageIcon.isHidden = true
            noMoreResultIcon.isHidden = true
            loadingHeader.hideLoadingPorgressLayer()
            footerEndRefreshing()
        case .resultMore:
            emptyImageIcon.isHidden = true
            noMoreResultIcon.isHidden = true
            footerStartRefreshing()
        case .empty:
            if state.isFirstPage {
                emptyImageIcon.isHidden = false
                noMoreResultIcon.isHidden = true
            } else {
                emptyImageIcon.isHidden = true
                noMoreResultIcon.isHidden = false
            }
            loadingHeader.hideLoadingPorgressLayer()
            footerEndRefreshing()
        case .error:
            var toast: String = BundleI18n.LarkLocationPicker.Lark_Core_MapServicesErrorMessage_UnableToSearchRetry
            let reach = Reachability()
            if reach?.connection == .none {
                // network problem
                toast = BundleI18n.LarkLocationPicker.Lark_Core_MapServicesErrorMessage_CheckDeviceLocationServiceRetry
            }
            UDToast.showFailure(with: toast, on: self)
            if state.isFirstPage {
                emptyImageIcon.isHidden = false
                noMoreResultIcon.isHidden = true
            } else {
                emptyImageIcon.isHidden = true
                noMoreResultIcon.isHidden = false
            }
            loadingHeader.hideLoadingPorgressLayer()
            footerEndRefreshing()
        }
    }

    private func footerStartRefreshing() {
        isRefreshing = true
        loadingFooter.showLoadingProgressLayer()
    }

    private func footerEndRefreshing() {
        isRefreshing = false
        loadingFooter.hideLoadingPorgressLayer()
    }

    public func hideFromSuperview() {
        searchTextField.clearTextField()
        searchTextField.endEditing(true)
        viewModel.reset()
        searchTipTableViewHeightConstraint?.update(offset: 0)
        searchTableViewHeightConstraint?.update(offset: 0)
    }

    public func updateMapType(_ type: MapType) {
        self.viewModel.updateMapType(type)
    }

    public func updateUserLocation(_ coordinate: CLLocationCoordinate2D) {
        userCoordinate = coordinate
    }
}

extension LocationTopPanel: UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return LarkLocationPickerUtils.cellHeight
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if scrollView.isDragging {
            return
        }
        // 当没有更多结果时，即使拉到最后也不刷新
        if distanceFromBottom < height && !isRefreshing && noMoreResultIcon.isHidden {
            viewModel.loadMoreSearchResult(center: self.userCoordinate ?? CLLocationCoordinate2D())
        }
    }
}

extension LocationTopPanel: UITextFieldDelegate {
    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        viewModel.reset()
        return true
    }
}

private final class ContentTextField: BaseTextField {
    var contentTextMaxLength = 400
    init(inset: CGFloat) {
        self.inset = inset
        super.init(frame: .zero)
        self.addTarget(self, action: #selector(textChanged(textField:)), for: .editingChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func textChanged(textField: UITextField) {
        if let filteredText = textField.filteredTextWithMaxLength(
            maxLength: self.contentTextMaxLength,
            text: textField.text ?? "") {
            textField.text = filteredText
        }
    }

    var inset: CGFloat = 10

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        if self.shouldShowOriginalInsets() {
            return super.textRect(forBounds: bounds)
        }
        return bounds.insetBy(dx: inset, dy: 0)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        if self.shouldShowOriginalInsets() {
            return super.editingRect(forBounds: bounds)
        }
        return bounds.insetBy(dx: inset, dy: 0)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        if self.shouldShowOriginalInsets() {
            return super.placeholderRect(forBounds: bounds)
        }
        return bounds.insetBy(dx: inset, dy: 0)
    }

    private func shouldShowOriginalInsets() -> Bool {
        return self.leftView != nil || self.rightView != nil || self.inset == 0
    }
}

private extension UITextField {
    func addSearchIcon() {
        let wrapperView = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 52))
        let iconView = UIImageView(frame: CGRect(x: 12, y: 14, width: 24, height: 24))
        iconView.image = BundleResources.LarkLocationPicker.search
        wrapperView.addSubview(iconView)
        wrapperView.contentMode = .center
        self.leftView = wrapperView
        self.leftViewMode = .always
        self.leftView?.systemLayoutSizeFitting(CGSize(width: 48, height: 52))
    }

    func addClearIcon() {
        let wrapperView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 52))
        let clearButton = UIButton(frame: CGRect(x: 16, y: 18, width: 16, height: 16))
        clearButton.setImage(BundleResources.LarkLocationPicker.search_clear, for: .normal)
        wrapperView.addSubview(clearButton)
        clearButton.addTarget(self, action: #selector(clearButtonClicked), for: .touchUpInside)
        self.rightView = wrapperView
        self.rightViewMode = .whileEditing
        self.rightView?.systemLayoutSizeFitting(CGSize(width: 44, height: 52))
    }

    func clearTextField() {
        self.text = ""
    }

    @objc
    private func clearButtonClicked() {
        clearTextField()
        _ = self.delegate?.textFieldShouldClear?(self)
    }
}

private extension UITextInput {
    func filteredTextWithMaxLength(maxLength: Int, text: String) -> String? {
        let toBeString = text as NSString
        if let selectedRange = self.markedTextRange, self.position(from: selectedRange.start, offset: 0) != nil {
            return nil
        }
        if toBeString.length <= maxLength {
            return nil
        }
        let range = toBeString.rangeOfComposedCharacterSequence(at: maxLength)
        if range.length == 1 {// 普通字符
            return toBeString.substring(to: maxLength) as String
        } else {
            let desRange = toBeString.rangeOfComposedCharacterSequences(for: NSRange(location: 0, length: maxLength))
            return toBeString.substring(with: desRange) as String
        }
    }
}
