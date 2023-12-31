//
//  DriveVideoPlayerViewController+FollowState.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2022/2/23.
//  


import Foundation

extension DriveVideoPlayerViewController: DriveFollowContentProvider {
    
    var vcFollowAvailable: Bool {
        return true
    }
    
    var followScrollView: UIScrollView? {
        return nil
    }
    
    func setup(followDelegate: DriveFollowAPIDelegate, mountToken: String?) {
        viewModel.setup(followDelegate: followDelegate, mountToken: mountToken)
    }
    
    func registerFollowableContent() {
        viewModel.registerFollowableContent()
    }
}
