#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSString (CDEAdditions)

#pragma mark - Human Readable Name
- (NSString *)humanReadableString_cde;
- (NSString *)humanReadableStringAccordingToUserDefaults_cde;

@end
