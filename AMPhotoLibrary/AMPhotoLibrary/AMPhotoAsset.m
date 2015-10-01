//
//  AMPhotoAsset.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoAsset.h"

@interface AMPhotoAsset ()
{
    ALAsset *_alAsset;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    PHAsset *_phAsset;
#endif
    AMAssetMediaType _mediaType;
    
    BOOL _hasGotThumbnail;
    UIImage *_thumbnailImage;
    
    BOOL _hasGotAspectRatioThumbnail;
    UIImage *_aspectRatioThumbnailImage;
    
    BOOL _hasGotFullScreenImage;
    UIImage *_fullScreenImage;
    
    BOOL _hasGotFullResolutionImage;
    UIImage *_fullResolutionImage;
    unsigned long long _fileSize;
    
    BOOL _hasGotInfo;
    BOOL _hasGotFullMetaData;
    NSMutableDictionary *_metaData;
    NSURL *_assetURL;
    NSString *_UTI;
    NSString *_localIdentifier;
    
    UIImageOrientation _orientation;
    
    NSTimeInterval _duration;
}
@end

@implementation AMPhotoAsset

+ (AMPhotoAsset *)photoAssetWithALAsset:(ALAsset *)asset
{
    return [[AMPhotoAsset alloc] initWithALAsset: asset];
}

- (AMPhotoAsset *)initWithALAsset:(ALAsset *)asset
{
    self = [super init];
    if (self) {
        _alAsset = asset;
        [self commonInit];
    }
    return self;
}

- (ALAsset *)asALAsset
{
    return _alAsset;
}

#ifdef __AMPHOTOLIB_USE_PHOTO__

+ (AMPhotoAsset *)photoAssetWithPHAsset:(PHAsset *)asset
{
    return [[AMPhotoAsset alloc] initWithPHAsset: asset];
}

- (AMPhotoAsset *)initWithPHAsset:(PHAsset *)asset
{
    self = [super init];
    if (self) {
        _phAsset = asset;
        [self commonInit];
    }
    return self;
}

- (PHAsset *)asPHAsset
{
    return _phAsset;
}

#endif

- (void)commonInit
{
    _hasGotInfo = NO;
    _hasGotFullMetaData = NO;
    _hasGotThumbnail = NO;
    _hasGotAspectRatioThumbnail = NO;
    _hasGotFullScreenImage = NO;
    _hasGotFullResolutionImage = NO;
    _duration = 0.f;
    _orientation = UIImageOrientationUp;
    
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        switch (_phAsset.mediaType) {
            case PHAssetMediaTypeImage:
                _mediaType = AMAssetMediaTypeImage;
                break;
            case PHAssetMediaTypeVideo:
                _mediaType = AMAssetMediaTypeVideo;
                _duration = _phAsset.duration;
                break;
            case PHAssetMediaTypeAudio:
                _mediaType = AMAssetMediaTypeAudio;
                break;
            default:
                _mediaType = AMAssetMediaTypeUnknown;
                break;
        }
    }
    else
#endif
    {
        NSString *mediaType = [_alAsset valueForProperty:ALAssetPropertyType];
        if ([mediaType isEqualToString:ALAssetTypePhoto]) {
            _mediaType = AMAssetMediaTypeImage;
        }
        else if ([mediaType isEqualToString:ALAssetTypeVideo]) {
            _mediaType = AMAssetMediaTypeVideo;
            _duration = [[_alAsset valueForProperty:ALAssetPropertyDuration] doubleValue];
        }
        else {
            _mediaType = AMAssetMediaTypeUnknown;
        }
    }
}

- (AMAssetMediaType)mediaType
{
    return _mediaType;
}

- (CGSize)dimensions
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return CGSizeMake(_phAsset.pixelWidth, _phAsset.pixelHeight);
    }
    else
#endif
    {
        return _alAsset.defaultRepresentation.dimensions;
    }
}

enum {
    kAMASSETMETADATA_PENDINGREADS = 1,
    kAMASSETMETADATA_ALLFINISHED = 0
};

