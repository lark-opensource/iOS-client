//
//  OPCustomBlockErrorPage.swift
//  OPBlock
//
//  Created by doujian on 2022/8/3.
//

import OPSDK

// block 默认使用基类实现
public final class OPCustomBlockErrorPage: OPBaseBlockErrorPage {

    public override init(delegate: OPBlockErrorPageButtonClickDelegate) {
        super.init(delegate: delegate)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
