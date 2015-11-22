//
//  AMPhotoAsset.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoAsset.h"

#define AMPhotoAssetThumbnailSize CGSizeMake(160, 160)

@interface AMPhotoAsset ()
{
    ALAsset *_alAsset;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    PHAsset *_phAsset;
#endif
    AMAssetMediaType _mediaType;
    unsigned long long _fileSize;
    
    BOOL _hasGotInfo;
    BOOL _hasGotFullMetaData;
    NSMutableDictionary *_metaData;
    NSURL *_assetURL;
    NSString *_UTI;
    NSString *_mimeType;
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

- (NSString *)localIdentifier
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _localIdentifier;
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

- (NSString *)mimeType
{
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _mimeType;
}

- (UIImage *)thumbnail
{
    __block UIImage *image = nil;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        CGSize pixelSize = CGSizeMake(_phAsset.pixelWidth, _phAsset.pixelHeight);
        CGFloat pixelWidth = MIN(pixelSize.width, pixelSize.height);
        CGRect cropRect = CGRectMake((pixelSize.width - pixelWidth) * 0.5, (pixelSize.height - pixelWidth) * 0.5, pixelWidth, pixelWidth);
        
        PHImageRequestOptions *request = [PHImageRequestOptions new];
        request.resizeMode = PHImageRequestOptionsResizeModeExact;
        request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        request.version = PHImageRequestOptionsVersionCurrent;
        request.normalizedCropRect = CGRectMake(cropRect.origin.x / pixelSize.width, cropRect.origin.y / pixelSize.height, cropRect.size.width / pixelSize.width, cropRect.size.height / pixelSize.height);
        request.synchronous = YES;
        
        [[PHImageManager defaultManager] requestImageForAsset: _phAsset targetSize:AMPhotoAssetThumbnailSize contentMode:PHImageContentModeAspectFill options:request resultHandler:^(UIImage *result, NSDictionary *info) {
            image = result;
        }];
    }
    else
#endif
    {
        image = [UIImage imageWithCGImage: _alAsset.thumbnail];
    }
    return image;
}

- (UIImage *)aspectRatioThumbnail
{
    __block UIImage *image = nil;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        PHImageRequestOptions *request = [PHImageRequestOptions new];
        request.resizeMode = PHImageRequestOptionsResizeModeFast;
        request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        request.version = PHImageRequestOptionsVersionCurrent;
        request.synchronous = YES;
        
        [[PHImageManager defaultManager] requestImageForAsset: _phAsset targetSize:AMPhotoAssetThumbnailSize contentMode:PHImageContentModeAspectFit options:request resultHandler:^(UIImage *result, NSDictionary *info) {
            image = result;
        }];
    }
    else
#endif
    {
        image = [UIImage imageWithCGImage: _alAsset.aspectRatioThumbnail];
    }
    return image;
}

- (UIImage *)fullScreenImage
{
    __block UIImage *image = nil;
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
            image = result;
        }];
    }
    else
#endif
    {
        ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
        image = [UIImage imageWithCGImage: defaultAssetRep.fullScreenImage scale:defaultAssetRep.scale orientation:(UIImageOrientation)defaultAssetRep.orientation];
    }
    return image;
}

- (UIImage *)fullResolutionImage
{
    if (AMAssetMediaTypeImage != _mediaType) {
        return nil;
    }
    __block UIImage *image = nil;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        PHImageRequestOptions *request = [PHImageRequestOptions new];
        request.resizeMode = PHImageRequestOptionsResizeModeNone;
        request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        request.version = PHImageRequestOptionsVersionCurrent;
        request.synchronous = YES;
        
        [[PHImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            image = [UIImage imageWithData: imageData];
        }];
    }
    else
#endif
    {
        ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
        image = [UIImage imageWithCGImage: defaultAssetRep.fullResolutionImage scale:defaultAssetRep.scale orientation:(UIImageOrientation)defaultAssetRep.orientation];
    }
    return image;
}

- (NSData *)imageFileData {
    if (AMAssetMediaTypeImage != _mediaType) {
        return nil;
    }
    __block NSData *imageFileData = nil;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        PHImageRequestOptions *request = [PHImageRequestOptions new];
        request.resizeMode = PHImageRequestOptionsResizeModeNone;
        request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        request.version = PHImageRequestOptionsVersionCurrent;
        request.synchronous = YES;

        [[PHImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            imageFileData = imageData;
        }];
    }
    else
