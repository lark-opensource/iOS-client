//
//  LKSVGDisplayView.swift
//  LarkUIKit
//
//  Created by lizechuang on 2020/8/17.
//

import UIKit
import Foundation
import LKCommonsLogging
import LarkUIKit
import SnapKit
import WebKit

public typealias SVGObtainCompletionHandler = (_ svgString: String?, _ error: Error?) -> Void

final class LKSVGDisplayView: UIView {
    private static let logger = Logger.log(LKPhotoZoomingScrollView.self,
                                           category: "LarkUIKit.LKSVGDisplayView")

    private static var frameworkBundle: Bundle? = {
        if let path = Bundle(for: LKSVGDisplayView.self).path(forResource: "LarkUIKit", ofType: "bundle") {
            return Bundle(path: path)
        }
        return nil
    }()

    private var function = "window.setSVGContent"

    var displayAsset: LKDisplayAsset?
    var displayIndex: Int = Int.max
    var didFinishLoad: Bool = false

    var dismissCallback: (() -> Void)?
    var longPressCallback: ((UIImage?, LKDisplayAsset, UIView?) -> Void)?
    var moreButtonClickedCallback: ((UIImage?, LKDisplayAsset, UIView?) -> Void)?

    private lazy var displayView: WKWebView = {
        let view = WKWebView(frame: .zero)
        return view
    }()

    var getExistedImageBlock: GetExistedImageBlock?
    var setImageBlock: SetImageBlock?
    var handleLoadCompletion: ((AssetLoadCompletionInfo) -> Void)?
    var prepareAssetInfo: PrepareAssetInfo?
    private var cancelImageBlock: CancelImageBlock?
    var setSVGBlock: SetSVGBlock?

    private lazy var progressView: LarkProgressHUD = {
        let view = LarkProgressHUD(view: self)
        view.isUserInteractionEnabled = false
        return view
    }()

    public fileprivate(set) var singleTap = UITapGestureRecognizer()
    public fileprivate(set) var doubleTap = UITapGestureRecognizer()
    public fileprivate(set) var longGesture = UILongPressGestureRecognizer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(displayView)
        self.addSubview(progressView)
        self.setupWebView()
        displayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        displayView.scrollView.showsVerticalScrollIndicator = false
        displayView.scrollView.showsHorizontalScrollIndicator = false

        doubleTap.addTarget(self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        displayView.addGestureRecognizer(doubleTap)

        singleTap.addTarget(self, action: #selector(handleSingleTap))
        singleTap.require(toFail: doubleTap)
        singleTap.delegate = self
        displayView.addGestureRecognizer(singleTap)

        longGesture.addTarget(self, action: #selector(handleLongPress))
        longGesture.delegate = self
        displayView.addGestureRecognizer(longGesture)
        displayView.navigationDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        displayAsset = nil
        displayIndex = Int.max
        displayView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }

    func setupWebView() {
        guard let path = LKSVGDisplayView.frameworkBundle?.path(forResource: "SVGTemplate", ofType: "html") else {
            return
        }
        let url = URL(fileURLWithPath: path)
        displayView.loadFileURL(url, allowingReadAccessTo: url)
        progressView.show(animated: true)
    }
}

extension LKSVGDisplayView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if (
            gestureRecognizer is UILongPressGestureRecognizer &&
            otherGestureRecognizer is UITapGestureRecognizer) ||
            (gestureRecognizer is UITapGestureRecognizer &&
             otherGestureRecognizer is UILongPressGestureRecognizer) {
            return false
        }
        return true
    }
}

private extension LKSVGDisplayView {

    private func displaySVG(completion: @escaping () -> Void) {
        guard let displayAsset = displayAsset else {
            return
        }

        let completionHandler: SVGObtainCompletionHandler = { [weak self] (svgString, error) in
            guard let self = self else { return }
            self.handleLoadCompletion?(AssetLoadCompletionInfo(index: self.displayIndex,
                                                                data: .svg(svgString),
                                                                error: error))
            self.displayAsset?.svgData = svgString
            if let curSvgString = svgString, self.didFinishLoad, let rawScript = self.serializationCharacters(curSvgString) {
                let script = self.function + "(\(rawScript))"
                self.displayView.evaluateJavaScript(script, completionHandler: nil)
                LKSVGDisplayView.logger.info("LKSVGDisplayView Load SvgString")
                self.progressView.hide(animated: true)
            }
            completion()
        }

        cancelImageBlock = self.setSVGBlock?(displayAsset, completionHandler)
    }

    func serializationCharacters(_ string: String) -> String? {
        let dic = ["svgString": string]
        do {
            assert(JSONSerialization.isValidJSONObject(dic))
            let jsonData = try JSONSerialization.data(withJSONObject: dic, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            assertionFailure("failure to serialization")
        }
        return nil
    }

    @objc
    func handleSingleTap(ges: UITapGestureRecognizer) {
        displayView.isHidden = true // 解决dismiss的时候因为statusBar被取消接管会有一个向下移的显示
        if dismissCallback == nil {
            Self.logger.info("handleSingleTap, dismissCallback is nil")
        } else {
            Self.logger.info("handleSingleTap, dismissCallback")
        }
        dismissCallback?()
    }

    @objc
    func handleDoubleTap(ges: UITapGestureRecognizer) {
    }

    @objc
    func handleLongPress(ges: UITapGestureRecognizer) {
        if ges.state == .began {
            if let asset = self.displayAsset {
                self.longPressCallback?(nil, asset, nil)
            }
        }
    }
}

extension LKSVGDisplayView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !didFinishLoad else {
            return
        }
        didFinishLoad = true
        if let curSvgString = self.displayAsset?.svgData, let rawScript = self.serializationCharacters(curSvgString) {
            let script = self.function + "(\(rawScript))"
            self.displayView.evaluateJavaScript(script, completionHandler: nil)
            LKSVGDisplayView.logger.info("LKSVGDisplayView Load SvgString")
            self.progressView.hide(animated: true)
        }
    }
}

extension LKSVGDisplayView: LKAssetPageView {

    func recoverToInitialState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let scrollView = self.displayView.scrollView
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
    }

    var dismissFrame: CGRect {
        return .zero
    }

    var dismissImage: UIImage? {
        return nil
    }

    func handleSwipeDown() {}

    func prepareDisplayAsset(completion: @escaping () -> Void) {
        self.displaySVG(completion: completion)
    }

    func handleCurrentDisplayAsset() {}

    func handleTranslateProcess(baseView: UIView,
                                cancelHandler: @escaping () -> Void,
                                processHandler: @escaping (@escaping () -> Void, @escaping (Bool, LKDisplayAsset?) -> Void) -> Void,
                                dataSourceUpdater: @escaping (LKDisplayAsset) -> Void) {
    }
}
