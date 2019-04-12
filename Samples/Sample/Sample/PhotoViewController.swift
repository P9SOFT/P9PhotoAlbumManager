//
//  PhotoViewController.swift
//  Sample
//
//  Created by Tae Hyun Na on 2016. 2. 25.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit

class PhotoViewController: UIViewController {
    
    private var backButton:UIButton = UIButton(type: .custom)
    private var scrollView:UIScrollView = UIScrollView(frame: .zero)
    private var imageView:UIImageView = UIImageView(frame: .zero)
    
    var albumIndex:Int = 0
    var mediaIndex:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false;
        self.view.backgroundColor = UIColor.white
        
        backButton.setTitle("🔙", for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTouchUpInside(sender:)), for: .touchUpInside)
        
        scrollView.delegate = self;
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.backgroundColor = UIColor.clear
        
        imageView.contentMode = UIView.ContentMode.scaleAspectFill
        
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        view.addSubview(backButton)
        
        // get the image data of asset.
        DispatchQueue.global(qos: .background).async {
            if let image = P9PhotoAlbumManager.shared.imageOfMedia(forIndex: self.mediaIndex, atAlbumIndex: self.albumIndex, targetSize: P9PhotoAlbumManager.maximumImageSize, contentMode: .aspectFill) {
                DispatchQueue.main.async {
                    self.imageView.image = image
                    self.view.setNeedsLayout()
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        var frame:CGRect = .zero
        
        frame.size = CGSize(width: 30, height: 30)
        frame.origin.x = 20
        frame.origin.y = UIApplication.shared.statusBarFrame.size.height + 5
        backButton.frame = frame
        
        frame = self.view.bounds
        frame.origin.y += (UIApplication.shared.statusBarFrame.size.height + 40)
        frame.size.height -= (UIApplication.shared.statusBarFrame.size.height + 40)
        scrollView.frame = frame
        if let image = imageView.image {
            var imageFrame = CGRect.zero
            if frame.size.width < frame.size.height {
                imageFrame.size.width = scrollView.bounds.size.width
                imageFrame.size.height = image.size.height * (scrollView.bounds.size.width/image.size.width)
            } else {
                imageFrame.size.height = scrollView.bounds.size.height
                imageFrame.size.width = image.size.width * (scrollView.bounds.size.height/image.size.height)
            }
            imageFrame.size.width *= scrollView.zoomScale
            imageFrame.size.height *= scrollView.zoomScale
            scrollView.contentSize = imageFrame.size
            imageView.frame = imageFrame
            imageView.image = image
            updateUpdateToCenterOfViewForScrollView(imageView, scrollView:scrollView)
        }
    }
    
    private func updateUpdateToCenterOfViewForScrollView(_ view:UIView, scrollView:UIScrollView) {
        
        let containerSize = scrollView.bounds.size
        var frame = view.frame
        frame.origin.x = (frame.size.width < containerSize.width) ? ((containerSize.width-frame.size.width)/2.0) : 0.0
        frame.origin.y = (frame.size.height < containerSize.height) ? ((containerSize.height-frame.size.height)/2.0) : 0.0
        view.frame = frame
    }
    
    @objc func backButtonTouchUpInside(sender:UIButton) {
        
        navigationController?.popViewController(animated: true)
    }
}

extension PhotoViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return imageView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        self.updateUpdateToCenterOfViewForScrollView(imageView, scrollView:scrollView)
    }
}
