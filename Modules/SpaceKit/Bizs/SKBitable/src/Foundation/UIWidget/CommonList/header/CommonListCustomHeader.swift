//
//  CommonListCustomHeader.swift
//  SKBitable
//
//  Created by zoujie on 2023/7/27.
//  


import SKFoundation
import SKCommon
import RxSwift
import UniverseDesignColor

final public class CommonListCustomHeader: CommonListBaseHeaderView {
    let disposeBag = DisposeBag()
    
    private lazy var headerView = SKDraggableTitleView().construct { it in
        it.topLine.isHidden = true
        it.titleLabel.textAlignment = .center
    }
    
    override func setUpView() {
        super.setUpView()
        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        headerView.titleLabel.text = model.title ?? ""
        
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, let left = model.leftAction, let right = model.rightAction {
            
            headerView.leftButton.isHidden = false
            // 不设置为nil会导致无法显示文字
            headerView.leftButton.setImage(nil, for: .normal)
            headerView.leftButton.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
            }
            
            headerView
                .leftButton
                .setTitle(
                    left.leftText,
                    withFontSize: 17,
                    fontWeight: .regular,
                    color: UDColor.textTitle,
                    forState: .normal
                )
            headerView
                .leftButton
                .titleLabel?
                .textAlignment = .center
            
            headerView
                .leftButton
                .rx
                .tap
                .subscribe { [weak self] (_) in
                    guard let self = self else { return }
                    self.onclick(id: left.id)
                }
                .disposed(by: disposeBag)
            
            headerView.rightButton.isHidden = false
            headerView
                .rightButton
                .setTitle(
                    right.leftText,
                    withFontSize: 17,
                    fontWeight: .regular,
                    color: UDColor.primaryPri500,
                    forState: .normal
                )
            headerView
                .rightButton
                .titleLabel?
                .textAlignment = .center
            
            headerView
                .rightButton
                .rx
                .tap
                .subscribe { [weak self] (_) in
                    guard let self = self else { return }
                    self.onclick(id: right.id)
                }
                .disposed(by: disposeBag)
            
        } else {
            headerView.rightButton.isHidden = true
            headerView.leftButton.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
            headerView.leftButton.addTarget(self, action: #selector(clickClose), for: .touchUpInside)
        }
    }
    
    override func update(headerModel: BTPanelItemActionParams) {
        self.model = headerModel
        headerView.titleLabel.text = headerModel.title ?? ""
    }
    
    override func setCloseButtonHidden(isHidden: Bool) {
        headerView.leftButton.isHidden = isHidden
    }
    
    override func getHeight() -> CGFloat {
        return 48
    }
    
    @objc
    func clickClose() {
        onclick(id: "exit")
    }
    
    func onclick(id: String) {
        clickCallback?(id)
    }
}
