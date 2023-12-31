//
//  MinutesMoreViewController.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/1/13.
//

import UIKit
import SnapKit
import UniverseDesignColor
import MinutesFoundation
import UniverseDesignColor
import UniverseDesignIcon
import FigmaKit
import UniverseDesignEmpty

private let kMinutesTableViewCellHeight: CGFloat = 48

protocol MinutesMoreTableViewCell: UITableViewCell {
    func setupItem(_ item: MinutesMoreItem)
    func onSelect()
}

protocol MinutesMoreItem {
    var identifier: String { get }
    var icon: UIImage { get }
    var title: String { get }

    var shouldDismiss: Bool { get }

    var height: CGFloat { get }
}

protocol MinutesDeleteItemDelegate: AnyObject {
    func deleteItem()
}

class MinutesMoreViewController: UIViewController {

    private let items: [MinutesMoreItem]
    private let topic: String
    private let info: String
    private let shouldShowDeleteItem: Bool
    let coverImageView = UIImageView()

    weak var delegate: MinutesDeleteItemDelegate?

    private lazy var cellHeight: CGFloat = {
        return items.reduce(0) { partialResult, item in
            return partialResult + item.height
        }
    }()

    var viewHeight: CGFloat {
        if shouldShowDeleteItem {
            return kMinutesTableViewCellHeight + cellHeight + 97 + (ScreenUtils.hasTopNotch && !isRegular ? 34 : 16)
        } else {
            return cellHeight + 89 + (ScreenUtils.hasTopNotch && !isRegular ? 34 : 16)
        }
    }

    private lazy var titleView: UILabel = {
        let titleView = UILabel()
        titleView.text = topic
        titleView.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleView.textColor = UIColor.ud.textTitle
        return titleView
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(BundleResources.Minutes.minutes_more_close, for: .normal)
        button.addTarget(self, action: #selector(closePanel), for: .touchUpInside)
        button.isHidden = isRegular
        return button
    }()

    private lazy var subtitelView: UILabel = {
        let subtitelView = UILabel()
        subtitelView.text = info
        subtitelView.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitelView.textColor = UIColor.ud.textCaption
        return subtitelView
    }()

    private lazy var blurView: BackgroundBlurView = {
        let blurView = BackgroundBlurView()
        blurView.blurRadius = 24
        blurView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.1)
        return blurView
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.layer.cornerRadius = 12
        let bottom = UIView()
        bottom.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(bottom)
        bottom.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(12)
        }
        return view
    }()

    private lazy var tableView: UITableView = {
        let tableView: UITableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.register(MinutesMoreClickCell.self, forCellReuseIdentifier: MinutesMoreClickCell.description())
        tableView.register(MinutesMoreSwitchCell.self, forCellReuseIdentifier: MinutesMoreSwitchCell.description())
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        tableView.layer.cornerRadius = 12
        tableView.backgroundColor = UIColor.ud.bgFloat
        tableView.isScrollEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var deleteButton: UIButton = {
        let deleteBtn = UIButton(type: .custom)
        deleteBtn.setTitle(BundleI18n.Minutes.MMWeb_G_Delete, for: .normal)
        deleteBtn.setTitleColor(UIColor.ud.udtokenTagStateRedLight, for: .normal)
        deleteBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        deleteBtn.backgroundColor = UIColor.ud.bgFloat
        deleteBtn.layer.cornerRadius = 12
        deleteBtn.addTarget(self, action: #selector(deleteItem), for: .touchUpInside)
        return deleteBtn
    }()

    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.delegate = self
        return tapGesture
    }()

    var isRegular: Bool = false

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(topic: String, info: String, items: [MinutesMoreItem], shouldShowDeleteItem: Bool) {
        self.topic = topic
        self.info = info
        self.items = items
        self.shouldShowDeleteItem = shouldShowDeleteItem
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(containerView)
        view.addGestureRecognizer(tapGesture)
//        containerView.addSubview(blurView)

        coverImageView.layer.cornerRadius = 3
        coverImageView.layer.masksToBounds = true
        coverImageView.contentMode = .scaleAspectFill

        containerView.addSubview(coverImageView)
        containerView.addSubview(titleView)
        containerView.addSubview(closeButton)
        containerView.addSubview(subtitelView)
        containerView.addSubview(tableView)

        if isRegular {
            containerView.snp.makeConstraints { make in
                make.left.bottom.right.equalToSuperview()
                make.top.equalTo(14)
            }
        } else {
            containerView.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(viewHeight)
            }
        }

//        blurView.snp.makeConstraints { (maker) in
//            maker.left.right.equalToSuperview()
//            maker.top.bottom.equalToSuperview()
//        }

        coverImageView.snp.makeConstraints { maker in
            maker.left.equalToSuperview().inset(16)
            maker.top.equalToSuperview().inset(16)
            maker.width.height.equalTo(40)
        }

        titleView.snp.makeConstraints { maker in
            maker.left.equalTo(coverImageView.snp.right).offset(12)
            maker.top.equalToSuperview().inset(16)
            maker.height.equalTo(20)
        }

        subtitelView.snp.makeConstraints { maker in
            maker.left.equalTo(coverImageView.snp.right).offset(12)
            maker.top.equalTo(titleView.snp.bottom).offset(2)
            maker.right.equalTo(titleView)
            maker.height.equalTo(18)
        }

        closeButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(4)
            maker.right.equalToSuperview().inset(6)
            maker.width.height.equalTo(44)
            maker.left.equalTo(titleView.snp.right).offset(12)
        }

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        containerView.addSubview(line)

        line.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.top.equalToSuperview().inset(72)
        }

        tableView.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().inset(16)
            maker.left.equalToSuperview().offset(16)
            maker.top.equalTo(line.snp.bottom).offset(16)
            maker.height.equalTo(cellHeight)
        }

        if shouldShowDeleteItem {
            containerView.addSubview(deleteButton)
            deleteButton.snp.makeConstraints { (maker) in
                maker.right.equalToSuperview().inset(16)
                maker.left.equalToSuperview().offset(16)
                maker.top.equalTo(tableView.snp.bottom).offset(8)
                maker.height.equalTo(kMinutesTableViewCellHeight)
            }
            tapGesture.cancelsTouchesInView = false
        }
    }

    @objc
    private func handleTapGesture(_ sender: UITapGestureRecognizer) {
        if !self.containerView.frame.contains(sender.location(in: self.view)) {
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc
    private func closePanel() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    private func deleteItem(_ sender: UITapGestureRecognizer) {
        self.delegate?.deleteItem()
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension MinutesMoreViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = items[indexPath.row]
        return item.height
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < items.count else { return UITableViewCell() }
        let item = items[indexPath.row]

        guard let cell = tableView.dequeueReusableCell(withIdentifier: item.identifier, for: indexPath)
                as? MinutesMoreTableViewCell else { return UITableViewCell() }

        if indexPath.row == items.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: cell.bounds.width + 100)
        }

        cell.setupItem(item)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < items.count else { return }
        let item = items[indexPath.row]
        guard let cell = tableView.cellForRow(at: indexPath) as? MinutesMoreTableViewCell else { return }
        if item.shouldDismiss {
            dismiss(animated: true) {
                cell.onSelect()
            }
        } else {
            cell.onSelect()
        }

    }
}

extension MinutesMoreViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !self.containerView.frame.contains(touch.location(in: self.view))
    }
}

extension MinutesMoreViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        return MinutesMorePresentationController(presentedViewController: presented, presenting: presenting)
    }
}
