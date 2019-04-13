//
//  PhotoRecordCollectionViewCell.swift
//  Sample
//
//  Created by Tae Hyun Na on 2016. 2. 25.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit

protocol PhotoRecordCollectionViewCellDelegate: class {
    
    func deleteButtonTouchUpInside(index:Int)
}

class PhotoRecordCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    var index:Int?
    weak var delegate:PhotoRecordCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        deleteButton.addTarget(self, action: #selector(deleteButtonTouchUpInside(sender:)), for: .touchUpInside)
    }
    
    @objc func deleteButtonTouchUpInside(sender:UIButton) {
        
        if let index = index {
            delegate?.deleteButtonTouchUpInside(index: index)
        }
    }
}
