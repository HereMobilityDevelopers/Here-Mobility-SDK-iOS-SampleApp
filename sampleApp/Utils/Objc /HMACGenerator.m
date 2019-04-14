#import "HMACGenerator.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation HMACGenerator

 + (NSString *)hmacSHA384From:(NSString*)appKey creationTimeSec:(int32_t)creationTimeSec withKey:(NSString *)key;
{
    NSString *appKey64 = [HMACGenerator base64forData:[appKey dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *creation = [NSString stringWithFormat:@"%d",creationTimeSec];

    NSString *data = [NSString stringWithFormat:@"%@.%@",appKey64,creation];

    NSData *hash = [HMACGenerator hmacSHA384:data withKey:key];

    NSString *hashStr = hash.description;
    NSCharacterSet *trim = [NSCharacterSet characterSetWithCharactersInString:@"<> "];
    NSString *result = [[hashStr componentsSeparatedByCharactersInSet:trim] componentsJoinedByString:@""];

    return result;
}


 + (NSData *)hmacSHA384:(NSString*)data withKey:(NSString *)key
{
    const char *cKey = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA384_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA384, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *hash = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    return hash;
}

+ (NSString*)base64forData:(NSData*)theData {
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];

    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;

    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;

            if (j < length) {  value |= (0xFF & input[j]);  }  }  NSInteger theIndex = (i / 3) * 4;  output[theIndex + 0] = table[(value >> 18) & 0x3F];
        output[theIndex + 1] = table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6) & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0) & 0x3F] : '=';
    }

    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

@end
