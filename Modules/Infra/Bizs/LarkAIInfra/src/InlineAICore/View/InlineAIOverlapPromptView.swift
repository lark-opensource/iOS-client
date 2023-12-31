//
//  InlineAIOverlapPromptView.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/5/6.
//  


import UIKit
import SnapKit
import RxSwift
import UniverseDesignColor

class InlineAIOverlapPromptView: InlineAIItemBaseView {
    
    lazy var promptView = InlineAIItemPromptView()
    let maskControl = UIControl(frame: .zero)
    let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        setupLayout()
        promptView.eventRelay.bind(to: eventRelay).disposed(by: disposeBag)
    }
    
    override var show: Bool {
        didSet {
            promptView.show = self.show
        }
    }
    
    func setupInit() {
        backgroundColor = .clear
        
        self.addSubview(maskControl)
        maskControl.addTarget(self, action: #selector(didClickMaskView), for: .touchUpInside)

        addSubview(promptView)
        promptView.setupTopRoundedCorner(showCorner: true)
    }
    
    @objc
    func didClickMaskView() {
        eventRelay.accept(.clickOverlapPromptMaskArea)
    }
    
    func setupLayout() {
        maskControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        promptView.tableView.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(6)
        }
        promptView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0)
        }
    }
    
    func update(groups: InlineAIPanelModel.Prompts) {
        promptView.update(groups: groups)
    }
    
    @discardableResult
    func update(maxHeight: CGFloat) -> CGFloat {
        let realHeight = promptView.getPromptRealHeight() + 6
        let height = min(realHeight + 6, maxHeight)
        promptView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        return height
    }
    
    func updatPromptView(bottom: CGFloat) {
        promptView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(bottom)
        }
    }

    
    func getOverlapPromptHeight() -> CGFloat {
        return promptView.getPromptRealHeight() + 6
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
