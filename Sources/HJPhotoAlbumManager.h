//
//  HJPhotoAlbumManager.h
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 11. 4.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

@import UIKit;
@import Photos;
#import <Hydra/Hydra.h>

#define     HJPhotoAlbumManagerNotification                 @"HJPhotoAlbumManagerNotification"

#define     HJPhotoAlbumManagerParameterKeyStatus           @"HJPhotoAlbumManagerParameterKeyStatus"
#define     HJPhotoAlbumManagerParameterKeyAlbumIndex       @"HJPhotoAlbumManagerParameterKeyAlbumIndex"
#define     HJPhotoAlbumManagerParameterKeyMediaType        @"HJPhotoAlbumManagerParameterKeyMediaType"

typedef enum _HJPhotoAlbumManagerStatus_
{
    HJPhotoAlbumManagerStatusIdle,
    HJPhotoAlbumManagerStatusRequesingAllAlbumsAndAssets,
    HJPhotoAlbumManagerStatusRequestingAllAlbums,
    HJPhotoAlbumManagerStatusRequestingAllAssetsForAlbum,
    HJPhotoAlbumManagerStatusAllAlbumsAndAssetsReady,
    HJPhotoAlbumManagerStatusAllAlbumsReady,
    HJPhotoAlbumManagerStatusAllAssetsForAlbumReady,
    HJPhotoAlbumManagerStatusAccessDenied,
    HJPhotoAlbumManagerStatusInternalError
    
} HJPhotoAlbumManagerStatus;

typedef enum _HJPhotoAlbumManagerOperation_
{
    HJPhotoAlbumManagerOperationRequestAllAlbumsAndAssets,
    HJPhotoAlbumManagerOperationRequestAllAlbums,
    HJPhotoAlbumManagerOperationRequestAllAssetsForAlbum
    
} HJPhotoAlbumManagerOperation;

typedef enum _HJPhotoAlbummanagerMediaType_
{
    HJPhotoAlbumManagerMediaTypeImage,
    HJPhotoAlbumManagerMediaTypeVideo,
    HJPhotoAlbumManagerMediaTypeAudio
    
} HJPhotoAlbumManagerMediaType;

typedef void(^HJPhotoAlbumManagerCompletion)(HJPhotoAlbumManagerStatus);

@interface HJPhotoAlbumManager : HYManager

+ (HJPhotoAlbumManager *)sharedManager;

- (BOOL)standbyWithWorkerName:(NSString *)workerName;

- (void)requestOperation:(HJPhotoAlbumManagerOperation)operation operandDict:(NSDictionary *)operandDict completion:(HJPhotoAlbumManagerCompletion)completion;
- (void)clearCache;

- (NSUInteger)numberOfAlbums;
- (NSString *)nameForAlbumIndex:(NSInteger)albumIndex;
- (NSUInteger)numberOfAssetsForAlbumIndex:(NSInteger)albumIndex;
- (UIImage *)posterImageForAlbumIndex:(NSInteger)albumIndex;
- (UIImage *)thumbnailImageOfAssetIndex:(NSInteger)assetIndex forAlbumIndex:(NSInteger)albumIndex;
- (UIImage *)imageOfAssetIndex:(NSInteger)assetIndex forAlbumIndex:(NSInteger)albumIndex;

@property (nonatomic, readonly) BOOL standby;
@property (nonatomic, readonly) NSString *workerName;

@end
