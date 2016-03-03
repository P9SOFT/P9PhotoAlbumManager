//
//  HJPhotoAlbumManager.m
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 11. 4.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJPhotoAlbumManager.h"
#import "HJPhotoAlbumExecutor.h"

@interface HJPhotoAlbumManager ()
{
    NSMutableArray      *_albums;
    NSMutableDictionary *_assetsForAlbumIndex;
    NSMutableArray      *_queryQueue;
    NSLock              *_lock;
}

- (NSMutableDictionary *)photoAlbumExecutorHandlerWithResult:(HYResult *)result;
- (void)postNotifyWithStatus:(HJPhotoAlbumManagerStatus)status;

@end

@implementation HJPhotoAlbumManager

- (id)init
{
    if( (self = [super init]) != nil ) {
        if( (_albums = [[NSMutableArray alloc] init]) == nil ) {
            return nil;
        }
        if( (_assetsForAlbumIndex = [[NSMutableDictionary alloc] init]) == nil ) {
            return nil;
        }
        if( (_queryQueue = [[NSMutableArray alloc] init]) == nil ) {
            return nil;
        }
        if( (_lock = [[NSLock alloc] init]) == nil ) {
            return nil;
        }
    }

    return self;
}

- (NSString *)name
{
    return HJPhotoAlbumManagerNotification;
}

- (NSMutableDictionary *)photoAlbumExecutorHandlerWithResult:(HYResult *)result
{
    if( result == nil ) {
        return nil;
    }
    
    HJPhotoAlbumExecutorOperation operation = (HJPhotoAlbumExecutorOperation)[[result parameterForKey:HJPhotoAlbumExecutorParameterKeyOperation] integerValue];
    HJPhotoAlbumExecutorStatus executorStatus = (HJPhotoAlbumExecutorStatus)[[result parameterForKey:HJPhotoAlbumExecutorParameterKeyStatus] integerValue];
    HJPhotoAlbumManagerCompletion completion = [result parameterForKey:HJPhotoAlbumExecutorParameterKeyCompletionBlock];
    NSNumber *albumIndexNumber = [result parameterForKey:HJPhotoAlbumExecutorParameterKeyAlbumIndex];
    HJPhotoAlbumManagerStatus managerStatus = HJPhotoAlbumManagerStatusInternalError;
    NSMutableArray *albums;
    NSMutableArray *assetsForAlbums;
    NSMutableDictionary *paramDict = [NSMutableDictionary new];
    
    switch( operation ) {
        case HJPhotoAlbumExecutorOperationRequestAllAlbumsAndAssets :
            if( executorStatus == HJPhotoAlbumExecutorStatusAllAlbumsAndAssetsReady ) {
                [_lock lock];
                [_albums removeAllObjects];
                [_assetsForAlbumIndex removeAllObjects];
                albums = [result parameterForKey:HJPhotoAlbumExecutorParameterKeyAlbums];
                assetsForAlbums = [result parameterForKey:HJPhotoAlbumExecutorParameterKeyAssetsForAlbums];
                if( (albums != nil) && (assetsForAlbums != nil) && ([albums count] == [assetsForAlbums count]) ) {
                    [_albums addObjectsFromArray:albums];
                    NSUInteger count = [assetsForAlbums count];
                    NSUInteger i;
                    for( i=0 ; i<count ; ++i ) {
                        [_assetsForAlbumIndex setObject:[assetsForAlbums objectAtIndex:i] forKey:@(i).stringValue];
                    }
                }
                [_lock unlock];
                managerStatus = HJPhotoAlbumManagerStatusAllAlbumsAndAssetsReady;
            }
            break;
        case HJPhotoAlbumExecutorOperationRequestAllAlbums :
            if( executorStatus == HJPhotoAlbumExecutorStatusAllAlbumsReady ) {
                [_lock lock];
                [_albums removeAllObjects];
                if( (albums = [result parameterForKey:HJPhotoAlbumExecutorParameterKeyAlbums]) != nil ) {
                    [_albums addObjectsFromArray:albums];
                }
                [_lock unlock];
                managerStatus = HJPhotoAlbumManagerStatusAllAlbumsReady;
            }
            break;
        case HJPhotoAlbumExecutorOperationRequestAllAssetsForAlbums :
            if( executorStatus == HJPhotoAlbumExecutorStatusAllAssetsForAlbumsReady ) {
                assetsForAlbums = [result parameterForKey:HJPhotoAlbumExecutorParameterKeyAssetsForAlbums];
                if( (albumIndexNumber != nil) && ([assetsForAlbums count] == 1) ) {
                    [_lock lock];
                    [_assetsForAlbumIndex setObject:[assetsForAlbums objectAtIndex:0] forKey:albumIndexNumber.stringValue];
                    [paramDict setObject:albumIndexNumber forKey:HJPhotoAlbumManagerParameterKeyAlbumIndex];
                    managerStatus = HJPhotoAlbumManagerStatusAllAssetsForAlbumReady;
                    [_lock unlock];
                }
            }
            break;
        default :
            break;
    }
    
    if( completion != nil ) {
        completion(managerStatus);
    }
    
    [paramDict setObject:@(managerStatus) forKey:HJPhotoAlbumManagerParameterKeyStatus];
    
    return paramDict;
}

