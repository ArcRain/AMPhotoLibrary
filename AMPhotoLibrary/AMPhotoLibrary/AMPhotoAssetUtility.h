//
//  AMPhotoAssetUtility.h
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMPhotoAssetUtility : NSObject

/*
 For Image: use rawData
 For Video: use playerItem, for URL use 'fetchPlayerItemURL'
 */
+ (void)fetchAsset:(id<AMPhotoAsset>)asset rawData:(void(^)(NSData *rawData, AVPlayerItem *playerItem))resultBlock;

+ (NSArray *)fetchPlayerItemURLs:(AVPlayerItem *)playerItem;

/*
 For async mode get image, use this method
 */
+ (void)fetchAsset:(id<AMPhotoAsset>)asset withImageType:(AMAssetImageType)imageType imageResult:(void(^)(UIImage *image))resultBlock;

@end
