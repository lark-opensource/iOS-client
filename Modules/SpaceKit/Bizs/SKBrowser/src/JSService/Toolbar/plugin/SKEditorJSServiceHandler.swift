//
//  SKEditorJSServiceHandler.swift
//  SKBrowser
//
//  Created by LiXiaolin on 2020/8/25.
//  


import Foundation
import SwiftyJSON
import SKCommon
import LarkWebViewContainer
import SpaceInterface

protocol SKEditorJSServiceProtocol: SKExecJSService {
    func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?)

    func editorDidReady()
    func editorDidContentChange(params: [String: Any])

    func editorDidFinishedInsertImages()
    func editorOpenImages(params: [String: Any])
    func editorResizeHeight(params: [String: Any])

    func showPanel(panel: MentionPanel)
    func hidePanel()
    func didSelect(at mentionInfo: MentionInfo, callback: String)
    func didClick(with name: String, openID: String)
}

class SKEditorJSServiceHandler: JSServiceHandler {

    var handleServices: [DocsJSService] = [
        .skNotifyReady,
        .navToolBar,
        .pickImage, //点击工具栏的图片按钮
        .utilOpenImage, //点击文档中的图片进行打开
        .utilAtFinder, //@人
        .utilProfile, //点击人名
        .highlightPanelJsName, //背景色面板
        .simulateFinishPickingImage, //选择了图片
        .onKeyboardChanged, //键盘高度发生了变化
        .simulateKeyboardChange, //键盘高度发生了变化
        .docToolBarJsNameV2,
        .insertBlockJsName,
        .clipboardSetContent,
        .clipboardGetContent,
        .clipboardSetEncryptId
    ]

    private var pickImageMethod: String = ""
    var imageMaxWidth: CGFloat = 1000
    var imageMaxHeight: CGFloat = 1000
    var imageMaxSize: CGFloat = 20_480

    public weak var delegate: SKEditorJSServiceProtocol?

    /// 收到docs前端的调用info
    func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        let service = DocsJSService(rawValue: serviceName)
        switch service {
        case .skNotifyReady:
            delegate?.editorDidReady()
        case .navToolBar, .highlightPanelJsName, .pickImage, .onKeyboardChanged, .docToolBarJsNameV2, .insertBlockJsName, .clipboardSetContent, .clipboardGetContent, .clipboardSetEncryptId:
            delegate?.handle(params: params, serviceName: serviceName, callback: callback)
        case .utilOpenImage:
            delegate?.editorOpenImages(params: params)
        case .utilAtFinder:
            delegate?.handle(params: params, serviceName: serviceName, callback: callback)
        case .utilProfile:
            delegate?.didClick(with: params["name"] as? String ?? "", openID: params["userId"] as? String ?? "")
        default:
            handle(params: params, serviceName: serviceName)
        }
    }

    func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(rawValue: serviceName)
        switch service {
        case .simulateFinishPickingImage, .simulateKeyboardChange:
            delegate?.handle(params: params, serviceName: serviceName, callback: nil)
        default:
            ()
        }
    }


//    /// call front end's js to upload images
//    ///
//    /// - Parameter images: images to uplaod
//    private func jsInsertImages(_ images: [UIImage], isOriginal: Bool) {
//        DispatchQueue.main.async {
//            if let res = self.makeResJson(images: images, code: 0).jsonString {
//                let js = self.pickImageMethod + "(\(res))"
//                self.delegate?.evaluateJavaScript(js, completionHandler: nil)
//            }
//            self.delegate?.editorDidFinishedInsertImages()
//        }
//    }

//    func insertImages(_ images: [[String: Any]]) {
//        DispatchQueue.main.async {
//            if let res = self.makeResJson(images: images, code: 0).jsonString {
//                let js = self.pickImageMethod + "(\(res))"
//                self.delegate?.evaluateJavaScript(js, completionHandler: nil)
//            }
//            self.delegate?.editorDidFinishedInsertImages()
//        }
//    }

//    private func makeResJson(images imageArr: [Any], code: Int) -> [String: Any] {
//        return [
//            "code": code,
//            "thumbs": imageArr
//            ] as [String: Any]
//    }
}
