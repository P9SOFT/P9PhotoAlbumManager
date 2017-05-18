//
//  HJPhotoAlbumExecutor.m
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2013. 11. 4.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "HJPhotoAlbumExecutor.h"

@interface HJPhotoAlbumExecutor ()

- (HYResult *)resultForQuery:(id)anQuery withStatus:(HJPhotoAlbumExecutorStatus)status;
- (BOOL)requestAllAlbumsAndAssets:(id)anQuery;
- (BOOL)requestAllAlbums:(id)anQuery;
- (BOOL)requestAllAsstesForAlbums:(id)anQuery;

@end

@implementation HJPhotoAlbumExecutor

- (NSString *)name
{
    return HJPhotoAlbumExecutorName;
}

- (NSString *)brief
{
    return @"HJPhotoAlubmManager's executor for job such as get groups and each assets.";
}

- (BOOL)calledExecutingWithQuery:(id)anQuery
{
    HJPhotoAlbumExecutorOperation operation = (HJPhotoAlbumExecutorOperation)[[anQuery parameterForKey:HJPhotoAlbumExecutorParameterKeyOperation] integerValue];
    
    switch( operation ) {
        case HJPhotoAlbumExecutorOperationRequestAllAlbumsAndAssets :
            if( [self requestAllAlbumsAndAssets:anQuery] == NO ) {
                [self storeResult:[self resultForQuery:anQuery withStatus:HJPhotoAlbumExecutorStatusInternalError]];
                return YES;
            }
            [self storeResult:[self resultForQuery:anQuery withStatus:HJPhotoAlbumExecutorStatusAllAlbumsAndAssetsReady]];
            break;
        case HJPhotoAlbumExecutorOperationRequestAllAlbums :
            if( [self requestAllAlbums:anQuery] == NO ) {
                [self storeResult:[self resultForQuery:anQuery withStatus:HJPhotoAlbumExecutorStatusInternalError]];
                return YES;
            }
            [self storeResult:[self resultForQuery:anQuery withStatus:HJPhotoAlbumExecutorStatusAllAlbumsReady]];
            break;
        case HJPhotoAlbumExecutorOperationRequestAllAssetsForAlbums :
            if( [self requestAllAsstesForAlbums:anQuery] == NO ) {
                [self storeResult:[self resultForQuery:anQuery withStatus:HJPhotoAlbumExecutorStatusInternalError]];
                return YES;
            }
            [self storeResult:[self resultForQuery:anQuery withStatus:HJPhotoAlbumExecutorStatusAllAssetsForAlbumsReady]];
            break;
        default :
            [self storeResult:[self resultForQuery:anQuery withStatus:HJPhotoAlbumExecutorStatusUnknownOperation]];
            break;
    }
    
    return YES;
}

- (BOOL)calledCancelingWithQuery:(id)anQuery
{
    [self storeResult:[self resultForQuery:anQuery withStatus:HJPhotoAlbumExecutorStatusCanceled]];
    
    return YES;
}

- (HYResult *)resultForQuery:(id)anQuery withStatus:(HJPhotoAlbumExecutorStatus)status
{
    HYResult *result;
    if( (result = [HYResult resultWithName:self.name]) != nil ) {
        [result setParametersFromDictionary:[anQuery paramDict]];
        [result setParameter:@((NSInteger)status) forKey:HJPhotoAlbumExecutorParameterKeyStatus];
    }
    
    return result;
}

- (BOOL)requestAllAlbumsAndAssets:(id)anQuery
{
    if( [self requestAllAlbums:anQuery] == NO ) {
        return NO;
    }
    if( [self requestAllAsstesForAlbums:anQuery] == NO ) {
        return NO;
    }
    
    return YES;
}

- (BOOL)requestAllAlbums:(id)anQuery
{
    NSMutableArray *albums = [NSMutableArray new];
    PHFetchOptions *userAlbumsOptions = [PHFetchOptions new];
    if( (albums == nil) || (userAlbumsOptions == nil) ) {
        return NO;
    }
    userAlbumsOptions.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:userAlbumsOptions];
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        if( collection != nil ) {
            [albums insertObject:collection atIndex:0];
        }
    }];
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    PHAssetCollection *assetCollection = result.firstObject;
    if( assetCollection != nil ) {
        [albums addObject:assetCollection];
    }
    
    [anQuery setParameter:albums forKey:HJPhotoAlbumExecutorParameterKeyAlbums];
    
    return YES;
}

- (BOOL)requestAllAsstesForAlbums:(id)anQuery
{
    NSMutableArray *albums = [anQuery parameterForKey:HJPhotoAlbumExecutorParameterKeyAlbums];
    if( albums == nil ) {
        NSNumber *albumIndexNumber = [anQuery parameterForKey:HJPhotoAlbumExecutorParameterKeyAlbumIndex];
        if( albumIndexNumber == nil ) {
            return NO;
        }
        if( [self requestAllAlbums:anQuery] == NO ) {
            return NO;
        }
        NSMutableArray *allAlbums = [anQuery parameterForKey:HJPhotoAlbumExecutorParameterKeyAlbums];
        if( (allAlbums.count == 0) || (allAlbums.count <= albumIndexNumber.unsignedIntegerValue) ) {
            return NO;
        }
        if( (albums = [[NSMutableArray alloc] initWithObjects:allAlbums[albumIndexNumber.unsignedIntegerValue], nil]) == nil ) {
            return NO;
        }
        [anQuery setParameter:albums forKey:HJPhotoAlbumExecutorParameterKeyAlbums];
    }
    PHAssetMediaType mediaType = (PHAssetMediaType)[[anQuery parameterForKey:HJPhotoAlbumExecutorParameterKeyMediaType] integerValue];
    if( mediaType == PHAssetMediaTypeUnknown ) {
        return NO;
    }
    
    NSMutableArray *assetsForAlbums = [NSMutableArray new];
    if( assetsForAlbums == nil ) {
        return NO;
    }
    
    for( PHAssetCollection *album in albums ) {
        PHFetchOptions *fetchOptions = [PHFetchOptions new];
        if( fetchOptions == nil ) {
            return NO;
        }
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i", mediaType];
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:album options:fetchOptions];
        if( result == nil ) {
            return NO;
        }
        NSMutableArray *assets = [NSMutableArray new];
        if( assets == nil ) {
            return NO;
        }
        [assetsForAlbums addObject:assets];
        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            [assets addObject:asset];
        }];
    }
    [anQuery setParameter:assetsForAlbums forKey:HJPhotoAlbumExecutorParameterKeyAssetsForAlbums];
    
    return YES;
}

@end
