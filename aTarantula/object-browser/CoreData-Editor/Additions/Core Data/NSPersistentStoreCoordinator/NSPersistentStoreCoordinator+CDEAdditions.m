#import "NSPersistentStoreCoordinator+CDEAdditions.h"
#import "NSURL+CDEAdditions.h"

@implementation NSPersistentStoreCoordinator (CDEAdditions)

- (NSPersistentStore *)addPersistentStoreWithType:(NSString *)storeType configuration:(NSString *)configuration URL:(NSURL *)storeURL options:(NSDictionary *)options error_cde:(NSError **)error {
  // We have a store type: Go the usual path
  if(storeType != nil) {
    return [self addPersistentStoreWithType:storeType configuration:configuration URL:storeURL options:options error:error];
  }

  NSLog(@"storeType is not set: Cannot add persistent store.");
  return nil;
}

@end
