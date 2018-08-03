//
//  ImageEvaluator.m
//  Net Runner
//
//  Created by Philip Dow on 7/18/18.
//  Copyright © 2018 doc.ai. All rights reserved.
//

#import "ImageEvaluator.h"

#import "UIImage+CVPixelBuffer.h"
#import "ObjcDefer.h"
#import "CVPixelBufferEvaluator.h"
#import "Utilities.h"

@interface ImageEvaluator ()

@property (readwrite) NSDictionary *results;
@property (readwrite) id<VisionModel> model;
@property (readwrite) UIImage *image;

@end

@implementation ImageEvaluator {
    dispatch_once_t _once;
}

- (instancetype)initWithModel:(id<VisionModel>)model image:(UIImage*)image {
    if (self = [super init]) {
        _image = image;
        _model = model;
    }
    
    return self;
}

- (void)evaluateWithCompletionHandler:(nullable EvaluatorCompletionBlock)completionHandler {
    dispatch_once(&_once, ^{
    
    defer_block {
        self.model = nil;
        self.image = nil;
    };
    
    CVPixelBufferRef pixelBuffer = self.image.pixelBuffer; // Returns ARGB
    
    CVPixelBufferEvaluator *pixelBufferEvaluator = [[CVPixelBufferEvaluator alloc] initWithModel:self.model pixelBuffer:pixelBuffer orientation:kCGImagePropertyOrientationUp];
    
    [pixelBufferEvaluator evaluateWithCompletionHandler:^(NSDictionary * _Nonnull result) {
        self.results = result;
        safe_block(completionHandler, self.results);
    }];
    
    }); // dispatch_once
}

@end
