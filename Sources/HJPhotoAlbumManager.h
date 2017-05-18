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

typedef NS_ENUM(NSInteger, HJPhotoAlbumManagerStatus)
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
};

typedef NS_ENUM(NSInteger, HJPhotoAlbumManagerOperation)
{
    HJPhotoAlbumManagerOperationRequestAllAlbumsAndAssets,
    HJPhotoAlbumManagerOperationRequestAllAlbums,
    HJPhotoAlbumManagerOperationRequestAllAssetsForAlbum
    
};

typedef NS_ENUM(NSInteger, HJPhotoAlbumManagerMediaType)
{
    HJPhotoAlbumManagerMediaTypeImage,
    HJPhotoAlbumManagerMediaTypeVideo,
    HJPhotoAlbumManagerMediaTypeAudio
    
};

typedef void(^HJPhotoAlbumManagerCompletion)(HJPhotoAlbumManagerStatus);

@interface HJPhotoAlbumManager : HYManager

+ (HJPhotoAlbumManager * _Nonnull)defaultHJPhotoAlbumManager;

- (BOOL)standbyWithWorkerName:(NSString * _Nullable)workerName;
- (BOOL)authorized;

- (void)requestOperation:(HJPhotoAlbumManagerOperation)operation operandDict:(NSDictionary * _Nullable)operandDict completion:(HJPhotoAlbumManagerCompletion _Nullable)completion;
- (void)clearCache;

- (NSUInteger)numberOfAlbums;
- (NSString * _Nullable)nameForAlbumIndex:(NSInteger)albumIndex;
- (NSUInteger)numberOfAssetsForAlbumIndex:(NSInteger)albumIndex;
- (UIImage * _Nullable)posterImageForAlbumIndex:(NSInteger)albumIndex;
- (UIImage * _Nullable)thumbnailImageOfAssetIndex:(NSInteger)assetIndex forAlbumIndex:(NSInteger)albumIndex;
- (UIImage * _Nullable)imageOfAssetIndex:(NSInteger)assetIndex forAlbumIndex:(NSInteger)albumIndex;

@property (nonatomic, readonly) BOOL standby;
@property (nonatomic, readonly) NSString * _Nullable workerName;

@end
