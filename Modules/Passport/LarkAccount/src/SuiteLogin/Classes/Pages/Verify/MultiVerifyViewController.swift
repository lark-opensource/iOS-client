//
//  MultiVerifyViewController.swift
//  LarkAccount
//
//  Created by zhaoKejie on 2023/7/26.
//

import Foundation
import UniverseDesignToast
import SnapKit
import UniverseDesignActionPanel
import LarkUIKit
import EENavigator

class MultiVerifyViewController: BaseViewController {

    var vm: MultiVerifyViewModel

    init(vm: MultiVerifyViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var needSkipWhilePop: Bool {
        return vm.getNeedSkipWhilePop()
    }

    /// 服务端下发的重置账号、找回密码等
    private lazy var retrieveLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        lbl.textContainerInset = .zero
        lbl.textContainer.lineFragmentPadding = 0
        return lbl
    }()

    /// 验证页面的主体差异部分
    lazy var verifyContentView: UIView = UIView()

    func updateVerifyView() {
        configTopInfo(vm.getTitle(), detail: V3ViewModel.attributedString(for: vm.getSubtitle()))
        updateVerifyContentView()
        updateRetrieveButton()
        updateSwitchButton()
        updateBottomView()
        self.vm.currentVerifyProvider.verifyDidAppear()
    }

    // MARK: - 更新当前验证方式的UI展示
    func updateVerifyContentView() {
        // 删除现有的VerifyView
        verifyContentView.snp.removeConstraints()
        verifyContentView.removeFromSuperview()

        // 放置新VerifyView
        verifyContentView = vm.getCurrentVerifyView()
        centerInputView.addSubview(verifyContentView)

        // 重新更新验证主体view约束
        verifyContentView.snp.remakeConstraints(vm.currentVerifyProvider.layoutMaker)
    }