- (NSDictionary *)metadata
{
    if (!_hasGotFullMetaData) {
        _hasGotFullMetaData = YES;
#ifdef __AMPHOTOLIB_USE_PHOTO__
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            if (PHAssetMediaTypeImage == _mediaType) {
                PHImageRequestOptions *request = [PHImageRequestOptions new];
                request.version = PHImageRequestOptionsVersionCurrent;
                request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                request.resizeMode = PHImageRequestOptionsResizeModeNone;
                request.synchronous = YES;
                
                [[PHImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
                    if (NULL != source) {
                        _metaData = (NSMutableDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
                        CFRelease(source);
                    }
                }];
            }
            else if (PHAssetMediaTypeVideo == _mediaType) {
                PHVideoRequestOptions *request = [PHVideoRequestOptions new];
                request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
                request.version = PHVideoRequestOptionsVersionCurrent;
                request.networkAccessAllowed = YES;
                
                NSConditionLock* assetReadLock = [[NSConditionLock alloc] initWithCondition:kAMASSETMETADATA_PENDINGREADS];
                [[PHImageManager defaultManager] requestPlayerItemForVideo:_phAsset options:request resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                    
                    _metaData = [NSMutableDictionary dictionary];
                    NSArray *commonMetaData = playerItem.asset.commonMetadata;
                    for (AVMetadataItem *item in commonMetaData) {
                        _metaData[item.commonKey] = item.value;
                    }
                    
                    [assetReadLock lock];
                    [assetReadLock unlockWithCondition:kAMASSETMETADATA_ALLFINISHED];
                }];
                [assetReadLock lockWhenCondition:kAMASSETMETADATA_ALLFINISHED];
                [assetReadLock unlock];
                assetReadLock = nil;
            }
        }
        else
#endif
        {
            ALAssetRepresentation *defaultRep = _alAsset.defaultRepresentation;
            _metaData = [NSMutableDictionary dictionaryWithDictionary:defaultRep.metadata];
        }
    }
    return _metaData;
}

- (NSDate *)creationDate
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return _phAsset.creationDate;
    }
    else
#endif
    {
        return [_alAsset valueForProperty: ALAssetPropertyDate];
    }
}

- (CLLocation *)location
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return _phAsset.location;
    }
    else
#endif
    {
        return [_alAsset valueForProperty: ALAssetPropertyLocation];
    }
}

- (NSURL *)assetURL
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _assetURL;
}

- (unsigned long long)fileSize
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _fileSize;
}

- (UIImageOrientation)orientation
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _orientation;
}

- (NSString *)UTI
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _UTI;
}

- (UIImage *)thumbnail
{
    if (!_hasGotThumbnail) {
        _hasGotThumbnail = YES;
#ifdef __AMPHOTOLIB_USE_PHOTO__
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeFast;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = YES;
            
            CGSize thumbsize = CGSizeMake(160, 160);
            [[PHImageManager defaultManager] requestImageForAsset: _phAsset targetSize:thumbsize contentMode:PHImageContentModeAspectFill options:request resultHandler:^(UIImage *result, NSDictionary *info) {
                
                @autoreleasepool {
                    CGFloat minWidth = MIN(result.size.width, result.size.height);
                    CGPoint offset = CGPointMake((result.size.width - minWidth) * 0.5, (result.size.height - minWidth) * 0.5);
                    CGFloat scale = thumbsize.width / (minWidth * result.scale);
                    
                    UIGraphicsBeginImageContextWithOptions(thumbsize, NO, 1.f);
                    CGContextRef contextRef = UIGraphicsGetCurrentContext();
                    CGContextTranslateCTM(contextRef, 0, thumbsize.height);
                    CGContextScaleCTM(contextRef, scale, -scale);
                    CGContextDrawImage(contextRef, CGRectMake(-offset.x, -offset.y, result.size.width, result.size.height), result.CGImage);
                    _thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }
                
            }];
        }
        else
#endif
        {
            _thumbnailImage = [UIImage imageWithCGImage: _alAsset.thumbnail];
        }
    }
    return _thumbnailImage;
}

- (UIImage *)aspectRatioThumbnail
{
    if (!_hasGotAspectRatioThumbnail) {
        _hasGotAspectRatioThumbnail = YES;
#ifdef __AMPHOTOLIB_USE_PHOTO__
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeFast;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = YES;
            
            CGSize thumbsize = CGSizeMake(160, 160);
            [[PHImageManager defaultManager] requestImageForAsset: _phAsset targetSize:thumbsize contentMode:PHImageContentModeAspectFit options:request resultHandler:^(UIImage *result, NSDictionary *info) {
                _aspectRatioThumbnailImage = result;
            }];
        }
        else
#endif
        {
            _aspectRatioThumbnailImage = [UIImage imageWithCGImage: _alAsset.aspectRatioThumbnail];
        }
    }
    return _aspectRatioThumbnailImage;
}

