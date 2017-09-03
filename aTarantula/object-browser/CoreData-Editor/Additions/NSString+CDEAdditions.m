#import "NSString+CDEAdditions.h"
#import "NSUserDefaults+CDEAdditions.h"

@implementation NSString (CDEAdditions)

#pragma mark - Human Readable Name
- (NSString *)humanReadableString_cde {
    // http://stackoverflow.com/questions/2559759/how-do-i-convert-camelcase-into-human-readable-names-in-java
    // source: https://github.com/mfornos/humanize
    NSString *pattern = @"(?<=[A-Z])(?=[A-Z][a-z])|(?<=[^A-Z])(?=[A-Z])|(?<=[A-Za-z])(?=[^A-Za-z])";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
    NSString *result = [expression stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@" "];
    if(result != nil) {
        // capitalize first letter
        if(result.length > 0) {
            NSString *firstLetter = [result substringToIndex:1];
            NSString *tail = [result substringFromIndex:1];
            result = [[firstLetter uppercaseString] stringByAppendingString:tail];
        }
    }
    return result == nil ? self : result;
}

- (NSString *)humanReadableStringAccordingToUserDefaults_cde {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL humanize = defaults.showsNiceEntityAndPropertyNames_cde;
    return humanize ? [self humanReadableString_cde] : self;
}

@end
