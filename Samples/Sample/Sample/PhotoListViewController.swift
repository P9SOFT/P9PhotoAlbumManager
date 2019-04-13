//
//  PhotoListViewController.swift
//  Sample
//
//  Created by Tae Hyun Na on 2016. 2. 25.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit
import AVKit

class PhotoListViewController: UIViewController {
    
    private let separatorWidth:CGFloat = 5.0
    private let columnCountPerRow:CGFloat = 4.0
    private let titleLabel:UILabel = UILabel(frame: .zero)
    private var backButton:UIButton = UIButton(type: .custom)
    private var editMediaButton:UIButton = UIButton(type: .custom)
    private var flowlayout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    private lazy var photoListCollectionView:UICollectionView = UICollectionView(frame:CGRect.zero, collectionViewLayout:flowlayout)
    private var mediaEditing:Bool = false
    
    var albumIndex:Int = 0 {
        didSet {
            // request asset list of specified album, and write code for result handling.
            P9PhotoAlbumManager.shared.requestMedia(atAlbumIndex: albumIndex) { (operation, status) in
                self.photoListCollectionView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoAlbumManagerReport(_:)), name: .P9PhotoAlbumManager, object: nil)
        
        automaticallyAdjustsScrollViewInsets = false;
        view.backgroundColor = UIColor.white
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = .black
        titleLabel.text = P9PhotoAlbumManager.shared.titleOfAlbum(forIndex: albumIndex)
        
        backButton.setTitle("🔙", for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTouchUpInside(sender:)), for: .touchUpInside)
        
        editMediaButton.setTitle("EDIT", for: .normal)
        editMediaButton.setTitleColor(.black, for: .normal)
        editMediaButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        editMediaButton.addTarget(self, action: #selector(editMediaButtonTouchUpInside(sender:)), for: .touchUpInside)
        
        let length = (view.bounds.size.width - (separatorWidth*columnCountPerRow))/columnCountPerRow
        flowlayout.itemSize = CGSize(width:length, height:length)
        flowlayout.minimumInteritemSpacing = 0;
        flowlayout.minimumLineSpacing = separatorWidth;
        
        photoListCollectionView.register(UINib(nibName:"PhotoRecordCollectionViewCell", bundle:nil), forCellWithReuseIdentifier:"PhotoRecordCollectionViewCell")
        photoListCollectionView.dataSource = self
        photoListCollectionView.delegate = self
        photoListCollectionView.backgroundColor = UIColor.clear
        photoListCollectionView.alwaysBounceVertical = true
        
        view.addSubview(photoListCollectionView)
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(editMediaButton)
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
        
        photoListCollectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let length = (self.view.bounds.size.width - (separatorWidth*columnCountPerRow))/columnCountPerRow
        flowlayout.itemSize = CGSize(width:length, height:length)
        
        var frame:CGRect = .zero
        
        frame.size.width = self.view.bounds.size.width - 100
        frame.size.height = 30
        frame.origin.x = (self.view.bounds.size.width - frame.size.width)*0.5
        frame.origin.y = UIApplication.shared.statusBarFrame.size.height + 5
        titleLabel.frame = frame
        
        frame.size = CGSize(width: 30, height: 30)
        frame.origin.x = 20
        frame.origin.y = UIApplication.shared.statusBarFrame.size.height + 5
        backButton.frame = frame
        
        frame.size = CGSize(width: 40, height: 30)
        frame.origin.x = self.view.bounds.size.width - 20 - frame.size.width
        frame.origin.y = UIApplication.shared.statusBarFrame.size.height + 5
        editMediaButton.frame = frame
        
        frame = self.view.bounds
        frame.origin.x += separatorWidth
        frame.origin.y += (UIApplication.shared.statusBarFrame.size.height + 40)
        frame.size.height -= (UIApplication.shared.statusBarFrame.size.height + 40)
        frame.size.width -= (separatorWidth*2.0)
        photoListCollectionView.frame = frame
    }
    