- (UIImage *)fullScreenImage
{
    if (AMAssetMediaTypeImage != _mediaType) {
        return nil;
    }
    if (!_hasGotFullScreenImage) {
        _hasGotFullScreenImage = YES;
#ifdef __AMPHOTOLIB_USE_PHOTO__
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeExact;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = YES;
            
            CGFloat scale = [UIScreen mainScreen].scale;
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            screenSize.width *= scale;
            screenSize.height *= scale;
            [[PHImageManager defaultManager] requestImageForAsset: _phAsset targetSize:screenSize contentMode:PHImageContentModeAspectFit options:request resultHandler:^(UIImage *result, NSDictionary *info) {
                _fullScreenImage = result;
            }];
        }
        else
#endif
        {
            ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
            _fullScreenImage = [UIImage imageWithCGImage: defaultAssetRep.fullScreenImage scale:defaultAssetRep.scale orientation:(UIImageOrientation)defaultAssetRep.orientation];
        }
    }
    return _fullScreenImage;
}

- (UIImage *)fullResolutionImage
{
    if (AMAssetMediaTypeImage != _mediaType) {
        return nil;
    }
    if (!_hasGotFullResolutionImage) {
        _hasGotFullResolutionImage = YES;
#ifdef __AMPHOTOLIB_USE_PHOTO__
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeNone;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = YES;
            
            [[PHImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                _fullResolutionImage = [UIImage imageWithData: imageData];
            }];
        }
        else
#endif
        {
            ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
            _fullResolutionImage = [UIImage imageWithCGImage: defaultAssetRep.fullResolutionImage scale:defaultAssetRep.scale orientation:(UIImageOrientation)defaultAssetRep.orientation];
        }
    }
    return _fullResolutionImage;
}

- (NSTimeInterval)duration
{
    return _duration;
}

- (void)getInfo
{
    if (!_hasGotInfo) {
        _hasGotInfo = YES;
#ifdef __AMPHOTOLIB_USE_PHOTO__
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            if (PHAssetMediaTypeImage == _mediaType) {
                PHImageRequestOptions *request = [PHImageRequestOptions new];
                request.version = PHImageRequestOptionsVersionCurrent;
                request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                request.resizeMode = PHImageRequestOptionsResizeModeNone;
                request.synchronous = YES;
                
                [[PHImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                    _fileSize = imageData.length;
                    _UTI = dataUTI;
                    _localIdentifier = _phAsset.localIdentifier;
                    _assetURL = [info objectForKey:@"PHImageFileURLKey"];
                    _orientation = orientation;
                }];
            }
            else if (PHAssetMediaTypeVideo == _mediaType) {
                PHVideoRequestOptions *request = [PHVideoRequestOptions new];
                request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
                request.version = PHVideoRequestOptionsVersionCurrent;
                request.networkAccessAllowed = YES;
                
                NSConditionLock* assetReadLock = [[NSConditionLock alloc] initWithCondition:kAMASSETMETADATA_PENDINGREADS];
                [[PHImageManager defaultManager] requestPlayerItemForVideo:_phAsset options:request resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                    AVURLAsset *urlAsset = (AVURLAsset *)playerItem.asset;
                    NSNumber *fileSize = nil;;
                    [urlAsset.URL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
                    _fileSize = [fileSize unsignedLongLongValue];
                    _UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([urlAsset.URL pathExtension]), NULL));
                    _localIdentifier = _phAsset.localIdentifier;
                    _assetURL = urlAsset.URL;
                    
                    [assetReadLock lock];
                    [assetReadLock unlockWithCondition:kAMASSETMETADATA_ALLFINISHED];
                }];
                [assetReadLock lockWhenCondition:kAMASSETMETADATA_ALLFINISHED];
                [assetReadLock unlock];
                assetReadLock = nil;
            }
        }
        else
#endif
        {
            ALAssetRepresentation *defaultRep = _alAsset.defaultRepresentation;
            _fileSize = defaultRep.size;
            _UTI = defaultRep.UTI;
            _assetURL = [_alAsset valueForProperty: ALAssetPropertyAssetURL];
            _localIdentifier = _assetURL.absoluteString;
            _orientation = (UIImageOrientation)_alAsset.defaultRepresentation.orientation;
        }
    }
}

+ (void)fetchAsset:(AMPhotoAsset *)asset rawData:(void (^)(NSData *, NSURL *, ALAssetRepresentation *))resultBlock
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        if (AMAssetMediaTypeImage == asset.mediaType) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeNone;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = NO;
            request.networkAccessAllowed = YES;
            
            [[PHImageManager defaultManager] requestImageDataForAsset:asset.asPHAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                resultBlock(imageData, nil, nil);
            }];
        }
        else if (AMAssetMediaTypeVideo == asset.mediaType) {
            PHVideoRequestOptions *request = [PHVideoRequestOptions new];
            request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            request.version = PHVideoRequestOptionsVersionCurrent;
            request.networkAccessAllowed = YES;
            
            [[PHImageManager defaultManager] requestPlayerItemForVideo:asset.asPHAsset options:request resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                AVURLAsset *urlAsset = (AVURLAsset *)playerItem.asset;
                resultBlock(nil, urlAsset.URL, nil);
            }];
        }
    }
    else
