//
//  AMPhotoAsset.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AMPhotoAssetMediaType) {
    AMPhotoAssetMediaTypeUnknown = 0,
    AMPhotoAssetMediaTypeImage   = 1,
    AMPhotoAssetMediaTypeVideo   = 2,
    AMPhotoAssetMediaTypeAudio   = 3,
};

@interface AMPhotoAsset : NSObject

@property (nonatomic, readonly, assign) AMPhotoAssetMediaType mediaType;

@property (nonatomic, readonly, assign) CGSize dimensions;
@property (nonatomic, readonly, strong) NSDictionary *metadata;
@property (nonatomic, readonly, strong) NSDate *creationDate;
@property (nonatomic, readonly, strong) CLLocation *location;
@property (nonatomic, readonly, strong) NSURL *assetURL;
@property (nonatomic, readonly, assign) unsigned long long fileSize;

@property (nonatomic, readonly, strong) UIImage *thumbnail;
@property (nonatomic, readonly, strong) UIImage *aspectRatioThumbnail;
@property (nonatomic, readonly, copy) NSString *UTI;

//Image Property
/*
 UIImageOrientation for fullResolutionImage
 */
@property (nonatomic, readonly, assign) UIImageOrientation orientation;
@property (nonatomic, readonly, strong) UIImage *fullScreenImage;
@property (nonatomic, readonly, strong) UIImage *fullResolutionImage;

//Video Property
@property (nonatomic, readonly, assign) NSTimeInterval duration;

+ (AMPhotoAsset *)photoAssetWithALAsset:(ALAsset *)asset;
- (ALAsset *)asALAsset;

#if __AMPHOTOLIB_USE_PHOTO__
+ (AMPhotoAsset *)photoAssetWithPHAsset:(PHAsset *)asset;
- (PHAsset *)asPHAsset;
#endif

/*
 For Image: use rawData
 For Video: create NSFileHandle with rawDataURL
 */
+ (void)fetchAsset:(AMPhotoAsset *)asset rawData:(void(^)(NSData *rawData, NSURL *rawDataURL, ALAssetRepresentation *assetRepresentation))result;

@end
