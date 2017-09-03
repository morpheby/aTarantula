#import <Foundation/Foundation.h>

@interface CDEConfiguration : NSObject

#pragma mark - Properties
@property (nonatomic, nullable, readonly) NSURL *storeURL, *modelURL, *applicationBundleURL;
@property (nonatomic, nullable, copy) NSString *applicationBundlePath;
@property (nonatomic, nullable, retain) NSDictionary *autosaveInformationByEntityName;
@property (nonatomic, nullable, copy) NSNumber *isMacApplication;
@property (nonatomic, nullable, copy) NSString *modelPath;
@property (nonatomic, nullable, copy) NSString *storePath;

#pragma mark - Properties
@property (nonatomic, readonly, getter = isValid) BOOL isValid;

#pragma mark - Setting URLs
- (void)setApplicationBundleURL:(nullable NSURL *)applicationBundleURL storeURL:(nullable NSURL *)storeURL modelURL:(nullable NSURL *)modelURL;

- (nonnull NSData *)data;
- (nullable instancetype)initWithData:(nullable NSData *)data;

@end
