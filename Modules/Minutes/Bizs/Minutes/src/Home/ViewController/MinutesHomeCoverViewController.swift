//
//  MinutesHomeCoverView.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/5/18.
//

import UIKit
import Foundation
import LarkUIKit
import MinutesFoundation
import MinutesNetwork

enum MinutesHomeCoverType {
    case loading
    case empty
    case error
    case unknown
}

class MinutesHomeCoverViewController: UIViewController {
    
    private lazy var loadingView: LoadingPlaceholderView = {
        let view = LoadingPlaceholderView(frame: .zero)
        view.isHidden = false
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    
    lazy var errorView = MinutesHomeErrorView()
    lazy var emptyView = MinutesHomeEmptyView()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    func show(type: MinutesHomeCoverType, spaceType: MinutesSpaceType = .home, isFilter: Bool = false) {
        removeAllSubviews()

        switch type {
        case .loading:
            view.addSubview(loadingView)
            loadingView.snp.remakeConstraints { maker in
                maker.center.equalToSuperview()
                maker.width.height.equalTo(150)
            }
            loadingView.isHidden = false
        case .empty:
            view.addSubview(emptyView)
            emptyView.snp.remakeConstraints { maker in
                maker.edges.equalToSuperview()
            }
            emptyView.type = spaceType
            emptyView.isFilter = isFilter
        case .error:
            view.addSubview(errorView)
            errorView.snp.remakeConstraints { maker in
                maker.edges.equalToSuperview()
            }
        case .unknown:
            hide()
        }
    }

    func hide() {
        removeAllSubviews()
    }

    func removeAllSubviews() {
        if loadingView.superview != nil {
            loadingView.removeFromSuperview()
        }
        if emptyView.superview != nil {
            emptyView.removeFromSuperview()
        }
        if errorView.superview != nil {
            errorView.removeFromSuperview()
        }
    }
}
