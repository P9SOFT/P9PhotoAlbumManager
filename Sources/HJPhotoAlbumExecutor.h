//
//  HJPhotoAlbumExecutor.h
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 11. 4.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

@import UIKit;
@import Photos;
#import <Hydra/Hydra.h>

#define     HJPhotoAlbumExecutorName                    @"HJPhotoAlbumExecutorName"

#define     HJPhotoAlbumExecutorParameterKeyStatus          @"HJPhotoAlbumExecutorParameterKeyStatus"
#define     HJPhotoAlbumExecutorParameterKeyOperation       @"HJPhotoAlbumExecutorParameterKeyOperation"
#define     HJPhotoAlbumExecutorParameterKeyAlbumIndex      @"HJPhotoAlbumExecutorParameterKeyAlbumIndex"
#define     HJPhotoAlbumExecutorParameterKeyMediaType       @"HJPhotoAlbumExecutorParameterKeyMediaType"
#define     HJPhotoAlbumExecutorParameterKeyCompletionBlock @"HJPhotoAlbumExecutorParameterKeyCompletionBlock"
#define     HJPhotoAlbumExecutorParameterKeyAlbums          @"HJPhotoAlbumExecutorParameterKeyAlbums"
#define     HJPhotoAlbumExecutorParameterKeyAssetsForAlbums @"HJPhotoAlbumExecutorParameterKeyAssetsForAlbums"

typedef enum _HJPhotoAlbumExecutorOperation_
{
    HJPhotoAlbumExecutorOperationRequestAllAlbumsAndAssets,
    HJPhotoAlbumExecutorOperationRequestAllAlbums,
    HJPhotoAlbumExecutorOperationRequestAllAssetsForAlbums
    
} HJPhotoAlbumExecutorOperation;

typedef enum _HJPhotoAlbumExecutorStatus_
{
    HJPhotoAlbumExecutorStatusDummy,
    HJPhotoAlbumExecutorStatusAllAlbumsAndAssetsReady,
    HJPhotoAlbumExecutorStatusAllAlbumsReady,
    HJPhotoAlbumExecutorStatusAllAssetsForAlbumsReady,
    HJPhotoAlbumExecutorStatusCanceled,
    HJPhotoAlbumExecutorStatusUnknownOperation,
    HJPhotoAlbumExecutorStatusInvalidParameter,
    HJPhotoAlbumExecutorStatusInternalError
    
} HJPhotoAlbumExecutorStatus;

@interface HJPhotoAlbumExecutor : HYExecuter

@end