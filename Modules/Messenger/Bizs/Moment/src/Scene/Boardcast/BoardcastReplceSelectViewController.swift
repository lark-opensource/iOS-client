//
//  BoardcastReplceSelectViewController.swift
//  Moment
//
//  Created by zc09v on 2021/3/10.
//

import UIKit
import Foundation
import LarkUIKit
import LarkTraitCollection
import RxSwift

protocol BoardcastReplceSelectViewControllerDelegate: AnyObject {
    func selected(boardcastId: String)
}

final class BoardcastReplceSelectViewControllerFactory {
    static func create(delegate: BoardcastReplceSelectViewControllerDelegate, replceBoardcastInfos: [ReplaceBoardcastInfo]) -> UIViewController {
        if Display.pad {
            let vc = BoardcastReplceSelectViewControllerForPad(replceBoardcastInfos: replceBoardcastInfos)
            vc.delegate = delegate
            vc.selectPanel.layoutIfNeeded()
            vc.preferredContentSize = vc.selectPanel.bounds.size
            return vc
        } else {
            let vc = BoardcastReplceSelectViewControllerForPhone(replceBoardcastInfos: replceBoardcastInfos)
            vc.delegate = delegate
            return vc
        }
    }
}

class BoardcastReplceSelectViewController: BaseUIViewController, SelectPanelDelegate {
    weak var delegate: BoardcastReplceSelectViewControllerDelegate?
    fileprivate let selectPanel: SelectPanel

    init(replceBoardcastInfos: [ReplaceBoardcastInfo], hasBottomLine: Bool) {
        self.selectPanel = SelectPanel(replceBoardcastInfos: replceBoardcastInfos, hasBottomLine: hasBottomLine)
        super.init(nibName: nil, bundle: nil)
        selectPanel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func selected(boardcastId: String) {
        self.delegate?.selected(boardcastId: boardcastId)
        self.dismiss(animated: false, completion: nil)
    }
}

final class BoardcastReplceSelectViewControllerForPad: BoardcastReplceSelectViewController {
    private let disposeBag = DisposeBag()

    init(replceBoardcastInfos: [ReplaceBoardcastInfo]) {
        super.init(replceBoardcastInfos: replceBoardcastInfos, hasBottomLine: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(selectPanel)
        updateUIForTraitCollectionChanged(isRegular: presentingViewController?.view.window?.traitCollection.horizontalSizeClass == .regular)
        view.backgroundColor = .ud.bgBody
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] traitChange in
                self?.updateUIForTraitCollectionChanged(isRegular: traitChange.new.horizontalSizeClass == .regular)
            }).disposed(by: self.disposeBag)
        updateUIForTraitCollectionChanged(isRegular: view.window?.traitCollection.horizontalSizeClass == .regular)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        selectPanel.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(view.safeAreaInsets.left)
            make.top.equalToSuperview().offset(view.safeAreaInsets.top)
        }
    }

    private func updateUIForTraitCollectionChanged(isRegular: Bool) {
        if isRegular {
            selectPanel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(view.safeAreaInsets.top)
                make.left.equalToSuperview().offset(view.safeAreaInsets.left)
            }
        } else {
            selectPanel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(view.safeAreaInsets.top)
                make.left.equalToSuperview().offset(view.safeAreaInsets.left)
                make.right.equalToSuperview()
            }
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !preferredContentSize.equalTo(selectPanel.bounds.size) {
            preferredContentSize = selectPanel.bounds.size
            view.layoutIfNeeded()
        }
    }
}
final class BoardcastReplceSelectViewControllerForPhone: BoardcastReplceSelectViewController {
    private let backGroud = UIView()

    init(replceBoardcastInfos: [ReplaceBoardcastInfo]) {
        super.init(replceBoardcastInfos: replceBoardcastInfos, hasBottomLine: true)
        self.modalPresentationStyle = .overCurrentContext
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: 0.3, animations: {
            self.backGroud.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.3)
            self.selectPanel.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
            }
            self.view.layoutIfNeeded()
        }) { (_) in
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        backGroud.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHandle)))
        self.view.addSubview(backGroud)
        self.view.addSubview(selectPanel)
        backGroud.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.selectPanel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.view.bounds.height)
        }
        // Do any additional setup after loading the view.
    }

    @objc
    private func tapHandle() {
        self.dismiss(animated: false, completion: nil)
    }
}

