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
        
        NotificationCenter.default.addObserver(self, selector:#selector(AlbumListViewController.photoAlbumManagerReport(_:)), name:NSNotification.Name(rawValue: HJPhotoAlbumManagerNotification), object: nil)
        
        self.automaticallyAdjustsScrollViewInsets = false;
        self.view.backgroundColor = UIColor.white
        
        albumTableView = UITableView()
        if albumTableView == nil {
            return
        }
        let nibName = UINib(nibName:"AlbumRecordTableViewCell", bundle:nil)
        albumTableView!.register(nibName, forCellReuseIdentifier:"AlbumRecordTableViewCell")
        albumTableView!.dataSource = self
        albumTableView!.delegate = self
        albumTableView!.backgroundColor = UIColor.clear
        self.view.addSubview(albumTableView!)
        
        // request album list, and write code for result handling.
        // you can write code for result handling with response of notification handler 'photoAlbumManagerReport' as below.
        HJPhotoAlbumManager.default().request(.requestAllAlbums, operandDict: nil) { (status:HJPhotoAlbumManagerStatus) in
            self.albumTableView?.reloadData()
        }
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        var frame:CGRect = self.view.bounds
        frame.origin.y += UIApplication.shared.statusBarFrame.size.height
        frame.size.height -= UIApplication.shared.statusBarFrame.size.height
        albumTableView?.frame = frame
    }
    
    func photoAlbumManagerReport(_ notification:Notification) {
        
        // you can write code as below for result handling, but in this case, just print log.
        // because we already pass the code for result handler when requesting data at 'viewDidLoad'.
        if let userInfo = notification.userInfo {
            if let statusNumber = userInfo[HJPhotoAlbumManagerParameterKeyStatus] as? Int {
                let status = HJPhotoAlbumManagerStatus(rawValue:statusNumber)
                print(status ?? "??")
            }
        }
        
    }
    
    func numberOfSections(in tableView:UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        
        return Int(HJPhotoAlbumManager.default().numberOfAlbums())
    }
    
    func tableView(_ tableView:UITableView, heightForRowAt indexPath:IndexPath) -> CGFloat {
        
        return 80
    }
    
    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        
        let cell:AlbumRecordTableViewCell = albumTableView!.dequeueReusableCell(withIdentifier: "AlbumRecordTableViewCell")! as! AlbumRecordTableViewCell
        cell.coverImageView.image = HJPhotoAlbumManager.default().posterImage(forAlbumIndex: indexPath.row)
        cell.titleLabel.text = HJPhotoAlbumManager.default().name(forAlbumIndex: indexPath.row)
        cell.countLabel.text = "\(HJPhotoAlbumManager.default().numberOfAssets(forAlbumIndex: indexPath.row))"
        return cell
    }
    
    func tableView(_ tableView:UITableView, didSelectRowAt indexPath:IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated:true)
        let photoListViewController = PhotoListViewController()
        photoListViewController.albumIndex = indexPath.row
        self.navigationController?.pushViewController(photoListViewController, animated:true)
    }
}

