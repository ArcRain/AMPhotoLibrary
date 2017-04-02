//
//  AMAssetsFilter.h
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AMPhotoAlbum, AMPhotoAsset;

typedef void (^AMPhotoManagerResultBlock)(BOOL success, NSError *error);
typedef void (^AMPhotoManagerCheckBlock)(id<AMPhotoAlbum> album, NSError *error);
typedef void (^AMPhotoManagerAlbumEnumerationBlock)(id<AMPhotoAlbum> album, BOOL *stop);
typedef void (^AMPhotoManagerAssetEnumerationBlock)(id<AMPhotoAsset> asset, NSUInteger index, BOOL *stop);

@interface AMAssetsFilter : NSObject

@property (nonatomic, assign) BOOL includeImage;
@property (nonatomic, assign) BOOL includeVideo;
@property (nonatomic, assign) BOOL includeAudio;

+ (AMAssetsFilter *)allAssets;
+ (AMAssetsFilter *)allImages;
+ (AMAssetsFilter *)allVideos;
+ (AMAssetsFilter *)allAudios;

@end
