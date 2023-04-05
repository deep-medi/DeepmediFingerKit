//
//  ObjcMapper.h
//  healthCare
//
//  Created by KangNamgyu on 8/17/18.
//  Copyright © 2018 deepmedi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonHMAC.h>

@interface ObjcMapper:NSObject

/**
 SHA256 인코딩
 */
+ (NSString *)hmacSHA256:(NSString *)key message:(NSString *)data;
@end