- (void)postNotifyWithStatus:(HJPhotoAlbumManagerStatus)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self postNotifyWithParamDict:@{HJPhotoAlbumManagerParameterKeyStatus:@(status)}];
    });
}

+ (HJPhotoAlbumManager *)sharedManager
{
    static dispatch_once_t once;
    static HJPhotoAlbumManager *sharedInstance;
    dispatch_once(&once, ^{sharedInstance = [[self alloc] init];});
    return sharedInstance;
}

- (BOOL)standbyWithWorkerName:(NSString *)workerName
{
    if( _standby == YES ) {
        return NO;
    }
    
    [self registExecuter:[[HJPhotoAlbumExecutor alloc] init] withWorkerName:workerName action:@selector(photoAlbumExecutorHandlerWithResult:)];
    _workerName = workerName;
    
    _standby = YES;
    
    return _standby;
}

- (void)requestOperation:(HJPhotoAlbumManagerOperation)operation operandDict:(NSDictionary *)operandDict completion:(HJPhotoAlbumManagerCompletion)completion
{
    HJPhotoAlbumManagerStatus status = HJPhotoAlbumManagerStatusInternalError;
    switch( operation ) {
        case HJPhotoAlbumManagerOperationRequestAllAlbumsAndAssets :
            status = HJPhotoAlbumManagerStatusRequesingAllAlbumsAndAssets;
            break;
        case HJPhotoAlbumManagerOperationRequestAllAlbums :
            status = HJPhotoAlbumManagerStatusRequestingAllAlbums;
            break;
        case HJPhotoAlbumManagerOperationRequestAllAssetsForAlbum :
            status = HJPhotoAlbumManagerStatusRequestingAllAssetsForAlbum;
            break;
        default :
            break;
    }
    
    PHAssetMediaType mediaType;
    NSNumber *mediaTypeNumber = [operandDict objectForKey:HJPhotoAlbumManagerParameterKeyMediaType];
    switch( (HJPhotoAlbumManagerMediaType)[mediaTypeNumber integerValue] ) {
        case HJPhotoAlbumManagerMediaTypeImage :
            mediaType = PHAssetMediaTypeImage;
            break;
        case HJPhotoAlbumManagerMediaTypeVideo :
            mediaType = PHAssetMediaTypeVideo;
            break;
        case HJPhotoAlbumManagerMediaTypeAudio :
            mediaType = PHAssetMediaTypeAudio;
            break;
        default :
            status = HJPhotoAlbumManagerStatusInternalError;
            break;
    }
    
    HYQuery *query = [self queryForExecutorName:HJPhotoAlbumExecutorName];
    if( (status == HJPhotoAlbumManagerStatusInternalError) || (query == nil) ) {
        if( completion != nil ) {
            completion(HJPhotoAlbumManagerStatusInternalError);
        }
        return;
    }
    [self postNotifyWithStatus:status];
    
    [query setParameter:@(operation) forKey:HJPhotoAlbumExecutorParameterKeyOperation];
    [query setParameter:[operandDict objectForKey:HJPhotoAlbumManagerParameterKeyAlbumIndex] forKey:HJPhotoAlbumExecutorParameterKeyAlbumIndex];
    [query setParameter:@(mediaType) forKey:HJPhotoAlbumExecutorParameterKeyMediaType];
    [query setParameter:completion forKey:HJPhotoAlbumExecutorParameterKeyCompletionBlock];
    
    [[Hydra defaultHydra] pushQuery:query];
}

