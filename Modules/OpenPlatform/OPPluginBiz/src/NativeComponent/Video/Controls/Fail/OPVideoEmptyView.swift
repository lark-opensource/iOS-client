//
//  OPVideoEmptyView.swift
//  OPPluginBiz
//
//  Created by zhujingcheng on 3/3/23.
//

import Foundation
import UniverseDesignEmpty

public final class OPVideoEmptyView: UIView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        let emptyView = UDEmpty(config: .init(type: .loadingFailure))
        addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
