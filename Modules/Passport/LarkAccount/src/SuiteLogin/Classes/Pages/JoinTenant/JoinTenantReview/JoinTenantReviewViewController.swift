//
//  JoinTenantReviewViewController.swift
//  LarkAccount
//
//  Created by bytedance on 2021/7/8.
//

import Foundation
import LKCommonsLogging
import RxSwift
import Homeric
import UIKit

class JoinTenantReviewViewController: BaseViewController {

    static let logger = Logger.log(JoinTenantReviewViewController.self, category: "JoinTenantReviewView")

    private let vm: JoinTenantReviewModel
    
    private lazy var subtitleLabel: UILabel = {
        let lb = UILabel(frame: .zero)
        lb.attributedText = vm.subtitle
        lb.numberOfLines = 0
        lb.textAlignment = .left
        lb.lineBreakMode = .byWordWrapping
        lb.font = UIFont.systemFont(ofSize: 14)
        lb.sizeToFit()
        return lb
    }()

    init(vm: JoinTenantReviewModel) {
        self.vm = vm
        super.init(viewModel: vm)
        _ = nextButton.rx.tap.subscribe { [weak self] (_) in
            self?.logger.info("n_action_click_iknow_button")
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: vm.joinTenantReviewInfo.flowType ?? "", click: "confirm", target: "")
            SuiteLoginTracker.track(Homeric.PASSPORT_WAIT_FOR_PERMISSION_CLICK, params: params)
            guard let self = self else { return }
            if let vc = self.navigationController,
               vc.viewControllers.count > 1 {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.logger.info("n_page_pending_approve")
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: vm.joinTenantReviewInfo.flowType ?? "")
        SuiteLoginTracker.track(Homeric.PASSPORT_WAIT_FOR_PERMISSION_VIEW, params: params)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.titleLabel.removeFromSuperview()
        self.titleLabel.text = vm.title
        
        let titleContainerView = UIView()
        titleContainerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.left.top.equalToSuperview()
        }
        
        titleContainerView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Self.Layout.subtitleLabelSpace)
            make.left.right.bottom.equalToSuperview()
        }
        
        moveBoddyView.addSubview(titleContainerView)
        titleContainerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview().inset(CL.itemSpace)
        }
        
        nextButton.setTitle(vm.button, for: .normal)
        nextButton.isEnabled = true
        
        let leftImage = BundleResources.LarkAccount.TeamConversion.join_tenant_review_bg_left
        let leftImageView = UIImageView(image: leftImage)
        self.inputAdjustView.addSubview(leftImageView)
        leftImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(BaseLayout.visualNaviBarHeight + Self.Layout.subtitleLabelSpace)
        }

        let rightImage = BundleResources.LarkAccount.TeamConversion.join_tenant_review_bg_right
        let rightImageView = UIImageView(image: rightImage)
        self.inputAdjustView.addSubview(rightImageView)
        rightImageView.snp.makeConstraints { make in
            make.right.equalTo(moveBoddyView)
            make.bottom.equalTo(self.nextButton.snp.top).offset(-Self.Layout.rightImageBottomSpace)
        }
    }
}

extension  JoinTenantReviewViewController{
    struct Layout {
        static let subtitleLabelSpace: CGFloat = 24
        static let rightImageBottomSpace: CGFloat = 32
    }
}
