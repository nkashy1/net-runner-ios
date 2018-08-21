//
//  TIODataInterface.h
//  TensorIO
//
//  Created by Philip Dow on 8/5/18.
//  Copyright © 2018 doc.ai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Describes an input or output layer. Used internally by a model when parsing its description.
 */

@protocol TIOLayerDescription <NSObject>

/**
 * `YES` if this data is quantized (bytes of type uint8_t), `NO` if not (bytes of type float_t)
 */

@property (readonly, getter=isQuantized) BOOL quantized;

@end

NS_ASSUME_NONNULL_END