//
//  RecordLayoutSettingViewController.swift
//  ByteView
//
//  Created by helijian on 2022/11/10.
//

import UIKit
import UniverseDesignCheckBox
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI

protocol RecordLayoutItemClickDelegate: AnyObject {
    func didClickItem()
}

struct RecordLayoutItem {
    var isSelected: Bool
    var layoutType: ViewUserSetting.RecordLayoutType
    var action: (() -> Void)?
}

final class RecordLayoutItemView: UIView {
    enum Layout {
        static let checkBoxLeft = CGFloat(16)
        static let checkBoxSize = CGSize(width: 16, height: 16)
        static let checkBoxRightToLayout = CGFloat(12)
        static let layoutRightToText = CGFloat(12)
        static let titleFont = CGFloat(14)
        static let detailedFont = CGFloat(12)
        static let imageSize = CGSize(width: 84, height: 60)
    }

    private let layoutImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: Layout.titleFont)
        return label
    }()

    private let detailedLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: Layout.detailedFont)
        return label
    }()

    private let labelContainerView: UIView = UIView()
    private let checkBoxView = UDCheckBox()
    weak var delegate: RecordLayoutItemClickDelegate?
    var action: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupSubviews()
        checkBoxView.isUserInteractionEnabled = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(clickItem))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let preferredMaxLayoutWidth = self.frame.width - 156
        titleLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        detailedLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth
    }

    private func setupSubviews() {
        addSubview(layoutImage)
        layoutImage.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.size.equalTo(Layout.imageSize)
            maker.bottom.lessThanOrEqualToSuperview()
        }

        addSubview(checkBoxView)
        checkBoxView.isSelected = false
        checkBoxView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().inset(Layout.checkBoxLeft)
            maker.centerY.equalTo(layoutImage.snp.centerY)
            maker.right.equalTo(layoutImage.snp.left).offset(-Layout.checkBoxRightToLayout)
            maker.size.equalTo(Layout.checkBoxSize)
        }

        addSubview(labelContainerView)
        labelContainerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.left.equalToSuperview()
        }

        labelContainerView.addSubview(detailedLabel)
        detailedLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom)
            maker.bottom.equalToSuperview()
            maker.left.equalToSuperview()
        }

        labelContainerView.snp.makeConstraints { maker in
            maker.left.equalTo(layoutImage.snp.right).offset(Layout.layoutRightToText)
            maker.centerY.equalToSuperview()
            maker.top.greaterThanOrEqualTo(layoutImage.snp.top).priority(.high)
            maker.right.equalToSuperview().inset(16)
        }
    }

    @objc private func clickItem() {
        if checkBoxView.isSelected { return }
        delegate?.didClickItem()
        setCheck(true)
        self.action?()
    }

    func setCheck(_ isSelected: Bool) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.checkBoxView.isSelected = isSelected
        }
    }

    func setItem(_ item: RecordLayoutItem) {
        self.checkBoxView.isSelected = item.isSelected
        if titleLabel.attributedText?.string == item.layoutType.title { return }
        self.layoutImage.image = item.layoutType.image
        self.action = item.action
        titleLabel.attributedText = NSAttributedString(string: item.layoutType.title, config: .bodyAssist)
        detailedLabel.attributedText = NSAttributedString(string: item.layoutType.detail, config: .tinyAssist)
    }
}

final class RecordLayoutSettingViewController: BaseViewController {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 10
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: itemViews)
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .equalSpacing
        stack.spacing = 20
        return stack
    }()

    private lazy var itemViews: [RecordLayoutItemView] = {
        var views = [RecordLayoutItemView]()
        let count = viewModel.items.count
        (1...count).forEach({ _ in
            let view = RecordLayoutItemView()
            view.delegate = self
            views.append(view)
        })
        return views
    }()

    private lazy var recordLayoutThirdItemView: RecordLayoutItemView = {
        let view = RecordLayoutItemView()
        view.delegate = self
        return view
    }()

    private var currentSelectedItem: Int = 0

    private let viewModel: RecordLayoutSettingViewModel

    private var clickCount = 0

    init(service: UserSettingManager) {
        self.viewModel = RecordLayoutSettingViewModel(service: service)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViewModel()
    }

    func setupViews() {
        title = I18n.View_G_DefaultRecordLayoutTitle
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview().inset(16)
            $0.bottom.lessThanOrEqualToSuperview()
        }
        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(20)
            make.bottom.equalTo(-20)
        }
    }

    func bindViewModel() {
        loadData()
        viewModel.bindAction { [weak self] in
            guard let self = self else { return }
            Util.runInMainThread {
                self.clickCount -= 1
                self.loadData()
            }
        }
    }

    private func loadData() {
        guard clickCount == 0 else { return }
        for (i, item) in viewModel.items.enumerated() {
            itemViews[i].setItem(item)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarBgColor(UIColor.ud.bgFloatBase)
    }
}

extension RecordLayoutSettingViewController: RecordLayoutItemClickDelegate {
    // 当有选项切换动作时，先全部为未选中，然后将其中一个置为选中
    func didClickItem() {
        clickCount += 1
        itemViews.forEach { item in
            item.setCheck(false)
        }
    }
}
