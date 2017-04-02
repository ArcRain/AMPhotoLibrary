//
//  AMALAsset.m
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import "AMALAsset.h"

@interface AMALAsset ()
{
    ALAsset *_alAsset;
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

@implementation AMALAsset

+ (instancetype)photoAssetWithALAsset:(ALAsset *)asset {
    return [[[self class] alloc] initWithALAsset: asset];
}

- (instancetype)initWithALAsset:(ALAsset *)asset {
    self = [super init];
    if (self) {
        _alAsset = asset;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _hasGotInfo = NO;
    _hasGotFullMetaData = NO;
    _duration = 0.f;
    _orientation = UIImageOrientationUp;
    
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

- (id)wrappedInstance {
    return _alAsset;
}

- (AMAssetMediaType)mediaType {
    return _mediaType;
}

- (CGSize)dimensions {
    return _alAsset.defaultRepresentation.dimensions;
}

- (NSDictionary *)metadata {
    if (!_hasGotFullMetaData) {
        _hasGotFullMetaData = YES;
        
        ALAssetRepresentation *defaultRep = _alAsset.defaultRepresentation;
        _metaData = [NSMutableDictionary dictionaryWithDictionary:defaultRep.metadata];    }
    return _metaData;
}

- (NSDate *)creationDate {
    return [_alAsset valueForProperty: ALAssetPropertyDate];
}

- (CLLocation *)location {
    return [_alAsset valueForProperty: ALAssetPropertyLocation];
}

- (NSString *)localIdentifier {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _localIdentifier;
}

- (NSURL *)assetURL {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _assetURL;
}

- (unsigned long long)fileSize {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _fileSize;
}

- (UIImageOrientation)orientation {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _orientation;
}

- (NSString *)UTI {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _UTI;
}

- (NSString *)mimeType {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _mimeType;
}

- (UIImage *)thumbnail {
    __block UIImage *image = nil;
    [[self class] fetchAsset:self withImageType:AMAssetImageTypeThumbnail syncMode:YES completion:^(UIImage *result) {
        image = result;
    }];
    return image;
}

- (UIImage *)aspectRatioThumbnail {
    __block UIImage *image = nil;
    [[self class] fetchAsset:self withImageType:AMAssetImageTypeAspectRatioThumbnail syncMode:YES completion:^(UIImage *result) {
        image = result;
    }];
    return image;
}

- (UIImage *)fullScreenImage {
    __block UIImage *image = nil;
    [[self class] fetchAsset:self withImageType:AMAssetImageTypeFullScreen syncMode:YES completion:^(UIImage *result) {
        image = result;
    }];
    return image;
}

- (UIImage *)fullResolutionImage {
    __block UIImage *image = nil;
    [[self class] fetchAsset:self withImageType:AMAssetImageTypeFullResolution syncMode:YES completion:^(UIImage *result) {
        image = result;
    }];
    return image;
}

- (NSData *)imageFileData {
    if (AMAssetMediaTypeImage != _mediaType) {
        return nil;
    }
    
    ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
    long long size = defaultAssetRep.size;
    
    NSData *imageFileData = nil;
    if (size > 0) {
        uint8_t *tempData = malloc((uint8_t)size);
        [defaultAssetRep getBytes:tempData fromOffset:0 length:(NSUInteger)size error:nil];
        imageFileData = [NSData dataWithBytesNoCopy:tempData length:(NSUInteger)size freeWhenDone:YES];
    }
    return imageFileData;
}

- (NSTimeInterval)duration {
    return _duration;
}

- (void)getInfo {
    if (!_hasGotInfo) {
        _hasGotInfo = YES;
        ALAssetRepresentation *defaultRep = _alAsset.defaultRepresentation;
        _fileSize = defaultRep.size;
        _orientation = (UIImageOrientation)defaultRep.orientation;
        _UTI = defaultRep.UTI;
        _assetURL = defaultRep.url;
        _localIdentifier = _assetURL.absoluteString;
    }
    CFStringRef UTI = (__bridge CFStringRef)_UTI;
    if (NULL != UTI) {
        _mimeType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    }
}

+ (void)fetchAsset:(id<AMPhotoAsset>)asset rawData:(void (^)(NSData *, AVPlayerItem *))resultBlock {
    ALAsset *alAsset = asset.wrappedInstance;
    ALAssetRepresentation *representation = alAsset.defaultRepresentation;
    AVPlayerItem *playerItem = nil;
    NSData *data = nil;
    if (AMAssetMediaTypeImage == asset.mediaType) {
        unsigned long long fileSize = representation.size;
        BytePtr bytes = malloc(sizeof(Byte) * fileSize);
        NSUInteger read = [representation getBytes:bytes fromOffset:0 length:fileSize error:nil];
        if ((read > 0) && (read == fileSize)) {
            data = [NSData dataWithBytesNoCopy:bytes length:read freeWhenDone:YES];
        }
        else {
            free(bytes);
        }
    }
    else if (AMAssetMediaTypeVideo == asset.mediaType) {
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:representation.url options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @NO}];
        playerItem = [AVPlayerItem playerItemWithAsset:urlAsset];
    }
    resultBlock(data, playerItem);
}

+ (void)fetchAsset:(id<AMPhotoAsset>)asset
     withImageType:(AMAssetImageType)imageType
          syncMode:(BOOL)isSynchronous
        completion:(void (^)(UIImage *))resultBlock {
    if (AMAssetMediaTypeImage != asset.mediaType) {
        if (AMAssetImageTypeFullResolution == imageType) {
            resultBlock(nil);
            return;
        }
    }
    
    ALAsset *alAsset = asset.wrappedInstance;
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

@end
