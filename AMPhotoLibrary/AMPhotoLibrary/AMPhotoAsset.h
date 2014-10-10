//
//  AMPhotoAsset.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMPhotoAsset : NSObject

@property (nonatomic, readonly, assign) CGSize dimensions;
@property (nonatomic, readonly, strong) NSDictionary *metadata;
@property (nonatomic, readonly, strong) NSDate *creationDate;
@property (nonatomic, readonly, strong) CLLocation *location;
@property (nonatomic, readonly, strong) NSURL *assetURL;

@property (nonatomic, readonly, strong) UIImage *thumbnail;
@property (nonatomic, readonly, strong) UIImage *aspectRatioThumbnail;
@property (nonatomic, readonly, strong) UIImage *fullScreenImage;
@property (nonatomic, readonly, strong) UIImage *fullResolutionImage;

@property (nonatomic, readonly, assign) UIImageOrientation orientation;
+ (AMPhotoAsset *)photoAssetWithALAsset:(ALAsset *)asset;
+ (AMPhotoAsset *)photoAssetWithPHAsset:(PHAsset *)asset;

- (ALAsset *)asALAsset;
- (PHAsset *)asPHAsset;

@end
