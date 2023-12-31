//
//  MinutesMoreViewControllerV2.swift
//  Minutes
//
//  Created by yangyao on 2023/2/16.
//

import Foundation
import LarkUIKit
import UniverseDesignIcon
import EENavigator
import LarkContainer

enum UI {
    static let headerViewHeight: CGFloat = 59
    static let cellHeight: CGFloat = 52
    static let maxCellCountForExpend: Int = 7
    static let dismissThresholdOffset: CGFloat = 120
    static let dismissButtonWidth: CGFloat = 24
    static let dismissButtonHeight: CGFloat = 24
    static let dismissButtonRight: CGFloat = 16
    static let displayFullScreenThreshold = 7
}


final public class SelectTargetLanguageTranslateCenter: NSObject, UITableViewDataSource, UITableViewDelegate {
    var dataSource: [MinutesTranslationLanguageModel] = []
    var cancelBlock: (() -> Void)?
    var selectBlock: ((MinutesTranslationLanguageModel) -> Void)?
    
    init(items: [MinutesTranslationLanguageModel]) {
        self.dataSource = items
    }
        
    weak var currentDrawer: MinutesSelectiveDrawerController?
    public func showSelectDrawer(from: UIViewController, resolver: UserResolver, isRegular: Bool = false) {
        let headerView: SelectLanguageHeaderView = SelectLanguageHeaderView()
        headerView.didTapBackButton = { [weak self] in
            guard let self = self else { return }
            self.dismissCurrentDrawer()
        }

        // disable-lint: magic number
        var config: DrawerConfig = DrawerConfig(backgroundColor: UIColor.ud.bgMask,
                                 cornerRadius: 12,
                                 thresholdOffset: UI.dismissThresholdOffset,
                                 maxContentHeight: UIScreen.main.bounds.height - 160,
                                 initialShowHeight: (UIScreen.main.bounds.height / 2.0),
                                 cellType: MinutesChooseTranslationLanguageCell.self,
                                 tableViewDataSource: self,
                                 tableViewDelegate: self,
                                 headerView: headerView,
                                 headerViewHeight: UI.headerViewHeight,
                                 isRegular: isRegular)
        // enable-lint: magic number

        let drawer = MinutesSelectiveDrawerController(config: config, cancelBlock: { [weak self] in
            guard let self = self else { return }
            
            self.cancelBlock?()
            self.dismissCurrentDrawer()
        })
        currentDrawer = drawer
        if isRegular {
            drawer.transitioningDelegate = nil
            drawer.modalPresentationStyle = .formSheet
        }
        resolver.navigator.present(drawer, from: from)
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesChooseTranslationLanguageCell.description(), for: indexPath) as? MinutesChooseTranslationLanguageCell else {
            return UITableViewCell()
        }
        cell.titleLabel.text = dataSource[indexPath.row].language
        cell.titleLabel.textColor =
            dataSource[indexPath.row].isHighlighted ?
            UIColor.ud.primaryContentDefault :
            UIColor.ud.textTitle
        cell.separatorInset = UIEdgeInsets(top: 0, left: indexPath.row == dataSource.count - 1 ? 0 : 16, bottom: 0, right: indexPath.row == dataSource.count - 1 ? .greatestFiniteMagnitude : 0)
        return cell
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UI.cellHeight
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let lang = dataSource[indexPath.row]
        selectBlock?(lang)
        dismissCurrentDrawer()
    }
}

private extension SelectTargetLanguageTranslateCenter {
    func dismissCurrentDrawer() {
        currentDrawer?.dismiss(animated: true, completion: {
        })
    }
}

final public class SelectLanguageHeaderView: UIView {
    var didTapBackButton: (() -> Void)?

    private lazy var headerTitle: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Minutes.MMWeb_G_SelectLanguage
        label.font = .systemFont(ofSize: 17)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        let image = UDIcon.getIconByKey(.closeSmallOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24))

        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault.withAlphaComponent(0.15)
        return view
    }()

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear
        addSubview(headerTitle)
        headerTitle.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(18)
            make.centerY.equalToSuperview()
        }

        addSubview(divider)
        divider.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    @objc
    private func backButtonTapped() {
        didTapBackButton?()
        didTapBackButton = nil
    }
}