    @objc func photoAlbumManagerReport(_ notification:Notification) {
        
        // you can write code as below for result handling, but in this case, just print log.
        if let userInfo = notification.userInfo, let operation = userInfo[P9PhotoAlbumManager.NotificationOperationKey] as? P9PhotoAlbumManager.Operation  {
            if operation == .reload {
                titleLabel.text = P9PhotoAlbumManager.shared.titleOfAlbum(forIndex: albumIndex) ?? "!! NOT FOUND !!"
                photoListCollectionView.reloadData()
            }
        }
    }
    
    @objc func backButtonTouchUpInside(sender:UIButton) {
        
        if mediaEditing == false {
            navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController(title: "Append Media", message: "Enter URL of media to append", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "Media URL"
                textField.textColor = .black
                textField.text = "http://www.p9soft.com/images/background.png"
            }
            alert.addAction(UIAlertAction(title: "Append", style: .default, handler: { (action) in
                if let textField = alert.textFields?.first, let urlString = textField.text, let url = URL(string:urlString) {
                    do {
                        let data = try Data(contentsOf: url)
                        if let image = UIImage(data: data) {
                            P9PhotoAlbumManager.shared.savePhotoImage(image: image, toAlbumIndex: self.albumIndex) { (operation, status) in
                                if status == .succeed {
                                    self.photoListCollectionView.reloadData()
                                }
                            }
                        }
                    } catch {}
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func editMediaButtonTouchUpInside(sender:UIButton) {
        
        if mediaEditing == false {
            mediaEditing = true
            backButton.setTitle("➕", for: .normal)
            editMediaButton.setTitle("DONE", for: .normal)
        } else {
            mediaEditing = false
            backButton.setTitle("🔙", for: .normal)
            editMediaButton.setTitle("EDIT", for: .normal)
        }
        photoListCollectionView.reloadData()
    }
}

extension PhotoListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return P9PhotoAlbumManager.shared.numberOfMediaAtAlbum(forIndex: albumIndex)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell:PhotoRecordCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoRecordCollectionViewCell", for: indexPath) as? PhotoRecordCollectionViewCell {
            cell.photoImageView.image = P9PhotoAlbumManager.shared.imageOfMedia(forIndex: indexPath.row, atAlbumIndex: albumIndex, targetSize: CGSize.init(width: 80, height: 80), contentMode: .aspectFill)
            cell.deleteButton.isHidden = (mediaEditing == false)
            cell.index = indexPath.row
            cell.delegate = self
            return cell
        }
        
        return UICollectionViewCell(frame: .zero)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated:true)
        if mediaEditing == false {
            let mediaType = P9PhotoAlbumManager.shared.mediaTypeOfMedia(forIndex: indexPath.row, atAlbumIndex: albumIndex)
            switch mediaType {
            case .image :
                let photoViewController = PhotoViewController()
                photoViewController.albumIndex = albumIndex
                photoViewController.mediaIndex = indexPath.row
                navigationController?.pushViewController(photoViewController, animated:true)
                break
            case .video, .audio :
                if let fileUrl = P9PhotoAlbumManager.shared.fileUrlOfMedia(forIndex: indexPath.row, atAlbumIndex: albumIndex) {
                    let playerViewController = AVPlayerViewController()
                    playerViewController.player = AVPlayer(url: fileUrl)
                    self.present(playerViewController, animated: true) {
                        playerViewController.player!.play()
                    }
                }
                break
            default :
                break
            }
        }
    }
}

extension PhotoListViewController: PhotoRecordCollectionViewCellDelegate {
    
    func deleteButtonTouchUpInside(index: Int) {
        
        P9PhotoAlbumManager.shared.deleteMedia(index: index, fromAlbumIndex: albumIndex) { (operation, status) in
            if status == .succeed {
                self.photoListCollectionView.reloadData()
            }
        }
    }
}
