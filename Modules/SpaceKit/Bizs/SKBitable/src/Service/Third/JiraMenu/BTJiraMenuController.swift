//
//  BTJiraMenuController.swift
//  DocsSDK
//
//  Created by lizechuang on 2020/1/6.
//

import Foundation
import HandyJSON
import SKUIKit
import SKCommon
import UniverseDesignColor

final class BTJiraMenuController: DraggableViewController, UITableViewDataSource, UITableViewDelegate {

    weak var delegate: BTJiraMenuControllerDelegate?
    private var jiraMenuParams: BTJiraMenuParams
    weak private var parentVC: UIViewController?

    let dragTitleHeight: CGFloat = 72
    let cellHeight: CGFloat = 52
    var cellCount: CGFloat = 0
    var bottomSafeAreaHeight: CGFloat {
        let view = self.parentVC?.view ?? self.view
        guard let windowSafeAreaBottomHeight = view?.window?.safeAreaInsets.bottom else { return 0 }
        return windowSafeAreaBottomHeight + 16 // 留出一点空白
    }

    lazy var dismissZone = UIView().construct { it in
        it.backgroundColor = UDColor.bgMask
        it.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapDimissView)))
    }

    private lazy var dragTitleView = BTJiraDragTitleView().construct { it in
        it.titleLabel.text = jiraMenuParams.title
        it.detailLabel.text = jiraMenuParams.desc
        it.addGestureRecognizer(panGestureRecognizer)
    }

    private lazy var tableView = UITableView(frame: .zero, style: .plain).construct { it in
        it.dataSource = self
        it.delegate = self
        it.separatorStyle = .none
        it.isScrollEnabled = false
        it.backgroundColor = UDColor.bgBody
        it.register(BTJiraMenuCell.self, forCellReuseIdentifier: NSStringFromClass(BTJiraMenuCell.self))
    }

    init(jiraMenuParams: BTJiraMenuParams, parentVC: UIViewController?) {
		self.jiraMenuParams = jiraMenuParams
        self.cellCount = CGFloat(jiraMenuParams.actions.count)
        self.parentVC = parentVC
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		if SKDisplay.pad {
			return super.supportedInterfaceOrientations
		}
		return [.allButUpsideDown]
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		setupLayout()
	}

    private func setupLayout() {
        contentView = UIView().construct { it in
            it.backgroundColor = UDColor.bgBody
        }
        let safeAreaInsets = parentVC?.view.window?.safeAreaInsets ?? view.safeAreaInsets

        view.addSubview(dismissZone)
        view.addSubview(contentView)
        contentView.addSubview(dragTitleView)
        contentView.addSubview(tableView)

        contentView.snp.makeConstraints { it in
            it.left.right.bottom.equalToSuperview()
            it.top.equalTo(view.bounds.height - (dragTitleHeight + cellHeight * cellCount + bottomSafeAreaHeight))
        }

        dismissZone.snp.makeConstraints { it in
            it.left.right.equalToSuperview()
            it.bottom.equalTo(contentView.snp.top)
            it.height.equalToSuperview().multipliedBy(2)
        }

        dragTitleView.snp.makeConstraints { it in
            it.top.right.left.equalToSuperview()
            it.height.equalTo(dragTitleHeight)
        }

        tableView.snp.makeConstraints { it in
            it.top.equalTo(dragTitleView.snp.bottom)
            it.height.equalTo(cellHeight * cellCount)
            it.left.equalToSuperview().offset(safeAreaInsets.left)
            it.right.equalToSuperview().offset(-safeAreaInsets.right)
        }

        contentViewMaxY = view.bounds.height - (dragTitleHeight + cellHeight * cellCount + bottomSafeAreaHeight)
	}

	override func dragDismiss() {
		dismiss()
	}

	@objc
    private func onTapDimissView() {
		dismiss()
	}

	private func dismiss(_ needNotify: Bool = true) {
        dismissZone.removeFromSuperview()
		dismiss(animated: true, completion: {
			self.delegate?.jiraMenuVCDidDismiss(self,
												blockId: self.jiraMenuParams.blockId,
												callback: self.jiraMenuParams.callback)
		})
	}
    // MARK: - UITableViewDataSource,  UITableViewDataSource
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return jiraMenuParams.actions.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(BTJiraMenuCell.self), for: indexPath) as? BTJiraMenuCell else {
			return UITableViewCell(style: .default, reuseIdentifier: nil)
		}
		cell.selectionStyle = .none
		cell.setActionData(action: jiraMenuParams.actions[indexPath.row], indexPath: indexPath)
		return cell
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return cellHeight
	}
    // MARK: - UITableViewDelegate,  UITableViewDelegate
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		delegate?.didSelectJiraMenuCell(self,
										didSelect: jiraMenuParams.actions[indexPath.row],
										blockId: jiraMenuParams.blockId,
										callback: jiraMenuParams.callback)
		dismiss(false)
	}
}
