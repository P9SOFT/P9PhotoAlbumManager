//
//  P9PhotoAlbumManager.swift
//
//
//  Created by Tae Hyun Na on 2019. 3. 19.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit
import Photos

extension Notification.Name {
    static let P9PhotoAlbumManager = Notification.Name("P9PhotoAlbumManagerNotification")
}
@objc extension NSNotification {
    public static let P9PhotoAlbumManager = Notification.Name.P9PhotoAlbumManager
}

open class P9PhotoAlbumManager: NSObject {
    
    @objc public static let NotificationOperationObjcKey = "P9PhotoAlbumManagerNotificationOperationObjcKey"
    @objc public static let NotificationStatusObjcKey = "P9PhotoAlbumManagerNotificationStatusObjcKey"
    public static let NotificationOperationKey = "P9PhotoAlbumManagerNotificationOperationKey"
    public static let NotificationStatusKey = "P9PhotoAlbumManagerNotificationStatusKey"
    
    @objc public static let maximumImageSize = PHImageManagerMaximumSize
    
    @objc(P9PhotoAlbumManagerOperation) public enum Operation: Int {
        case authorization
        case requestAlbums
        case requestMedias
        case createAlbum
        case deleteAlbum
        case renameAlbum
        case saveMediaToAlbum
        case deleteMediaFromAlbum
        case reload
        case clearCache
        case appWillEnterForeground
    }
    
    @objc(P9PhotoAlbumManagerStatus) public enum Status: Int {
        case accessDenied
        case succeed
        case failed
    }
    
    @objc(P9PhotoAlbumManagerPredefinedAlbumType) public enum PredefinedAlbumType: Int {
        case cameraRoll
        case favorite
        case recentlyAdded
        case screenshots
        case videos
        case regular
        case customCollectionType
    }
    
    @objc(P9PhotoAlbumManagerMediaType) public enum MediaType: Int {
        case unknown
        case image
        case video
        case audio
    }
    
    @objc(P9PhotoAlbumManagerContentMode) public enum ContentMode: Int {
        case aspectFit
        case aspectFill
    }
    
    @objc(P9PhotoAlbumManagerAlbumInfo) public class AlbumInfo : NSObject {
        
        var collectionType:PHAssetCollectionType = .smartAlbum
        var collectionTypeSubtype:PHAssetCollectionSubtype = .smartAlbumUserLibrary
        var mediaTypes:[MediaType] = [.image]
        var ascending:Bool = false
        
        @objc public convenience init(type:Int) {
            
            let convertedType = PredefinedAlbumType(rawValue: type) ?? .cameraRoll
            self.init(type: convertedType, mediaTypes: [.image], ascending: false)
        }
        
        public convenience init(type:PredefinedAlbumType) {
            self.init(type: type, mediaTypes: [.image], ascending: false)
        }
        
        @objc public convenience init(type:Int, mediaTypes:[Int], ascending:Bool) {
            
            let convertedType = PredefinedAlbumType(rawValue: type) ?? .cameraRoll
            let convertedMediaTypes = mediaTypes.map({ MediaType(rawValue: $0) ?? .unknown})
            self.init(type: convertedType, mediaTypes: convertedMediaTypes, ascending: ascending)
        }
        
        public convenience init(type:PredefinedAlbumType, mediaTypes:[MediaType], ascending:Bool) {
            self.init()
            switch type {
            case .cameraRoll :
                self.collectionType = .smartAlbum
                self.collectionTypeSubtype = .smartAlbumUserLibrary
            case .favorite :
                self.collectionType = .smartAlbum
                self.collectionTypeSubtype = .smartAlbumFavorites
            case .recentlyAdded :
                self.collectionType = .smartAlbum
                self.collectionTypeSubtype = .smartAlbumRecentlyAdded
            case .screenshots :
                if #available(iOS 9.0, *) {
                    self.collectionType = .smartAlbum
                    self.collectionTypeSubtype = .smartAlbumScreenshots
                }
            case .videos :
                self.collectionType = .smartAlbum
                self.collectionTypeSubtype = .smartAlbumVideos
            case .regular :
                self.collectionType = .album
                self.collectionTypeSubtype = .albumRegular
            default :
                break
            }
            self.mediaTypes = mediaTypes
            self.ascending = ascending
        }
        
