//
//  PhotoViewController.swift
//  Sample
//
//  Created by Tae Hyun Na on 2016. 2. 25.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit

class PhotoViewController: UIViewController, UIScrollViewDelegate {
    
    var albumIndex:Int?
    var assetIndex:Int?
    var scrollView:UIScrollView?
    var imageView:UIImageView?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false;
        self.view.backgroundColor = UIColor.whiteColor()
        
        if (albumIndex == nil) || (assetIndex == nil) {
            return
        }
        
        scrollView = UIScrollView()
        if scrollView == nil {
            return
        }
        scrollView!.delegate = self;
        scrollView!.minimumZoomScale = 1.0
        scrollView!.maximumZoomScale = 5.0
        scrollView!.backgroundColor = UIColor.clearColor()
        self.view.addSubview(scrollView!)
        
        imageView = UIImageView()
        if imageView == nil {
            return
        }
        imageView!.contentMode = UIViewContentMode.ScaleAspectFill
        scrollView?.addSubview(imageView!)
        
        // get the image data of asset.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let image = HJPhotoAlbumManager.sharedManager().imageOfAssetIndex(self.assetIndex!, forAlbumIndex:self.albumIndex!)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.imageView!.image = image
                self.view.setNeedsLayout()
            })
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        
        var frame:CGRect = self.view.bounds
        frame.origin.y += UIApplication.sharedApplication().statusBarFrame.size.height
        frame.size.height -= UIApplication.sharedApplication().statusBarFrame.size.height
        scrollView?.frame = frame
        if let image = imageView?.image {
            var imageFrame = CGRectZero
            if frame.size.width < frame.size.height {
                imageFrame.size.width = scrollView!.bounds.size.width
                imageFrame.size.height = image.size.height * (scrollView!.bounds.size.width/image.size.width)
            } else {
                imageFrame.size.height = scrollView!.bounds.size.height
                imageFrame.size.width = image.size.width * (scrollView!.bounds.size.height/image.size.height)
            }
            imageFrame.size.width *= scrollView!.zoomScale
            imageFrame.size.height *= scrollView!.zoomScale
            scrollView!.contentSize = imageFrame.size
            imageView!.frame = imageFrame
            imageView!.image = image
            updateUpdateToCenterOfViewForScrollView(imageView!, scrollView:scrollView!)
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        
        return imageView
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        print( scrollView.zoomScale, scrollView.contentSize )
        if imageView != nil {
            self.updateUpdateToCenterOfViewForScrollView(imageView!, scrollView:scrollView)
        }
    }
    
    private func updateUpdateToCenterOfViewForScrollView(view:UIView, scrollView:UIScrollView) {
        
        let containerSize = scrollView.bounds.size
        var frame = view.frame
        frame.origin.x = (frame.size.width < containerSize.width) ? ((containerSize.width-frame.size.width)/2.0) : 0.0
        frame.origin.y = (frame.size.height < containerSize.height) ? ((containerSize.height-frame.size.height)/2.0) : 0.0
        view.frame = frame
    }
}
