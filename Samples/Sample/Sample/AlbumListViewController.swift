//
//  AlbumListViewController.swift
//  Sample
//
//  Created by Tae Hyun Na on 2016. 2. 25.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit

class AlbumListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var albumTableView:UITableView?

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"photoAlbumManagerReport:", name:HJPhotoAlbumManagerNotification, object: nil)
        
        self.automaticallyAdjustsScrollViewInsets = false;
        self.view.backgroundColor = UIColor.whiteColor()
        
        albumTableView = UITableView()
        if albumTableView == nil {
            return
        }
        let nibName = UINib(nibName:"AlbumRecordTableViewCell", bundle:nil)
        albumTableView!.registerNib(nibName, forCellReuseIdentifier:"AlbumRecordTableViewCell")
        albumTableView!.dataSource = self
        albumTableView!.delegate = self
        albumTableView!.backgroundColor = UIColor.clearColor()
        self.view.addSubview(albumTableView!)
        
        // request album list, and write code for result handling.
        // you can write code for result handling with response of notification handler 'photoAlbumManagerReport' as below.
        HJPhotoAlbumManager.sharedManager().requestOperation(HJPhotoAlbumManagerOperationRequestAllAlbums, operandDict:nil) { (status:HJPhotoAlbumManagerStatus) -> Void in
            self.albumTableView?.reloadData()
        }
    }
    
    deinit {
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        
        var frame:CGRect = self.view.bounds
        frame.origin.y += UIApplication.sharedApplication().statusBarFrame.size.height
        frame.size.height -= UIApplication.sharedApplication().statusBarFrame.size.height
        albumTableView?.frame = frame
    }
    
    func photoAlbumManagerReport(notification:NSNotification) {
        
        // you can write code as below for result handling, but in this case, just print log.
        // because we already pass the code for result handler when requesting data at 'viewDidLoad'.
        if let userInfo = notification.userInfo {
            if let statusNumber = userInfo[HJPhotoAlbumManagerParameterKeyStatus] {
                let status = HJPhotoAlbumManagerStatus(rawValue:UInt32(statusNumber.integerValue))
                print(status)
            }
        }
        
    }
    
    func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        
        return Int(HJPhotoAlbumManager.sharedManager().numberOfAlbums())
    }
    
    func tableView(tableView:UITableView, heightForRowAtIndexPath indexPath:NSIndexPath) -> CGFloat {
        
        return 80
    }
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        
        let cell:AlbumRecordTableViewCell = albumTableView!.dequeueReusableCellWithIdentifier("AlbumRecordTableViewCell")! as! AlbumRecordTableViewCell
        cell.coverImageView.image = HJPhotoAlbumManager.sharedManager().posterImageForAlbumIndex(indexPath.row)
        cell.titleLabel.text = HJPhotoAlbumManager.sharedManager().nameForAlbumIndex(indexPath.row)
        cell.countLabel.text = "\(HJPhotoAlbumManager.sharedManager().numberOfAssetsForAlbumIndex(indexPath.row))"
        return cell
    }
    
    func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated:true)
        let photoListViewController = PhotoListViewController()
        photoListViewController.albumIndex = indexPath.row
        self.navigationController?.pushViewController(photoListViewController, animated:true)
    }
}

