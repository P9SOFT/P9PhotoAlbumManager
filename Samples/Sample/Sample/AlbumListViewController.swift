//
//  AlbumListViewController.swift
//  Sample
//
//  Created by Tae Hyun Na on 2016. 2. 25.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit

class AlbumListViewController: UIViewController {
    
    private var createAlbumButton:UIButton = UIButton(type: .custom)
    private var editAlbumButton:UIButton = UIButton(type: .custom)
    private var albumTableView:UITableView = UITableView(frame: .zero)

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoAlbumManagerReport(_:)), name: .P9PhotoAlbumManager, object: nil)
        
        automaticallyAdjustsScrollViewInsets = false;
        view.backgroundColor = UIColor.white
        
        createAlbumButton.setTitle("➕", for: .normal)
        createAlbumButton.addTarget(self, action: #selector(createAlbumButtonTouchUpInside(sender:)), for: .touchUpInside)
        createAlbumButton.isHidden = true
        
        editAlbumButton.setTitle("EDIT", for: .normal)
        editAlbumButton.setTitleColor(.black, for: .normal)
        editAlbumButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        editAlbumButton.addTarget(self, action: #selector(editAlbumButtonTouchUpInside(sender:)), for: .touchUpInside)
        
        albumTableView.register(UINib(nibName:"AlbumRecordTableViewCell", bundle:nil), forCellReuseIdentifier:"AlbumRecordTableViewCell")
        albumTableView.dataSource = self
        albumTableView.delegate = self
        albumTableView.backgroundColor = UIColor.clear
        
        view.addSubview(albumTableView)
        view.addSubview(createAlbumButton)
        view.addSubview(editAlbumButton)
        
        // request album list, and write code for result handling.
        // you can write code for result handling with response of notification handler 'photoAlbumManagerReport' as below.
        
        let cameraRoll = P9PhotoAlbumManager.AlbumInfo.init(type: .cameraRoll)
        let favorite = P9PhotoAlbumManager.AlbumInfo.init(type: .favorite)
        let recentlyAdded = P9PhotoAlbumManager.AlbumInfo.init(type: .recentlyAdded)
        let screenshots = P9PhotoAlbumManager.AlbumInfo.init(type: .screenshots)
        let videos = P9PhotoAlbumManager.AlbumInfo.init(type: .videos, mediaTypes: [.video], ascending: false)
        let regular = P9PhotoAlbumManager.AlbumInfo.init(type: .regular)
        let albumInfos = [cameraRoll, favorite, recentlyAdded, screenshots, videos, regular]
        
        if P9PhotoAlbumManager.shared.authorized == false {
            P9PhotoAlbumManager.shared.authorization { (operation, status) in
                if status == .succeed {
                    P9PhotoAlbumManager.shared.requestAlbums(byInfos: albumInfos) { (operation, status) in
                        self.albumTableView.reloadData()
                    }
                } else {
                    let alert = UIAlertController(title: "Need Authorization", message: "You need to move setting to give access authorization of photo for this app", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            return;
        }
        
        P9PhotoAlbumManager.shared.requestAlbums(byInfos: albumInfos) { (operation, status) in
            self.albumTableView.reloadData()
        }
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        albumTableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        var frame:CGRect = .zero
        
        frame.size = CGSize(width: 30, height: 30)
        frame.origin.x = 20
        frame.origin.y = UIApplication.shared.statusBarFrame.size.height + 5
        createAlbumButton.frame = frame
        
        frame.size = CGSize(width: 40, height: 30)
        frame.origin.x = self.view.bounds.size.width - 20 - frame.size.width
        frame.origin.y = UIApplication.shared.statusBarFrame.size.height + 5
        editAlbumButton.frame = frame
        
        frame = self.view.bounds
        frame.origin.y += (UIApplication.shared.statusBarFrame.size.height + 40)
        frame.size.height -= (UIApplication.shared.statusBarFrame.size.height + 40)
        albumTableView.frame = frame
    }
    
    @objc func photoAlbumManagerReport(_ notification:Notification) {
        
        // you can write code as below for result handling, but in this case, just print log.
        // because we already pass the code for result handler when requesting data at 'viewDidLoad'.
        if let userInfo = notification.userInfo, let operation = userInfo[P9PhotoAlbumManager.NotificationOperationKey] as? P9PhotoAlbumManager.Operation, let status = userInfo[P9PhotoAlbumManager.NotificationStatusKey] as? P9PhotoAlbumManager.Status  {
            print("Operatoin[\(operation.rawValue)], Status[\(status.rawValue)]")
            if operation == .reload {
                albumTableView.reloadData()
            }
        }
    }
    
    @objc func createAlbumButtonTouchUpInside(sender:UIButton) {
        
        let alert = UIAlertController(title: "Create Album", message: "Enter album title to create", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Album Title"
            textField.textColor = .black
        }
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { (action) in
            if let textField = alert.textFields?.first, let title = textField.text {
                P9PhotoAlbumManager.shared.createAlbum(title: title, mediaTypes: [.image], ascending: false, completion: { (operation, status) in
                    self.albumTableView.reloadData()
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func editAlbumButtonTouchUpInside(sender:UIButton) {
        
        if albumTableView.isEditing == false {
            createAlbumButton.isHidden = false
            albumTableView.setEditing(true, animated: true)
            editAlbumButton.setTitle("DONE", for: .normal)
        } else {
            createAlbumButton.isHidden = true
            albumTableView.setEditing(false, animated: true)
            editAlbumButton.setTitle("EDIT", for: .normal)
        }
    }
}

extension AlbumListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView:UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        
        return P9PhotoAlbumManager.shared.numberOfAlbums()
    }
    
    func tableView(_ tableView:UITableView, heightForRowAt indexPath:IndexPath) -> CGFloat {
        
        return 80
    }
    
    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        
        if let cell = albumTableView.dequeueReusableCell(withIdentifier: "AlbumRecordTableViewCell") as? AlbumRecordTableViewCell {
            cell.coverImageView.image = P9PhotoAlbumManager.shared.imageOfMedia(forIndex: 0, atAlbumIndex: indexPath.row, targetSize: CGSize.init(width: 80, height: 80), contentMode: .aspectFill)
            cell.titleLabel.text = P9PhotoAlbumManager.shared.titleOfAlbum(forIndex: indexPath.row)
            cell.countLabel.text = "\(P9PhotoAlbumManager.shared.numberOfMediaAtAlbum(forIndex: indexPath.row))"
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView:UITableView, didSelectRowAt indexPath:IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated:true)
        let photoListViewController = PhotoListViewController()
        photoListViewController.albumIndex = indexPath.row
        navigationController?.pushViewController(photoListViewController, animated:true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if let type = P9PhotoAlbumManager.shared.predefineTypeOfAlbum(forIndex: indexPath.row), type == .regular {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        if let type = P9PhotoAlbumManager.shared.predefineTypeOfAlbum(forIndex: indexPath.row), type == .regular {
            return .delete
        }
        return .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            P9PhotoAlbumManager.shared.deleteAlbum(index: indexPath.row) { (operation, status) in
                self.albumTableView.reloadData()
            }
        }
    }
}

