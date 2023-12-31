//
//  DocsSearchFactory.swift
//  SpaceInterface
//
//  Created by liujinwei on 2023/6/16.
//  


import Foundation
import LarkModel

public protocol DocsPickerFactory {
    func createDocsPicker(delegate: DocsPickerDelegate) -> UIViewController
}

public protocol DocsPickerDelegate: AnyObject {
    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool
    func pickerDidCancel()
}
