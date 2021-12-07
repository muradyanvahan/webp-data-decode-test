//
//  ViewController.m
//  WebPCSMode
//
//  Created by Vahan Muradyan on 07.12.21.
//

#import "ViewController.h"
#import <libwebp/decode.h>

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (IBAction)rgbA:(id)sender {
    self.imageView.image = [self imageWithWebPData:[self webpData] usebgrAMode:NO];
}

- (IBAction)bgrA:(id)sender {
    self.imageView.image = [self imageWithWebPData:[self webpData] usebgrAMode:YES];
}

- (NSData *)webpData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"111" ofType:@"webp"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    return data;
}

- (UIImage *)imageWithWebPData:(NSData *)webPData usebgrAMode:(BOOL)usebgrAMode {
    WebPDecoderConfig cfg;
    WebPInitDecoderConfig(&cfg);
    if (WebPGetFeatures(webPData.bytes, webPData.length, &cfg.input) != VP8_STATUS_OK) {
        return nil;
    }
    CGSize size = CGSizeMake(cfg.input.width, cfg.input.height);
    CGContextRef ctx = NULL;
    UIImage *image;
    UIGraphicsBeginImageContextWithOptions(size, !cfg.input.has_alpha, 1.0);
    if (!cfg.input.has_alpha) {
        NSLog(@"cfffff");
    } else {
        NSLog(@"cddfdff222");
    }
    ctx = UIGraphicsGetCurrentContext();
    NSAssert(ctx != NULL, @"Failed to get CG context.");
    BOOL getColorspaceFailed = NO;
    cfg.output.colorspace = webp_cs_mode_from_cg_bitmap_info(CGBitmapContextGetBitmapInfo(ctx),
                                                             &getColorspaceFailed, usebgrAMode);
    if (getColorspaceFailed) {
        return nil;
    }
    cfg.output.width = cfg.input.width;
    cfg.output.height = cfg.input.height;
    cfg.output.is_external_memory = 1;
    cfg.output.u.RGBA.rgba = (uint8_t *)CGBitmapContextGetData(ctx);
    cfg.output.u.RGBA.stride = (int)CGBitmapContextGetBytesPerRow(ctx);
    cfg.output.u.RGBA.size = cfg.output.u.RGBA.stride * cfg.input.height;
    int status = WebPDecode(webPData.bytes, webPData.length, &cfg);
    if (status == VP8_STATUS_OK) {
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    return status == VP8_STATUS_OK ? image : nil;
}

static enum WEBP_CSP_MODE webp_cs_mode_from_cg_bitmap_info(CGBitmapInfo info, BOOL *fail, BOOL usebgrAMode) {
    CGImageByteOrderInfo byteOrder = info & kCGBitmapByteOrderMask;
    BOOL keepByteOrder;
    switch (byteOrder) {
        case kCGImageByteOrder32Big:
            keepByteOrder = YES;
            break;
        case kCGImageByteOrder32Little:
            keepByteOrder = NO;
            break;
        case kCGImageByteOrder16Big:
        case kCGImageByteOrder16Little:
        case kCGImageByteOrderDefault:
        case kCGImageByteOrderMask:
            *fail = YES;
            return MODE_RGBA;
    }

    CGImageAlphaInfo ai = info & kCGBitmapAlphaInfoMask;
    switch (ai) {
        case kCGImageAlphaLast:
        case kCGImageAlphaNoneSkipLast:
            return keepByteOrder ? MODE_RGBA : MODE_ARGB;
        case kCGImageAlphaNone:
            return keepByteOrder ? MODE_RGB  : MODE_BGR;
        case kCGImageAlphaFirst:
        case kCGImageAlphaNoneSkipFirst:
            return keepByteOrder ? MODE_ARGB : MODE_BGRA;
        case kCGImageAlphaPremultipliedLast:
            return keepByteOrder ? MODE_rgbA : MODE_Argb;
        case kCGImageAlphaPremultipliedFirst:
            return keepByteOrder ? MODE_Argb : (usebgrAMode ? MODE_bgrA : MODE_rgbA);
        case kCGImageAlphaOnly:
            *fail = YES;
            return MODE_RGB;
    }
}

@end
