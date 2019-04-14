/***************************************************************
 * Copyright © 2017 HERE Global B.V. All rights reserved. *
 **************************************************************/

#import <Foundation/Foundation.h>

@interface HMACGenerator : NSObject

 + (NSString *)hmacSHA384From:(NSString*)appKey creationTimeSec:(int32_t)creationTimeSec withKey:(NSString *)key;

@end
