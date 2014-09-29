//
//  AMPhotoManager.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPhotoAlbum.h"
#import "AMPhotoAsset.h"

typedef void (^AMPhotoManagerResultBlock)(BOOL success, NSError *error);
typedef void (^AMPhotoManagerCheckBlock)(AMPhotoAlbum *album, NSError *error);
typedef void (^AMPhotoManagerAlbumEnumeratorBlock)(AMPhotoAlbum *album, BOOL *stop);
typedef void (^AMPhotoManagerAssetEnumeratorBlock)(AMPhotoAsset *asset, NSUInteger index, BOOL *stop);

#pragma mark - AMPhotoManager
@protocol AMPhotoManager <NSObject>

@required
- (void)createAlbum:(NSString *)title resultBlock:(AMPhotoManagerResultBlock)resultBlock;
- (void)checkAlbum:(NSString *)title resultBlock:(AMPhotoManagerCheckBlock)resultBlock;

- (void)enumerateAlbums:(AMPhotoManagerAlbumEnumeratorBlock)enumeratorBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock;
- (void)enumerateAssets:(AMPhotoManagerAssetEnumeratorBlock)enumeratorBlock inPhotoAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock;

- (void)addAsset:(AMPhotoAsset *)asset toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock;

- (void)writeImageToSavedPhotosAlbum:(UIImage *)image resultBlock:(AMPhotoManagerResultBlock)resultBlock;
- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData metadata:(NSDictionary *)metadata resultBlock:(AMPhotoManagerResultBlock)resultBlock;

- (void)writeImage:(UIImage *)image toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock;
- (void)writeImageData:(NSData *)imageData metadata:(NSDictionary *)metadata toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock;

@end
