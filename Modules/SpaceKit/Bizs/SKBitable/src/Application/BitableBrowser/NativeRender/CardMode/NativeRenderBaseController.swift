//
//  NativeRenderBaseController.swift
//  SKBitable
//
//  Created by zoujie on 2023/10/31.
//  


import Foundation
import SKInfra
import SKBrowser
import UniverseDesignEmpty
import UniverseDesignColor

struct BTNativeRenderContext {
    let id: String
    var openBaseTraceId: String
    var nativeRenderTraceId: String
}

class NativeRenderBaseController: UIViewController {
    
    var context: BTNativeRenderContext
    
    private lazy var emptyViewContainer = UIView().construct { it in
        it.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.centerY.greaterThanOrEqualToSuperview()
        }
        
        it.backgroundColor = UDColor.bgFloat
    }

    private var emptyConfig: UDEmptyConfig = UDEmptyConfig(title: .init(titleText: "",
                                                                        font: .systemFont(ofSize: 14, weight: .regular)),
                                                           description: .init(descriptionText: ""),
                                                           imageSize: 100,
                                                           type: .noContent,
                                                           labelHandler: nil,
                                                           primaryButtonConfig: nil,
                                                           secondaryButtonConfig: nil)
    
    private lazy var emptyView: UDEmptyView = {
        let blankView = UDEmptyView(config: emptyConfig)
        // 不用userCenterConstraints会非常不雅观
        blankView.useCenterConstraints = true
        blankView.backgroundColor = UDColor.bgFloat
        return blankView
    }()
    
    required init(context: BTNativeRenderContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
    func setUpUI() {
        view.addSubview(emptyViewContainer)
        view.clipsToBounds = true
        emptyViewContainer.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        
        emptyViewContainer.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let viewFrameInWindow = view.convert(view.bounds, to: nil)
        emptyViewContainer.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(-viewFrameInWindow.minY)
        }
    }
    
    func updateModel(model: NativeRenderBaseModel?) {
        if let empty = model?.empty {
            emptyConfig.description = .init(descriptionText: empty.text ?? "")
            emptyConfig.type = empty.icon?.enumIcon?.getEmptyType() ?? .noContent
            emptyView.update(config: emptyConfig)
            emptyViewContainer.isHidden = false
            self.view.bringSubviewToFront(emptyViewContainer)
        } else {
            emptyViewContainer.isHidden = true
        }
    }
    
    func searchModeDidChange(searchMode: BrowserViewController.SearchMode?) {}
}