    func updateRetrieveButton() {
        if let retrieveText = vm.getRetrieveRichText() {
            retrieveLabel.isHidden = false
            retrieveLabel.attributedText = retrieveText
            retrieveLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(VerifyPageLayout.itemTopSpace)
                make.left.equalToSuperview().inset(VerifyPageLayout.itemLeftSpace)
                make.right.lessThanOrEqualToSuperview().inset(VerifyPageLayout.itemRightSpace)
            }
        } else {
            retrieveLabel.isHidden = true
            retrieveLabel.attributedText = NSAttributedString(string: "")
            retrieveLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview().inset(VerifyPageLayout.itemLeftSpace)
                make.right.lessThanOrEqualToSuperview().inset(VerifyPageLayout.itemRightSpace)
                make.height.equalTo(0).priority(.high)
            }
        }
    }

    func updateSwitchButton() {
        if let switchButtonInfo = vm.getSwitchButtonInfo() {
            switchButton.isHidden = false
            switchButton.setTitle(switchButtonInfo.text, for: .normal)
            switchButton.snp.remakeConstraints { make in
                make.top.equalTo(retrieveLabel.snp.bottom).offset(VerifyPageLayout.itemTopSpace)
                make.left.equalToSuperview().inset(VerifyPageLayout.itemLeftSpace)
                make.right.lessThanOrEqualToSuperview().inset(VerifyPageLayout.itemRightSpace)
                make.bottom.equalToSuperview()
            }
        } else {
            switchButton.isHidden = true
            switchButton.setTitle("", for: .normal)
            switchButton.snp.remakeConstraints { make in
                make.top.equalTo(retrieveLabel.snp.bottom)
                make.left.equalToSuperview().inset(VerifyPageLayout.itemLeftSpace)
                make.right.lessThanOrEqualToSuperview().inset(VerifyPageLayout.itemRightSpace)
                make.height.equalTo(0).priority(.high)
                make.bottom.equalToSuperview()
            }
        }
    }

    func updateBottomView() {
        vm.currentVerifyProvider.setupBottom(nextButton: nextButton, bottomView: bottomView)
    }

    /// 处理验证方式状态变化需要的loading toast等UI展示
    func bindVerifyStatusPublish() {
        vm.bindCurrentVerifyStatus().subscribe {[weak self] event in
            guard let self = self else { return }
            guard let verifyStatus = event.element else { return }
            self.stopLoading()
            switch verifyStatus {
            case .start:
                self.startLoading()
            case .showTips(let str):
                self.showToast(str)
            case .fail(let error):
                self.handleError(error: error)
            case .succ:
                self.stopLoading()
            case .commonError(let error):
                self.handleError(error: error)
            }
        }.disposed(by: disposeBag)
    }

    // MARK: - 通用的action定义

    /// 点击找回账号、重置密码按钮
    @objc func retrieveAction() {
        vm.handleRetrieveAction()
    }
    /// 点击下一步按钮
    @objc func nextAction(sender: UIButton) {
        self.vm.handleNextAction()
    }
    /// 点击切换验证方式按钮
    override func switchAction(sender: UIButton) {
        guard let switchButtonInfo = vm.getSwitchButtonInfo(),
              let actionType = switchButtonInfo.actionType else {
            return
        }
        var nextActon: ActionIconType = actionType
        // 列表形式的切换验证方式
        if actionType == .verifyOtherList,
           let verifyMethodTable = vm.getVerifyMethodsTable() {
            vm.trackerViewClick(event: "change_to_verify_authn_methods")
            let verifyMethodsWithoutCurrent = verifyMethodTable.authMethods.filter { verifyInfo in
                !vm.isCurrentVerify(type: verifyInfo.actionType ?? .unknown)
            }
            let otherVerifyListVC = OtherVerifyMethodViewController(title: verifyMethodTable.title ?? "",
                                                                    verifyList: verifyMethodsWithoutCurrent) {[weak self] selectAction in
                guard let self = self else { return }
                nextActon = selectAction
                self.switchTo(nextAction: nextActon)
            }
            if Display.pad {
                otherVerifyListVC.modalPresentationStyle = .formSheet
                otherVerifyListVC.preferredContentSize = self.preferredContentSize
                self.present(otherVerifyListVC, animated: true)
            } else {
                showActionPanel(vc: otherVerifyListVC)
            }
        } else {
            switchTo(nextAction: nextActon)
        }

    }

    /// 尝试切换到某个验证方式
    func switchTo(nextAction: ActionIconType) {
        vm.trySwitchToNext(actionType: nextAction)
        UIView.animate(withDuration: 0.2, animations: {
            self.moveBoddyView.alpha = 0
        }) { (_) in
            self.updateVerifyView()
            self.vm.currentVerifyProvider.verifyDidAppear()
            UIView.animate(withDuration: 0.2, animations: {
                self.moveBoddyView.alpha = 1
            })
        }
    }

    /// 通过actionPanel形式展示验证方式选择页
    func showActionPanel(vc: OtherVerifyMethodViewController) {
        var config = UDActionPanelUIConfig()
        //由于需要计算偏移尺寸，所以需要先进行Layout
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()
        let maxHeight = self.view.bounds.height * 0.7
        let tableviewContentHeight = vc.dataSource.count * Int(VerifyPageLayout.itemTopSpace + VerifyPageLayout.tableviewCellHeight)
        var currentHeight = CGFloat(tableviewContentHeight) +
                            VerifyPageLayout.tableviewEdge * 2 +
                            VerifyPageLayout.navigationBarHeight
        currentHeight = min(currentHeight, maxHeight)
        config.originY = self.view.bounds.height - currentHeight
        let panel = UDActionPanel(customViewController: vc, config: config)
        self.present(panel, animated: true)
    }

    // MARK: - ViewController lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        switchButtonContainer.addSubview(retrieveLabel)
        nextButton.addTarget(self, action: #selector(nextAction), for: .touchUpInside)
        switchButton.contentEdgeInsets = .init(edges: CGFLOAT_MIN)
        updateVerifyView()
        view.layoutIfNeeded()

        bindVerifyStatusPublish()

    }

    override func clickBackOrClose(isBack: Bool) {
        vm.monitorVerifyEventCancel()

        if vm.backToFeed,
           let tabVC = Navigator.shared.tabProvider?().tabbarController, // user:checked (navigator)
           let presentedVC = tabVC.presentedViewController {
            tabVC.navigationController?.popToRootViewController(animated: false)
            presentedVC.dismiss(animated: true, completion: nil)
        } else {
            super.clickBackOrClose(isBack: isBack)
        }
    }

    override func handleClickLink(_ URL: URL, textView: UITextView) {
        switch URL {
        case Link.retrieveAction:
            showLoading()
            vm.handleRetrieveAction()
        default:
            super.handleClickLink(URL, textView: textView)
        }
    }

}

// MARK: - 验证页的UI约束静态值定义
struct VerifyPageLayout {
    static let itemTopSpace: CGFloat = 16
    static let itemLeftSpace: CGFloat = 16
    static let itemRightSpace: CGFloat = 16
    static let tableviewEdge: CGFloat = 16
    static let tableviewCellHeight: CGFloat = 90
    static let navigationBarHeight: CGFloat = 48
}

// MARK: - 给用户操作的UI反馈
extension MultiVerifyViewController {

    func startLoading() {
        super.showLoading()
    }

    func showToast(_ str: String) {
        UDToast.showTips(with: str,on: self.view)
    }

    func handleError(error: Error) {
        /// 解决在密码或验证码输入错误时 toast 会从左上角飘进来的问题
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.errorHandler.handle(error)
        }
        stopLoading()
    }
}

