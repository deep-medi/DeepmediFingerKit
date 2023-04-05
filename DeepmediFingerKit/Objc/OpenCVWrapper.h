//
//  OpenCVWraaper.h
//  Avocado_ios
//
//  Created by 딥메디 on 2020/10/28.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface OpenCVWrapper : NSObject

+ (NSString *)openCVVersionString;
+ (NSArray *)preccessbuffer:(CMSampleBufferRef)sampleBuffer hasTorch:(BOOL)isTorch device: (NSString *)device;

@end
