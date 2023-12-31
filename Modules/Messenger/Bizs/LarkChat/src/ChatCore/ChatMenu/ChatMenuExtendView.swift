//
//  ChatMenuExtendView.swift
//  LarkChat
//
//  Created by Zigeng on 2022/9/10.
//

import Foundation
import UIKit
import SnapKit
import RustPB
import RxSwift
import RxCocoa
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging

struct ChatExtendMenuConfig {
    static let cellPadding: CGFloat = 16
    static let cellHeight: CGFloat = 46
    static let iconLabelPadding: CGFloat = 4
    static let iconSize: CGSize = CGSize(width: 16, height: 16)
    static let expandMenuIcon: UIImage = Resources.menu_outlined
    static let font = UIFont.systemFont(ofSize: 14)
}

final class ChatMenuExtendViewController: UIViewController {
    let tableView = ChatMenuExtendView()
    var dataSource: [Im_V1_ChatMenuItem]
    weak var clickDelegate: ChatMenuClickDelegate?
    private let minWidth: CGFloat
    private var rootIndex: Int
    init(rootIndex: Int, dataSource: [Im_V1_ChatMenuItem], sourceView: UIView, minWidth: CGFloat) {
        self.dataSource = dataSource
        self.minWidth = min(minWidth, 120)
        self.rootIndex = rootIndex
        self.sourceView = sourceView
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }

    final class TapBackgroundView: UIView {
        private let tapHandler: () -> Void

        init(tapHandler: @escaping () -> Void) {
            self.tapHandler = tapHandler
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.tapHandler()
            super.touchesBegan(touches, with: event)
        }
    }

    lazy var tapBackgroundView: UIView = {
        let tapBackgroundView = TapBackgroundView(tapHandler: { [weak self] in
            self?.dismiss(animated: true)
        })
        return tapBackgroundView
    }()

    lazy var shadowBackgroundView: UIView = {
        let shadowBackgroundView = UIView()
        shadowBackgroundView.backgroundColor = UIColor.ud.bgFloat
        shadowBackgroundView.layer.cornerRadius = 8
        shadowBackgroundView.layer.ud.setShadow(type: .s4Down)
        return shadowBackgroundView
    }()

    final class ChatMenuExtendArrowView: UIView {
        override func draw(_ rect: CGRect) {
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(UIColor.ud.bgFloat.cgColor)
            context?.move(to: CGPoint(x: 0, y: 0))
            context?.addLine(to: CGPoint(x: self.bounds.width, y: 0))
            context?.addLine(to: CGPoint(x: self.bounds.width / 2, y: self.bounds.height))
            context?.closePath()
            context?.drawPath(using: .fill)
        }
    }

    lazy var arrowView: UIView = {
        let arrowView = ChatMenuExtendArrowView(frame: CGRect(x: 0, y: 0, width: 17, height: 8.5))
        arrowView.backgroundColor = UIColor.clear
        return arrowView
    }()

    weak var sourceView: UIView?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgFloat
        self.view.layer.cornerRadius = 8
        self.view.layer.masksToBounds = true
        setTableView()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.dismiss(animated: true)
    }

    lazy var contentSize: CGSize = {
        let height = CGFloat(self.dataSource.count) * ChatExtendMenuConfig.cellHeight
        let contentWidth: CGFloat = self.dataSource
              .map { button -> CGFloat in
                  let buttonItem = button.buttonItem
                  let text = buttonItem.name
                  let textWidth = (text as NSString).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT),
                                                                               height: ChatExtendMenuConfig.font.pointSize + 10),
                                                                               options: .usesLineFragmentOrigin,
                                                                               attributes: [NSAttributedString.Key.font: ChatExtendMenuConfig.font],
                                                                               context: nil).width
                  let iconWidth: CGFloat = buttonItem.imageKey.isEmpty ? 0 : (ChatExtendMenuConfig.iconSize.width + ChatExtendMenuConfig.iconLabelPadding)
                  return (ceil(textWidth) + iconWidth + (ChatExtendMenuConfig.cellPadding * 2))
              }.max() ?? 0
        return CGSize(width: max(minWidth, contentWidth), height: height)
    }()

    func setTableView() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.register(ChatMenuExtendCell.self, forCellReuseIdentifier: ChatMenuExtendCell.reuseIdentifier)
        tableView.alwaysBounceVertical = false
        tableView.rowHeight = ChatExtendMenuConfig.cellHeight
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension ChatMenuExtendViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.clickDelegate?.didClickExtendItem(rootIndex: self.rootIndex, index: indexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatMenuExtendCell.reuseIdentifier, for: indexPath)
              as? ChatMenuExtendCell else {
            return UITableViewCell()
        }
        let cellInfo = dataSource[indexPath.row]
        cell.setMenuCell(imageKey: cellInfo.buttonItem.imageKey, text: cellInfo.buttonItem.name)
        return cell
    }
}

extension ChatMenuExtendViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ChatMenuExtendPresentTransition()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ChatMenuExtendDismissTransition()
    }
}

final class ChatMenuExtendView: UITableView {
    init() {
        super.init(frame: .zero, style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ChatMenuExtendCell: UITableViewCell {
    static var reuseIdentifier = "ChatMenuExtendCell"
    private static let logger = Logger.log(ChatMenuExtendCell.self, category: "LarkChat.ChatMenuExtendCell")
    private let icon = UIImageView()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = ChatExtendMenuConfig.font
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    func setMenuCell(imageKey: String, text: String) {
        if imageKey.isEmpty {
            setNoImageLayout()
        } else {
            self.loadImage(key: imageKey)
            setHasImageLayout()
        }
        self.label.text = text
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgFloat
        self.addSubview(icon)
        self.addSubview(label)
    }

    private func loadImage(key: String) {
        self.icon.bt.setLarkImage(with: .default(key: key)) { [weak self] res in
            guard let self = self else { return }
            switch res {
            case .success(let imageResult):
                guard let image = imageResult.image else { return }
                self.icon.image = image
            case .failure(let error):
                Self.logger.error("set image fail", error: error)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.icon.bt.setLarkImage(with: .default(key: ""))
    }

    private func setHasImageLayout() {
        icon.isHidden = false
        icon.snp.remakeConstraints { make in
            make.size.equalTo(ChatExtendMenuConfig.iconSize)
            make.left.equalToSuperview().inset(ChatExtendMenuConfig.cellPadding)
            make.centerY.equalToSuperview()
        }
        label.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(ChatExtendMenuConfig.iconLabelPadding)
            make.right.equalToSuperview().inset(ChatExtendMenuConfig.cellPadding)
            make.centerY.equalToSuperview()
        }
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setNoImageLayout() {
        icon.isHidden = true
        label.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(ChatExtendMenuConfig.cellPadding)
            make.centerY.equalToSuperview()
        }
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