#endif
    {
        resultBlock(nil, nil, asset.asALAsset.defaultRepresentation);
    }
}

+ (void)fetchAsset:(AMPhotoAsset *)asset withImageType:(AMAssetImageType)imageType imageResult:(void (^)(UIImage *))resultBlock
{
    if (AMAssetMediaTypeImage != asset.mediaType) {
        if ((AMAssetImageTypeFullResolution == imageType) || (AMAssetImageTypeFullScreen == imageType)) {
            resultBlock(nil);
            return;
        }
    }
    
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        PHImageRequestOptions *request = [PHImageRequestOptions new];
        request.version = PHImageRequestOptionsVersionCurrent;
        //PHImageRequestOptionsDeliveryModeHighQualityFormat: Make sure clients will get one result only
        request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        request.synchronous = NO;
        request.networkAccessAllowed = YES;
        
        CGSize targetSize = CGSizeZero;
        BOOL needSquareCrop = NO;
        switch (imageType) {
            case AMAssetImageTypeThumbnail:
                needSquareCrop = YES;
            case AMAssetImageTypeAspectRatioThumbnail:
            {
                request.resizeMode = PHImageRequestOptionsResizeModeFast;
                targetSize = CGSizeMake(160, 160);
            }
                break;
            case AMAssetImageTypeFullScreen:
            {
                CGFloat scale = [UIScreen mainScreen].scale;
                CGSize screenSize = [UIScreen mainScreen].bounds.size;
                targetSize = CGSizeMake(screenSize.width *= scale, screenSize.height *= scale);
                request.resizeMode = PHImageRequestOptionsResizeModeExact;
            }
                break;
            case AMAssetImageTypeFullResolution:
            {
                request.resizeMode = PHImageRequestOptionsResizeModeNone;
            }
                break;
            default:
                break;
        }
        
        if (AMAssetImageTypeFullResolution != imageType) {
            [[PHImageManager defaultManager] requestImageForAsset:[asset asPHAsset] targetSize:targetSize contentMode:PHImageContentModeAspectFit options:request resultHandler:^(UIImage *result, NSDictionary *info) {
                UIImage *resultImage = result;
                if (needSquareCrop) {
                    @autoreleasepool {
                        CGFloat minWidth = MIN(result.size.width, result.size.height);
                        CGPoint offset = CGPointMake((result.size.width - minWidth) * 0.5, (result.size.height - minWidth) * 0.5);
                        
                        UIGraphicsBeginImageContextWithOptions(CGSizeMake(minWidth, minWidth), NO, 1.f);
                        CGContextRef contextRef = UIGraphicsGetCurrentContext();
                        CGContextDrawImage(contextRef, CGRectMake(-offset.x, -offset.y, result.size.width, result.size.height), result.CGImage);
                        resultImage = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                    }
                }
                resultBlock(result);
            }];
        }
        else {
            [[PHImageManager defaultManager] requestImageDataForAsset:[asset asPHAsset] options:request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                if (nil == imageData) {
                    resultBlock(nil);
                }
                else {
                    resultBlock([UIImage imageWithData:imageData]);
                }
            }];
        }
    }
    else
#endif
    {
        ALAsset *alAsset = [asset asALAsset];
        ALAssetRepresentation *defaultRep = alAsset.defaultRepresentation;
        CGImageRef imageRef = NULL;
        switch (imageType) {
            case AMAssetImageTypeThumbnail:
            {
                imageRef = alAsset.thumbnail;
            }
                break;
            case AMAssetImageTypeAspectRatioThumbnail:
            {
                imageRef = alAsset.aspectRatioThumbnail;
            }
                break;
            case AMAssetImageTypeFullScreen:
            {
                imageRef = defaultRep.fullScreenImage;
            }
                break;
            case AMAssetImageTypeFullResolution:
            {
                imageRef = defaultRep.fullResolutionImage;
            }
                break;
            default:
                break;
        }
        if (NULL == imageRef) {
            resultBlock(nil);
        }
        else {
            if (AMAssetImageTypeFullResolution != imageType) {
                resultBlock([UIImage imageWithCGImage:imageRef]);
            }
            else {
                resultBlock([UIImage imageWithCGImage:imageRef scale:defaultRep.scale orientation:(UIImageOrientation)defaultRep.orientation]);
            }
        }
    }
}

@end