#endif
        {
        ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
        long long size = defaultAssetRep.size;

        if (size > 0) {
            uint8_t *tempData = malloc((uint8_t)size);
            [defaultAssetRep getBytes:tempData fromOffset:0 length:(NSUInteger)size error:nil];
            imageFileData = [NSData dataWithBytesNoCopy:tempData length:(NSUInteger)size freeWhenDone:YES];
        }
        }
    return imageFileData;
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
                    NSURL *videoURL = [[self class] fetchPlayerItemURL:playerItem];
                    NSNumber *fileSize = nil;;
                    if ([videoURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil]) {
                        _fileSize = [fileSize unsignedLongLongValue];
                    }
                    else {
                        _fileSize = 0;
                    }
                    _UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([videoURL pathExtension]), NULL));
                    _localIdentifier = _phAsset.localIdentifier;
                    _assetURL = videoURL;
                    
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
            _orientation = (UIImageOrientation)defaultRep.orientation;
            _UTI = defaultRep.UTI;
            _assetURL = defaultRep.url;
            _localIdentifier = _assetURL.absoluteString;
        }
    }
    CFStringRef UTI = (__bridge CFStringRef)_UTI;
    if (NULL != UTI) {
        _mimeType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    }
}

+ (NSURL *)fetchPlayerItemURL:(AVPlayerItem *)playerItem
{
    AVAsset *videoAsset = playerItem.asset;
    NSURL *videoURL = nil;
    if ([videoAsset isKindOfClass:[AVURLAsset class]]) {
        AVURLAsset *urlAsset = (AVURLAsset *)videoAsset;
        videoURL = urlAsset.URL;
    }
    else if ([videoAsset isKindOfClass:[AVComposition class]]) {
        AVComposition *composition = (AVComposition *)videoAsset;
        AVCompositionTrack *videoTrack = nil;
        for (AVCompositionTrack *track in composition.tracks) {
            if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
                videoTrack = track;
                break;
            }
        }
        if (nil != videoTrack) {
            NSArray *segments = videoTrack.segments;
            for (AVCompositionTrackSegment *segment in segments) {
                videoURL = segment.sourceURL;
                break;
            }
        }
    }
    return videoURL;
}

+ (void)fetchAsset:(AMPhotoAsset *)asset rawData:(void (^)(NSData *, AVPlayerItem *, ALAssetRepresentation *))resultBlock
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
                resultBlock(nil, playerItem, nil);
            }];
        }
    }
    else
#endif
    {
        ALAssetRepresentation *representation = asset.asALAsset.defaultRepresentation;
        AVPlayerItem *playerItem = nil;
        if (AMAssetMediaTypeVideo == asset.mediaType) {
            AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:representation.url options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @NO}];
            playerItem = [AVPlayerItem playerItemWithAsset:urlAsset];
        }
        resultBlock(nil, playerItem, representation);
    }
}

+ (void)fetchAsset:(AMPhotoAsset *)asset withImageType:(AMAssetImageType)imageType imageResult:(void (^)(UIImage *))resultBlock
{
    if (AMAssetMediaTypeImage != asset.mediaType) {
        if (AMAssetImageTypeFullResolution == imageType) {
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
        switch (imageType) {
            case AMAssetImageTypeThumbnail:
            {
                targetSize = AMPhotoAssetThumbnailSize;
                CGSize pixelSize = asset.dimensions;
                CGFloat pixelWidth = MIN(pixelSize.width, pixelSize.height);
                CGRect cropRect = CGRectMake((pixelSize.width - pixelWidth) * 0.5, (pixelSize.height - pixelWidth) * 0.5, pixelWidth, pixelWidth);
                request.normalizedCropRect = CGRectMake(cropRect.origin.x / pixelSize.width, cropRect.origin.y / pixelSize.height, cropRect.size.width / pixelSize.width, cropRect.size.height / pixelSize.height);
                request.resizeMode = PHImageRequestOptionsResizeModeExact;
                request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
                break;
            }
            case AMAssetImageTypeAspectRatioThumbnail:
            {
                targetSize = AMPhotoAssetThumbnailSize;
                request.resizeMode = PHImageRequestOptionsResizeModeFast;
                request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
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
