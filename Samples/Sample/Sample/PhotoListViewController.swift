//
//  PhotoListViewController.swift
//  Sample
//
//  Created by Tae Hyun Na on 2016. 2. 25.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit

class PhotoListViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var albumIndex:Int?
    var flowlayout:UICollectionViewFlowLayout?
    var photoListCollectionView:UICollectionView?
    let separatorWidth:CGFloat = 5.0
    let columnCountPerRow:CGFloat = 4.0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false;
        self.view.backgroundColor = UIColor.white
        
        if albumIndex == nil {
            return
        }
        
        flowlayout = UICollectionViewFlowLayout()
        if flowlayout == nil {
            return
        }
        let length = (self.view.bounds.size.width - (separatorWidth*columnCountPerRow))/columnCountPerRow
        flowlayout!.itemSize = CGSize(width:length, height:length)
        flowlayout!.minimumInteritemSpacing = 0;
        flowlayout!.minimumLineSpacing = separatorWidth;
        
        photoListCollectionView = UICollectionView(frame:CGRect.zero, collectionViewLayout:flowlayout!)
        if photoListCollectionView == nil {
            return
        }
        let nibName = UINib(nibName:"PhotoRecordCollectionViewCell", bundle:nil)
        photoListCollectionView!.register(nibName, forCellWithReuseIdentifier:"PhotoRecordCollectionViewCell")
        photoListCollectionView!.dataSource = self
        photoListCollectionView!.delegate = self
        photoListCollectionView!.backgroundColor = UIColor.clear
        photoListCollectionView!.alwaysBounceVertical = true
        self.view.addSubview(photoListCollectionView!)
        
        if albumIndex != nil {
            // request asset list of specified album, and write code for result handling.
            HJPhotoAlbumManager.default().request(.requestAllAssetsForAlbum, operandDict: [HJPhotoAlbumManagerParameterKeyAlbumIndex:NSNumber(value: albumIndex! as Int)], completion: { (status:HJPhotoAlbumManagerStatus) in
                self.photoListCollectionView?.reloadData()
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        let length = (self.view.bounds.size.width - (separatorWidth*columnCountPerRow))/columnCountPerRow
        flowlayout?.itemSize = CGSize(width:length, height:length)
        var frame:CGRect = self.view.bounds
        frame.origin.x += separatorWidth
        frame.origin.y += UIApplication.shared.statusBarFrame.size.height
        frame.size.height -= UIApplication.shared.statusBarFrame.size.height
        frame.size.width -= (separatorWidth*2.0)
        photoListCollectionView?.frame = frame
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if self.albumIndex == nil {
            return 0
        }
        
        return Int(HJPhotoAlbumManager.default().numberOfAssets(forAlbumIndex: self.albumIndex!))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell:PhotoRecordCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoRecordCollectionViewCell", for: indexPath) as! PhotoRecordCollectionViewCell
        if self.albumIndex != nil {
            cell.photoImageView.image = HJPhotoAlbumManager.default().thumbnailImage(ofAssetIndex: indexPath.row, forAlbumIndex:self.albumIndex!)
        }
        return cell;
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated:true)
        let photoViewController = PhotoViewController()
        photoViewController.albumIndex = self.albumIndex!
        photoViewController.assetIndex = indexPath.row
        self.navigationController?.pushViewController(photoViewController, animated:true)
    }
}

