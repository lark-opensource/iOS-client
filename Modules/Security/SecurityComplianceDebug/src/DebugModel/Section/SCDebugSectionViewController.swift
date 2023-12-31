//
//  SCDebugSectionViewController.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/28.
//

import Foundation

public final class SCDebugSectionViewController: UIViewController {
    public init(model: [SCDebugModel]) {
        super.init(nibName: nil, bundle: nil)
        let sectionView = SCDebugSectionView(model: model)
        view.addSubview(sectionView)
        sectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