protocol SelectPanelDelegate: BoardcastReplceSelectViewControllerDelegate {
}

final class SelectPanel: UIView, BoardcastReplceCellDelegate {
    weak var delegate: SelectPanelDelegate?

    private let replceBoardcastInfos: [ReplaceBoardcastInfo]

    private let titleLabel = UILabel()

    private let maskLayer = CAShapeLayer()
    init(replceBoardcastInfos: [ReplaceBoardcastInfo], hasBottomLine: Bool = true) {
        self.replceBoardcastInfos = replceBoardcastInfos
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.masksToBounds = true
        self.addSubview(titleLabel)
        titleLabel.backgroundColor = UIColor.ud.bgBody
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.text = BundleI18n.Moment.Lark_Moments_SelectAPostToBeReplace_MenuTitle
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-20)
        }

        let line = UIView()
        line.backgroundColor = UIColor.ud.commonTableSeparatorColor
        self.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        var lastCell: BoardcastReplceCell?
        for (index, boardcastInfo) in replceBoardcastInfos.enumerated() {
            let cell = BoardcastReplceCell(boardcastInfo: boardcastInfo,
                                           hasBottomLine: hasBottomLine || (index != replceBoardcastInfos.count - 1))
            cell.delegate = self
            self.addSubview(cell)
            if let lastCell = lastCell {
                cell.snp.makeConstraints { (make) in
                    make.top.equalTo(lastCell.snp.bottom)
                    make.left.right.equalToSuperview()
                    if index == replceBoardcastInfos.count - 1 {
                        make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
                    }
                }
            } else {
                cell.snp.makeConstraints { (make) in
                    make.top.equalTo(line.snp.bottom)
                    make.left.right.equalToSuperview()
                    if index == replceBoardcastInfos.count - 1 {
                        make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
                    }
                }
            }
            lastCell = cell
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func selected(boardcastId: String) {
        self.delegate?.selected(boardcastId: boardcastId)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let maskPath = UIBezierPath(
            roundedRect: self.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 12, height: 12)
        )
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }
}

protocol BoardcastReplceCellDelegate: BoardcastReplceSelectViewControllerDelegate {
}

final class BoardcastReplceCell: UIView {
    weak var delegate: BoardcastReplceCellDelegate?
    private let boardcastInfo: ReplaceBoardcastInfo
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.N900
        label.numberOfLines = 2
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        label.numberOfLines = 1
        return label
    }()

    private let placeBoardcastSelectView: UIImageView = {
        let placeBoardcastSelectView = UIImageView()
        placeBoardcastSelectView.image = Resources.placeBoardcastSelect
        placeBoardcastSelectView.isHidden = true
        return placeBoardcastSelectView
    }()

    init(boardcastInfo: ReplaceBoardcastInfo, hasBottomLine: Bool) {
        self.boardcastInfo = boardcastInfo
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        self.addSubview(contentLabel)
        self.addSubview(timeLabel)
        self.addSubview(placeBoardcastSelectView)
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(placeBoardcastSelectView.snp.left).offset(-20)
        }
        timeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(contentLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(placeBoardcastSelectView.snp.left).offset(-20)
            make.bottom.equalToSuperview().offset(-12)
        }
        placeBoardcastSelectView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-20)
        }
        self.contentLabel.text = boardcastInfo.boardcast.title
        let endTime = Date(timeIntervalSince1970: TimeInterval(boardcastInfo.boardcast.endTimeSec))
        self.timeLabel.text = "\(BundleI18n.Moment.Lark_Community_PinnedUntil) \(endTime.format(with: "YYYY-MM-dd HH:mm"))"
        placeBoardcastSelectView.isHidden = !boardcastInfo.selected

        if hasBottomLine {
            self.lu.addBottomBorder(leading: 16, trailing: 0, color: UIColor.ud.commonTableSeparatorColor)
        }
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHandle)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func tapHandle() {
        self.delegate?.selected(boardcastId: self.boardcastInfo.boardcast.postID)
    }
}
