
#import "RNMergeImages.h"

@implementation RNMergeImages

- (NSString *)saveImage:(UIImage *)image {
    NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *fullPath = [NSString stringWithFormat:@"%@%@.jpg", NSTemporaryDirectory(), fileName];
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:fullPath atomically:YES];
    return fullPath;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

- (NSDictionary *)constantsToExport
{
    return @{
             @"Size": @{
                    @"largest": @"1",
                    @"smallest": @"0",
                },
             @"Target": @{
                 @"temp": @"1",
                 @"disk": @"0",
                 }
             };
}

RCT_EXPORT_METHOD(merge:(NSArray *)imagePaths
                  options:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{

    NSMutableArray *images = [@[] mutableCopy];
    CGSize contextSize = CGSizeMake(0, 0);
    for (id tempObject in imagePaths) {
        NSURL *URL = [RCTConvert NSURL:tempObject];
        NSData *imgData = [[NSData alloc] initWithContentsOfURL:URL];
        if (imgData != nil)
        {
            UIImage *image = [[UIImage alloc] initWithData:imgData];
            [images addObject:image];

            CGFloat width = image.size.width;
            CGFloat height = image.size.height;
            if (width > contextSize.width || height > contextSize.height) {
                contextSize = CGSizeMake(width, height);
            }
        }
    }
    // create context with size
    UIGraphicsBeginImageContext(contextSize);
    // loop through image array

    for (UIImage *image in images) {
        [image drawInRect:CGRectMake(0,0,contextSize.width,contextSize.height)];
    }
    // creating final image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // save final image in temp
    NSString *imagePath = [self saveImage:newImage];
    //resolve with image path
    resolve(@{@"path":imagePath, @"width":[NSNumber numberWithFloat:newImage.size.width], @"height":[NSNumber numberWithFloat:newImage.size.height]});
}


RCT_EXPORT_METHOD(mergeSideBySide:(NSArray *)imagePaths
                  options:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{

    NSMutableArray *images = [@[] mutableCopy];
    CGSize contextSize = CGSizeMake(0, 0);
    CGFloat contextHeight = 0;
    CGFloat contextWidth = 0;
    
    for (id tempObject in imagePaths) {
        NSURL *URL = [RCTConvert NSURL:tempObject];
        NSData *imgData = [[NSData alloc] initWithContentsOfURL:URL];
        if (imgData != nil)
        {
            UIImage *image = [[UIImage alloc] initWithData:imgData];
            [images addObject:image];

            CGFloat width = image.size.width;
            CGFloat height = image.size.height;
            if (height > contextHeight) {
                contextHeight = height;
            }
            contextWidth = contextWidth + width;
        }
    }

    contextSize = CGSizeMake(contextWidth, contextHeight);
    // create context with size
    UIGraphicsBeginImageContext(contextSize);
    // loop through image array
    CGFloat x = 0 ;
    CGFloat y = 0;
    for (UIImage *image in images) {
        [image drawInRect:CGRectMake(x,y,image.size.width,contextSize.height)];
        x = x + image.size.width;
    }
    // creating final image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // save final image in temp
    NSString *imagePath = [self saveImage:newImage];
    //resolve with image path
    resolve(@{@"path":imagePath, @"width":[NSNumber numberWithFloat:newImage.size.width], @"height":[NSNumber numberWithFloat:newImage.size.height]});
}
@end