- (void)clearCache
{
    [_lock lock];
    [_albums removeAllObjects];
    [_assetsForAlbumIndex removeAllObjects];
    [_lock unlock];
}

- (NSUInteger)numberOfAlbums
{
    NSUInteger count = 0;
    
    [_lock lock];
    count = [_albums count];
    [_lock unlock];
    
    return count;
}

- (NSString *)nameForAlbumIndex:(NSInteger)albumIndex
{
    NSString *name = nil;
    
    [_lock lock];
    if( (0 <= albumIndex) && (albumIndex < [_albums count]) ) {
        name = [[_albums objectAtIndex:albumIndex] localizedTitle];
    }
    [_lock unlock];
    
    return name;
}

- (NSUInteger)numberOfAssetsForAlbumIndex:(NSInteger)albumIndex
{
    NSUInteger numberOfAssets = 0;
    
    [_lock lock];
    if( (0 <= albumIndex) && (albumIndex < [_albums count]) ) {
        numberOfAssets = [[PHAsset fetchAssetsInAssetCollection:[_albums objectAtIndex:albumIndex] options:nil] count];
    }
    [_lock unlock];
    
    return numberOfAssets;
}

- (UIImage *)posterImageForAlbumIndex:(NSInteger)albumIndex
{
    PHFetchOptions *fetchOptions = nil;
    
    [_lock lock];
    if( (0 <= albumIndex) && (albumIndex < [_albums count]) ) {
        fetchOptions = [[PHFetchOptions alloc] init];
    }
    [_lock unlock];
    
    if( fetchOptions == nil ) {
        return nil;
    }
    
    __block UIImage *image = nil;
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *fetchResult = [PHAsset fetchKeyAssetsInAssetCollection:[_albums objectAtIndex:albumIndex] options:fetchOptions];
    PHAsset *asset = [fetchResult firstObject];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat dimension = 80.0f;
    CGSize size = CGSizeMake(dimension*scale, dimension*scale);
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        image = result;
    }];
    
    return image;
}

- (UIImage *)thumbnailImageOfAssetIndex:(NSInteger)assetIndex forAlbumIndex:(NSInteger)albumIndex
{
    if( (albumIndex < 0) || (albumIndex >= [_albums count]) ) {
        return nil;
    }
    
    NSArray *assets;
    PHAsset *asset = nil;
    
    [_lock lock];
    if( (assets = [_assetsForAlbumIndex objectForKey:@(albumIndex).stringValue]) != nil ) {
        if( assetIndex <= [assets count] ) {
            asset = [assets objectAtIndex:assetIndex];
        }
    }
    [_lock unlock];
    
    if( asset == nil ) {
        return nil;
    }
    
    __block UIImage *image = nil;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat dimension = 80.0f;
    CGSize size = CGSizeMake(dimension*scale, dimension*scale);
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        image = result;
    }];
    
    return image;
}

- (UIImage *)imageOfAssetIndex:(NSInteger)assetIndex forAlbumIndex:(NSInteger)albumIndex
{
    if( (albumIndex < 0) || (albumIndex >= [_albums count]) ) {
        return nil;
    }
    
    NSArray *assets;
    PHAsset *asset = nil;
    
    [_lock lock];
    if( (assets = [_assetsForAlbumIndex objectForKey:@(albumIndex).stringValue]) != nil ) {
        if( assetIndex <= [assets count] ) {
            asset = [assets objectAtIndex:assetIndex];
        }
    }
    [_lock unlock];
    
    if( asset == nil ) {
        return nil;
    }
    
    __block UIImage *image = nil;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        image = result;
    }];
    
    return image;
}

@end
