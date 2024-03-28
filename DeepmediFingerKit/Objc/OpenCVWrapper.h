//
//  OpenCVWraaper.h
//  Avocado_ios
//
//  Created by 딥메디 on 2020/10/28.
//

#ifdef __cplusplus
#include <opencv2/core/core.hpp>
#endif

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface OpenCVWrapper : NSObject

+ (NSString *)openCVVersionString;
+ (NSArray *)preccessbuffer:(CMSampleBufferRef)sampleBuffer device: (NSString *)device;

@end
