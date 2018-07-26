//
//  EvaluateResultsPhotoViewController.m
//  tflite_camera_example
//
//  Created by Philip Dow on 7/25/18.
//  Copyright © 2018 doc.ai. All rights reserved.
//

#import "EvaluateResultsPhotoViewController.h"

#import "ImageInputPreviewView.h"
#import "ModelBundle.h"
#import "AlbumPhotoEvaluator.h"
#import "UserDefaults.h"
#import "VisionModel.h"
#import "NSArray+Extensions.h"
#import "ResultInfoView.h"

@interface EvaluateResultsPhotoViewController ()

@property (nonatomic, readwrite) UIImage *image;

@end

@implementation EvaluateResultsPhotoViewController

+ (PHImageRequestOptions*)imageRequestOptions {
    static PHImageRequestOptions *options = nil;
    
    if ( options != nil ) {
        return options;
    }
    
    options = [[PHImageRequestOptions alloc] init];
    
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.networkAccessAllowed = YES;
    options.synchronous = YES;
    
    return options;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    assert(self.modelBundle != nil);
    assert(self.results != nil);
    assert(self.imageManager != nil);
    assert(self.album != nil);
    assert(self.asset != nil);
    
    // Preferences
    
    self.imageInputPreviewView.hidden = ![NSUserDefaults.standardUserDefaults boolForKey:kPrefsShowInputBuffers];
    self.imageInputPreviewView.showsAlphaChannel = [NSUserDefaults.standardUserDefaults boolForKey:kPrefsShowInputBufferAlpha];
    
    // Load Image
    
    [self.imageManager
        requestImageForAsset:self.asset
        targetSize:PHImageManagerMaximumSize
        contentMode:PHImageContentModeAspectFill
        options:[EvaluateResultsPhotoViewController imageRequestOptions]
        resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
            if ( result == nil ) {
                NSLog(@"Unable to request image for asset %@", self.asset.localIdentifier);
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = result;
            });
    }];
    
    // Run the model on the asset
    
    // We could run the model on the image returned here or the asset but they should be the same
    // And we want to run the same process that produced the results we recieved
    
    [self runModelOnAsset:self.asset];
}

- (void)setImage:(UIImage *)image {
    _image = image;
    
    self.imageView.image = _image;
}

- (void)runModelOnAsset:(PHAsset*)asset {
    id<VisionModel> model = (id<VisionModel>)self.modelBundle.newModel;
    
    if ( ![model conformsToProtocol:@protocol(VisionModel)] ) {
        NSLog(@"Model does not conform to vision protocol: %@", model.identifier);
        return;
    }
    
    AlbumPhotoEvaluator *evaluator = [[AlbumPhotoEvaluator alloc] initWithModel:model photo:asset album:self.album cachingManager:self.imageManager];
    
    [evaluator evaluateWithCompletionHandler:^(NSDictionary * _Nonnull result) {
        
        NSDictionary *providedInference = self.results[@"evaluation"][@"inference_results"];
        NSDictionary *myInference = result[@"evaluation"][@"inference_results"];
        
        if ( ![providedInference isEqualToDictionary:myInference] ) {
            NSLog(@"Expected provivided inference and new inference to match but they did not, provided inference: %@, new inference: %@", providedInference, myInference);
        }
        
        // Visualize last pixel buffer used by model
    
        if ( [NSUserDefaults.standardUserDefaults boolForKey:kPrefsShowInputBuffers] ) {
            self.imageInputPreviewView.pixelBuffer = model.inputPixelBuffer;
        }
        
        // Show the inference results
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self displayResults:myInference];
        });
    }];
}

- (void)displayResults:(NSDictionary*)inference {
    if ( inference.count == 0 ) {
        self.resultInfoView.classifications = @"None";
        self.title = @"No Inference";
        return;
    }
    
    NSArray *keys = [inference keysSortedByValueUsingSelector:@selector(compare:)].reversed;
    NSMutableString *description = [NSMutableString string];
    
    for ( NSString *key in keys ) {
        NSNumber *value = inference[key];
        [description appendFormat:@"(%.2f) %@\n", value.floatValue, key];
    }
    
    [description deleteCharactersInRange:NSMakeRange(description.length-1, 1)];
    
    self.resultInfoView.classifications = description;
}

@end
