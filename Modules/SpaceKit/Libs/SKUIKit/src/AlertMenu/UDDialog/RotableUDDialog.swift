//
//  RotableUDDialog.swift
//  SKUIKit
//
//  Created by ZhangYuanping on 2023/6/15.
//  


import UniverseDesignDialog


public class RotatableUDDialog: UDDialog {

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}
