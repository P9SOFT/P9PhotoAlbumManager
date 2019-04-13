P9PhotoAlbumManager
============

Easy, and quick library for handling iOS Photo album.

# Installation

You can download the latest framework files from our Release page.
P9PhotoAlbumManager also available through CocoaPods. To install it simply add the following line to your Podfile.
pod ‘P9PhotoAlbumManager’

# Play

First, you should check authorization to access Photo Album, and request authorization to user if need.

```swift
if P9PhotoAlbumManager.shared.authorized == false {
    P9PhotoAlbumManager.shared.authorization { (operation, status) in
        if status == .succeed {
            // do something you want.
        }
    }
}
```

And, request album list that you want to listing.
You can describe album information by predefined type or PHAssetCollectionType directly.

```swift
let cameraRoll = P9PhotoAlbumManager.AlbumInfo.init(type: .cameraRoll)
let favorite = P9PhotoAlbumManager.AlbumInfo.init(type: .favorite)
let recentlyAdded = P9PhotoAlbumManager.AlbumInfo.init(type: .recentlyAdded)
let screenshots = P9PhotoAlbumManager.AlbumInfo.init(type: .screenshots)
let videos = P9PhotoAlbumManager.AlbumInfo.init(type: .videos, mediaTypes: [.video], ascending: false)
let regular = P9PhotoAlbumManager.AlbumInfo.init(type: .regular)

let albumInfos = [cameraRoll, favorite, recentlyAdded, screenshots, videos, regular]

P9PhotoAlbumManager.shared.requestAlbums(byInfos: albumInfos) { (operation, status) in
    // now, album list cached on P9PhotoAlbumManager.
}
```

After caching done. You can use all information and integrate with UITableView, UICollectionView and so on, easily.

```swift
// get count of albums
P9PhotoAlbumManager.shared.numberOfAlbums()
// get album cover image
P9PhotoAlbumManager.shared.imageOfMedia(forIndex: 0, atAlbumIndex: indexPath.row, targetSize: CGSize.init(width: 80, height: 80), contentMode: .aspectFill)
```

Handing medias in album also same way.

```swift
// requesting
P9PhotoAlbumManager.shared.requestMedia(atAlbumIndex: albumIndex) { (operation, status) in
    // now, media list cached on P9PhotoAlbumManager.
}
// get count of medias
P9PhotoAlbumManager.shared.numberOfMediaAtAlbum(forIndex: albumIndex)
// get image of media
P9PhotoAlbumManager.shared.imageOfMedia(forIndex: mediaIndex, atAlbumIndex: albumIndex, targetSize: P9PhotoAlbumManager.maximumImageSize, contentMode: .aspectFill)
```

You can also create, delete, rename album and save, delete media(image, video, audio) at album, easily.

# License

MIT License, where applicable. http://en.wikipedia.org/wiki/MIT_License
