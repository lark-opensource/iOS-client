//
//  LKNativeAvatar.swift
//  Demo
//
//  Created by tefeng liu on 2020/11/4.
//

import Foundation
import LarkWebviewNativeComponent

class NativeAvatarComponent: UIView, NativeComponentAble {
    func willBeRemovedComponent(params: [String : Any]) {

    }


    required init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.green
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var nativeView: UIView {
        return self
    }

    static var tagName: String {
        return "lk-native-avatar"
    }

    func willInsertComponent(params: [String : Any]) {
        print("willInsertComponent \(params)")
    }

    func didInsertComponent(params: [String : Any]) {
        print("didInsertComponent \(params)")
        fireEvent(name: "fuck", params: ["hello": "hhhh"])
    }

    func updateCompoent(params: [String : Any]) {
        print("updateCompoent \(params)")
    }
}