        @objc public convenience init(collectionType:Int, collectionTypeSubtype:Int, mediaTypes:[Int], ascending:Bool) {
            
            let convertedCollectionType = PHAssetCollectionType(rawValue: collectionType) ?? .smartAlbum
            let convertedCollectionTypeSubtype = PHAssetCollectionSubtype(rawValue: collectionType) ?? .smartAlbumUserLibrary
            let convertedMediaTypes = mediaTypes.map({ MediaType(rawValue: $0) ?? .unknown})
            self.init(collectionType: convertedCollectionType, collectionTypeSubtype: convertedCollectionTypeSubtype, mediaTypes: convertedMediaTypes, ascending: ascending)
        }
        
        public convenience init(collectionType:PHAssetCollectionType, collectionTypeSubtype:PHAssetCollectionSubtype, mediaTypes:[MediaType], ascending:Bool) {
            self.init()
            self.collectionType = collectionType
            self.collectionTypeSubtype = collectionTypeSubtype
            self.mediaTypes = mediaTypes
            self.ascending = ascending
        }
    }
    
    public typealias P9PhotoAlbumManagerCompletionBlock = (_ operation:Operation, _ status:Status) -> Void
    
    private let serialQueue = DispatchQueue(label: "p9photoalbummanager")
    private let dispatchGroup = DispatchGroup()
    private var albumInfos:[AlbumInfo] = []
    private var albums:[PHAssetCollection] = []
    private var assetsAtAlbumIndex:[Int:[PHAsset]] = [:]
    
    @objc public var autoReloadWhenAppWillEnterForeground:Bool = true
    
    @objc public static let shared = P9PhotoAlbumManager()
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForegroundHandler(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc fileprivate func applicationWillEnterForegroundHandler(notification:Notification) {
        
        self.postNotify(operation: .appWillEnterForeground, status: .succeed, completion: nil)
        if autoReloadWhenAppWillEnterForeground == true {
            reload(nil)
        }
    }
    
    @objc public var authorized:Bool {
        get {
            return (PHPhotoLibrary.authorizationStatus() == .authorized)
        }
    }
    
    @objc public func authorization(completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            postNotify(operation: .authorization, status: .succeed, completion: completion)
            return
        }
        PHPhotoLibrary.requestAuthorization { (status) in
            self.postNotify(operation: .authorization, status: (status == .authorized ? .succeed : .failed), completion: completion)
        }
    }
    
    @objc public func requestAlbums(byInfos infos:[AlbumInfo], completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        guard authorized == true, infos.count > 0 else {
            postNotify(operation: .requestAlbums, status: .failed, completion: completion)
            return
        }
        
        serialQueue.async {
            self.albumInfos.removeAll()
            self.albums.removeAll()
            self.assetsAtAlbumIndex.removeAll()
            for info in infos {
                let result = PHAssetCollection.fetchAssetCollections(with: info.collectionType, subtype: info.collectionTypeSubtype, options: nil)
                result.enumerateObjects { (collection, index, stop) in
                    self.albumInfos.append(info)
                    self.albums.append(collection)
                }
            }
            self.postNotify(operation: .requestAlbums, status: .succeed, completion: completion)
        }
    }
    
    public func requestMedia(atAlbumIndex albumIndex:Int, completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        guard authorized == true, 0 <= albumIndex, albumIndex < albums.count else {
            postNotify(operation: .requestMedias, status: .failed, completion: completion)
            return
        }
        
        serialQueue.async {
            var assets:[PHAsset] = []
            let result = self.fetchResultAssetForAlbumIndex(albumIndex)
            result.enumerateObjects({ (asset, index, stop) in
                assets.append(asset)
            })
            self.assetsAtAlbumIndex[albumIndex] = assets
            self.postNotify(operation: .requestMedias, status: .succeed, completion: completion)
        }
    }
    
    @objc(createAlbumTitle:mediaTypes:ascending:completion:)
    public func objc_createAlbum(title:String, mediaTypes:[Int], ascending:Bool, completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        createAlbum(title: title, mediaTypes: mediaTypes.map({ MediaType(rawValue: $0) ?? .unknown}), ascending: ascending, completion: completion)
    }
    
    public func createAlbum(title:String, mediaTypes:[MediaType], ascending:Bool, completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        guard authorized == true, title.count > 0, mediaTypes.count > 0 else {
            self.postNotify(operation: .createAlbum, status: .failed, completion: completion)
            return
        }
        
        serialQueue.async {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            }) { (succeed, error) in
                if succeed == true {
                    let options = PHFetchOptions.init()
                    options.predicate = NSPredicate.init(format: "title = %@", title)
                    let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options)
                    if let assetCollection = result.lastObject {
                        self.albumInfos.append(AlbumInfo.init(type: .regular, mediaTypes: mediaTypes, ascending: ascending))
                        self.albums.append(assetCollection)
                    }
                }
                self.postNotify(operation: .createAlbum, status: (succeed == true ? .succeed : .failed), completion: completion)
            }
        }
    }
    
    @objc public func deleteAlbum(index:Int, completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        guard authorized == true, 0 <= index, index < albums.count else {
            postNotify(operation: .deleteAlbum, status: .failed, completion: completion)
            return
        }
        
        serialQueue.async {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.deleteAssetCollections([self.albums[index]] as NSFastEnumeration)
            }) { (succeed, error) in
                if succeed == true {
                    self.albumInfos.remove(at: index)
                    self.albums.remove(at: index)
                    self.assetsAtAlbumIndex.removeValue(forKey: index)
                }
                self.postNotify(operation: .deleteAlbum, status: (succeed == true ? .succeed : .failed), completion: completion)
            }
        }
    }
    
    @objc public func renameAlbum(index:Int, title:String, completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        guard authorized == true, 0 <= index, index < albums.count, title.count > 0 else {
            postNotify(operation: .deleteAlbum, status: .failed, completion: completion)
            return
        }
        
        serialQueue.async {
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCollectionChangeRequest(for: self.albums[index])
                request?.title = title
            }) { (succeed, error) in
                if succeed == true {
                    let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [self.albums[index].localIdentifier], options: nil)
                    if let collection = result.lastObject {
                        self.albums[index] = collection
                    }
                }
                self.postNotify(operation: .renameAlbum, status: (succeed == true ? .succeed : .failed), completion: completion)
            }
        }
    }
    
    @objc public func savePhotoImage(image:UIImage, toAlbumIndex albumIndex:Int, completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        guard authorized == true, 0 <= albumIndex, albumIndex < albums.count else {
            postNotify(operation: .saveMediaToAlbum, status: .failed, completion: completion)
            return
        }
        
        serialQueue.async {
            var placeHolder:PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges({
                let mediaRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                placeHolder = mediaRequest.placeholderForCreatedAsset
                if self.predefineTypeOfAlbum(forIndex: albumIndex) == .regular {
                    if let placeHolder = placeHolder, let albumRequest = PHAssetCollectionChangeRequest(for: self.albums[albumIndex]) {
                        albumRequest.addAssets([placeHolder] as NSFastEnumeration)
                    }
                }
            }) { (succeed, error) in
                if succeed == true, let placeHolder = placeHolder {
                    let result = PHAsset.fetchAssets(withLocalIdentifiers: [placeHolder.localIdentifier], options: nil)
                    if let asset = result.lastObject {
                        if self.albumInfos[albumIndex].ascending == true {
                            self.assetsAtAlbumIndex[albumIndex]?.append(asset)
                        } else {
                            self.assetsAtAlbumIndex[albumIndex]?.insert(asset, at: 0)
                        }
                    }
                }
                self.postNotify(operation: .saveMediaToAlbum, status: (succeed == true ? .succeed : .failed), completion: completion)
            }
        }
    }
    
    @objc public func saveMediaFile(url:URL, mediaType:MediaType, toAlbumIndex albumIndex:Int, completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        guard authorized == true, url.isFileURL == true, 0 <= albumIndex, albumIndex < albums.count else {
            postNotify(operation: .saveMediaToAlbum, status: .failed, completion: completion)
            return
        }
        
        serialQueue.async {
            var placeHolder:PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges({
                var mediaRequest:PHAssetChangeRequest?
                switch mediaType {
                case .image :
                    mediaRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                case .video, .audio :
                    mediaRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                default :
                    break
                }
                if let mediaRequest = mediaRequest {
                    placeHolder = mediaRequest.placeholderForCreatedAsset
                    if self.predefineTypeOfAlbum(forIndex: albumIndex) == .regular {
                        if let placeHolder = placeHolder, let albumRequest = PHAssetCollectionChangeRequest(for: self.albums[albumIndex]) {
                            albumRequest.addAssets([placeHolder] as NSFastEnumeration)
                        }
                    }
                }
            }) { (succeed, error) in
                if succeed == true, let placeHolder = placeHolder {
                    let result = PHAsset.fetchAssets(withLocalIdentifiers: [placeHolder.localIdentifier], options: nil)
                    if let asset = result.lastObject {
                        if self.albumInfos[albumIndex].ascending == true {
                            self.assetsAtAlbumIndex[albumIndex]?.append(asset)
                        } else {
                            self.assetsAtAlbumIndex[albumIndex]?.insert(asset, at: 0)
                        }
                    }
                }
                self.postNotify(operation: .saveMediaToAlbum, status: (succeed == true ? .succeed : .failed), completion: completion)
            }
        }
    }
    
    @objc public func deleteMedia(index:Int, fromAlbumIndex albumIndex:Int, completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        guard authorized == true, 0 <= albumIndex, albumIndex < albums.count, let assets = assetsAtAlbumIndex[albumIndex], 0 <= index, index < assets.count else {
            postNotify(operation: .deleteMediaFromAlbum, status: .failed, completion: completion)
            return
        }
        
        serialQueue.async {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets([assets[index]] as NSFastEnumeration)
            }) { (succeed, error) in
                if succeed == true {
                    self.assetsAtAlbumIndex[albumIndex]?.remove(at: index)
                }
                self.postNotify(operation: .deleteMediaFromAlbum, status: (succeed == true ? .succeed : .failed), completion: completion)
            }
        }
    }
    
    @objc public func deleteMedia(indices:[Int], fromAlbumIndex albumIndex:Int, completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        guard authorized == true, 0 <= albumIndex, albumIndex < albums.count, let assets = assetsAtAlbumIndex[albumIndex], indices.count > 0 else {
            postNotify(operation: .deleteMediaFromAlbum, status: .failed, completion: completion)
            return
        }
        
        serialQueue.async {
            var deleteAssets:[PHAsset] = []
            for index in indices {
                if 0 <= index, index < assets.count {
                    deleteAssets.append(assets[index])
                }
            }
            if deleteAssets.count == 0 {
                self.postNotify(operation: .deleteMediaFromAlbum, status: .failed, completion: completion)
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(deleteAssets as NSFastEnumeration)
            }) { (succeed, error) in
                if succeed == true {
                    let reverseOrderIndices = indices.sorted(by: >)
                    for index in reverseOrderIndices {
                        self.assetsAtAlbumIndex[albumIndex]?.remove(at: index)
                    }
                }
                self.postNotify(operation: .deleteMediaFromAlbum, status: (succeed == true ? .succeed : .failed), completion: completion)
            }
        }
    }
    
    @objc public func reload(_ completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        serialQueue.async {
            var albumInfos:[AlbumInfo] = []
            var albums:[PHAssetCollection] = []
            var assetsAtAlbumIndex:[Int:[PHAsset]] = [:]
            for i in 0..<self.albums.count {
                let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [self.albums[i].localIdentifier], options: nil)
                if let lastObject = result.lastObject {
                    albumInfos.append(self.albumInfos[i])
                    albums.append(lastObject)
                    if self.assetsAtAlbumIndex[i] != nil, let info = albumInfos.last, let collection = albums.last {
                        let options = PHFetchOptions.init()
                        if let predicates = self.predicateFromMediaType(mediaTypes: info.mediaTypes) {
                            options.predicate = NSCompoundPredicate.init(orPredicateWithSubpredicates: predicates)
                        }
                        options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: info.ascending)]
                        let result = PHAsset.fetchAssets(in: collection, options: options)
                        var assets:[PHAsset] = []
                        result.enumerateObjects({ (asset, index, stop) in
                            assets.append(asset)
                        })
                        assetsAtAlbumIndex[albumInfos.count-1] = assets
                    }
                }
            }
            self.albumInfos = albumInfos
            self.albums = albums
            self.assetsAtAlbumIndex = assetsAtAlbumIndex
            self.postNotify(operation: .reload, status: .succeed, completion: completion)
        }
    }
    
    @objc public func clearCache() {
        
        serialQueue.async {
            self.albumInfos.removeAll()
            self.albums.removeAll()
            self.assetsAtAlbumIndex.removeAll()
            self.postNotify(operation: .clearCache, status: .succeed, completion: nil)
        }
    }
    
    @objc public func numberOfAlbums() -> Int {
        
        guard authorized == true else {
            return 0
        }
        
        return albums.count
    }
    
    @objc public func titleOfAlbum(forIndex index:Int) -> String? {
        
        guard authorized == true, 0 <= index, index < albums.count else {
            return nil
        }
        
        return albums[index].localizedTitle
    }
    
    @objc(predefineTypeOfAlbum:)
    public func objc_predefineTypeOfAlbum(forIndex index:Int) -> Int {
        
        return predefineTypeOfAlbum(forIndex: index)?.rawValue ?? PredefinedAlbumType.customCollectionType.rawValue
    }
    
    public func predefineTypeOfAlbum(forIndex index:Int) -> PredefinedAlbumType? {
        
        guard authorized == true, 0 <= index, index < albums.count else {
            return nil
        }
        
        switch albums[index].assetCollectionType {
        case .album :
            switch albums[index].assetCollectionSubtype {
            case .albumRegular :
                return .regular
            default :
                break
            }
            break
        case .smartAlbum :
            switch albums[index].assetCollectionSubtype {
            case .smartAlbumUserLibrary :
                return .cameraRoll
            case .smartAlbumFavorites :
                return .favorite
            case .smartAlbumRecentlyAdded :
                return .recentlyAdded
            case .smartAlbumScreenshots :
                return .screenshots
            case .smartAlbumVideos :
                return .videos
            default :
                break
            }
            break
        case .moment :
            break
        default :
            break
        }
        
        return .customCollectionType
    }
    
    @objc public func infoOfAlbum(forIndex index:Int) -> AlbumInfo? {
        
        guard authorized == true, 0 <= index, index < albums.count else {
            return nil
        }
        
        return albumInfos[index]
    }
    
    @objc public func numberOfMediaAtAlbum(forIndex index:Int) -> Int {
        
        guard authorized == true, 0 <= index, index < albums.count else {
            return 0
        }
        
        if let assets = assetsAtAlbumIndex[index] {
            return assets.count
        }
        
        let options = PHFetchOptions.init()
        if let predicates = predicateFromMediaType(mediaTypes: albumInfos[index].mediaTypes) {
            options.predicate = NSCompoundPredicate.init(orPredicateWithSubpredicates: predicates)
        }
        return PHAsset.fetchAssets(in: albums[index], options: options).count
    }
    
    @objc public func mediaTypeOfMedia(forIndex mediaIndex:Int, atAlbumIndex albumIndex:Int) -> MediaType {
        
        guard authorized == true, 0 <= albumIndex, albumIndex < albums.count else {
            return .unknown
        }
        
        if let asset = assetOfMedia(forIndex: mediaIndex, atAlbumIndex: albumIndex) {
            switch asset.mediaType {
            case .image :
                return .image
            case .video :
                return .video
            case .audio :
                return .audio
            default :
                break
            }
        }
        return .unknown
    }
    
    @objc public func imageOfMedia(forIndex mediaIndex:Int, atAlbumIndex albumIndex:Int, targetSize:CGSize, contentMode:ContentMode) -> UIImage? {
        
        guard authorized == true, 0 <= albumIndex, albumIndex < albums.count else {
            return nil
        }
        
        let mode:PHImageContentMode = (contentMode == .aspectFit) ? .aspectFit : .aspectFill
        let options = PHImageRequestOptions.init()
        options.isSynchronous = true
        options.resizeMode = .exact
        var foundImage:UIImage?
        var asset:PHAsset?
        if let assets = assetsAtAlbumIndex[albumIndex], 0 <= mediaIndex, mediaIndex < assets.count {
            asset = assets[mediaIndex]
        } else {
            let result = fetchResultAssetForAlbumIndex(albumIndex)
            if 0 <= mediaIndex, mediaIndex < result.count {
                asset = result[mediaIndex]
            }
        }
        if let asset = asset {
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: mode, options: options) { (image, info) in
                foundImage = image
            }
        }
        return foundImage
    }
    
    @objc public func fileUrlOfMedia(forIndex mediaIndex:Int, atAlbumIndex albumIndex:Int) -> URL? {
        
        guard authorized == true, 0 <= albumIndex, albumIndex < albums.count else {
            return nil
        }
        
        var fileUrl:URL?
        if let asset = assetOfMedia(forIndex: mediaIndex, atAlbumIndex: albumIndex) {
            switch asset.mediaType {
            case .image :
                let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
                options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                    return true
                }
                dispatchGroup.enter()
                asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (contentEditingInput, info) in
                    if let url = contentEditingInput?.fullSizeImageURL {
                        fileUrl = url
                    }
                    self.dispatchGroup.leave()
                }
                dispatchGroup.wait()
            case .video, .audio :
                dispatchGroup.enter()
                PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { (asset, audioMix, info) in
                    if let urlAsset = asset as? AVURLAsset {
                        fileUrl = urlAsset.url
                    }
                    self.dispatchGroup.leave()
                }
                dispatchGroup.wait()
            default :
                break
            }
        }
        return fileUrl
    }
    
    @objc public func assetOfMedia(forIndex mediaIndex:Int, atAlbumIndex albumIndex:Int) -> PHAsset? {
        
        guard authorized == true, 0 <= albumIndex, albumIndex < albums.count else {
            return nil
        }
        
        var asset:PHAsset?
        if let assets = assetsAtAlbumIndex[albumIndex], 0 <= mediaIndex, mediaIndex < assets.count {
            asset = assets[mediaIndex]
        } else {
            let result = fetchResultAssetForAlbumIndex(albumIndex)
            if 0 <= mediaIndex, mediaIndex < result.count {
                asset = result[mediaIndex]
            }
        }
        return asset
    }
    
    private func postNotify(operation:Operation, status:Status, completion:P9PhotoAlbumManagerCompletionBlock?) {
        
        DispatchQueue.main.async {
            if let completion = completion {
                completion(operation, status)
            }
            NotificationCenter.default.post(name: .P9PhotoAlbumManager, object: self, userInfo: [P9PhotoAlbumManager.NotificationOperationKey:operation, P9PhotoAlbumManager.NotificationStatusKey:status, P9PhotoAlbumManager.NotificationOperationObjcKey:operation.rawValue, P9PhotoAlbumManager.NotificationStatusObjcKey:status.rawValue])
        }
    }
    
    private func predicateFromMediaType(mediaTypes:[MediaType]) -> [NSPredicate]? {
        
        var predicates:[NSPredicate] = []
        for type in mediaTypes {
            switch type {
            case .image :
                predicates.append(NSPredicate(format: "mediaType = %i", PHAssetMediaType.image.rawValue))
            case .video :
                predicates.append(NSPredicate(format: "mediaType = %i", PHAssetMediaType.video.rawValue))
            case .audio :
                predicates.append(NSPredicate(format: "mediaType = %i", PHAssetMediaType.audio.rawValue))
            default :
                break
            }
        }
        return (predicates.count > 0 ? predicates : nil)
    }
    
    private func fetchResultAssetForAlbumIndex(_ albumIndex:Int) -> PHFetchResult<PHAsset> {
        
        let options = PHFetchOptions.init()
        if let predicates = predicateFromMediaType(mediaTypes: albumInfos[albumIndex].mediaTypes) {
            options.predicate = NSCompoundPredicate.init(orPredicateWithSubpredicates: predicates)
        }
        options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: albumInfos[albumIndex].ascending)]
        return PHAsset.fetchAssets(in: albums[albumIndex], options: options)
    }
}
