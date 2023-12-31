//
//  GuideDialogViewController.swift
//  LarkAccount
//
//  Created by au on 2023/5/17.
//

import LKCommonsLogging
import UIKit
import UniverseDesignColor
import UniverseDesignFont

final class GuideDialogViewController: UIViewController {

    private static let logger = Logger.log(GuideDialogViewController.self, category: "LarkAccount")

    private let vm: GuideDialogViewModel

    init(vm: GuideDialogViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        vm.trackViewLoad()
    }
    
    private func setupViews() {
        view.backgroundColor = UIColor.ud.bgLogin

        setupNavigation()
        setupActionButtons()
        setupInfoView()
    }

    private func setupNavigation() {
        guard let title = vm.stepInfo.title else { return }
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = UDColor.textTitle
        titleLabel.textAlignment = .center
        titleLabel.font = UDFont.title3
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.top.equalToSuperview().offset(9)
            make.left.equalToSuperview().offset(64)
            make.right.equalToSuperview().offset(-64)
        }

        let separator = UIView()
        separator.backgroundColor = UDColor.lineDividerDefault
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(42)
            make.height.equalTo(0.5)
        }
    }

    private func setupActionButtons() {
        guard let buttonList = vm.stepInfo.buttonList, !buttonList.isEmpty else {
            return
        }
        var actionButtons = [NextButton]()

        // reversed 后，从底往上排
        Array(buttonList.reversed()).enumerated().forEach { (index, buttonInfo) in
            // 只有第一个 button 用主题蓝色
            let style: NextButton.Style = (index == buttonList.count - 1) ? .roundedRectBlue : .roundedRectWhiteWithGrayOutline
            let button = NextButton(title: buttonInfo.text ?? "", style: style)
            button.addTarget(self, action: #selector(onActionButtonTapped(_:)), for: .touchUpInside)
            view.addSubview(button)

            let section = CGFloat(index) * (48.0 + 16.0) // button height + spacing
            let bottomOffset: CGFloat = -8 - section

            button.snp.makeConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(bottomOffset)
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(48)
            }

            actionButtons.append(button)
        }

        actionButtonList = Array(actionButtons.reversed())
        actionButtonList.enumerated().forEach { (index, button) in
            button.tag = index
        }
    }

    private func setupInfoView() {
        let infoContainerView = UIView()
        infoContainerView.backgroundColor = .clear
        view.addSubview(infoContainerView)
        infoContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(60)
            if let button = self.actionButtonList.first {
                make.bottom.equalTo(button.snp.top).offset(-24)
            } else {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            }
        }

        infoContainerView.addSubview(infoView)
        infoView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.center.equalToSuperview()
        }
    }

    @objc
    private func onActionButtonTapped(_ sender: NextButton) {
        let tag = sender.tag
        guard let buttonList = vm.stepInfo.buttonList,
              tag < buttonList.count else {
            Self.logger.error("n_action_guide_dialog", body: "tag incorrect")
            return
        }
        let buttonInfo = buttonList[tag]
        vm.postButtonInfo(buttonInfo: buttonInfo) { [weak self] in
            guard let self = self else { return }
            if self.vm.needDismiss(buttonInfo: buttonInfo) {
                self.dismiss(animated: true)
            }
        }
    }

    func getDisplayHeight() -> CGFloat {
        // bar height + info view top & bottom padding + buttons height
        let height = 60 + infoView.frame.height + 24 + 64 * CGFloat(vm.stepInfo.buttonList?.count ?? 0) - 16 + 40
        return min(UIScreen.main.bounds.height, height)
    }

    private lazy var infoView: RiskRemindView = {
        let view = RiskRemindView(title: vm.stepInfo.subtitle, subtitle: vm.stepInfo.tips, descList: vm.stepInfo.descList)
        return view
    }()

    private lazy var actionButtonList = [NextButton]()
}
