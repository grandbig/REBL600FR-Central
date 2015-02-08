//
//  NSString+Conversion.m
//  BLECentralSample
//
//  Created by 加藤 雄大 on 2015/02/09.
//  Copyright (c) 2015年 grandbig.github.io. All rights reserved.
//

#import "NSString+Conversion.h"

@implementation NSString (NSString_Conversion)

#pragma mark - Data Conversion
- (NSData *)dataFromHexString {
    const char *chars = [self UTF8String];
    int i = 0, len = self.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}

@end
