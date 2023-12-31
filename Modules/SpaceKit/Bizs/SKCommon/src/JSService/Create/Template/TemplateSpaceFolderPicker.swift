//
//  TemplateSpaceFolderPicker.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/6/3.
//  

import Foundation

public protocol TemplateSpaceFolderPickerCreator {
    func createPicker(with completion: @escaping (_ folderToken: String, _ folderVersion: Int, _ controller: UIViewController) -> Void) -> UIViewController
}
