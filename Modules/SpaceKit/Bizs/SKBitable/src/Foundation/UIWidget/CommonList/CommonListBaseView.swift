//
//  CommonListBaseView.swift
//  SKBitable
//
//  Created by zoujie on 2023/7/27.
//  


import Foundation

public class CommonListBaseView: UIView {
    var model: BTPanelItemActionParams
    var clickCallback: ((String) -> Void)?
    
    init(model: BTPanelItemActionParams) {
        self.model = model
        super.init(frame: .zero)
        setUpView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpView() {}
    
    func update(headerModel: BTPanelItemActionParams) {}
    
    func getHeight() -> CGFloat {
        return 48
    }
}
