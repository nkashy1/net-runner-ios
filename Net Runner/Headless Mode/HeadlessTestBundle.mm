//
//  HeadlessTestBundle.m
//  tflite_camera_example
//
//  Created by Philip Dow on 7/19/18.
//  Copyright © 2018 doc.ai. All rights reserved.
//

#import "HeadlessTestBundle.h"

#import "HeadlessTestBundleManager.h"
#import "EvaluationMetricFactory.h"
#import "EvaluationMetric.h"

@interface HeadlessTestBundle ()

@property (readwrite) NSString *path;
@property (readwrite) NSDictionary *info;

@property (readwrite) NSString *name;
@property (readwrite) NSString *identifier;
@property (readwrite) NSString *version;

@property (readwrite) NSArray<NSString*> *modelIds;
@property (readwrite) NSArray<NSDictionary*> *images;
@property (readwrite) NSDictionary *labels;
@property (readwrite) NSDictionary *options;

@property (readwrite) NSUInteger iterations;
@property (readwrite) id<EvaluationMetric> metric;

@end

@implementation HeadlessTestBundle

- (instancetype) initWithPath:(NSString*)path {
    if (self = [super init]) {
        
        // Read json
        
        NSString *jsonPath = [path stringByAppendingPathComponent:kTFTestInfoFile];
        NSData *data = [NSData dataWithContentsOfFile:jsonPath];
        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if ( json == nil ) {
            NSLog(@"Error reading json file at path %@, error %@", jsonPath, jsonError);
            return nil;
        }
        
        // Required properties
        
        assert(json[@"id"] != nil);
        assert(json[@"name"] != nil);
        assert(json[@"version"] != nil);
        assert(json[@"models"] != nil);
        assert(json[@"options"] != nil);
        assert(json[@"images"] != nil);
        assert(json[@"labels"] != nil);
        
        // Initialize
        
        _path = path;
        _info = json;
        
        _name = json[@"name"];
        _identifier = json[@"id"];
        _version = json[@"version"];
        
        _modelIds = json[@"models"];
        _options = json[@"options"];
        _images = json[@"images"];
        
        // Options
        
        _iterations = [_options[@"iterations"] unsignedIntegerValue];
        
        if ( NSString *metricName = _options[@"metric"] ) {
            _metric = [EvaluationMetricFactory.sharedInstance evaluationMetricForName:metricName];
        }
        
        // Labels
        
        if ( NSArray<NSDictionary*> *labelsArray = json[@"labels"] ) {
            NSMutableDictionary *labels = [[NSMutableDictionary alloc] init];
            for ( NSDictionary* label in labelsArray ) {
                labels[label[@"path"]] = label[@"inference_results"];
            }
            _labels = [labels copy];
        }
    }
    
    return self;
}

- (NSString*)filePathForImageInfo:(NSDictionary*)imageInfo {
    NSString *imageType = imageInfo[@"type"];
    NSString *imagePath = imageInfo[@"path"];
    
    assert([imageType isEqualToString:@"file"]);
    return [self.path stringByAppendingPathComponent:imagePath];
}

@end
